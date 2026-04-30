# Enabling Docker to Run and Compile Multiplatforms on Linux

Before continuing below steps, you should enable **containerd** image store for Docker Engine. Furthermore, if you haven't already, you might need to enable Docker's experimental features to use the `buildx` command. 

Edit or create the **daemon.json** file:

```sh
sudo nano /etc/docker/daemon.json
```

**`daemon.json`** file:
```json
{
  "experimental": true,
  "features": {
    "containerd-snapshotter": true
  }
}
```

Finally, restart Docker service:

```sh
sudo systemctl restart docker
```

Next, to enable Docker to run and compile for multiple platforms on a Linux system without Docker Desktop, follow these steps:

## Step 1: Install QEMU

First, install QEMU on your system. The installation command may vary depending on your Linux distribution.

**For Debian-based systems (e.g., Ubuntu):**

```sh
sudo apt-get update
sudo apt-get install -y qemu binfmt-support qemu-user-static
```

**For Red Hat-based systems (e.g., CentOS):**

```sh
sudo yum install -y qemu binfmt-support qemu-user-static
```

## Step 2: Download QEMU Static Binaries

You need to download the statically compiled QEMU binaries. The easiest way to get these is from the **tonistiigi/binfmt** Docker image.

```sh
docker run --rm --privileged tonistiigi/binfmt --install all
```

## Step 3: Register QEMU Binaries with `binfmt_misc`

This step registers the QEMU binaries so that they can be used to run containers for different architectures.

```sh
sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

## Step 4: Verify QEMU Registration

You can check if the registration was successful by listing the contents of **`/proc/sys/fs/binfmt_misc`**.

```sh
ls -la /proc/sys/fs/binfmt_misc/
```

You should see entries for different architectures such as **qemu-aarch64**, **qemu-arm**, **qemu-ppc64le**, etc.

## Step 5: Set Up Docker Buildx

Docker Buildx is a Docker CLI plugin that extends the Docker command with the full support of the features provided by Moby BuildKit builder toolkit.

```sh
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap multiarch
```

## Step 6: Build and Push Docker Image(s)

Build from a **bake.hcl** configuration file starts with setting required environment variables.
The default workflow is to pass variables directly in the terminal when running `docker buildx bake`.

### Step 6.1: Build Docker image via `docker buildx`.

For multi-platform builds, publish images with `--push`:

```sh
R_VERSION=latest UBUNTU_VERSION=noble docker buildx bake --file bake/image-builds.hcl --builder multiarch --push r-base
```

For local testing, use `--load` with a single platform override:

```sh
R_VERSION=4.4.3 UBUNTU_VERSION=noble docker buildx bake --file bake/image-builds.hcl --builder multiarch --set r-base.platform=linux/arm64 --load r-base
```

Build an RStudio image with optional development features:

```sh
R_VERSION=4.4.3 UBUNTU_VERSION=noble RSTUDIO_VERSION=2026.04.0+526 INSTALL_R_DEV_DEPS=true INSTALL_R_CMD_CHECK_DEPS=true TEX_VARIANT=base INSTALL_SSH=true docker buildx bake --file bake/image-builds.hcl --builder multiarch --push rstudio
```

Use `bake/image-builds.hcl` as the canonical build workflow. Its default group
builds `r-base` and `rstudio` together, and the RStudio target is wired to the
local `r-base` target, so the build does not depend on an already-published
`dncr/r-base:${R_VERSION}-${UBUNTU_VERSION}` image. For a base-only build, pass
the `r-base` target explicitly. For an RStudio build, run the default workflow
or pass the `rstudio` target.

For `bake/image-builds.hcl`, the extra args below control optional RStudio image customizations:

- `INSTALL_R_DEV_DEPS=true`: installs R package development system dependencies and preinstalls `devtools` and `BiocManager` using `scripts/install_r_dev_deps.sh`. This also forces Java installation, even when `INSTALL_JAVA=false`.
- `INSTALL_R_CMD_CHECK_DEPS=true`: installs `qpdf` and `ghostscript-x` for `R CMD check` workflows using `scripts/install_r_cmd_check_deps.sh`.
- `TEX_VARIANT=none|base|full`: controls TeX Live installation using `scripts/install_texlive_variant.sh`. The default is `none`; `base` installs a smaller TeX set, and `full` installs the full Ubuntu TeX Live distribution.
- `INSTALL_JAVA=true`: installs Java and runs `R CMD javareconf -e` using `scripts/install_java.sh`. This arg remains available for minimal images that need Java without the full R development dependency set.
- `INSTALL_SSH=true`: installs and configures OpenSSH Server under s6 supervision using `scripts/install_ssh.sh`.

All optional RStudio build args default to `false`, so the default image keeps
only the dependencies needed for RStudio Server and the base R environment.

### Step 6.2 (Optional): Use a `.env` file instead of typing variables every time

If you prefer, keep build variables in a local `.env` file and export them before build.
For the default Noble build, create a repo-root `.env` with values such as:

```sh
R_VERSION=latest
UBUNTU_VERSION=noble
```

Then export those variables before running bake:

```sh
set -a
source .env
set +a

docker buildx bake --file bake/image-builds.hcl --builder multiarch --load
```

This is optional and useful when you build frequently with the same variable set.
Use `--push` for multi-platform output, or add a single-platform `--set`
override when using `--load`.

## Experimental Shiny Server Files

Shiny Server support is kept outside the canonical `r-base` and `rstudio`
workflow. Related Dockerfile, bake, compose, and installer assets live under
their respective `experimental` directories:

- `dockerfiles/experimental/shiny-server.Dockerfile`
- `bake/experimental/shiny-server-AMD64.hcl`
- `bake/experimental/shiny-server-ARM64.hcl`
- `composer/experimental/shiny.yml`
- `scripts/experimental/install_shiny_server.sh`

Treat these files as experimental until the Shiny Server package source and
platform support are verified for the target Ubuntu/R combination.

## Acknowledgement

The scripts in the `scripts` directory are copied from and adapted from the
[`rocker-org/rocker-versioned2`](https://github.com/rocker-org/rocker-versioned2)
project. They have been revised for this repository's needs while preserving
credit to the original project and maintainers. Thank you to the rocker-org
project for making these build scripts available.
