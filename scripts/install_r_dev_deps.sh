#!/bin/bash

set -e

. /rocker_scripts/build_metadata.sh

INSTALL_R_DEV_DEPS=${INSTALL_R_DEV_DEPS:-false}

if [ "$INSTALL_R_DEV_DEPS" = "true" ]; then
    metadata_init "${BUILD_IMAGE:-unknown}"

    if metadata_has_bool_module "r_dev_deps"; then
        echo "Skipping R development dependencies because modules.json already records r_dev_deps=true"
        exit 0
    fi

    echo "Installing R development system dependencies and R packages"

    apt-get update
    apt-get install -y --no-install-recommends \
        zlib1g-dev \
        nano \
        librsvg2-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libssh2-1-dev \
        libgdal-dev \
        libproj-dev \
        libgeos-dev \
        libglu1-mesa-dev \
        libgmp3-dev \
        libmpfr-dev \
        libgl-dev \
        libglpk-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libgit2-dev
    rm -rf /var/lib/apt/lists/*

    R -e "install.packages(c('devtools', 'BiocManager'), repos='https://cran.r-project.org')"
    metadata_set_module "r_dev_deps" "true"
else
    echo "Skipping R development dependencies (INSTALL_R_DEV_DEPS=$INSTALL_R_DEV_DEPS)"
fi
