#!/bin/bash

set -e

. /rocker_scripts/build_metadata.sh

INSTALL_JAVA=${INSTALL_JAVA:-false}
R_DEV_DEPS=${R_DEV_DEPS:-false}
INSTALL_JAVA=$(metadata_bool "$INSTALL_JAVA")
R_DEV_DEPS=$(metadata_bool "$R_DEV_DEPS")

if [ "$R_DEV_DEPS" = "true" ]; then
    INSTALL_JAVA=true
    echo "Enabling Java installation because R_DEV_DEPS=true"
fi

if [ "$INSTALL_JAVA" = "true" ]; then
    metadata_init "${BUILD_IMAGE:-unknown}"

    if metadata_has_bool_module "java"; then
        if [ "${BUILD_IMAGE:-unknown}" = "rstudio" ] && ! metadata_component_has_bool_module "rstudio" "java"; then
            metadata_set_skipped_from_base "java" "true"
        fi
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
    echo "Skipping Java installation (INSTALL_JAVA=$INSTALL_JAVA, R_DEV_DEPS=$R_DEV_DEPS)"
fi
