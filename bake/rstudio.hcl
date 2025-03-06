
group "default" {
  targets = ["rstudio"]
}

variable "UBUNTU_VERSION" {
  default = "jammy"
}

variable "R_VERSION" {
  default = "latest"
}

variable "RSTUDIO_VERSION" {
  default = "2024.12.1+563"
}

variable "R_LANG" {
  default = "en_US.UTF-8"
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

  platforms = ["linux/amd64","linux/arm64"]

  tags = ["dncr/rstudio-server:${R_VERSION}-${UBUNTU_VERSION}"]

  args = {
    "R_VERSION" = "${R_VERSION}"
    "RSTUDIO_VERSION" = "${RSTUDIO_VERSION}"
    "LANG" = "${R_LANG}"
    "UBUNTU_VERSION" = "${UBUNTU_VERSION}"
  }
}
