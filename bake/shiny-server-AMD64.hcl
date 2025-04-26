group "default" {
  targets = ["shiny-server"]
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

variable "SHINY_SERVER_VERSION" {
  default = "latest"
}

target "shiny-server" {
  context = "../"
  
  dockerfile = "dockerfiles/shiny-server.Dockerfile"

  labels = {
    "org.opencontainers.image.title" = "dncr/shiny-server"
    "org.opencontainers.image.description" = "Reproducible builds to fixed version of R"
    "org.opencontainers.image.base.name" = "docker.io/library/ubuntu:${UBUNTU_VERSION}"
    "org.opencontainers.image.licenses" = "GPL-2.0-or-later"
    "org.opencontainers.image.source" = "https://github.com/dncr/rstudio-server"
    "org.opencontainers.image.authors" = "Dincer Goksuluk <dincergoksuluk@erciyes.edu.tr>"
  }

  tags = ["dncr/shiny-server:${R_VERSION}-${UBUNTU_VERSION}"]
  
  cache-to = [
    {
      type = "registry",
      ref = "docker.io/dncr/shiny-server:cache-${R_VERSION}-${UBUNTU_VERSION}",
      mode = "max"
    },
    
    {
      type = "local",
      dest = "/tmp/docker/cache/shiny-server-${R_VERSION}-${UBUNTU_VERSION}",
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
  
  platforms = ["linux/amd64"]

  args = {
    "R_VERSION" = "${R_VERSION}"
    "R_HOME" = "${R_HOME}"
    "TZ" = "${TZ}"
    "LANG" = "${R_LANG}"
    "UBUNTU_VERSION" = "${UBUNTU_VERSION}"
    "DEBIAN_FRONTEND" = "${DEBIAN_FRONTEND}"
    "SHINY_SERVER_VERSION" = "${SHINY_SERVER_VERSION}"
  }
}
