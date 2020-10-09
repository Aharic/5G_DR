# vCNE Recovery


STRUCTURE

src/

     Contains golden .yaml files for NF and DataCollector deployments, cluster.tfvars files for vCNE deployment, and config files for Bootstrap host.
     
deploy/ 

     Contains deploy scripts for automated vCNE and NRF deployments.
     
repo/

     Contains public and private repo files required for common tools download and use.
     
     
vCNE INSTALL INSTRUCTIONS

     1. Download the bootstrap yaml file for the desired vCNE version from /5G_DR/src/bootstrap/

     2. Launch new bootstrap instance via OpenStack GUI using desired flavor and img version and paste the contents of the previously-downloaded bootstrap yaml file into the Configuration section's "Customization Script" form.

     3. Download openrc.sh file from OpenStack GUI by clicking the username menu in the top right and selecting the "OpenStack RC File" option and then upload it to the bootstrap instance to the home directory.

     4. Modify the downloaded openrc.sh file commenting out the password input prompt lines as follows:

          #echo "Please enter your OpenStack Password for project $OS_PROJECT_NAME as user $OS_USERNAME: "
          #read -sr OS_PASSWORD_INPUT
          #export OS_PASSWORD=$OS_PASSWORD_INPUT

     5. Add the following line directly under the portion you commented out above replacing examplepassword with your actual password. Make sure to leave the quotation marks in place so it is treated as a string.

          export OS_PASSWORD="examplepassword"

     6. Save the file.

NOTE: Steps 4, 5, and 6 are necessary to avoid interrupting the vCNE auto-deployment script with a user-prompt requiring the user to input their OpenStack password. If the preference is to not store password and have the user provide it manually upon being prompted, note that script will not proceed until password is provided.

     7. Download the vCNE install yaml file from /5G_DR/deploy/vcne/ making sure to select the appropriate type based available OpenStack resources. 
          
          To confirm resource requirements for each vnce install yaml file, reference the corresponding cluster.tfvars file in /5G_DR/src/cne/ (Ex: a "minimal" deploy file will correspond to the instance sizes and resource requirements of a "minimal" cluster.tfvars file)

     8. Upload the vCNE install yaml file to the bootstrap instance to the home directory.

     9. Issue following command in the bootstrap home directory to grant execute permissions for all required files: chmod 777 *.sh

     10. Run vCNE install script making sure to declare required variables below:
     
          OCCNE_TFVARS_DIR=
          CENTRAL_REPO=
          CENTRAL_REPO_IP=
          OCCNE_VERSION=
          CLUSTER_NAME=
          LAB= 
          
          Ex: OCCNE_TFVARS_DIR=occne_clouduser CENTRAL_REPO=winterfell CENTRAL_REPO_IP=10.75.216.10 OCCNE_VERSION=1.5.0 CLUSTER_NAME=vzw2 LAB=arcus ./vcne_install_minimal.sh

NOTE: After the deploy.sh script runs and the vCNE is successfully installed, the user will be prompted about whether they want to continue auto-installing the NFs or stop for the time being and install the NFs at a later time (either manually or via NF-specific deploy scripts.
