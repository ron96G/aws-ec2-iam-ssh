#!/bin/bash -e


SCRIPT_DIR="/opt/iam-ssh"

[[ $(id -u) -gt 0 ]] && echo "must be root to execute this script" && exit 1


mkdir -p $SCRIPT_DIR
mv import_users.sh $SCRIPT_DIR
mv authorized_keys_command.sh $SCRIPT_DIR
mv install.sh $SCRIPT_DIR

chown -R root:root $SCRIPT_DIR/*

# setup cronjob
IMPORT_USERS_FILE="$SCRIPT_DIR/import_users.sh"
CRON_D_CONFIG_FILE="/etc/cron.d/import_users"

if [ -f $CRON_D_CONFIG_FILE ]; then

cat > $CRON_D_CONFIG_FILE << EOF
SHELL=/bin/bash
PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/aws/bin
MAILTO=root
HOME=/
*/10 * * * * root $IMPORT_USERS_FILE
EOF
chmod 0644 $CRON_D_CONFIG_FILE


else
      echo "File $CRON_D_CONFIG_FILE already exists. Skipping..."

fi

# setup sshd config
# see https://man.openbsd.org/sshd_config

SSHD_CONFIG_FILE="/etc/ssh/sshd_config"
COMMAND_FILE="$SCRIPT_DIR/authorized_keys_command.sh"

chown root:root $COMMAND_FILE
chmod 711 $COMMAND_FILE

[[ $(cat "$SSHD_CONFIG_FILE" |grep "AuthorizedKeysCommand") ]] || echo "AuthorizedKeysCommand $COMMAND_FILE" >> $SSHD_CONFIG_FILE && echo "AuthorizedKeysCommand already exists"
[[ $(cat "$SSHD_CONFIG_FILE" |grep 'AuthorizedKeysCommandUser') ]] || echo 'AuthorizedKeysCommandUser nobody' >> $SSHD_CONFIG_FILE && echo "AuthorizedKeysCommandUser already exists"


systemctl restart sshd.service