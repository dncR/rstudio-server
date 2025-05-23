
group "default" {
  targets = ["r-base"]
}

variable "DOCKER_HUB_REPO" {
  default = "ubuntu"
}

variable "UBUNTU_VERSION" {
  default = "jammy"
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

variable "DEBIAN_FRONTEND" {
  default = "noninteractive"
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
    },
    
    {
      type = "local",
      dest = "/tmp/docker/cache/r-base-${R_VERSION}-${UBUNTU_VERSION}",
      mode = "max"
    }
  ]

  cache-from = [
    {
      ref = "docker.io/dncr/r-base:cache-${R_VERSION}-${UBUNTU_VERSION}",
      type = "registry"
    },

    {
      type = "local",
      src = "/tmp/docker/cache/r-base-${R_VERSION}-${UBUNTU_VERSION}"
    }
  ]
  
  platforms = ["linux/amd64", "linux/arm64"]

  args = {
    "R_VERSION" = "${R_VERSION}"
    "R_HOME" = "${R_HOME}"
    "TZ" = "${TZ}"
    "LANG" = "${R_LANG}"
    "UBUNTU_VERSION" = "${UBUNTU_VERSION}"
    "DOCKER_HUB_REPO" = "${DOCKER_HUB_REPO}"
    "DEBIAN_FRONTEND" = "${DEBIAN_FRONTEND}"
  }
}
