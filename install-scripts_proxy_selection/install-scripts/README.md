# Environment Setup Scripts

This set of Bash scripts is designed to assist you in setting up your Ubuntu environment for testing. The main script, `install_environment.sh`, orchestrates the configuration of various components such as proxies, Git, APT sources, Docker, and more. The goal is to prepare your system for software development and testing tasks.

## Prerequisites

Before running these scripts, you will need:

1. Installed Ubuntu 20.04 or Ubuntu 22.04 on your VM.
2. Access to DevStack and Artifactory.

## How to Use

To configure your environment using the provided scripts, follow these steps:

1. **Navigate to the Directory**: Change your working directory to the cloned repository
    ```bash
    $ cd /install_scripts
    ```
2. **Run the main script**: Execute the install_environment.sh script. This script will install the test environment (proxy, Git, APT sources, Docker, ...)
    ```bash
    $ ./install_environment.sh
    ```
    - You will be prompted for DevStack and GitLab credentials
    - You will be asked to reboot during the scripts execution. After the reboot repeat steps **1**. and **2.** from this section.
    - After the script finishes you should restart your shell.

## Included Scripts

- `config.sh`: This script contains initial configuration settings, such as proxy settings, URLs, dependencies etc.
- `utils.sh`: Contains utility functions used in other scripts (regular expression matching, credential prompts, GPG key retrieval, ...).
- `preconfig_proxy_apt_pypi_docker.sh`: Sets up the proxy, APT sources, Git, Docker, and other prerequisites before configuring DevStack repositories.
- `postconfig.sh`: Configures various tools and components, including Pip dependencies for MVP, Conan, and QEMU, as well as Docker, and more.
- `install_environment.sh`: This script wraps all of the above scripts.