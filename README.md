# Citrix Virtual Apps and Desktop vCenter Lab Deploy
Uses Terraform and Ansible to deploy a fully functional CVAD environment. Many of the scripts used are thanks to [Dennis Span](https://dennisspan.com) and his fantastic blog.

## What it does

Deploys the following:
 - 2 DDC Controllers with Director
 - 2 Storefront Servers (Cluster)
 - 1 SQL and License Server
 - 1 Stand alone VDA

### DDC
 - Installs components including director
 - Creates Citrix site
 - Creates 1 Machine Catalog
 - Creates 1 Delivery Group
 - Creates 1 Published Desktop
 - Creates 3 Applications
    - Notepad
    - Calculator
    - Paint
 - Configures director
    - Adds logon domain
    - Sets default page
    - Removes SSL Warning

### Storefront
 - Installs Storefront components
 - Creates Storefront cluster
 - Configures Storefromt
   - Adds Citrix Gateway
   - Sets default page
   - Enables HTTP loopback for SSL offload
   - Adjusts logoff behavior

### SQL and Citrix License
 - Installs SQL and license server
 - Installs SQL management tools
 - Configures SQL for admins and service account
 - Copies Citrix license files

### VDA
 - Installs VDA components
 - Configures for DDCs

## Prerequisites

- Need CVAD ISO contents copied to accessible share via Ansible account (eg \\\mynas\isos\Citrix\Citrix_Virtual_Apps_and_Desktops_7_1906_2)
    - I used CVAD 1906 2 ISO
- Need SQL ISO contents copied to accessible share via Ansible account (eg \\\mynas\isos\Microsoft\SQL\en_sql_server_2017_standard_x64_dvd_11294407)
    - I used SQL 2017 but other versions should work
- DHCP enabled network
- vCenter access and rights capable of deploying machines
- (optional for remote state) [Terraform Cloud](https://app.terraform.io/signup/account) account created and API key for remote state.

### Deploy machine
I used [Ubuntu WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to deploy from

1. [Ansible installed](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ansible-on-ubuntu-18-04)
   - Install **pywinrm** `pip install pywinrm` and `pip install pywinrm[credssp]`
2. [Terraform installed](https://askubuntu.com/questions/983351/how-to-install-terraform-in-ubuntu)
3. [Terraform-Inventory](https://github.com/adammck/terraform-inventory/releases) installed in path.  This is used for the Ansible inventory
    - I copied to */usr/bin/*
4. (If using remote state)[Configure Access for the Terraform CLI](https://www.terraform.io/docs/cloud/free/index.html#configure-access-for-the-terraform-cli)
5. This REPO cloned down

### vCenter Windows Server Template
    
1. I used Windows Server 2019 but I assume 2016 should also work.
2. WinRM needs to be configured and **CredSSP** enabled
    - Ansible provides a great script to enable quickly https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1
    - Run manually `Enable-WSManCredSSP -Role Server -Force`
3. I use linked clones to quickly deploy.  In order for this to work the template needs to be converted to a VM with a **single snapshot** created.

## Getting Started

### Terraform
1. From the *terraform* directory copy **lab.tfvars.sample** to **lab.tfvars**
2. Adjust variables to reflect vCenter environment
3. Review **main.tf** and adjust any VM resources if needed
4. (If using remote cloud state) At the bottom of **main.tf** uncomment the *terraform* section and edit the *organization* and *workspaces* fields
```
terraform {
   backend "remote" {
     organization = "TechDrabble"
     workspaces {
       name = "cvad-lab"
     }
   }
}
```
5. run `terraform init` to install needed provider

### Ansible
1. From the *ansible* directory copy **vars.yml.sample** to **vars.yml**
2. Adjust variables to reflect environment
3. If you want to license CVAD environment place generated license file in **ansible\roles\license\files**

## Deploy
If you are comfortable with below process `build.sh` handles the below steps.  

**Note:** If you prefer to run many of the tasks asynchronously switch the `ansible-playbook` lines within `build.sh` which will call a seperate playbook. This is faster but can consume more resources and less informative output.
```
#Sync
#ansible-playbook --inventory-file=/usr/bin/terraform-inventory ./ansible/playbook.yml -e @./ansible/vars.yml
#If you prefer to run most of the tasks async (can increase resources)
ansible-playbook --inventory-file=/usr/bin/terraform-inventory ./ansible/playbook-async.yml -e @./ansible/vars.yml
```

## Terraform
1. From the *terraform* directory run `terraform apply --var-file="lab.tfvars"`
2. Verify the results and type `yes` to start the build

## Ansible
1. From the *root* directory and the terraform deployment is completed run the following
    - `export TF_STATE=./terraform` used for the inventory script
    - Synchronous run (Serial tasks)
        - `ansible-playbook --inventory-file=/usr/bin/terraform-inventory ./ansible/playbook.yml -e @./ansible/vars.yml` to start the playbook
    - Asynchronous run (Parallel tasks)
        - `ansible-playbook --inventory-file=/usr/bin/terraform-inventory ./ansible/playbook-async.yml -e @./ansible/vars.yml` to start the playbook
    - Grab coffee

## Destroy
If you are comfortable with below process `destroy.sh` handles the below steps.  **Please note this does not clean up the computer accounts**

## Terraform
1. From the *terraform* directory run `terraform destroy --var-file="lab.tfvars"`
2. Verify the results and type `yes` to destroy


