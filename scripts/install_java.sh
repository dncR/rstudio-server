#!/bin/bash

set -e

. /rocker_scripts/build_metadata.sh

JAVA=${JAVA:-false}
R_DEV_DEPS=${R_DEV_DEPS:-false}

if [ "$R_DEV_DEPS" = "true" ]; then
    JAVA=true
    echo "Enabling Java installation because R_DEV_DEPS=true"
fi

if [ "$JAVA" = "true" ]; then
    metadata_init "${BUILD_IMAGE:-unknown}"

    if metadata_has_bool_module "java"; then
        echo "Skipping Java installation because modules.json already records java=true"
        exit 0
    fi

    echo "Installing Java and configuring R Java support"

    apt-get update
    apt-get install -y --no-install-recommends \
        default-jdk \
        default-jre
    rm -rf /var/lib/apt/lists/*

    R CMD javareconf -e
    metadata_set_module "java" "true"
else
    echo "Skipping Java installation (JAVA=$JAVA, R_DEV_DEPS=$R_DEV_DEPS)"
fi
