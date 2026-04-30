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

Build docker images by passing variables inline:

```sh
# Load into local image library. 
# (Use --push to push created image directly to the Docker Hub repository. Login required.)

# docker buildx bake --file bake/image-builds.hcl --builder multiarch --load <target>
R_VERSION=latest UBUNTU_VERSION=noble docker buildx bake --file bake/image-builds.hcl --builder multiarch --load r-base
```

Change environment variables and build images:

```sh
# Build a specific R version
R_VERSION=4.4.3 UBUNTU_VERSION=noble docker buildx bake --file bake/image-builds.hcl --builder multiarch --load r-base

# Build RStudio image with extra bake args
R_VERSION=4.4.3 UBUNTU_VERSION=noble RSTUDIO_VERSION=2026.04.0+526 PREINSTALL_R_PKG=true INSTALL_TEX=false docker buildx bake --file bake/image-builds.hcl --builder multiarch --load
```

Use `bake/image-builds.hcl` as the canonical build workflow. Its default group
builds `r-base` and `rstudio` together, and the RStudio target is wired to the
local `r-base` target, so the build does not depend on an already-published
`dncr/r-base:${R_VERSION}-${UBUNTU_VERSION}` image. For a base-only build, pass
the `r-base` target explicitly. For an RStudio build, run the default workflow
or pass the `rstudio` target.

For `bake/image-builds.hcl`, the extra args below control optional image customizations:

- `INSTALL_TEX=true`: installs the full TeX Live distribution from Ubuntu's `apt` repository using `scripts/texlive_full.sh`.
- `PREINSTALL_R_PKG=true`: installs pre-defined R packages from `scripts/preinstall_r_packages.sh` while building the image.
  By default, this script installs `devtools` and `BiocManager`.
  Developers can extend this script to preinstall additional R packages as needed.

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
