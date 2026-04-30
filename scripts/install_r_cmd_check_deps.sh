#!/bin/bash

set -e

. /rocker_scripts/build_metadata.sh

INSTALL_R_CMD_CHECK_DEPS=${INSTALL_R_CMD_CHECK_DEPS:-false}

if [ "$INSTALL_R_CMD_CHECK_DEPS" = "true" ]; then
    metadata_init "${BUILD_IMAGE:-unknown}"

    if metadata_has_bool_module "r_cmd_check_deps"; then
        echo "Skipping R CMD check dependencies because modules.json already records r_cmd_check_deps=true"
        exit 0
    fi

    echo "Installing R CMD check system dependencies"

    apt-get update
    apt-get install -y --no-install-recommends \
        qpdf \
        ghostscript-x
    rm -rf /var/lib/apt/lists/*
    metadata_set_module "r_cmd_check_deps" "true"
else
    echo "Skipping R CMD check dependencies (INSTALL_R_CMD_CHECK_DEPS=$INSTALL_R_CMD_CHECK_DEPS)"
fi
