group "default" {
  targets = ["r-base", "rstudio"]
}

variable "UBUNTU_IMAGE_REPO" {
  default = "ubuntu"
}

variable "R_BASE_IMAGE_REPO" {
  default = "dncr/r-base"
}

variable "RSTUDIO_IMAGE_REPO" {
  default = "dncr/rstudio-server"
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

variable "R_DEV_DEPS" {
  default = "false"
}

variable "INSTALL_TEX" {
  default = "none"
}

variable "INSTALL_JAVA" {
  default = "false"
}

variable "INSTALL_SSH" {
  default = "false"
}

variable "CACHE_REMOTE" {
  default = "false"
}

target "r-base" {
  context = "."
  dockerfile = "dockerfiles/r-base.Dockerfile"

  labels = {
    "org.opencontainers.image.title" = "${R_BASE_IMAGE_REPO}"
    "org.opencontainers.image.description" = "Reproducible builds to fixed version of R"
    "org.opencontainers.image.base.name" = "docker.io/library/ubuntu:${UBUNTU_VERSION}"
    "org.opencontainers.image.licenses" = "GPL-2.0-or-later"
    "org.opencontainers.image.source" = "https://github.com/dncr/rstudio-server"
    "org.opencontainers.image.authors" = "Dincer Goksuluk <dincergoksuluk@sakarya.edu.tr>"
  }

  tags = ["${R_BASE_IMAGE_REPO}:${R_VERSION}-${UBUNTU_VERSION}"]

  cache-to = lower(CACHE_REMOTE) == "true" || CACHE_REMOTE == "1" ? [
    {
      type = "registry",
      ref = "docker.io/${R_BASE_IMAGE_REPO}:cache-${R_VERSION}-${UBUNTU_VERSION}",
      mode = "max"
    }
  ] : []

  cache-from = lower(CACHE_REMOTE) == "true" || CACHE_REMOTE == "1" ? [
    {
      ref = "docker.io/${R_BASE_IMAGE_REPO}:cache-${R_VERSION}-${UBUNTU_VERSION}",
      type = "registry"
    }
  ] : []

  platforms = ["linux/amd64", "linux/arm64"]

  args = {
    "R_VERSION" = "${R_VERSION}"
    "R_HOME" = "${R_HOME}"
    "TZ" = "${TZ}"
    "CRAN" = "${CRAN}"
    "LANG" = "${R_LANG}"
    "UBUNTU_VERSION" = "${UBUNTU_VERSION}"
    "UBUNTU_IMAGE_REPO" = "${UBUNTU_IMAGE_REPO}"
    "R_BASE_IMAGE_REPO" = "${R_BASE_IMAGE_REPO}"
    "RSTUDIO_IMAGE_REPO" = "${RSTUDIO_IMAGE_REPO}"
    "DEBIAN_FRONTEND" = "${DEBIAN_FRONTEND}"
    "R_BASE_MODE" = "${R_BASE_MODE}"
    "R_DEV_DEPS" = R_BASE_MODE == "dev" ? "true" : "${R_DEV_DEPS}"
    "INSTALL_TEX" = "${INSTALL_TEX}"
    "INSTALL_JAVA" = "${INSTALL_JAVA}"
  }
}

target "rstudio" {
  context = "."
  dockerfile = "dockerfiles/rstudio.Dockerfile"

  contexts = {
    "${R_BASE_IMAGE_REPO}:${R_VERSION}-${UBUNTU_VERSION}" = "target:r-base"
  }

  labels = {
    "org.opencontainers.image.title" = "${RSTUDIO_IMAGE_REPO}"
    "org.opencontainers.image.description" = "Reproducible builds to fixed version of R"
    "org.opencontainers.image.base.name" = "docker.io/${R_BASE_IMAGE_REPO}:${R_VERSION}-${UBUNTU_VERSION}"
    "org.opencontainers.image.licenses" = "GPL-2.0-or-later"
    "org.opencontainers.image.source" = "https://github.com/dncr/rstudio-server"
    "org.opencontainers.image.authors" = "Dincer Goksuluk <dincergoksuluk@erciyes.edu.tr>"
  }

  platforms = ["linux/amd64", "linux/arm64"]

  cache-to = lower(CACHE_REMOTE) == "true" || CACHE_REMOTE == "1" ? [
    {
      type = "registry",
      ref = "docker.io/${RSTUDIO_IMAGE_REPO}:cache-${R_VERSION}-${UBUNTU_VERSION}",
      mode = "max"
    }
  ] : []

  cache-from = lower(CACHE_REMOTE) == "true" || CACHE_REMOTE == "1" ? [
    {
      ref = "docker.io/${R_BASE_IMAGE_REPO}:cache-${R_VERSION}-${UBUNTU_VERSION}",
      type = "registry"
    },
    {
      ref = "docker.io/${RSTUDIO_IMAGE_REPO}:cache-${R_VERSION}-${UBUNTU_VERSION}",
      type = "registry"
    }
  ] : []

  tags = ["${RSTUDIO_IMAGE_REPO}:${R_VERSION}-${UBUNTU_VERSION}"]

  args = {
    "R_VERSION" = "${R_VERSION}"
    "R_BASE_IMAGE_REPO" = "${R_BASE_IMAGE_REPO}"
    "RSTUDIO_IMAGE_REPO" = "${RSTUDIO_IMAGE_REPO}"
    "RSTUDIO_VERSION" = "${RSTUDIO_VERSION}"
    "DEFAULT_USER" = "${DEFAULT_USER}"
    "LANG" = "${R_LANG}"
    "UBUNTU_VERSION" = "${UBUNTU_VERSION}"
    "R_DEV_DEPS" = "${R_DEV_DEPS}"
    "INSTALL_TEX" = "${INSTALL_TEX}"
    "INSTALL_JAVA" = "${INSTALL_JAVA}"
    "INSTALL_SSH" = "${INSTALL_SSH}"
  }
}
