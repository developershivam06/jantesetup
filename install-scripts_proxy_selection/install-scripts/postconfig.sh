#!/usr/bin/env bash

# Has functions defined to help setup dev and test environment:
#   (configureMVP):   Configures pip dependencies for MVP
#   (configureConan):   Configures pip dependencies for Conan
#   (checkConanFiles):   Verifies that Conan install dir is added to PATH
#   (configureConanCLI):  Configures Conan client
#   (addUserToQEMU): Adds user to relevant QEMU groups

# all these helper functions are executed as a part of wrapper function postconfig.

# Configures pip dependencies for MVP
function configureMVP() {
    local indexUrl="https://${vw_user}:${vw_pass}@$pypiUrl"
    # Loop over pip dependencies
    for pipPkg in "${e3_mvp_pipDependencies[@]}"; do
        # Update pip package
        python3 -m pip install -i "${indexUrl}" -U $pipPkg || die "Could not update '$pipPkg' using pip." "$LINENO" "${BASH_SOURCE[0]}"
    done 
}

# Configures pip dependencies for Conan
function configureConan() {
    local indexUrl="https://${vw_user}:${vw_pass}@$pypiUrl"
    # Loop over pip dependencies
    for pipPkg in "${e3_docker_pipDependencies[@]}" ; do
        echo "Trying to install pip package "$pipPkg"" # in target version '$pkgVers'"
        
        # Install with pip
        python3 -m pip install -i "${indexUrl}" -U "$pipPkg" || die "Could not install required dependency "$pipPkg" using pip3." "$LINENO" "${BASH_SOURCE[0]}"
    done
}

# Verifies that Conan install dir is added to PATH
function checkConanFiles() {
    # Check if ~/.bashrc is present
    [[ ! -f $pathToBashRc ]] && echo "Could not find ~/.bashrc in user home. Add this file after script execution."

    # Verify that Conan's install dir exists and is added to PATH in .profile
    if [[ -d $conanInstallDir && -z $(regexMatch $pattern_conan $pathToBashRc) ]] ; then
        echo "Extending FILE '$pathToBashRc' to make 'conan' CLI available"

        # Extend user's PATH in profile
        echo '' | sudo tee -a $pathToBashRc 
        echo '# extend PATH for conan CLI' | sudo tee -a $pathToBashRc 
        echo 'if [ -d "$HOME/.local/bin" ] ; then' | sudo tee -a $pathToBashRc
        echo '    PATH="$HOME/.local/bin:$PATH"' | sudo tee -a $pathToBashRc 
        echo 'fi' | sudo tee -a $pathToBashRc 
        
        # Inform user to kill shell
        echo -e "${YELLOW}Please restart your shell after script execution to make 'conan' CLI available for you."
    else
        echo "PATH '$conanInstallDir' is already present in FILE '$pathToBashRc'"
    fi

    # Temporary add Conan install dir to PATH
    if [[ ! "$PATH" =~ "$HOME/.local/bin" && -d "$HOME/.local/bin" ]] ; then
        # Inform the user and extend the PATH
        echo -e "${NC}Extending PATH to make 'conan' CLI available"
        PATH="$HOME/.local/bin:$PATH"
    fi
}

# Configures Conan client
function configureConanCLI() {
    # Define variables
    local tempgitdir="e3_conan_settings_e3sdkinstaller"
    local remoteFile="remotes.txt"
    local remoteFileBackup="remotes.txt.bak"
    local conanCache=$HOME/.conan
    local conanUrl=$(echo "$e3_bitbucketBaseUrl$e3_conan_repo" | sed -n 's|.*//||p') # remove https:// from conan url

    {
    if [[ "${CI:-false}" != "true" ]]; then   
    rm -rf ${tempgitdir}

    # Clone Conan settings repo
    git clone "https://${vw_user}:${vw_pass}@$conanUrl" ${tempgitdir} 
    fi

    # Authenticate user against Conan remotes
    echo "Authenticate '$USER' against Conan remotes"
    
    # Install global remotes
    conan config install $tempgitdir || die "Could not install global E3 Conan settings" "$LINENO" "${BASH_SOURCE[0]}"
    # Loop over remotes and authenticate user
    for conanRemote in "${conanRemotes[@]}"
    do
        echo "Trying to login '$vw_user' to conan remote '$conanRemote'"
        conan user "${vw_user}" -p "${vw_pass}" -r $conanRemote || die "Could not login to Conan remote '$conanRemote'." "$LINENO" "${BASH_SOURCE[0]}"
    done

    # Cleanup temorary directory
    rm -rf ${tempgitdir}
    
    } || die "Could not apply global E3 Conan settings to local Conan client." "$LINENO" "${BASH_SOURCE[0]}" 
}

# Adds user to relevant QEMU groups
function addUserToQEMU() {
    # Loop over required qemu groups
    for qemuGroup in "${e3_qemu_groups[@]}" ; do
        # Add user to dedicated group
        if [[ ! -z $(regexMatch $qemuGroup "/etc/group") ]]
        then
            sudo usermod -aG $qemuGroup $USER
            echo -e "${YELLOW}Reboot the system to apply changes on '$qemuGroup'."
        else
        echo -e "${YELLOW}Local group '$qemuGroup' does not exist"
        fi
    done
}

# Function wrapper
function postconfig() {
    # Fetch and store encrypted password
    log "${NC}Configuring encrypted DevStack password"
    getDevstackEncryptedPassword
    log "${GREEN}Done"

    # Login to Docker registry
    log "${NC}Login to E3 Docker registry '$e3_docker_registry'"
    docker login -u "$vw_user" -p "$enc_pw" $e3_docker_registry || die "Could not login to E3 docker registry '$e3_docker_registry'." "$LINENO" "${BASH_SOURCE[0]}"
    log "${GREEN}Done"

    log "${NC}Trying to update required pip dependencies for MVP..."
    configureMVP
    log "${GREEN}Done"

    #log "${NC}Trying to install required pip dependencies for Conan..."
    #configureConan
    #log "${GREEN}Done"

    #log "${NC}Checking if Conan install directory exists..."
    #checkConanFiles
    #log "${GREEN}Done"
    
    # Configure Conan client
    ##log "${NC}Configuring local Conan client..."
    #configureConanCLI
    #log "${GREEN}Done"

    # Add user to required Qemu groups
    log "${NC}Adding user $USER to required testing groups"
    addUserToQEMU
    log "${GREEN}Done"
}
