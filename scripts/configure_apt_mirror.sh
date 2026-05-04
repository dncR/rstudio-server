#!/bin/bash

set -eu

apt_mirror_amd64="${APT_MIRROR_AMD64:-http://archive.ubuntu.com/ubuntu}"
apt_mirror_arm64="${APT_MIRROR_ARM64:-http://ports.ubuntu.com/ubuntu-ports}"

case "${TARGETARCH:-amd64}" in
    amd64)
        apt_mirror="$apt_mirror_amd64"
        ;;
    arm64)
        apt_mirror="$apt_mirror_arm64"
        ;;
    *)
        apt_mirror="$apt_mirror_amd64"
        ;;
esac

replace_apt_mirror() {
    sources_file="$1"

    if [ ! -f "$sources_file" ]; then
        return 0
    fi

    sed -i \
        -e "s|http://archive.ubuntu.com/ubuntu|${apt_mirror}|g" \
        -e "s|http://security.ubuntu.com/ubuntu|${apt_mirror}|g" \
        -e "s|http://ports.ubuntu.com/ubuntu-ports|${apt_mirror}|g" \
        -e "s|https://archive.ubuntu.com/ubuntu|${apt_mirror}|g" \
        -e "s|https://security.ubuntu.com/ubuntu|${apt_mirror}|g" \
        -e "s|https://ports.ubuntu.com/ubuntu-ports|${apt_mirror}|g" \
        "$sources_file"
}

replace_apt_mirror /etc/apt/sources.list.d/ubuntu.sources
replace_apt_mirror /etc/apt/sources.list
