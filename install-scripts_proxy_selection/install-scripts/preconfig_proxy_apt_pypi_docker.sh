#!/usr/bin/env bash

# Has functions defined to configure the following in a newly set up VM:
#   (configureProxy):   Set Proxy with Porsche Prague data 
#   (configureAptPackages): Install Needed base Apt Packages 
#   (configureGit): Configure Git with Proxy and user details 
#   (configureAptSources):  Configure artifactory debian sources for devstack 
#   (configurePyPI):    Configure PyPI with artifactory 
#   (configureDocker):  Configure Docker settings with user authentication keys and docker sources 

# all these helper functions are executed as a part of wrapper function preconfig.

# Initial proxy set-up
function configureProxy()
{
    gsettings set org.gnome.system.proxy mode 'auto'
    gsettings set org.gnome.system.proxy autoconfig-url "$auto_proxy_url"

    nmcli connection show
    # CONNECTION_NAME=$(nmcli connection show | awk -F'  ' 'NR==2 {print $1}')
    CONNECTION_NAME=$(nmcli connection show | grep Wired | awk -F'  ' '{print $1}')
    sudo nmcli con mod "$CONNECTION_NAME" ipv4.method auto
    sudo nmcli con mod "$CONNECTION_NAME" ipv4.dns "$dns_data"
    sudo nmcli con mod "$CONNECTION_NAME" ipv6.method ignore
    sudo nmcli con up "$CONNECTION_NAME"
    sudo systemctl restart NetworkManager

    # configuring the apt proxy
    case $PROXY_VAR in 
        [yY] ) echo "Proceeding with apt proxy configuration";
            # Configuring proxy 
            [ -e "$localPath_proxy_conf" ] && sudo rm "$localPath_proxy_conf" || sudo touch "$localPath_proxy_conf"
            #[ -e "$localPath_proxy_conf" ] || sudo touch "$localPath_proxy_conf"
            echo "$proxy_conf_data" | sudo tee -a "$localPath_proxy_conf"
            break;;
        [nN] ) echo "Not setting apt proxy";
            continue;;
        * ) echo "invalid response in 'configureProxy' function";;
    esac

    # Check if the source exists in apt.conf
    case $PROXY_VAR in 
        [yY] ) echo "Proceeding with proxy configuration";
            # Configuring proxy 
            if ! grep -qF "$proxy_conf_data" "$localPath_proxy_conf"; then
                echo "$proxy_conf_data" | sudo tee -a "$localPath_proxy_conf"
            else
                echo "Line already exists in apt.conf"
            fi
            break;;
        [nN] ) echo "Not setting apt.conf proxy";
            continue;;
        * ) echo "invalid response in 'configureProxy' function";;
    esac

}

# configure needed base apt packages before adding devstack repo source
function configureAptPackages()
{
    # needs to disable security repositories in apt sources
    sudo sed -i '/^deb http:\/\/security.ubuntu.com\/ubuntu focal-security/ s/^/# /' $localPath_sourcesList

    sudo apt update
    sudo apt full-upgrade -y
    for tool in "${requiredTools[@]}" ; do
        sudo apt install -y $tool
    done
}

# configure Git with proxies
function configureGit()
{
    name_surname=''
    email=''

    # Check for name and surname
    echo "Please type in your name and surname (for GitLab):"
    read -rp "" name_surname

    # Chceck for email
    echo "Please type in your email (for GitLab):"
    read -rp "" email

    # git global settings
    git config --global credential.helper store
    git config --global user.name "$name_surname"
    git config --global user.email "$email"

    case $PROXY_VAR in 
        [yY] ) echo "Proceeding with Git proxy configuration";
            # Configuring proxy 
            git config --global http.proxy "$http_proxy"
            git config --global https.proxy "$http_proxy"
            break;;
        [nN] ) echo "Not setting Git proxy";
            continue;;
        * ) echo "invalid response in 'configureGit' function";;
    esac

}

# Configure APT sources for E3 
function configureAptSources()
{
    # Get args
    local distribution=($(echo "$debDistribution" | tr ',' ' '))
    
    # ASSUMPTION: E3 DEBIAN FILE DOES NOT EXIST
    if [ ! -f "$localPath_devstack_srcs" ] ; then

        # Creating devstack.list
        echo "Creating FILE '$localPath_devstack_srcs'..."
        sudo mkdir -p "$(dirname $localPath_devstack_srcs)" && sudo touch $localPath_devstack_srcs

        # REPLACE UBUNTU REPOS (not needed for VWIF)
        # Mirror general Ubuntu repos
        echo "Using DevStack E3 Debian repositories instead of general Ubuntu ones..."
        # Copy content of sources.list
        sudo cp $localPath_sourcesList $localPath_devstack_srcs
        sudo sed -i '/^# deb http:\/\/security.ubuntu.com\/ubuntu focal-security/ s/^# //' $localPath_devstack_srcs
        # Replace Ubuntu urls with DevStack urls
        sudo sed -ri "s!$pattern_ubuntuUrl!$e3_baseUrl/artifactory/!g" $localPath_devstack_srcs

        # PROD REPO -> Just one entry
        echo "Adding PROD repo to FILE '$localPath_devstack_srcs'..."
        echo "" | sudo tee -a $localPath_devstack_srcs  
        echo "# [IDE.HUB] Entries for private E3 repositories" | sudo tee -a $localPath_devstack_srcs  
        for el in "${distribution[@]}" ; do
            echo "deb [trusted=yes] $e3_baseUrl$e3_debian_prod_repo $el private" | sudo tee -a $localPath_devstack_srcs  
        done

        if [[ "$operatingSystem" =~ "Ubuntu 22.04" ]]; then
            echo "Adding python3.8 PROD repo for Ubuntu 22.04 from deadsnakes ppa."
            echo "deb [trusted=yes] $e3_baseUrl$e3_debian_prod_repo jammy main" | sudo tee -a $localPath_devstack_srcs  
        fi
    fi
}

# Configure local PyPI
function configurePyPI()
{
    # ASSUMES: previous pip config doesnt exist.
    # Declare local variables
    local pathToConf
    local strippedBaseUrl

    # Get arguments
    pathToConf=$1

    # Remove protocol https:// from URL
    strippedBaseUrl=$(echo "$e3_baseUrl" | sed -n 's|.*//||p')
    
    echo "Writing DevStack PyPI's into '$pathToConf'..."

    # Create pip config dir
    mkdir -p "$HOME"/.config/pip
        
    # Write general/private E3 PyPI to pip.conf
    echo "[global]" | tee "$pathToConf" 

    echo "index-url = https://${strippedBaseUrl}${e3_pypi_indexUrl}" | tee -a "$pathToConf" 
    echo "extra-index-url = https://${strippedBaseUrl}${e3_pypi_sdk_indexUrl}" | tee -a "$pathToConf" 
    echo "trusted-host = ${strippedBaseUrl}" | tee -a "$pathToConf" 
}

# Configure docker settings and profiles
function configureDocker()
{
    # Check if required tools are installed
    for tool in "${requiredTools_docker[@]}" ; do
        sudo apt install -y "$tool"
    done

    # Add docker gpg key to local APT keys
    local authFile="docker.gpg"
    echo "Trying to GET public GPG key for docker from route $e3_docker_gpgKey_endpoint"
    curl -o "$authFile" -u "$vw_user":"$vw_pass" -X GET "$e3_baseUrl$e3_docker_gpgKey_endpoint"
    echo "Trying to add public GPG key to local APT keys"
    sudo apt-key add "$authFile"
    rm "$authFile"

    # Generate docker.list
    echo "deb [arch=$(dpkg --print-architecture)] "$e3_baseUrl$e3_docker_repo" $(lsb_release -cs) stable" | sudo tee "$localPath_docker_srcs" > /dev/null
    sudo apt update

    # Add user to groupd "docker"
    sudo usermod -aG docker "$USER"
}

# Configure required tools before installation
function preconfig() 
{
    
    case $PROXY_VAR in 
        [yY] ) echo "Proceeding with proxy configuration";
            # Configuring proxy 
            log "${NC}Configuring private Proxy for external communication"
            configureProxy
            log "${GREEN}Done"
            break;;
        [nN] ) echo "Continue without setting proxy in 'preconfig' function";;
            
        * ) echo invalid response in preconfig;;
    esac


    # Configure E3 Debian repositories
    log "${NC}Configuring the stock security sources and installing needed base packages"
    configureAptPackages
    log "${GREEN}Done"

    # Configure Git for the necessary proxy
    log "${NC}Configuring git"
    configureGit
    log "${GREEN}Done"

    # Configure E3 Debian repositories
    log "${NC}Configuring private Debian repositories"
    configureAptSources
    log "${GREEN}Done"

    # Fetch and store GPG key 
    log "${NC}Configuring public DevStack GPG key"
    getDevstackPublicGpgKey
    log "${GREEN}Done"

    # Fetch and store encrypted password 
    log "${NC}Configuring encrypted DevStack password"
    getDevstackEncryptedPassword
    log "${GREEN}Done"

    # Configure local PyPI 
    log "${NC}Configuring private E3 Python Package Index (PyPI)"
    configurePyPI "$localPath_pip_confFile"
    log "${GREEN}Done"

    # Configure docker
    log "${NC}Configuring Docker installation"
    configureDocker
    log "${GREEN}Done"
}
