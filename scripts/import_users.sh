#!/bin/bash

function log() {
  /usr/bin/logger -i -p auth.info -t aws-ec2-iam-ssh "$@"
}

source $1

## host config
SUDOERS_CONFIG_DIR="/etc/sudoers.d"
LOCAL_GROUP_NAME="iam-users"

get_iam_users() {
  if [ -n "$GROUP_NAME" ]; then
    aws iam get-group --group-name "$GROUP_NAME" --query="Users[].[UserName]" --output text | tr "\n" ","

  else
    log "No group name configured"
    exit 1
  fi
}

get_local_users() {
  getent group $LOCAL_GROUP_NAME | cut -d : -f4-
}

#
# $1 := username
# $2 := groups in csv format without whitespaces
# $3 := sudoer
create_local_user() {
  local groups
  local username

  username="$1"
  groups="$2"

  if [ -x $(which useradd) ]; then
    useradd --groups "$groups" --create-home "$username"

  else
    log "unable to find binary to create local user"
    exit 1

  fi

  if [ "$3" ]; then
    path="$SUDOERS_CONFIG_DIR/$username"

cat > $path << EOF
#################################################
# This file is generated by iam-ssh integration #
#################################################

EOF

    echo "$username ALL=(ALL) NOPASSWD:ALL" >> "$path"
  fi
}

#
# $1 := username
delete_local_user() {
  username="$1"
  # lock user and disable login
  usermod -L -s /sbin/nologin "$username" || true

  if [ -x $(which userdel) ]; then
    pkill -9 -u "$username" || true
    sleep 1
    userdel --force --remove "$username"
    rm -f $SUDOERS_CONFIG_DIR/$username || true
    
  else
    log "unable to find binary to delete local user"
    exit 1
  fi
}

#
# $1 := groups in csv format without whitespaces
create_local_groups() {
  local cmd

  if [ -x $(which groupadd) ]; then
    cmd=groupadd
  else
    log "unable to find binary to create local group"
    exit 1
  fi

  for group in $(echo $1 | tr "," " "); do
    [ $(getent group $group) ] && continue
    groupadd $group
  done
}

# main controls that the local machine users are 
main() {
  # create the local group but do not error if it already exists
  create_local_groups $LOCAL_GROUP_NAME || true

  local users
  users=$(get_iam_users)
  local_users=$(get_local_users)

  # create all users that are currently in the iam group
  # if the user already exists, skip
  for user in $(echo $users | tr "," " "); do
    if ! [ $(echo "$local_users" | grep "$user") ]; then
      log "creating user $user"
      create_local_user $user $LOCAL_GROUP_NAME "true"
    fi
  done

  # delete all users which are in the local group but
  # not in the iam group
  for user in $(echo $local_users | tr "," " "); do
    if [ ! $(echo "$users" | grep "$user") ]; then
      log "removing user $user"
      delete_local_user $user
    fi
  done
}


main