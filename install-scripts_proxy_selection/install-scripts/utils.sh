#!/usr/bin/env bash

# Has utility helper functions defined to help setup dev and test environment:
#   (regexMatch):   Regular Expression Matcher 
#   (promptForCredentials):   Request DevStack Credentials
#   (getDevstackEncryptedPassword):   Gets encrypted devstack password and saves as authententication file for private debian repos
#   (configureAptSources):  Configure artifactory debian sources for devstack 
#   (getDevstackPublicGpgKey): Requests a devstack public gpg key and saves to APT keys

# Regular expression matcher
function regexMatch()
{
    # Get arguments
    local pattern=$1
    local target=$2

    # Checking for FILE stream
    if [ -f $target ] ; then
        # Do regEx search
        match=$(grep -oP $pattern $target)

    # Checking for STRING stream
    else
        # Do regex search
        match=$(grep -oP $pattern <<< $target)
    fi

    # Return match
    echo $match
}

# Request DevStack credentials
function promptForCredentials()
{
    # Check for vw user
    echo "Please type in your DevStack user:"
    read -rp "" vw_user
    unset vw_pass
  
    # Check for vw pass
    echo "Please provide password for DevStack user '$vw_user':"
    read -rsp "" vw_pass
    echo ""
}

# Get encrypted password for DevStack
function getDevstackEncryptedPassword()
{ 
    # Define local variables
    local numOfAttempts=1
    local strippedBaseUrl
    local strippedOldBaseUrl
    
    strippedBaseUrl=$(echo "$e3_baseUrl" | sed -n 's|.*//||p') # remove https:// from URL
    strippedOldBaseUrl=$(echo "$e3_bitbucketBaseUrl" | sed -n 's|.*//||p') # remove https:// from URL
    enc_pw=$(curl -u "$vw_user":"$vw_pass" -X GET "$e3_baseUrl$e3_devstack_encPw_endpoint")

    # Check if credentials are valid
    while echo "$enc_pw" | grep -q 'errors'; do
        # Check for number of attempts
        if [ $numOfAttempts -eq 2 ] ; then
            echo "Could not get 'encrypted password' from DevStack Artifactory REST API. Ensure that you provided correct credentials or that your account is not locked."
        fi

        # Increment number of attempts
        ((numOfAttempts=numOfAttempts+1))

        # Prompt user for additional attempt
        echo "Incorrect username or password." 
        echo "Please type in DevStack user:"
        read -rp "" vw_user
        echo "Please type in your DevStack password:"
        read -rsp "" vw_pass
        echo ""

        # Request artifactory again
        echo "Trying again to GET encrypted password from Artifactory REST API"
                
        enc_pw=$(curl -u "$vw_user":"$vw_pass" -X GET "$e3_baseUrl$e3_devstack_encPw_endpoint" 2>/dev/null)
    done

    # Create devstack.auth file
    echo "Trying to create local authentication file for APT to store encrypted password..."
    sudo mkdir -p "$(dirname $localPath_devstack_auth)" && sudo touch $localPath_devstack_auth

    # Store credentials for apt
    echo "Writing encrypted password into $localPath_devstack_auth..."

    # Create authentication file for private Debian repos
  {
sudo tee $localPath_devstack_auth >/dev/null <<- EOF
machine $strippedBaseUrl/artifactory login $vw_user password $enc_pw
machine $strippedOldBaseUrl/artifactory login $vw_user password $enc_pw
EOF
} || echo "Could not get and save encrypted password in '$localPath_devstack_auth' authentication file."

    # Make sure only root can read them
    sudo chown root:root "$localPath_devstack_auth" || echo "Couldn't set root as owner of $localPath_devstack_auth."
    sudo chmod 600 "$localPath_devstack_auth" || echo "Couldn't change access rights for $localPath_devstack_auth."
}

# Fetch and configure GPG key
function getDevstackPublicGpgKey()
{
    # Define local variables
    local authFile="devstack_key.gpg"

    # Call apiGet function from commons.sh
    echo "Trying to GET public GPG key from Artifactory REST API for VW user '$vw_user'"
    curl -o "$authFile" -u "$vw_user":"$vw_pass" -X GET "$e3_baseUrl$e3_devstack_gpgKey_endpoint" 

    # Adding GPG key to APT keys
    echo "Trying to add GPG key to APT keys to authenticate private E3 Debian pkgs..."
    # Add GPG key to APT
    ( sudo apt-key add $authFile ) 

    # Check for execution
    if [ $? -ne 0 ] ; then
        #checkForWrongSudoPw
        echo "Could not get 'public GPG key' from DevStack Artifactory. Ensure that you provided correct credentials or that your account is not locked."
        exit 1
    fi
    # Remove tmp file
    rm $authFile
}