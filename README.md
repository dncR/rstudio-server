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

# docker buildx bake --file <path_to_bake_file> --builder multiarch --load
R_VERSION=latest UBUNTU_VERSION=jammy docker buildx bake --file r-base.hcl --builder multiarch --load
```

Change environment variables and build images:

```sh
# Build a specific R version
R_VERSION=4.4.3 UBUNTU_VERSION=jammy docker buildx bake --file r-base.hcl --builder multiarch --load

# Build RStudio image with extra bake args
R_VERSION=4.4.3 UBUNTU_VERSION=jammy RSTUDIO_VERSION=2024.12.1+563 PREINSTALL_R_PKG=true INSTALL_TEX=false docker buildx bake --file rstudio.hcl --builder multiarch --load
```

### Step 6.2 (Optional): Use a `.env` file instead of typing variables every time

If you prefer, keep build variables in a local `.env` file and export them before build:

```sh
set -a
source .env
set +a

docker buildx bake --file r-base.hcl --builder multiarch --load
```

This is optional and useful when you build frequently with the same variable set.
