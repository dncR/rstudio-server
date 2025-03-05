# Creating Docker Container for Development Environment.

We propose a docker container to be used for package development. The built VMs are distributed through Docker Hub ([dncr/rstudio-server](https://hub.docker.com/repository/docker/dncr/rstudio-server/general)) and source codes are available through GitHub ([https://github.com/dncR/rstudio-server](https://github.com/dncR/rstudio-server)). The docker container is built upon **Linux Operating System** (particularly, Ubuntu Jammy) with pre-installed **R** and **RStudio Server**. All the arguments to be used while *pulling*, *building*, or *creating* docker image/container are given with an environment file **.env**. One may change the value of corresponding arguments to customize Docker Environment. See below for more details on **.env** file.

## Working with .env file

This file includes argument used to customize Docker images and/or containers. The container comes with **Ubuntu Jammy** distribution, supporting for both platforms **ARM (e.g., Apple's silicon chips)** and **AMD (e.g., Intel-based chips)**. It is not required to set OS platform. Docker will pull appropriate platform from the repository.

* **UBUNTU_VERSION**: The codename of Ubuntu distro. Default is `jammy`.
* **R_VERSION**: The version of base R installation. Default is `latest`.
* **RSTUDIO_VERSION**: The version of RStudio Server installation. Default is `2023.12.0+369`. This option does not have an effect while running pre-built containers. It is used while creating the Docker image from sctracth.

For other arguments, see **.env** file.

## Running the Docker Container

One may run the Docker Container using the codes below:

1. Pull pre-built container (including R 4.4.1 installed) from Docker Hub.

```
R_VERSION=4.4.1 docker compose -f rstudio.yml pull
```

2. Run container from pulled image.

```
R_VERSION=4.4.1 docker compose -f rstudio.yml up -d
```

One may change the **rstudio.yml** file to customize the docker container, e.g., binding volumes, adding services, changing the localhost ports, etc. See Docker Compose file documentation for more details on how to edit YAML file to customize Docker Containers.

We benefitted from the installation scripts of [Rocker Project](https://hub.docker.com/u/rocker) and modified some scripts to create our custom docker image. Rocker Project is available as a GitHub repository [here](https://github.com/rocker-org/rocker-versioned2).

## Post Installation Steps

### 1. Linux Dependencies (Ubuntu 22.04 - Jammy)

Below linux packages are required to be installed after Docker Container is created.

```sh
sudo apt-get update
sudo apt-get install -y \
  libmagick++-dev
```
	
### 2. TexLive Installation (Optional)

We included all the scripts used (or not used) while creating the docker image under in-container folder `/rocker_scripts`. Two scripts, called `texlive_base.sh` and `texlive-full.sh`, are available in this folder. One may run one of these scripts to install **TeX**, which uses the [Tex Live](https://www.tug.org/texlive/) distribution.

