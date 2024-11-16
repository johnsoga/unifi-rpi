#!/bin/bash

UBUNTU_CODENAME=jammy
PRIMARY_USER=""
SOURCE_PATH=$PWD
CONFIG_FILE=$SOURCE_PATH/params.conf

function create_user() {

    if [ "$PRIMARY_USER" = "" ]; then
        printf "FAILURE: No User Provided!\n"
        exit 1
    fi

    printf "Checking User ($PRIMARY_USER)...\n"
    if id "$PRIMARY_USER" >/dev/null 2>&1; then
        printf "User ($PRIMARY_USER) already exists!\n"
    else
        printf "Creating user $PRIMARY_USER...\n"
        sudo adduser "$PRIMARY_USER"
    fi

    printf "Adding User to Sudoers Group...\n"
    sudo usermod -aG sudo "$PRIMARY_USER"
}

function install_ansible() {

    printf "Checking for Ansible (Dependency)...\n"
    if ! command -v ansible-playbook &> /dev/null; then
        printf "Installing Ansible...\n"
        
        wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list

        # Update Repository Inventory & Install Required Packages
        sudo apt update && sudo apt install ansible && INSTALLED=true

        if [ "$INSTALLED" == "true" ]; then
            printf "Ansible now installed!\n"
        else
            printf "FAILURE: Ansible was unable to be installed!\n"
        fi
    else
        printf "Ansible already installed!\n"
    fi

}

function install_docker() {

    printf "Checking for Docker (Dependency)...\n"
    if ! command -v docker 2>&1 >/dev/null; then
        printf "Installing Docker...\n"

        sudo apt update && sudo apt install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update
        sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        printf "Docker already installed!\n"
    fi 

    printf "Enable Docker in SystemD on boot...\n"
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    printf "Adding user ($PRIMARY_USER) to docker group...\n"
    sudo usermod -aG docker $PRIMARY_USER 
}

if test -f ${CONFIG_FILE}; then
    printf "SUCCESS: Using config ${CONFIG_FILE}\n"
    . ${CONFIG_FILE}
else
    printf "FAILURE: No Config File Found!\n"
    exit 1
fi

create_user
install_ansible
install_docker
