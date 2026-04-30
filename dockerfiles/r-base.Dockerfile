# Define BUILD args.
ARG UBUNTU_VERSION
ARG DOCKER_HUB_REPO

FROM ${DOCKER_HUB_REPO:-ubuntu}:${UBUNTU_VERSION:-noble}

ARG UBUNTU_VERSION
ARG R_VERSION
ARG R_HOME
ARG TZ
ARG CRAN
ARG LANG
ARG DEBIAN_FRONTEND
ARG R_BASE_MODE
ARG INSTALL_R_DEV_DEPS
ARG INSTALL_R_CMD_CHECK_DEPS
ARG TEX_VARIANT
ARG INSTALL_JAVA

# Import values of ARGs from ENVIRONMENT
ENV R_VERSION=${R_VERSION:-latest}
ENV R_HOME=${R_HOME:-/usr/local/lib/R}
ENV TZ=${TZ:-Etc/UTC}
ENV CRAN=${CRAN:-https://p3m.dev/cran/__linux__/${UBUNTU_VERSION:-noble}/latest}
ENV LANG=${LANG:-en_US.UTF-8}
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}

# Ubuntu packages not included in "install_R_source.sh" or "setup_R.sh"
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libxml2-dev && \
    rm -rf /var/lib/apt/lists/*

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh
RUN /rocker_scripts/install_R_source.sh

COPY scripts /rocker_scripts

# RUN /rocker_scripts/setup_R.sh
RUN <<EOF
## Use getent to match UID 1000 exactly before removing the default user.
## Previous broad match could trigger on any /etc/passwd field containing 1000.
# if grep -q "1000" /etc/passwd; then
#     userdel --remove "$(id -un 1000)";
# fi
if getent passwd 1000 >/dev/null; then
    userdel --remove "$(id -un 1000)";
fi
/rocker_scripts/setup_R.sh
EOF

RUN case "${R_BASE_MODE:-base}" in \
        base | dev) ;; \
        *) echo "Invalid R_BASE_MODE=${R_BASE_MODE}. Use one of: base, dev." >&2; exit 1 ;; \
    esac

RUN BUILD_IMAGE=r-base /rocker_scripts/build_metadata.sh init r-base

# Optional R ecosystem modules for CLI-first R images. These are ignored when
# R_BASE_MODE=base, regardless of the module-specific build args.
RUN if [ "${R_BASE_MODE:-base}" = "dev" ]; then \
        BUILD_IMAGE=r-base /rocker_scripts/install_r_dev_deps.sh && \
        /rocker_scripts/fix_r_site_library_permissions.sh; \
    else \
        echo "Skipping r-base optional modules because R_BASE_MODE=${R_BASE_MODE:-base}"; \
    fi

RUN if [ "${R_BASE_MODE:-base}" = "dev" ]; then \
        BUILD_IMAGE=r-base /rocker_scripts/install_r_cmd_check_deps.sh; \
    else \
        echo "Skipping r-base R CMD check dependencies because R_BASE_MODE=${R_BASE_MODE:-base}"; \
    fi

RUN if [ "${R_BASE_MODE:-base}" = "dev" ]; then \
        BUILD_IMAGE=r-base /rocker_scripts/install_texlive_variant.sh; \
    else \
        echo "Skipping r-base TeX installation because R_BASE_MODE=${R_BASE_MODE:-base}"; \
    fi

RUN if [ "${R_BASE_MODE:-base}" = "dev" ]; then \
        BUILD_IMAGE=r-base /rocker_scripts/install_java.sh; \
    else \
        echo "Skipping r-base Java installation because R_BASE_MODE=${R_BASE_MODE:-base}"; \
    fi

CMD ["R"]
