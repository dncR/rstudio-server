#!/bin/bash

set -e

INSTALL_R_CMD_CHECK_DEPS=${INSTALL_R_CMD_CHECK_DEPS:-false}

if [ "$INSTALL_R_CMD_CHECK_DEPS" = "true" ]; then
    echo "Installing R CMD check system dependencies"

    apt-get update
    apt-get install -y --no-install-recommends \
        qpdf \
        ghostscript-x
    rm -rf /var/lib/apt/lists/*
else
    echo "Skipping R CMD check dependencies (INSTALL_R_CMD_CHECK_DEPS=$INSTALL_R_CMD_CHECK_DEPS)"
fi
