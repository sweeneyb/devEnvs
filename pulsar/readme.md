


# Debugging
cloud-init logs are kept in /var/log/cloud-init.log and cloud-init-output.log.

To validate the schema
`cloud-init schema --system`


terraform plan -var-file=variables.tfvars
terraform apply -var-file=variables.tfvars
terraform destory -var-file=variables.tfvars

to see the tailscale key:
terraform output key



# TODO
# user isn't in the docker group
sudo usermod -aG docker $USER