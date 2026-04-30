#!/bin/bash

set -e

INSTALL_JAVA=${INSTALL_JAVA:-false}
INSTALL_R_DEV_DEPS=${INSTALL_R_DEV_DEPS:-false}

if [ "$INSTALL_R_DEV_DEPS" = "true" ]; then
    INSTALL_JAVA=true
    echo "Enabling Java installation because INSTALL_R_DEV_DEPS=true"
fi

if [ "$INSTALL_JAVA" = "true" ]; then
    echo "Installing Java and configuring R Java support"

    apt-get update
    apt-get install -y --no-install-recommends \
        default-jdk \
        default-jre
    rm -rf /var/lib/apt/lists/*

    R CMD javareconf -e
else
    echo "Skipping Java installation (INSTALL_JAVA=$INSTALL_JAVA, INSTALL_R_DEV_DEPS=$INSTALL_R_DEV_DEPS)"
fi
