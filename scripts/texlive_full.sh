#!/bin/bash

# INSTALL_TEX argümanını kontrol et
INSTALL_TEX=${INSTALL_TEX:-false}

if [ "$INSTALL_TEX" = "true" ]; then
    apt-get update && apt-get install -y texlive-full

    # Set character mapping for new fonts.
    updmap-user
else
    echo "Skipping TeX installation (INSTALL_TEX=$INSTALL_TEX)"
fi