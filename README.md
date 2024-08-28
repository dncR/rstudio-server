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

Build from a **bake.hcl** configuration file should start with **exporting build variables** from **.env** file. To export environment variables, run `load_env` script available under **bake/** folder.

### Step 6.1: Enable the "load_env()" function in linux shell.

Add the function [load_env()](https://github.com/dncR/rstudio-server/blob/main/bake/load_env.sh) to your **.bashrc**, **.zshrc**, or another shell configuration file:

```sh
nano ~/.bashrc
```

Reload your shell configuration to make the function available in the current session:

```sh
source ~/.bashrc
```

Load environment variables from file:

```sh
# load_env /path/to/file/.env
load_env ./bake/.env
````

### Step 6.2: Build Docker image via `docker buildx`.

Build docker images using default environment variables, which are set through **bake/.env** file.

```sh
# Load into local image library. 
# (Use --push to push created image directly to the Docker Hub repository. Login required.)

# docker buildx bake --file <path_to_bake_file> --builder multiarch --load
docker buildx bake --file r-base.hcl --builder multiarch --load
```

Change environment variable and build images.

```sh
# Change R version to 3.6.3
R_VERSION=3.6.3 docker buildx bake --file r-base.hcl --builder multiarch --load
```

