#!/bin/sh

USER_HOME=/home/$X2GO_ADMIN_USER
KEYGEN=/usr/bin/ssh-keygen
KEYFILE=${USER_HOME}/.ssh/id_rsa

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] \
		&& [ "${FUNCNAME[0]}" = '_is_sourced' ] \
		&& [ "${FUNCNAME[1]}" = 'source' ]
}

ssh_moduli() {
    echo "# SSH moduli generation"
    if [ ! -z "$SSH_GENERATE_MODULI" ]; then
        echo "  * Generate (this may take a while...)"
        $KEYGEN -G /root/moduli-2048.candidates -b 2048
        $KEYGEN -T /root/moduli-2048 -f /root/moduli-2048.candidates
        echo "  * Replace SSH moduli files"
        cp /root/moduli-2048 /etc/ssh/moduli
        echo "  * Replace SSH moduli files"
        rm /root/moduli-2048 /root/moduli-2048.candidates
    else
        echo "  * SSH moduli disabled, skipping.."
    fi
}

ssh_host_keys() {
    echo "# Generate host keys"
    if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
        echo "  * ECDSA host key"
        $KEYGEN -q -t ecdsa -N '' -f /etc/ssh/ssh_host_ecdsa_key -N ''
    else
        echo "  * ECDSA host key already exists, skipping.."
    fi

    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        echo "  * RSA host key"
        $KEYGEN -q -t rsa -b 2048 -N '' -f /etc/ssh/ssh_host_rsa_key -N ''
    else
        echo "  * RSA host key already exists, skipping.."
    fi
}

ssh_admin_keys() {
    echo "# admin keys"
    if [ ! -f $KEYFILE ]; then
        echo "  * RSA admin user key"
        $KEYGEN -q -t rsa -b 4096 -N '' -f $KEYFILE
        cat $KEYFILE.pub >> ${USER_HOME}/.ssh/authorized_keys
        echo "== Use this private key to log-in =="
        cat $KEYFILE
    else
        echo "  * admin user key already exists, skipping"
    fi
}

lynis_audit_system() {
    echo "# audit with lynis"
    lynis audit system
}

dbus_service() {
    echo "# dbus-service"
    if [ ! -f /var/lib/dbus/machine-id ]; then
        echo "  * generate machine-id"
        dbus-uuidgen > /var/lib/dbus/machine-id
    fi

    if [ ! -d /var/run/dbus ]; then
        echo "  * create dbus volatile folder"
        mkdir -p /var/run/dbus
    fi

    echo "  * run dbus daemon"
    dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address
}

sshd_service() {
    echo "# start sshd"
    /usr/sbin/sshd -D -e
}

_main() {
    ssh_moduli
    ssh_host_keys
    ssh_admin_keys
    dbus_service
    sshd_service
}

if ! _is_sourced; then
	_main "$@"
fi