# aws-ec2-iam-ssh

**Only tested on Amazon Linux. Requires binaries (useradd, usermod, userdel, groupadd)**
## How to 

1. Add the [IAM-Policy](aws-iam-policy.json) to the role of the ec2 instance. Make sure to replace `name` with the actual group name
2. Log into the ec2 instance or configure its userdata
3. Make sure git is installed
4. Execute `git clone https://github.com/ron96G/aws-ec2-iam-ssh.git`
5. cd aws-ec2-iam-ssh/scripts
6. Make sure you are root: `whoami`
7. Set the env var `IAM_GROUP_NAME` to the IAM group name that you want to use
8. Execute the install script: `./install.sh`