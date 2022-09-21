#!/bin/bash

#################################################################################
#                                                                               #
#  Basic script to prepare a Linux instance to be able to run Terraform code.   #
#                                                                               #
#  By default, it will install the latest Terraform binary and the tfswitch     #
#  utility. The following options are supported, and will install the           #
#  corresponding cloud CLI utility. This shouldn't be needed if this is being   #
#  run in a cloud shell, but can be helpful if running in a local VM or bare    #
#  cloud Linux instance.                                                        #
#                                                                               #
#################################################################################

# Functions
function install_cloud_cli {
    if [ "$CLOUD" = "aws" ]; then
        PKG_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
        cd /home/vagrant
        curl -sSL $PKG_URL -o awscliv2.zip
        unzip awscliv2.zip
        # AWS does some jackery by needing lsb-release, which appears broken in xenial
        # so we symlink it to a proper python path...idk, could be the package 
        # maintainers jackery too
        sudo cp /usr/share/pyshared/lsb_release.py /usr/lib/python3.6/site-packages/.
        ./aws/install
    elif [ "$CLOUD" = "azure" ]; then
        PKG_URL="https://azurecliprod.blob.core.windows.net/rhel7_6_install.sh"
        cd /home/vagrant
        curl -sSL $PKG_URL -o az-installer.sh
        bash az-installer.sh

    elif [ "$CLOUD" = "gcp" ]; then
        PKG_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-402.0.0-linux-x86_64.tar.gz"
        cd /home/vagrant
        curl -sSL $PKG_URL -o gcloud-install.sh
        tar xzfv gcloud-install.sh
        bash google-cloud-sdk/install.sh
    else
        printf "Skipping cloud CLI installation"
    fi
}

function probe_pkg_manager {
    if [ "$(which yum)" ]; then
        PM="yum"
        probe_os
        echo "done"
    elif [ "$(which dnf)" ]; then
        PM="dnf"
        probe_os
        echo "done"
    elif [ "$(which apt)" ]; then
        PM="apt"
        echo "done"
    else
        PM="unsupported"
        echo "done"
    fi
}

# Needed to populate the RELEASE variable for yum/dnf releases from Hashi
function probe_os {
    if cat /etc/system-release | grep "CentOS"; then
        # There is no "centos" dir at Hashi, so we use RHEL here
        RELEASE="RHEL"
    elif cat /etc/system-release | grep "Amazon"; then
        RELEASE="amazon"
    elif cat /etc/system-release | grep "Fedora"; then
        RELEASE="fedora"        
    else :
    fi
}

function tfswitch_install {
    curl -Ls https://github.com/warrensbox/terraform-switcher/archive/refs/tags/0.13.1288.tar.gz -o /tmp/tfswitch.tar.gz
    cd /tmp/tfswitch
    tar -xzvf /tmp/tfswitch.tar.gz
    make
    make install
}

function yum_install {
    echo "sudo may be needed to install packages. You may be prompted for your password"
    printf "Installing dependencies..."
    sudo yum makecache
    sudo yum install -y -q curl net-tools yum-utils unzip zlib-devel lsb-release \
        make automake gcc gcc-c++ kernel-devel openssl-devel sqlite-devel
    echo "done"
    printf "Installing Terraform..."
    sudo yum-config-manager -yq --add-repo https://rpm.releases.hashicorp.com/$RELEASE/hashicorp.repo
    sudo yum makecache
    sudo yum install -y -q terraform
    tfswitch_install
    echo "done"
}

function dnf_install {
    echo "sudo may be needed to install packages. You may be prompted for your password"
    printf "Installing dependencies..."
    sudo dnf install -y -q curl net-tools dnf-plugins-core unzip zlib-devel lsb-release \
        make automake gcc gcc-c++ kernel-devel openssl-devel sqlite-devel
    echo "done"
    printf "Installing Terraform..."
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/$RELEASE/hashicorp.repo
    sudo dnf install -y -q terraform
    tfswitch_install
    echo "done"
}

function apt_install {
    echo "sudo may be needed to install packages. You may be prompted for your password"
    printf "Installing dependencies..."
    # Prevent errors from not having a tty assigned
    DEBIAN_FRONTEND=noninteractive sudo apt-get update -qq
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -yqq curl net-tools apt-utils unzip \
        apt-transport-https ca-certificates gnupg build-essential zlib1g-dev libssl-dev \
        libsqlite3-dev lsb-release
    echo "done"
    printf "Installing Terraform..."
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    DEBIAN_FRONTEND=noninteractive sudo apt-add-repository -y \
        "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    DEBIAN_FRONTEND=noninteractive sudo apt-get update -qq 
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -yqq terraform
    tfswitch_install
    echo "done"
}

# Check for args and offer possible args
case $1 in
  aws)
    CLOUD="aws"
    ;;

  azure)
    CLOUD="azure"
    ;;

  gcp)
    CLOUD="gcp"
    ;;

  *)
    echo "No or unrecognized input arguments provided. Installing just the generic utilities."
    echo "
    To add cloud-specific CLI tools, pass one of the following as an input arg:
      - aws
      - gcp
      - azure
    "
    ;;
esac


# Check for package manager
printf "Probing for package manager..."
probe_pkg_manager
echo "done"
case $PM in
    yum)
    yum_install
    echo "done"
    ;;

    dnf)
    dnf_install
    echo "done"
    ;;

    apt)
    apt_install
    echo "done"
    ;;

    unsupported)
    echo "Unsupported or unknown package manager...exiting"
    echo "
    This script only supports: 
    - RedHat/CentOS/Fedora/Amazon Linux 2
    - Debian/Ubuntu
    "
    exit 1
    ;;
esac

# Install cloud tools
if [ ! -z "$CLOUD" ]; then
    printf "Installing $CLOUD tools..."
    install_cloud_cli
    echo "done"
fi