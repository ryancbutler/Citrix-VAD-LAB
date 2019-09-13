#!/bin/bash
export TF_STATE=./terraform
cd terraform
terraform apply --auto-approve --var-file="lab.tfvars"
sleep 60s
cd ..
ansible-playbook --inventory-file=/usr/bin/terraform-inventory ./ansible/playbook.yml -e @./ansible/vars.yml
#If you prefer to run most of the tasks async (can increase resources)
#ansible-playbook --inventory-file=/usr/bin/terraform-inventory ./ansible/playbook-async.yml -e @./ansible/vars.yml