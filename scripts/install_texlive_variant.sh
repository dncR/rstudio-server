#!/bin/bash

set -e

. /rocker_scripts/build_metadata.sh

TEX_VARIANT=${TEX_VARIANT:-none}

case "$TEX_VARIANT" in
    none)
        echo "Skipping TeX installation (TEX_VARIANT=none)"
        ;;
    base)
        metadata_init "${BUILD_IMAGE:-unknown}"
        if metadata_tex_satisfies "base"; then
            echo "Skipping base TeX Live installation because modules.json records tex=$(metadata_module "tex" "none")"
            exit 0
        fi

        echo "Installing base TeX Live packages"
        apt-get update
        apt-get install -y --no-install-recommends \
            texlive-base \
            texlive-latex-base \
            texlive-fonts-recommended \
            texlive-fonts-extra
        rm -rf /var/lib/apt/lists/*
        updmap-user
        metadata_set_module "tex" "base"
        ;;
    extra)
        metadata_init "${BUILD_IMAGE:-unknown}"
        if metadata_tex_satisfies "extra"; then
            echo "Skipping extra TeX Live installation because modules.json records tex=$(metadata_module "tex" "none")"
            exit 0
        fi

        echo "Installing extra TeX Live packages"
        apt-get update
        apt-get install -y --no-install-recommends \
            texlive-base \
            texlive-latex-base \
            texlive-latex-recommended \
            texlive-latex-extra \
            texlive-fonts-recommended \
            texlive-fonts-extra \
            texlive-extra-utils
        rm -rf /var/lib/apt/lists/*
        updmap-user
        metadata_set_module "tex" "extra"
        ;;
    full)
        metadata_init "${BUILD_IMAGE:-unknown}"
        if metadata_tex_satisfies "full"; then
            echo "Skipping full TeX Live installation because modules.json already records tex=full"
            exit 0
        fi

        echo "Installing full TeX Live distribution"
        apt-get update
        apt-get install -y --no-install-recommends texlive-full
        rm -rf /var/lib/apt/lists/*
        updmap-user
        metadata_set_module "tex" "full"
        ;;
    *)
        echo "Invalid TEX_VARIANT=$TEX_VARIANT. Use one of: none, base, extra, full." >&2
        exit 1
        ;;
esac
