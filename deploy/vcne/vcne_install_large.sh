#!/bin/bash

# Launch command example
# OCCNE_TFVARS_DIR=occne_clouduser CENTRAL_REPO=winterfell CENTRAL_REPO_IP=10.75.216.10 OCCNE_VERSION=1.5.0 CLUSTER_NAME=vzw2 LAB=arcus ./vcne_install_large.sh

# Global variables
# Set known NTP IPs for cluster.tfvars dynamic allocation

arcus_ntp=10.75.141.194
thundercloud_ntp=10.75.171.2


# Pre-Deployment global variable checks

if [ -z "${CENTRAL_REPO}" ]; then
   echo "No DOCKER_REG variable specified for all services, stopping deployment" 1>&2
   exit 1
elif [ -z "${OCCNE_VERSION}" ]; then
   echo "No OCCNE_VERSION variable specified, stopping deployment" 1>&2
   exit 1
elif [ -z "${OCCNE_TFVARS_DIR}" ]; then
   echo "No OCCNE_TFVARS_DIR variable specified, stopping deployment" 1>&2
   exit 1
fi

if [ -z "${CI_COMMIT_REF_NAME}" ]; then
   CI_COMMIT_REF_NAME=master
fi

# Install a basic necessary tools

sudo yum install -y wget
sudo yum install -y vim
pip3 install --user python-openstackclient

# Setup Git and clone 5G_DR repo

cd ~
sudo yum install git -y
mkdir .git
cd .git
git init
git clone https://github.com/Aharic/5G_DR.git

# Build directories for all required repo files and repo certs

sudo wget --no-proxy -P /tmp/db http://winterfell/occne/db/V980756-01.zip
mkdir /tmp/certificates
mkdir /tmp/yum.repos.d

# Copy files from .git/repo to local repo directories

cp 5G_DR/src/cne/certificates/winterfell:5000.crt /tmp/certificates/
cp 5G_DR/repos/winterfell-ol7-mirror.repo /tmp/yum.repos.d
sudo cp 5G_DR/repos/public-yum-ol7.repo /etc/yum.repos.d/public-yum-ol7.repo

# Setup occne_clouduser folder w/ golden cluster.tfvars file

mkdir /var/terraform/occne_clouduser
cp 5G_DR/src/cne/cluster-$OCCNE_VERSION-large.tfvars /var/terraform/occne_clouduser/cluster.tfvars

# Openstack initialization

cd ~
. *openrc.sh

# Test openstack underlay access

access_test=$(openstack region list)

if [ -z "$access_test" ]; then
   echo "openrc.sh file not properly initialized, stopping deployment"
   exit 1;
fi

# Gather Openstack subnet info

openstack network list > networks
external_net=$(awk '$4 !~ /ipv6|lab/ && $2 !~ /ID| / {print $2}' networks | grep -v -e '^$' | grep -m1 "")
floatingip_pool=$(awk -v var="$external_net" '$0 ~ var {print $4}' networks)

# Gather Openstack instance info

nova list


# Gather Openstack volume info

# Replace cluster.tfvars tmp placeholder variables with environment data from command and global

tmp_extnet=$(cat /var/terraform/occne_clouduser/cluster.tfvars | grep -i external_net | grep -oP 'external_net = "\K[^"]+')
tmp_floatpool=$(cat /var/terraform/occne_clouduser/cluster.tfvars | grep -i floatingip_pool | grep -oP 'floatingip_pool = "\K[^"]+')
tmp_cluster=$(cat /var/terraform/occne_clouduser/cluster.tfvars | grep -i cluster_name | grep -oP 'cluster_name = "\K[^"]+')
tmp_netname=$(cat /var/terraform/occne_clouduser/cluster.tfvars | grep -i network_name | grep -oP 'network_name = "\K[^"]+')
tmp_ntp=$(cat /var/terraform/occne_clouduser/cluster.tfvars | grep -i ntp_server | grep -oP 'ntp_server = "\K[^"]+')
ntp_var=$LAB"_ntp"
sed -i "s/$tmp_extnet/$external_net/g" /var/terraform/occne_clouduser/cluster.tfvars
sed -i "s/$tmp_floatpool/$floatingip_pool/g" /var/terraform/occne_clouduser/cluster.tfvars
sed -i "s/$tmp_cluster/$CLUSTER_NAME/g" /var/terraform/occne_clouduser/cluster.tfvars
sed -i "s/$tmp_netname/$CLUSTER_NAME/g" /var/terraform/occne_clouduser/cluster.tfvars
sed -i "s/$tmp_ntp/"${!ntp_var}"/g" /var/terraform/occne_clouduser/cluster.tfvars

# Generate private/public key-pair

ssh-keygen -m PEM -t rsa -N '' -b 2048 -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null

# Cleanup Artifacts

rm networks

# Run vCNE Large Install

cd /var/terraform
OCCNE_TFVARS_DIR=${OCCNE_TFVARS_DIR} CENTRAL_REPO=${CENTRAL_REPO} OCCNE_VERSION=${OCCNE_VERSION} CENTRAL_REPO_IP=${CENTRAL_REPO_IP} ./deploy.sh

# Prompt if user wants to continue to autoinstallation of NFs or stop here



echo "Would you like to continue and auto-install NFs? (yes|no)"
read -sr CONT_INPUT
while [[ "${CONT_INPUT^^}" != "YES" && "${CONT_INPUT^^}" != "NO" ]]; do
   echo "Please choose either 'yes' or 'no'"
   read -sr CONT_INPUT
done
if [ "${CONT_INPUT^^}" = "YES" ]; then
   #Link with specific NF install logic once each NF install script is verified
   echo "Proceeding with NF installs"
   exit 1
elif [ "${CONT_INPUT^^}" = "NO" ]; then
   echo "Thanks! Enjoy your new vCNE environment!"
   exit 1
fi
