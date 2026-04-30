#!/bin/bash

set -e

TEX_VARIANT=${TEX_VARIANT:-none}

case "$TEX_VARIANT" in
    none)
        echo "Skipping TeX installation (TEX_VARIANT=none)"
        ;;
    base)
        echo "Installing base TeX Live packages"
        apt-get update
        apt-get install -y --no-install-recommends \
            texlive-base \
            texlive-latex-base \
            texlive-fonts-recommended \
            texlive-fonts-extra
        rm -rf /var/lib/apt/lists/*
        updmap-user
        ;;
    full)
        echo "Installing full TeX Live distribution"
        apt-get update
        apt-get install -y --no-install-recommends texlive-full
        rm -rf /var/lib/apt/lists/*
        updmap-user
        ;;
    *)
        echo "Invalid TEX_VARIANT=$TEX_VARIANT. Use one of: none, base, full." >&2
        exit 1
        ;;
esac
