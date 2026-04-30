# Creating Docker Container for Development Environment.

We propose a docker container to be used for package development. The built VMs are distributed through Docker Hub ([dncr/rstudio-server](https://hub.docker.com/repository/docker/dncr/rstudio-server/general)) and source codes are available through GitHub ([https://github.com/dncR/rstudio-server](https://github.com/dncR/rstudio-server)). The docker container is built upon **Linux Operating System** (by default, Ubuntu Noble) with pre-installed **R** and **RStudio Server**. All the arguments to be used while *pulling*, *building*, or *creating* docker image/container are given with an environment file **.env**. One may change the value of corresponding arguments to customize Docker Environment. See below for more details on **.env** file.

## Working with .env file

This file includes argument used to customize Docker images and/or containers. The container comes with **Ubuntu Noble** distribution by default, supporting for both platforms **ARM (e.g., Apple's silicon chips)** and **AMD (e.g., Intel-based chips)**. It is not required to set OS platform. Docker will pull appropriate platform from the repository.

* **UBUNTU_VERSION**: The codename of Ubuntu distro. Default is `noble`.
* **R_VERSION**: The version of base R installation. Default is `latest`.
* **RSTUDIO_VERSION**: The version of RStudio Server installation. Default is `2026.04.0+526`. This option does not have an effect while running pre-built containers. It is used while creating the Docker image from scratch.

For other arguments, see **.env** file.

## Running the Docker Container

This workflow uses pre-built images published on Docker Hub.
If you want to rebuild images locally (instead of pulling pre-built tags), see the root build guide in `../README.md` and the canonical bake workflow at `../bake/image-builds.hcl`.

One may run the Docker Container using the commands below:

1. Pull pre-built image (including R 4.4.1 installed) from Docker Hub.

```
R_VERSION=4.4.1 docker compose -f rstudio.yml pull
```

2. Run container from the pulled image.

```
R_VERSION=4.4.1 docker compose -f rstudio.yml up -d
```

One may change the **rstudio.yml** file to customize the docker container, e.g., binding volumes, adding services, changing the localhost ports, etc. See Docker Compose file documentation for more details on how to edit YAML file to customize Docker Containers.

## SSH Key Setup for Container Access

The `rstudio.yml` file mounts a host public key into the container as:

```yml
~/.ssh/id_ed25519.pub:/home/rstudio/.ssh/authorized_keys:ro
```

Before running compose, ensure the public key file exists on the host and matches the mounted path.

1. Check existing SSH public keys:

```sh
ls -la ~/.ssh/*.pub
```

2. If no suitable key exists, create one (example: Ed25519):

```sh
ssh-keygen -t ed25519 -C "your_email@example.com"
```

This creates a private key and a public key (default: `~/.ssh/id_ed25519` and `~/.ssh/id_ed25519.pub`).

3. Update `rstudio.yml` volume mapping to the correct public key path.

Examples:

```yml
# Default Ed25519 key
- ~/.ssh/id_ed25519.pub:/home/rstudio/.ssh/authorized_keys:ro

# Custom key location
- /absolute/path/to/your_key.pub:/home/rstudio/.ssh/authorized_keys:ro
```

4. Start the container after confirming the key path:

```sh
R_VERSION=4.4.1 docker compose -f rstudio.yml up -d
```

We benefitted from the installation scripts of [Rocker Project](https://hub.docker.com/u/rocker) and modified some scripts to create our custom docker image. Rocker Project is available as a GitHub repository [here](https://github.com/rocker-org/rocker-versioned2).

## Post Installation Steps

### 1. Linux Dependencies (Ubuntu Noble)

Below linux packages are required to be installed after Docker Container is created.

```sh
sudo apt-get update
sudo apt-get install -y \
  libmagick++-dev
```
	
### 2. TexLive Installation (Optional)

We included all the scripts used (or not used) while creating the docker image under in-container folder `/rocker_scripts`. Two scripts, called `texlive_base.sh` and `texlive-full.sh`, are available in this folder.

If TeX was already installed during image build (for example with `INSTALL_TEX=true`), do not run post-install TeX setup again.
First, run the container and check whether TeX is already available:

```sh
pdflatex --version
```

If this command works, skip this step to avoid duplicate installation and extra build time.
Only run `texlive_base.sh` or `texlive-full.sh` when TeX is not present in the running image.
