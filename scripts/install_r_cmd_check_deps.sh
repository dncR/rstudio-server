#!/bin/bash

set -e

echo "install_r_cmd_check_deps.sh is deprecated; use install_r_dev_deps.sh with R_DEV_DEPS=true."
R_DEV_DEPS=${R_DEV_DEPS:-false}
export R_DEV_DEPS

/rocker_scripts/install_r_dev_deps.sh
