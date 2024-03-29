# initial config
g_is_verbose=1
requiredTools=('curl' 'docker' 'git' 'build-essential' 'gcc' 'python3' 'python3-pip' 'python3-venv' 'kvmtool' 'libvirt-dev' 'libverto1' 'libverto-dev' 'libverto-glib1' 'libverto-libevent1' 'containerd' 'docker.io' 'qemu' 'qemu-system' 'libxml2-utils')
supportedPlatforms=('Ubuntu 20.04' 'Ubuntu 22.04')
localPATHS=$(echo $PATH)
pathToBashRc="$HOME/.bashrc"

# formatting preferences
GREEN='\033[0;32m'
NC='\033[0m'
RED='\e[31m'
YELLOW='\e[33m'

# proxy config
auto_proxy_url='http://proxy-autoconfig-prg.tech.emea.porsche.biz/'      # replace this with your proxy settings
http_proxy='http-proxy.porsche.org:3133'      # replace this with your proxy settings
dns_data='141.36.46.129, 141.36.225.1'      # replace this with your proxy settings
localPath_proxy_conf='/etc/apt/apt.conf'
proxy_conf_data='Acquire::http::Proxy "http://http-proxy.porsche.org:3133";'      # replace this with your proxy settings

# user config
vw_user=''
vw_pass=''
debComp="private"
debDistribution=("trusty" "focal")
operatingSystem=$(grep -oP '^PRETTY_NAME=.*' /etc/os-release | cut -d "=" -f2 | sed 's/^.\{1\}//' | sed 's/.$//')

# apt source config
e3_baseUrl='https://jfrog.devstack.vwgroup.com'
e3_bitbucketBaseUrl='https://devstack.vwgroup.com'
e3_devstack_gpgKey_endpoint='/artifactory/api/gpg/key/public'
e3_devstack_encPw_endpoint='/artifactory/api/security/encryptedPassword'
localPath_devstack_auth='/etc/apt/auth.conf.d/devstack.conf'
e3_debian_prod_repo='/artifactory/e3-e3sp-deb-repo'
e3_debian_test_repo='/artifactory/e3-e3sp-deb-repo-test'
localPath_sourcesList=/etc/apt/sources.list
localPath_devstack_srcs='/etc/apt/sources.list.d/devstack.list'

# pip config
localPath_pip_confFile=~/.config/pip/pip.conf
e3_pypi_indexUrl='/artifactory/api/pypi/pypi/simple'
e3_pypi_sdk_indexUrl='/artifactory/api/pypi/e3-e3sp-sdk-pypi/simple'
pypiUrl=$(echo "$e3_baseUrl$e3_pypi_indexUrl" | sed -n 's|.*//||p') # remove https:// from pypi url

# regex patterns
pattern_vwInf='Infotainment'
pattern_ubuntuUrl='http:\W{2}.*(security|archive).ubuntu.com\S?'
pattern_identifier='(develop\z|E3SDK-\d*\z|RC\d{1,2}\z)?$'
pattern_releaseVersion='\K([1-9]+\.[0-9]+\.[0-9]$)'
pattern_version='^([0-9]+\.[0-9]+\.[0-9]+)(?:-(develop\z|E3SDK-\d*\z|RC\d{1,2}\z))?$'
pattern_conan='PATH=.*/\.local/bin.*'

# docker config
requiredTools_docker=('ca-certificates' 'curl' 'gnupg' 'lsb-release')
localPath_dockerHome=~/.docker
localPath_docker_srcs='/etc/apt/sources.list.d/docker.list'
e3_docker_registry='e3-e3sp-dockerdev.docker.devstack.vwgroup.com'
e3_docker_gpgKey_endpoint='/artifactory/deb-docker-public/gpg'
e3_docker_repo='/artifactory/deb-docker-public'
docker_min_version='20.10.0'
e3_docker_pipDependencies=('six==1.12.0' 'astroid==2.5.6' 'pylint==2.8.3' 'MarkupSafe==2.0.1' 'conan==1.35.1')  # stick to this order

# conan config
conanInstallDir="$HOME/.local/bin"
conanProfiles=('default' 'jante-aarch64' 'jante-aarch64-debug' 'ubuntu-x86_64' 'ubuntu-x86_64-debug')
conanRemotes=('e3-snapshot' 'e3-release' 'e3-app-snapshot' 'e3-app-release')
localPath_e3ConanSettings='~/e3_conan_settings_e3sdkinstaller'
e3_conan_repo='/bitbucket/scm/e3sdk/e3_conan_settings.git'

# ide_hub config
e3_idehub_deb_pkg_dependencies=('e3-sdk-emushape')  # stick to this order
idehub_deb_pkgnames=("tools-idehub" "e3-sdk-ide-hub")
e3_idehub_deb_pkg=${idehub_deb_pkgnames[0]}
e3_idehub_deb_pkg_preferences='preferences'  # appropirate $idehub_deb_pkgnames is attached to the pref during install and uninstall
e3_idehub_dev_repo='/bitbucket/scm/e3sdk/e3_sdk_install_scripts.git'

localPath_idehub_installDir='/opt/e3sdk/ide_hub'
localPath_idehub_preferences='/etc/apt/preferences.d/e3_sdk_preferences'

# qemu config
qemu_libs=('qemu' 'qemu-system')
e3_mvp_pipDependencies=('pip' 'testresources' 'setuptools' 'paramiko' 'pyopenssl')
# these are given list of apt dependencies from test automation team here for reference they arent explicitly installed"
e3_qemu_apt_dependencies=('adb' 'build-essential' 'graphviz' 'jq' 'libatlas-base-dev'
'libmaxminddb0' 'libbz2-dev' 'libc-ares2' 'libdb4o-cil-dev' 'libffi-dev' 'libgdbm-dev' 
'libgdm-dev' 'libgraphviz-dev' 'liblzma-dev' 'liblua5.2-0' 'libncurses5-dev' 'libnl-3-200' 
'libnl-genl-3-200' 'libnss3-dev' 'libpcap-dev' 'libreadline-dev' 'libpcap0.8' 'libsbc1' 
'libsmi2ldbl' 'libspeexdsp1' 'libssh-gcrypt-4' 'libssl-dev' 'libsnappy1v5' 'libspandsp2' 
'libsqlite3-dev' 'libtk8.6' 'libxcb-icccm4' 'libxcb-image0' 'libxcb-keysyms1' 
'libxcb-render-util0' 'libxcb-xinerama0' 'libxcb-xkb1' 'libxkbcommon-x11-0' 'libxkbcommon0' 
'openssl' 'picocom' 'python3.8-dev' 'python3.8-distutils' 'python3.8-venv' 'rsync' 'snapd' 
'sshpass' 'stunnel' 'tmux' 'tree' 'tshark' 'openjdk-11-jre' 'wireshark' 'xvfb' 'zlib1g-dev')
e3_qemu_groups=('libvirt' 'kvm' 'libvirt-qemu')
