#!/bin/bash -e

source logger

if [ -z "$1" ]; then
      log "missing username parameter"
      exit 1
fi

# check if AWS CLI exists
if ! [ -x "$(which aws)" ]; then
      log "unable to find aws binary"
      exit 1
fi

username="$1"
log "Login requested by user $username" 

aws iam list-ssh-public-keys --user-name "$username" --query "SSHPublicKeys[?Status == 'Active'].[SSHPublicKeyId]" --output text | while read -r KeyId; do
      aws iam get-ssh-public-key --user-name "$username" --ssh-public-key-id "$KeyId" --encoding SSH --query "SSHPublicKey.SSHPublicKeyBody" --output text
done