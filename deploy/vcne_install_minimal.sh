#!/bin/bash

# Launch command example
# OCCNE_TFVARS_DIR=occne_clouduser CENTRAL_REPO=winterfell CENTRAL_REPO_IP=10.75.216.10 OCCNE_VERSION=1.5.0 OCCNE_CLUSTER=occne ./vcne_install.sh


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

# Setup Git and clone cne_backup repo

cd ~
sudo yum install git -y
mkdir .git
cd .git
git init
git clone https://github.com/Aharic/cne_backup.git

# Build directories for all required repo files and repo certs

sudo wget --no-proxy -P /tmp/db http://winterfell/occne/db/V980756-01.zip
mkdir /tmp/certificates
mkdir /tmp/yum.repos.d

# Copy files from .git/repo to local repo directories

cp cne_backup/src/CNE/certificates/winterfell:5000.crt /tmp/certificates/
cp cne_backup/repos/winterfell-ol7-mirror.repo /tmp/yum.repos.d
sudo cp cne_backup/repos/public-yum-ol7.repo /etc/yum.repos.d/public-yum-ol7.repo

# Setup occne_clouduser folder w/ golden cluster.tfvars file

mkdir /var/terraform/occne_clouduser
cp cne_backup/src/CNE/cluster-$OCCNE_VERSION.tfvars /var/terraform/occne_clouduser/cluster.tfvars

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

# Replace cluster.tfvars subnet placeholder variables with environment data from above

old_extnet=$(cat /var/terraform/occne_clouduser/cluster.tfvars | grep -i external_net | grep -oP 'external_net = "\K[^"]+')
old_floatpool=$(cat /var/terraform/occne_clouduser/cluster.tfvars | grep -i floatingip_pool | grep -oP 'floatingip_pool = "\K[^"]+')
sed -i "s/$old_extnet/$external_net/g" /var/terraform/occne_clouduser/cluster.tfvars
sed -i "s/$old_floatpool/$floatingip_pool/g" /var/terraform/occne_clouduser/cluster.tfvars

# Generate private/public key-pair

ssh-keygen -m PEM -t rsa -N '' -b 2048 -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null

# Cleanup Artifacts

rm networks

# Run vCNE Minimal Install

cd /var/terraform
OCCNE_TFVARS_DIR=${OCCNE_TFVARS_DIR} CENTRAL_REPO=${CENTRAL_REPO} OCCNE_VERSION=${OCCNE_VERSION} OCCNE_CLUSTER=${OCCNE_CLUSTER} CENTRAL_REPO_IP=${CENTRAL_REPO_IP} ./deploy.sh
