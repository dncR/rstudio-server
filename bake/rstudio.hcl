
group "default" {
  targets = ["rstudio"]
}

variable "R_VERSION" {
  default = "$R_VERSION"
}

variable "RSTUDIO_VERSION" {
  default = "$RSTUDIO_VERSION"
}

variable "UBUNTU_VERSION" {
  default = "$UBUNTU_VERSION"
}

variable "R_HOME" {
  default = "$R_HOME"
}

variable "TZ" {
  default = "$TZ"
}

variable "LANG_SET" {
  default = "$LANG_SET"
}

variable "CRAN" {
  default = "https://p3m.dev/cran/__linux__/${UBUNTU_VERSION}/latest"
}

variable "DOCKER_HUB_REPO" {
  default = "$DOCKER_HUB_REPO"
}

target "rstudio" {
  context = "../"
  dockerfile = "dockerfiles/rstudio.Dockerfile"

  labels = {
    "org.opencontainers.image.title" = "dncr/rstudio"
    "org.opencontainers.image.description" = "Reproducible builds to fixed version of R"
    "org.opencontainers.image.base.name" = "docker.io/library/ubuntu:${UBUNTU_VERSION}"
    "org.opencontainers.image.licenses" = "GPL-2.0-or-later"
    "org.opencontainers.image.source" = "https://github.com/dncr/rstudio-server"
    "org.opencontainers.image.authors" = "Dincer Goksuluk <dincergoksuluk@erciyes.edu.tr>"
  }

  platforms = ["linux/amd64","linux/arm64/v8"]

  tags = ["dncr/rstudio-server:${R_VERSION}-${UBUNTU_VERSION}"]

  args = {
    "R_VERSION" = "${R_VERSION}"
    "RSTUDIO_VERSION" = "${RSTUDIO_VERSION}"
    "R_HOME" = "${R_HOME}"
    "TZ" = "${TZ}"
    "CRAN" = "${CRAN}"
    "LANG" = "${LANG_SET}"
    "UBUNTU_VERSION" = "${UBUNTU_VERSION}"
    "DOCKER_HUB_REPO" = "${DOCKER_HUB_REPO}"
  }
}
