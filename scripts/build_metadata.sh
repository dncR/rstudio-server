#!/bin/bash

set -e

if [ -n "${BUILD_METADATA_FILE:-}" ]; then
    BUILD_METADATA_DIR=${BUILD_METADATA_DIR:-$(dirname "$BUILD_METADATA_FILE")}
else
    BUILD_METADATA_DIR=${BUILD_METADATA_DIR:-/usr/local/share/rstudio-server-build}
    BUILD_METADATA_FILE=${BUILD_METADATA_DIR}/modules.json
fi

metadata_bool() {
    case "${1:-false}" in
        true | TRUE | True | 1 | yes | YES | Yes) echo "true" ;;
        *) echo "false" ;;
    esac
}

metadata_json_string_or_null() {
    local value="$1"

    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "null"
        return
    fi

    value=$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '"%s"\n' "$value"
}

metadata_string() {
    if [ -f "$BUILD_METADATA_FILE" ]; then
        grep -E "\"$1\"[[:space:]]*:" "$BUILD_METADATA_FILE" | head -n 1 | sed -nE 's/^[^:]+:[[:space:]]*"([^"]*)".*$/\1/p' || true
    fi
}

metadata_module() {
    local key="$1"
    local default="$2"

    if [ -f "$BUILD_METADATA_FILE" ]; then
        local value
        value=$(grep -E "\"$key\"[[:space:]]*:" "$BUILD_METADATA_FILE" | head -n 1 | sed -E 's/^[^:]+:[[:space:]]*([^,}]+).*$/\1/' | tr -d '" ' || true)
        if [ -n "$value" ]; then
            echo "$value"
            return
        fi
    fi

    echo "$default"
}

metadata_write() {
    local image="$1"
    local r_base_mode="$2"
    local r_dev_deps="$3"
    local tex="$4"
    local java="$5"
    local ssh="$6"
    local r_version
    local ubuntu_version
    local default_user
    local rstudio_version
    local tex_requested
    local r_version_json
    local ubuntu_version_json
    local default_user_json
    local rstudio_version_json
    local r_base_mode_json
    local tex_requested_json

    r_version=${R_VERSION:-$(metadata_string "r_version")}
    ubuntu_version=${UBUNTU_VERSION:-$(metadata_string "ubuntu_version")}
    tex_requested=${TEX:-$(metadata_string "tex")}

    case "$image" in
        rstudio)
            default_user=${DEFAULT_USER:-$(metadata_string "default_user")}
            rstudio_version=${RSTUDIO_VERSION:-$(metadata_string "rstudio_version")}
            ;;
        *)
            default_user=""
            rstudio_version=""
            ;;
    esac

    r_version_json=$(metadata_json_string_or_null "$r_version")
    ubuntu_version_json=$(metadata_json_string_or_null "$ubuntu_version")
    default_user_json=$(metadata_json_string_or_null "$default_user")
    rstudio_version_json=$(metadata_json_string_or_null "$rstudio_version")
    r_base_mode_json=$(metadata_json_string_or_null "$r_base_mode")
    tex_requested_json=$(metadata_json_string_or_null "$tex_requested")

    mkdir -p "$BUILD_METADATA_DIR"
    cat > "$BUILD_METADATA_FILE" <<EOF
{
  "schema_version": 4,
  "image": "$image",
  "r_version": $r_version_json,
  "ubuntu_version": $ubuntu_version_json,
  "default_user": $default_user_json,
  "rstudio_version": $rstudio_version_json,
  "r_base_mode": $r_base_mode_json,
  "requested": {
    "tex": $tex_requested_json
  },
  "modules": {
    "r_dev_deps": $r_dev_deps,
    "tex": "$tex",
    "java": $java,
    "ssh": $ssh
  }
}
EOF
}

metadata_init() {
    local image="${1:-unknown}"
    local current_mode
    local current_r_dev
    local current_tex
    local current_java
    local current_ssh

    current_mode=$(metadata_string "r_base_mode")
    current_r_dev=$(metadata_module "r_dev_deps" "false")
    current_tex=$(metadata_module "tex" "none")
    current_java=$(metadata_module "java" "false")
    current_ssh=$(metadata_module "ssh" "false")

    if [ -z "$current_mode" ]; then
        current_mode=${R_BASE_MODE:-base}
    fi

    case "$image" in
        r-base)
            current_ssh="null"
            ;;
        rstudio)
            if [ "$current_ssh" = "null" ]; then
                current_ssh="false"
            fi
            ;;
    esac

    metadata_write "$image" "$current_mode" "$current_r_dev" "$current_tex" "$current_java" "$current_ssh"
}

metadata_set_module() {
    local key="$1"
    local value="$2"
    local image
    local mode
    local r_dev
    local tex
    local java
    local ssh

    image=$(metadata_string "image")
    mode=$(metadata_string "r_base_mode")
    r_dev=$(metadata_module "r_dev_deps" "false")
    tex=$(metadata_module "tex" "none")
    java=$(metadata_module "java" "false")
    ssh=$(metadata_module "ssh" "false")

    [ -n "$image" ] || image="${BUILD_IMAGE:-unknown}"
    [ -n "$mode" ] || mode="${R_BASE_MODE:-base}"

    case "$key" in
        r_dev_deps) r_dev=$(metadata_bool "$value") ;;
        tex) tex="$value" ;;
        java) java=$(metadata_bool "$value") ;;
        ssh) ssh=$(metadata_bool "$value") ;;
        *)
            echo "Unknown metadata module: $key" >&2
            exit 1
            ;;
    esac

    metadata_write "$image" "$mode" "$r_dev" "$tex" "$java" "$ssh"
}

metadata_has_bool_module() {
    [ "$(metadata_module "$1" "false")" = "true" ]
}

metadata_tex_satisfies() {
    local requested="$1"
    local installed

    installed=$(metadata_module "tex" "none")

    case "$requested:$installed" in
        none:*) return 0 ;;
        base:base | base:extra | base:full) return 0 ;;
        extra:extra | extra:full) return 0 ;;
        full:full) return 0 ;;
        *) return 1 ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    command="$1"
    shift || true

    case "$command" in
        init) metadata_init "$@" ;;
        set-module) metadata_set_module "$@" ;;
        get-module) metadata_module "$@" ;;
        *)
            echo "Usage: $0 {init IMAGE|set-module KEY VALUE|get-module KEY DEFAULT}" >&2
            exit 1
            ;;
    esac
fi
