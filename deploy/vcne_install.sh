﻿# command example
# OCCNE_TFVARS_DIR=occne_clouduser CENTRAL_REPO=winterfell CENTRAL_REPO_IP=10.75.216.10 OCCNE_VERSION=1.5.0 OCCNE_CLUSTER=occne ./vcne_install.sh


# Pre-Deployment global variable checks

if [ -z "${CENTRAL_REPO}" ]; then
   echo "No DOCKER_REG variable specified for all services, stopping deployment" 1>&2
   exit 1;
elif [ -z "${vCNE_VERSION}" ]; then
   echo "No vCNE_VERSION variable specified, stopping deployment" 1>&2
   exit 1;
else [ -z "${OCCNE_TFVARS}" ]; then
   echo "No OCCNE_TFVARS variable specified, stopping deployment" 1>&2
   exit 1;
fi

if [ -z "${CI_COMMIT_REF_NAME}" ]; then
   CI_COMMIT_REF_NAME=master
fi

# Test openstack underlay access

access_test=$(openstack region list)

if [ -z "$access_test" ]; then
   echo "openrc.sh file not properly initialized, stopping deployment"
   exit 1;
fi

# Install a few basic tools

sudo yum install -y wget
sudo yum install -y vim


# Setup Git and clone cne_backup
sudo yum install git -y
mkdir .git
cd .git
git init
git clone https://github.com/Aharic/cne_backup.git


# Build diretories for all required repo files and repo certs

sudo wget --no-proxy -P /tmp/db http://winterfell/occne/db/V980756-01.zip
mkdir /tmp/certificates
mkdir /tmp/yum.repos.d

# Copy files from .git directories to respective repo directories

cp cne_backup/CNE/certificates/winterfell:5000.crt /tmp/certificates/
cp cne_backup/CNE/yum.repos.d/winterfell-ol7-mirror.repo /tmp/yum.repos.d
sudo cp cne_backup/CNE/yum.repos.d/public-yum-ol7.repo /etc/yum.repos.d/public-yum-ol7.repo

# Setup occne_clouduser folder w/ golden cluster.tfvars file

mkdir /var/terraform/occne_clouduser
cp CNE/cluster.tfvars /var/terraform/occne_clouduser

# Gather Openstack subnet info

openstack network list > networks
external_net=$(awk '$4 !~ /ipv6|lab/ && $2 !~ /ID| / {print $2}' networks | grep -v -e '^$' | grep -m1 "")
floatingip_pool=$(awk -v var="$external_net" '$0 ~ var {print $4}' networks)

# Replace cluster.tfvars subnet placeholder variables with environment data from above

old_extnet=$(cat cluster.tfvars | grep -i external_net | grep -oP 'external_net = "\K[^"]+')
old_floatpool=$(cat cluster.tfvars | grep -i floatingip_pool | grep -oP 'floatingip_pool = "\K[^"]+')
sed -i "s/$old_extnet/$external_net/g" cluster.tfvars
sed -i "s/$old_floatpool/$floatingip_pool/g" cluster.tfvars

# Generate private/public key-pair

ssh-keygen -m PEM -t rsa -N '' -b 2048 -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null 

# Cleanup Artifacts

# Run vCNE Minimal Install

cd /var/terraform
OCCNE_TFVARS_DIR=${OCCNE_TFVARS_DIR} CENTRAL_REPO=${CENTRAL_REPO} OCCNE_VERSION=${OCCNE_VERSION} OCCNE_CLUSTER=${OCCNE_CLUSTER} CENTRAL_REPO_IP=${CENTRAL_REPO_IP} ./deploy.sh
