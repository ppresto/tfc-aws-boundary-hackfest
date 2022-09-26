# AWS EC2 Node

# AWS VPC + Transit Gateway

Configuration in this directory creates the AWS EC2 instance.

## Notes
An SSH Bastion host was created in the public shared network with rules allowing ssh to private networks for troubleshooting.
* Update variable: ec2_key_pair_name with your key pair name
* Update variable: allowed_bastion_cidr_blocks to your public IP for better security

If you have your aws keypair setup your ssh agent (-A) and the bastion_ip you can ssh to it.
```
ssh -A ubuntu@${bastion_ip}
```

# Troubleshooting

## AWS user_data
When a user data script is processed, it is copied to and run from /var/lib/cloud/instances/instance-id/. The script is not deleted after it is run and can be found in this directory with the name user-data.txt.  
```
sudo cat /var/lib/cloud/instance/user-data.txt
```
The cloud-init log captures console output of the user-data script run.
```
sudo cat /var/log/cloud-init-output.log
```

## systemctl consul.service
This repo creates the systemd start script located at `/etc/systemd/system/consul.service`.  This scripts requires:
*  /opt/consul to store data.
*  /etc/consul.d/certs - ca.pem from HCP
*  /etc/consul.d/ - HCP default configs and an ACL token

To stop, start, and get the status of the service
```
systemctl stop consul.service
systemctl start consul.service
systemctl status consul.service
```

To investigate systemd errors starting consul use `journalctl`
```
journalctl -u consul.service
```
