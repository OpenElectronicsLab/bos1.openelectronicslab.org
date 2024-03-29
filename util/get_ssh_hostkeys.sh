#!/bin/bash

#set -x
set -e

SSHARGS="-J ${USER}admin@boletus0.bos1.openelectronicslab.org"

for HOST in \
    testvm3.private.vpn.boletus3.bos1.openelectronicslab.org
do
    echo ""
    echo "###################################################################"
    echo    Processing host $HOST
    echo "###################################################################"
    mkdir -p hostkeys.tmp/$HOST
    # copy the hostkeys from the remote machine
    ssh ${USER}admin@$HOST $SSHARGS mkdir -p hostkeys.tmp
    ssh ${USER}admin@$HOST $SSHARGS sudo cp /etc/ssh/ssh_host_\*key\* hostkeys.tmp/
    ssh ${USER}admin@$HOST $SSHARGS sudo bash -c \
        "\"cp /etc/dropbear-initramfs/dropbear_\*host_key hostkeys.tmp/ || /bin/true\""
    ssh ${USER}admin@$HOST $SSHARGS sudo chown ${USER}admin:${USER}admin hostkeys.tmp/\*
    scp $SSHARGS ${USER}admin@$HOST:hostkeys.tmp/* hostkeys.tmp/$HOST/
    ssh ${USER}admin@$HOST $SSHARGS shred -u hostkeys.tmp/\*
    ssh ${USER}admin@$HOST $SSHARGS rm -rf hostkeys.tmp

    # append the keys to the host variables for the given machine
    for KEYTYPE in ecdsa ed25519 rsa; do
        printf "\n" >> host_vars/$HOST.yml
        cat hostkeys.tmp/$HOST/ssh_host_${KEYTYPE}_key \
            | ansible-vault encrypt_string \
                --stdin-name ssh_host_${KEYTYPE}_key \
            >> host_vars/$HOST.yml
        printf "\nssh_host_${KEYTYPE}_key_pub: " >> host_vars/$HOST.yml
        cat hostkeys.tmp/$HOST/ssh_host_${KEYTYPE}_key.pub >> host_vars/$HOST.yml
    done

    # do the same for dropbear keys, if they exist
    for KEYTYPE in dss ecdsa rsa; do
        DROPBEAR_KEYFILE=hostkeys.tmp/$HOST/dropbear_${KEYTYPE}_host_key
        echo "Processing dropbear keytype $KEYTYPE ($DROPBEAR_KEYFILE)"
        if [[ -f $DROPBEAR_KEYFILE ]]; then
            printf "\n" >> host_vars/$HOST.yml
            base64 $DROPBEAR_KEYFILE \
                | ansible-vault encrypt_string \
                    --stdin-name dropbear_${KEYTYPE}_host_key_base64 \
                >> host_vars/$HOST.yml
            printf "\ndropbear_${KEYTYPE}_host_key_pub: " >> host_vars/$HOST.yml
            dropbearkey -y -f $DROPBEAR_KEYFILE | head -2 | tail -1 \
               | cut -d' ' -f1-2 | sed -e "s/$/ root@$HOST/g" \
                >> host_vars/$HOST.yml
        fi
    done

    # clean up the hostkeys
    shred -u hostkeys.tmp/$HOST/*
    echo "Finished processing host $HOST."
done
