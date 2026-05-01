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
        [Tt][Rr][Uu][Ee] | 1) echo "true" ;;
        [Ff][Aa][Ll][Ss][Ee] | 0 | "") echo "false" ;;
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

metadata_block_field() {
    local component="$1"
    local section="$2"
    local key="$3"
    local default="$4"

    if [ ! -f "$BUILD_METADATA_FILE" ]; then
        echo "$default"
        return
    fi

    local value
    value=$(awk -v component="$component" -v section="$section" -v key="$key" '
        function count_open(line, tmp) {
            tmp = line
            return gsub(/\{/, "", tmp)
        }
        function count_close(line, tmp) {
            tmp = line
            return gsub(/\}/, "", tmp)
        }
        function clean_value(line) {
            sub(/^[^:]+:[[:space:]]*/, "", line)
            sub(/,[[:space:]]*$/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            gsub(/^"|"$/, "", line)
            return line
        }
        $0 ~ "\"" component "\"[[:space:]]*:[[:space:]]*\\{" {
            in_component = 1
            component_depth = 0
        }
        in_component {
            if ($0 ~ "\"" section "\"[[:space:]]*:[[:space:]]*\\{") {
                in_section = 1
                section_depth = 0
            }
            if (in_section && $0 ~ "\"" key "\"[[:space:]]*:") {
                print clean_value($0)
                found = 1
                exit
            }
            component_depth += count_open($0) - count_close($0)
            if (in_section) {
                section_depth += count_open($0) - count_close($0)
                if (section_depth <= 0) {
                    in_section = 0
                }
            }
            if (component_depth <= 0) {
                in_component = 0
            }
        }
        END {
            if (!found) {
                print ""
            }
        }
    ' "$BUILD_METADATA_FILE")

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

metadata_effective_module() {
    local key="$1"
    local default="$2"

    if [ ! -f "$BUILD_METADATA_FILE" ]; then
        echo "$default"
        return
    fi

    local value
    value=$(awk -v key="$key" '
        function count_open(line, tmp) {
            tmp = line
            return gsub(/\{/, "", tmp)
        }
        function count_close(line, tmp) {
            tmp = line
            return gsub(/\}/, "", tmp)
        }
        function clean_value(line) {
            sub(/^[^:]+:[[:space:]]*/, "", line)
            sub(/,[[:space:]]*$/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            gsub(/^"|"$/, "", line)
            return line
        }
        $0 ~ "\"effective\"[[:space:]]*:[[:space:]]*\\{" {
            in_effective = 1
            effective_depth = 0
        }
        in_effective {
            if ($0 ~ "\"modules\"[[:space:]]*:[[:space:]]*\\{") {
                in_modules = 1
                modules_depth = 0
            }
            if (in_modules && $0 ~ "\"" key "\"[[:space:]]*:") {
                print clean_value($0)
                found = 1
                exit
            }
            effective_depth += count_open($0) - count_close($0)
            if (in_modules) {
                modules_depth += count_open($0) - count_close($0)
                if (modules_depth <= 0) {
                    in_modules = 0
                }
            }
            if (effective_depth <= 0) {
                in_effective = 0
            }
        }
        END {
            if (!found) {
                print ""
            }
        }
    ' "$BUILD_METADATA_FILE")

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

metadata_tex_rank() {
    case "${1:-none}" in
        full) echo 3 ;;
        extra) echo 2 ;;
        base) echo 1 ;;
        *) echo 0 ;;
    esac
}

metadata_max_tex() {
    local left="${1:-none}"
    local right="${2:-none}"

    if [ "$(metadata_tex_rank "$right")" -gt "$(metadata_tex_rank "$left")" ]; then
        echo "$right"
    else
        echo "$left"
    fi
}

metadata_bool_or() {
    if [ "$1" = "true" ] || [ "$2" = "true" ]; then
        echo "true"
    else
        echo "false"
    fi
}

metadata_image_ref() {
    local repo="$1"
    local r_version="$2"
    local ubuntu_version="$3"

    if [ -z "$r_version" ] || [ "$r_version" = "null" ] || [ -z "$ubuntu_version" ] || [ "$ubuntu_version" = "null" ]; then
        echo "null"
    else
        metadata_json_string_or_null "${repo}:${r_version}-${ubuntu_version}"
    fi
}

metadata_load_state() {
    local image="$1"

    r_version=${R_VERSION:-$(metadata_string "r_version")}
    ubuntu_version=${UBUNTU_VERSION:-$(metadata_string "ubuntu_version")}

    rb_mode=$(metadata_block_field "r_base" "meta" "r_base_mode" "${R_BASE_MODE:-base}")
    rb_default_user=$(metadata_block_field "r_base" "meta" "default_user" "null")
    rb_rstudio_version=$(metadata_block_field "r_base" "meta" "rstudio_version" "null")
    rb_req_r_dev=$(metadata_block_field "r_base" "requested" "r_dev_deps" "false")
    rb_req_tex=$(metadata_block_field "r_base" "requested" "tex" "none")
    rb_req_java=$(metadata_block_field "r_base" "requested" "java" "false")
    rb_req_ssh=$(metadata_block_field "r_base" "requested" "ssh" "null")
    rb_mod_r_dev=$(metadata_block_field "r_base" "modules" "r_dev_deps" "false")
    rb_mod_tex=$(metadata_block_field "r_base" "modules" "tex" "none")
    rb_mod_java=$(metadata_block_field "r_base" "modules" "java" "false")
    rb_mod_ssh=$(metadata_block_field "r_base" "modules" "ssh" "null")

    rs_default_user=$(metadata_block_field "rstudio" "meta" "default_user" "null")
    rs_rstudio_version=$(metadata_block_field "rstudio" "meta" "rstudio_version" "null")
    rs_req_r_dev=$(metadata_block_field "rstudio" "requested" "r_dev_deps" "false")
    rs_req_tex=$(metadata_block_field "rstudio" "requested" "tex" "none")
    rs_req_java=$(metadata_block_field "rstudio" "requested" "java" "false")
    rs_req_ssh=$(metadata_block_field "rstudio" "requested" "ssh" "false")
    rs_mod_r_dev=$(metadata_block_field "rstudio" "modules" "r_dev_deps" "false")
    rs_mod_tex=$(metadata_block_field "rstudio" "modules" "tex" "none")
    rs_mod_java=$(metadata_block_field "rstudio" "modules" "java" "false")
    rs_mod_ssh=$(metadata_block_field "rstudio" "modules" "ssh" "false")
    rs_skip_r_dev=$(metadata_block_field "rstudio" "skipped_from_base" "r_dev_deps" "false")
    rs_skip_tex=$(metadata_block_field "rstudio" "skipped_from_base" "tex" "false")
    rs_skip_java=$(metadata_block_field "rstudio" "skipped_from_base" "java" "false")
    rs_skip_ssh=$(metadata_block_field "rstudio" "skipped_from_base" "ssh" "false")

}

metadata_write_state() {
    local image_chain="$1"
    local include_rstudio="false"
    local effective_r_dev
    local effective_tex
    local effective_java
    local effective_ssh
    local r_version_json
    local ubuntu_version_json
    local rb_image_json
    local rs_image_json
    local rb_default_user_json
    local rb_rstudio_version_json
    local rb_mode_json
    local rb_req_tex_json
    local rb_mod_tex_json
    local rs_default_user_json
    local rs_rstudio_version_json
    local rs_mode_json
    local rs_req_tex_json
    local rs_mod_tex_json

    if [ "$image_chain" = "r-base + rstudio" ]; then
        include_rstudio="true"
    fi

    effective_r_dev=$rb_mod_r_dev
    effective_tex=$rb_mod_tex
    effective_java=$rb_mod_java
    effective_ssh=$rb_mod_ssh

    if [ "$include_rstudio" = "true" ]; then
        effective_r_dev=$(metadata_bool_or "$effective_r_dev" "$rs_mod_r_dev")
        effective_tex=$(metadata_max_tex "$effective_tex" "$rs_mod_tex")
        effective_java=$(metadata_bool_or "$effective_java" "$rs_mod_java")
        effective_ssh=$(metadata_bool_or "$effective_ssh" "$rs_mod_ssh")
    fi

    r_version_json=$(metadata_json_string_or_null "$r_version")
    ubuntu_version_json=$(metadata_json_string_or_null "$ubuntu_version")
    rb_image_json=$(metadata_image_ref "dncr/r-base" "$r_version" "$ubuntu_version")
    rs_image_json=$(metadata_image_ref "dncr/rstudio-server" "$r_version" "$ubuntu_version")
    rb_default_user_json=$(metadata_json_string_or_null "$rb_default_user")
    rb_rstudio_version_json=$(metadata_json_string_or_null "$rb_rstudio_version")
    rb_mode_json=$(metadata_json_string_or_null "$rb_mode")
    rb_req_tex_json=$(metadata_json_string_or_null "$rb_req_tex")
    rb_mod_tex_json=$(metadata_json_string_or_null "$rb_mod_tex")
    rs_default_user_json=$(metadata_json_string_or_null "$rs_default_user")
    rs_rstudio_version_json=$(metadata_json_string_or_null "$rs_rstudio_version")
    rs_mode_json=$(metadata_json_string_or_null "null")
    rs_req_tex_json=$(metadata_json_string_or_null "$rs_req_tex")
    rs_mod_tex_json=$(metadata_json_string_or_null "$rs_mod_tex")

    mkdir -p "$BUILD_METADATA_DIR"
    cat >"$BUILD_METADATA_FILE" <<EOF
{
  "schema_version": 5,
  "image_chain": "$image_chain",
  "r_version": $r_version_json,
  "ubuntu_version": $ubuntu_version_json,
  "effective": {
    "modules": {
      "r_dev_deps": $effective_r_dev,
      "tex": "$effective_tex",
      "java": $effective_java,
      "ssh": $effective_ssh
    }
  },
  "components": {
    "r_base": {
      "image": $rb_image_json,
      "meta": {
        "r_base_mode": $rb_mode_json,
        "default_user": $rb_default_user_json,
        "rstudio_version": $rb_rstudio_version_json
      },
      "requested": {
        "r_dev_deps": $rb_req_r_dev,
        "tex": $rb_req_tex_json,
        "java": $rb_req_java,
        "ssh": $rb_req_ssh
      },
      "modules": {
        "r_dev_deps": $rb_mod_r_dev,
        "tex": $rb_mod_tex_json,
        "java": $rb_mod_java,
        "ssh": $rb_mod_ssh
      }
    }$(if [ "$include_rstudio" = "true" ]; then cat <<EOF2
,
    "rstudio": {
      "image": $rs_image_json,
      "meta": {
        "r_base_mode": $rs_mode_json,
        "default_user": $rs_default_user_json,
        "rstudio_version": $rs_rstudio_version_json
      },
      "requested": {
        "r_dev_deps": $rs_req_r_dev,
        "tex": $rs_req_tex_json,
        "java": $rs_req_java,
        "ssh": $rs_req_ssh
      },
      "modules": {
        "r_dev_deps": $rs_mod_r_dev,
        "tex": $rs_mod_tex_json,
        "java": $rs_mod_java,
        "ssh": $rs_mod_ssh
      },
      "skipped_from_base": {
        "r_dev_deps": $rs_skip_r_dev,
        "tex": $rs_skip_tex,
        "java": $rs_skip_java,
        "ssh": $rs_skip_ssh
      }
    }
EOF2
fi)
  }
}
EOF
}

metadata_init() {
    local image="${1:-unknown}"
    local image_chain="r-base"

    metadata_load_state "$image"

    if [ "$image" = "rstudio" ]; then
        image_chain="r-base + rstudio"
        rs_default_user=${DEFAULT_USER:-$(metadata_block_field "rstudio" "meta" "default_user" "rstudio")}
        rs_rstudio_version=${RSTUDIO_VERSION:-$(metadata_block_field "rstudio" "meta" "rstudio_version" "")}
        rs_req_r_dev=$(metadata_bool "${R_DEV_DEPS:-false}")
        rs_req_tex=${INSTALL_TEX:-none}
        rs_req_java=$(metadata_bool "${INSTALL_JAVA:-false}")
        if [ "$rs_req_r_dev" = "true" ]; then
            rs_req_java="true"
        fi
        rs_req_ssh=$(metadata_bool "${INSTALL_SSH:-false}")
    else
        rb_mode=${R_BASE_MODE:-base}
        rb_req_r_dev=$(metadata_bool "${R_DEV_DEPS:-false}")
        rb_req_tex=${INSTALL_TEX:-none}
        rb_req_java=$(metadata_bool "${INSTALL_JAVA:-false}")
        if [ "$rb_req_r_dev" = "true" ]; then
            rb_req_java="true"
        fi
        rb_req_ssh="null"
    fi

    metadata_write_state "$image_chain"
}

metadata_set_module() {
    local key="$1"
    local value="$2"
    local image
    local image_chain

    image=$(metadata_string "image_chain")
    case "$image" in
        "r-base + rstudio") image_chain="r-base + rstudio" ;;
        *) image_chain="r-base" ;;
    esac

    image=${BUILD_IMAGE:-unknown}
    metadata_load_state "$image"

    if [ "$image" = "rstudio" ]; then
        image_chain="r-base + rstudio"
        case "$key" in
            r_dev_deps) rs_mod_r_dev=$(metadata_bool "$value"); rs_skip_r_dev="false" ;;
            tex) rs_mod_tex="$value"; rs_skip_tex="false" ;;
            java) rs_mod_java=$(metadata_bool "$value"); rs_skip_java="false" ;;
            ssh) rs_mod_ssh=$(metadata_bool "$value"); rs_skip_ssh="false" ;;
            *)
                echo "Unknown metadata module: $key" >&2
                exit 1
                ;;
        esac
    else
        image_chain="r-base"
        case "$key" in
            r_dev_deps) rb_mod_r_dev=$(metadata_bool "$value") ;;
            tex) rb_mod_tex="$value" ;;
            java) rb_mod_java=$(metadata_bool "$value") ;;
            ssh) rb_mod_ssh=$(metadata_bool "$value") ;;
            *)
                echo "Unknown metadata module: $key" >&2
                exit 1
                ;;
        esac
    fi

    metadata_write_state "$image_chain"
}

metadata_set_skipped_from_base() {
    local key="$1"
    local value="$2"

    metadata_load_state "rstudio"

    case "$key" in
        r_dev_deps) rs_skip_r_dev=$(metadata_bool "$value") ;;
        tex) rs_skip_tex=$(metadata_bool "$value") ;;
        java) rs_skip_java=$(metadata_bool "$value") ;;
        ssh) rs_skip_ssh=$(metadata_bool "$value") ;;
        *)
            echo "Unknown skipped metadata module: $key" >&2
            exit 1
            ;;
    esac

    metadata_write_state "r-base + rstudio"
}

metadata_module() {
    metadata_effective_module "$1" "$2"
}

metadata_has_bool_module() {
    [ "$(metadata_module "$1" "false")" = "true" ]
}

metadata_component_has_bool_module() {
    [ "$(metadata_block_field "$1" "modules" "$2" "false")" = "true" ]
}

metadata_component_tex_satisfies() {
    local component="$1"
    local requested="$2"
    local installed

    installed=$(metadata_block_field "$component" "modules" "tex" "none")

    case "$requested:$installed" in
        none:*) return 0 ;;
        base:base | base:extra | base:full) return 0 ;;
        extra:extra | extra:full) return 0 ;;
        full:full) return 0 ;;
        *) return 1 ;;
    esac
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
        set-skipped-from-base) metadata_set_skipped_from_base "$@" ;;
        *)
            echo "Usage: $0 {init IMAGE|set-module KEY VALUE|get-module KEY DEFAULT|set-skipped-from-base KEY VALUE}" >&2
            exit 1
            ;;
    esac
fi
