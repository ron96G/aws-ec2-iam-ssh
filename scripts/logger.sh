#!/bin/bash

TIME_FOMRAT='%Y-%m-%d %H:%M:%S %z'
LOG_FORMAT="{\"time\":\"%s\",\"level\":\"%s\",\"msg\":\"%s\"}\n"
LOG_FILE="/opt/iam-ssh.log"

now() {
    echo $(date +"$TIME_FOMRAT")
}

clean() {
    echo $(echo "$1" | tr '\n' ' ')
}

log() {
    level="${1^^}"
    [ "$level" == "" ] && level="INFO"
    msg=$(clean "${2:--}")
    printf $LOG_FORMAT "$(now)" "$level" "$msg" >> $LOG_FILE
}