
group "default" {
  targets = ["rstudio"]
}

variable "R_VERSION" {
  default = "4.4.1"
}

variable "RSTUDIO_VERSION" {
  default = "2024.04.2+764"
}

variable "UBUNTU_VERSION" {
  default = "jammy"
}

variable "R_HOME" {
  default = "/usr/local/lib/R"
}

variable "TZ" {
  default = "Etc/UTC"
}

variable "CRAN" {
  default = "https://p3m.dev/cran/__linux__/${UBUNTU_VERSION}/latest"
}

variable "DOCKER_HUB_REPO" {
  default = "ubuntu"
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
    "LANG" = "en_US.UTF-8"
    "UBUNTU_VERSION" = "${UBUNTU_VERSION}"
    "DOCKER_HUB_REPO" = "${DOCKER_HUB_REPO}"
  }
}
