#!/bin/bash

set -e

. /rocker_scripts/build_metadata.sh

INSTALL_TEX=${INSTALL_TEX:-none}

case "$INSTALL_TEX" in
    none)
        echo "Skipping TeX installation (INSTALL_TEX=none)"
        ;;
    base)
        metadata_init "${BUILD_IMAGE:-unknown}"
        if metadata_tex_satisfies "base"; then
            if [ "${BUILD_IMAGE:-unknown}" = "rstudio" ] && ! metadata_component_tex_satisfies "rstudio" "base"; then
                metadata_set_skipped_from_base "tex" "true"
            fi
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
        mktexlsr
        updmap-sys
        metadata_set_module "tex" "base"
        ;;
    extra)
        metadata_init "${BUILD_IMAGE:-unknown}"
        if metadata_tex_satisfies "extra"; then
            if [ "${BUILD_IMAGE:-unknown}" = "rstudio" ] && ! metadata_component_tex_satisfies "rstudio" "extra"; then
                metadata_set_skipped_from_base "tex" "true"
            fi
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
        mktexlsr
        updmap-sys
        metadata_set_module "tex" "extra"
        ;;
    full)
        metadata_init "${BUILD_IMAGE:-unknown}"
        if metadata_tex_satisfies "full"; then
            if [ "${BUILD_IMAGE:-unknown}" = "rstudio" ] && ! metadata_component_tex_satisfies "rstudio" "full"; then
                metadata_set_skipped_from_base "tex" "true"
            fi
            echo "Skipping full TeX Live installation because modules.json already records tex=full"
            exit 0
        fi

        echo "Installing full TeX Live distribution"
        apt-get update
        apt-get install -y --no-install-recommends texlive-full
        rm -rf /var/lib/apt/lists/*
        mktexlsr
        updmap-sys
        metadata_set_module "tex" "full"
        ;;
    *)
        echo "Invalid INSTALL_TEX=$INSTALL_TEX. Use one of: none, base, extra, full." >&2
        exit 1
        ;;
esac
