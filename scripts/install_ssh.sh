#!/bin/bash

set -e

INSTALL_SSH=${INSTALL_SSH:-false}
DEFAULT_USER=${DEFAULT_USER:-rstudio}

if [ "$INSTALL_SSH" = "true" ]; then
    echo "Installing and configuring OpenSSH server"

    apt-get update
    apt-get install -y --no-install-recommends openssh-server
    rm -rf /var/lib/apt/lists/*

    mkdir -p /var/run/sshd "/home/${DEFAULT_USER}/.ssh"
    chown "${DEFAULT_USER}:${DEFAULT_USER}" "/home/${DEFAULT_USER}/.ssh"
    chmod 700 "/home/${DEFAULT_USER}/.ssh"

    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    grep -qxF "PermitRootLogin no" /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    grep -qxF "PubkeyAuthentication yes" /etc/ssh/sshd_config || echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

    mkdir -p /etc/services.d/ssh
    cat <<"EOF" >/etc/services.d/ssh/run
#!/usr/bin/with-contenv bash
exec /usr/sbin/sshd -D -e
EOF
    chmod 755 /etc/services.d/ssh/run
else
    echo "Skipping OpenSSH server installation (INSTALL_SSH=$INSTALL_SSH)"
fi
