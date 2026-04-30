#!/bin/bash

# PREINSTALL_R_PKG argümanını kontrol et
PREINSTALL_R_PKG=${PREINSTALL_R_PKG:-false}

if [ "$PREINSTALL_R_PKG" = "true" ]; then
    echo "Installing R packages: devtools, BiocManager"
    R -e "install.packages('devtools', repos='https://cran.r-project.org')"
    R -e "install.packages('BiocManager', repos='https://cran.r-project.org')"
else
    echo "Skipping R package installation (PREINSTALL_R_PKG=$PREINSTALL_R_PKG)"
fi