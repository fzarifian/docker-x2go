#!/bin/sh

USER_HOME=/home/user
KEYGEN=/usr/bin/ssh-keygen
KEYFILE=${USER_HOME}/.ssh/id_rsa
SSH_MODULI=false

echo "# SSH moduli generation"
if [[  "$SSH_MODULI" != 'false' ]]; then
    echo "  * Generate SSH moduli (this may take a while...)"
    $KEYGEN -G /root/moduli-2048.candidates -b 2048
    $KEYGEN -T /root/moduli-2048 -f /root/moduli-2048.candidates
    cp /root/moduli-2048 /etc/ssh/moduli
    rm /root/moduli-2048 /root/moduli-2048.candidates
else
    echo "  * SSH moduli disabled, skipping.."

fi

echo "# host keys"
if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
    echo "  * Generate ECDSA host key"
    $KEYGEN -q -t ecdsa -N '' -f /etc/ssh/ssh_host_ecdsa_key -N ''
else
    echo "  * ECDSA host key already exists, skipping.."
fi

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "  * Generate RSA host key"
    $KEYGEN -q -t rsa -b 2048 -N '' -f /etc/ssh/ssh_host_rsa_key -N ''
else
    echo "  * RSA host key already exists, skipping.."
fi

echo "# admin keys"
if [ ! -f $KEYFILE ]; then
    $KEYGEN -q -t rsa -N '' -f $KEYFILE
    cat $KEYFILE.pub >> ${USER_HOME}/.ssh/authorized_keys
else
    echo "  * admin key already exists, skipping"
fi

echo "== Use this private key to log-in =="
cat $KEYFILE

echo "# start sshd"
/usr/sbin/sshd -D