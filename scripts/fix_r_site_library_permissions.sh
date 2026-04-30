#!/bin/bash
set -e

R_SITE_LIBRARY=${1:-${R_SITE_LIBRARY:-/usr/local/lib/R/site-library}}
R_LIBRARY_GROUP=${R_LIBRARY_GROUP:-staff}

if ! getent group "${R_LIBRARY_GROUP}" >/dev/null; then
    groupadd --system "${R_LIBRARY_GROUP}"
fi

mkdir -p "${R_SITE_LIBRARY}"

# Users created by the Rocker-style init scripts are members of `staff`.
# Keep the library root-owned, group-writable, and readable by everyone.
chown -R root:"${R_LIBRARY_GROUP}" "${R_SITE_LIBRARY}"
chmod -R u+rwX,g+rwX,o+rX,o-w "${R_SITE_LIBRARY}"
find "${R_SITE_LIBRARY}" -type d -exec chmod g+s {} +
