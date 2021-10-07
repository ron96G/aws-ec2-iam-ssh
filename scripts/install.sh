#!/bin/bash


SCRIPT_DIR="/opt/iam-ssh"

[[ $(id -u) -gt 0 ]] && echo "must be root to execute this script" && exit 1


mkdir -p $SCRIPT_DIR
cp import_users.sh $SCRIPT_DIR
cp authorized_keys_command.sh $SCRIPT_DIR
cp install.sh $SCRIPT_DIR

chown -R root:root $SCRIPT_DIR/*

# setup cronjob
IMPORT_USERS_FILE="$SCRIPT_DIR/import_users.sh"
CRON_D_CONFIG_FILE="/etc/cron.d/import_users"

if ! [ -f $CRON_D_CONFIG_FILE ]; then

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
SSHD_COMMAND_USER="root"

chown root:root $COMMAND_FILE
chmod 711 $COMMAND_FILE


if ! grep -q "^AuthorizedKeysCommand $COMMAND_FILE" ${SSHD_CONFIG_FILE}; then
	sed -e '/AuthorizedKeysCommand / s/^#*/#/' -i $SSHD_CONFIG_FILE; echo "AuthorizedKeysCommand $COMMAND_FILE" >> $SSHD_CONFIG_FILE
fi

if ! grep -q "^AuthorizedKeysCommandUser $SSHD_COMMAND_USER" $SSHD_CONFIG_FILE; then
	sed -e '/AuthorizedKeysCommandUser / s/^#*/#/' -i $SSHD_CONFIG_FILE; echo "AuthorizedKeysCommandUser $SSHD_COMMAND_USER" >> $SSHD_CONFIG_FILE
fi

systemctl restart sshd.service

log "Initializing iam users"
source $SCRIPT_DIR/import_users.sh