group "default" {
  targets = ["r-base", "rstudio"]
}

variable "DOCKER_HUB_REPO" {
  default = "ubuntu"
}

variable "UBUNTU_VERSION" {
  default = "noble"
}

variable "R_VERSION" {
  default = "latest"
}

variable "R_HOME" {
  default = "/usr/local/lib/R"
}

variable "TZ" {
  default = "Etc/UTC"
}

variable "R_LANG" {
  default = "en_US.UTF-8"
}

variable "CRAN" {
  default = "https://p3m.dev/cran/__linux__/${UBUNTU_VERSION}/latest"
}

variable "DEBIAN_FRONTEND" {
  default = "noninteractive"
}

variable "RSTUDIO_VERSION" {
  default = "2026.04.0+526"
}

variable "DEFAULT_USER" {
  default = "rstudio"
}

variable "R_BASE_MODE" {
  default = "base"
}

variable "INSTALL_R_DEV_DEPS" {
  default = "false"
}

variable "INSTALL_R_CMD_CHECK_DEPS" {
  default = "false"
}

variable "TEX_VARIANT" {
  default = "none"
}

variable "INSTALL_JAVA" {
  default = "false"
}

variable "INSTALL_SSH" {
  default = "false"
}

target "r-base" {
  context = "../"
  dockerfile = "dockerfiles/r-base.Dockerfile"

  labels = {
    "org.opencontainers.image.title" = "dncr/r-base"
    "org.opencontainers.image.description" = "Reproducible builds to fixed version of R"
    "org.opencontainers.image.base.name" = "docker.io/library/ubuntu:${UBUNTU_VERSION}"
    "org.opencontainers.image.licenses" = "GPL-2.0-or-later"
    "org.opencontainers.image.source" = "https://github.com/dncr/rstudio-server"
    "org.opencontainers.image.authors" = "Dincer Goksuluk <dincergoksuluk@erciyes.edu.tr>"
  }

  tags = ["dncr/r-base:${R_VERSION}-${UBUNTU_VERSION}"]

  cache-to = [
    {
      type = "registry",
      ref = "docker.io/dncr/r-base:cache-${R_VERSION}-${UBUNTU_VERSION}",
      mode = "max"
    }
  ]

  cache-from = [
    {
      ref = "docker.io/dncr/r-base:cache-${R_VERSION}-${UBUNTU_VERSION}",
      type = "registry"
    }
  ]

  platforms = ["linux/amd64", "linux/arm64"]

  args = {
    "R_VERSION" = "${R_VERSION}"
    "R_HOME" = "${R_HOME}"
    "TZ" = "${TZ}"
    "CRAN" = "${CRAN}"
    "LANG" = "${R_LANG}"
    "UBUNTU_VERSION" = "${UBUNTU_VERSION}"
    "DOCKER_HUB_REPO" = "${DOCKER_HUB_REPO}"
    "DEBIAN_FRONTEND" = "${DEBIAN_FRONTEND}"
    "R_BASE_MODE" = "${R_BASE_MODE}"
    "INSTALL_R_DEV_DEPS" = "${INSTALL_R_DEV_DEPS}"
    "INSTALL_R_CMD_CHECK_DEPS" = "${INSTALL_R_CMD_CHECK_DEPS}"
    "TEX_VARIANT" = "${TEX_VARIANT}"
    "INSTALL_JAVA" = "${INSTALL_JAVA}"
  }
}

target "rstudio" {
  context = "../"
  dockerfile = "dockerfiles/rstudio.Dockerfile"

  contexts = {
    "dncr/r-base:${R_VERSION}-${UBUNTU_VERSION}" = "target:r-base"
  }

  labels = {
    "org.opencontainers.image.title" = "dncr/rstudio"
    "org.opencontainers.image.description" = "Reproducible builds to fixed version of R"
    "org.opencontainers.image.base.name" = "docker.io/library/ubuntu:${UBUNTU_VERSION}"
    "org.opencontainers.image.licenses" = "GPL-2.0-or-later"
    "org.opencontainers.image.source" = "https://github.com/dncr/rstudio-server"
    "org.opencontainers.image.authors" = "Dincer Goksuluk <dincergoksuluk@erciyes.edu.tr>"
  }

  platforms = ["linux/amd64", "linux/arm64"]

  cache-to = [
    {
      type = "registry",
      ref = "docker.io/dncr/rstudio-server:cache-${R_VERSION}-${UBUNTU_VERSION}",
      mode = "max"
    }
  ]

  cache-from = [
    {
      ref = "docker.io/dncr/r-base:cache-${R_VERSION}-${UBUNTU_VERSION}",
      type = "registry"
    },
    {
      ref = "docker.io/dncr/rstudio-server:cache-${R_VERSION}-${UBUNTU_VERSION}",
      type = "registry"
    }
  ]

  tags = ["dncr/rstudio-server:${R_VERSION}-${UBUNTU_VERSION}"]

  args = {
    "R_VERSION" = "${R_VERSION}"
    "RSTUDIO_VERSION" = "${RSTUDIO_VERSION}"
    "DEFAULT_USER" = "${DEFAULT_USER}"
    "LANG" = "${R_LANG}"
    "UBUNTU_VERSION" = "${UBUNTU_VERSION}"
    "INSTALL_R_DEV_DEPS" = "${INSTALL_R_DEV_DEPS}"
    "INSTALL_R_CMD_CHECK_DEPS" = "${INSTALL_R_CMD_CHECK_DEPS}"
    "TEX_VARIANT" = "${TEX_VARIANT}"
    "INSTALL_JAVA" = "${INSTALL_JAVA}"
    "INSTALL_SSH" = "${INSTALL_SSH}"
  }
}
