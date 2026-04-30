#!/bin/bash

set -e

INSTALL_R_DEV_DEPS=${INSTALL_R_DEV_DEPS:-false}

if [ "$INSTALL_R_DEV_DEPS" = "true" ]; then
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
else
    echo "Skipping R development dependencies (INSTALL_R_DEV_DEPS=$INSTALL_R_DEV_DEPS)"
fi
