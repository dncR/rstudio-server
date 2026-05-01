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
Run the image build commands from the project root directory. The bake files use
`context = "."`, so relative paths such as `dockerfiles/r-base.Dockerfile` and
`scripts/` are resolved from the current working directory. If you run bake from
another directory, update the relevant `context` values or adjust relative paths
before building.

### Step 6.1: Build Docker image via `docker buildx`.

For multi-platform builds, publish images with `--push`:

```sh
R_VERSION=latest UBUNTU_VERSION=noble CACHE_REMOTE=true docker buildx bake --file bake/image-builds.hcl --builder multiarch --push r-base
```

For local testing, use `--load` with a single platform override:

```sh
R_VERSION=4.4.3 UBUNTU_VERSION=noble docker buildx bake --file bake/image-builds.hcl --builder multiarch --set r-base.platform=linux/arm64 --load r-base
```

`--push`, `--load`, and registry cache are separate concerns. `--push` exports
the final image tag to the registry. `--load` exports a single-platform image to
the local Docker image store. `CACHE_REMOTE=true` enables registry cache
import/export through the `cache-*` tags; it does not push the final image by
itself. `CACHE_REMOTE=false` is the default and disables remote registry cache.

Build an RStudio image with optional development features:

```sh
R_VERSION=4.4.3 UBUNTU_VERSION=noble RSTUDIO_VERSION=2026.04.0+526 R_DEV_DEPS=true INSTALL_TEX=base INSTALL_SSH=true CACHE_REMOTE=true docker buildx bake --file bake/image-builds.hcl --builder multiarch --push rstudio
```

Build a CLI-first `r-base` development image with optional modules:

```sh
R_VERSION=4.4.3 UBUNTU_VERSION=noble R_BASE_MODE=dev INSTALL_TEX=base docker buildx bake --file bake/image-builds.hcl --builder multiarch --push r-base
```

Use `bake/image-builds.hcl` as the canonical build workflow. Its default group
builds `r-base` and `rstudio` together, and the RStudio target is wired to the
local `r-base` target, so the build does not depend on an already-published
`dncr/r-base:${R_VERSION}-${UBUNTU_VERSION}` image. For a base-only build, pass
the `r-base` target explicitly. For an RStudio build, run the default workflow
or pass the `rstudio` target.

If you want separate workflows, use `bake/r-base.hcl` to build and push `r-base`,
then use `bake/rstudio.hcl` to build `rstudio` from the already-published
`dncr/r-base:${R_VERSION}-${UBUNTU_VERSION}` image. The separated RStudio
workflow does not solve the local `r-base` target again:

```sh
R_VERSION=4.4.3 UBUNTU_VERSION=noble CACHE_REMOTE=true docker buildx bake --file bake/r-base.hcl --builder multiarch --push r-base
R_VERSION=4.4.3 UBUNTU_VERSION=noble INSTALL_SSH=true INSTALL_TEX=extra INSTALL_JAVA=true CACHE_REMOTE=true docker buildx bake --file bake/rstudio.hcl --builder multiarch --push rstudio
```

For `bake/image-builds.hcl`, the extra args below control optional image customizations:

- `DEFAULT_USER=rstudio`: sets the Linux user created for the `rstudio` image. The default is defined as an image environment variable during build.
- `R_BASE_MODE=base|dev`: controls whether optional modules are allowed in the `r-base` target. The default `base` ignores optional module args for `r-base`; `dev` enables r-base development mode and forces `R_DEV_DEPS=true` for the `r-base` image.
- `R_DEV_DEPS=true`: installs R package development system dependencies, `qpdf` and `ghostscript-x` for R package checks, and preinstalls `devtools` and `BiocManager` using `scripts/install_r_dev_deps.sh`. This also forces Java installation, even when `INSTALL_JAVA=false`. In `r-base`, `R_BASE_MODE=dev` forces this behavior even if `R_DEV_DEPS=false`.
- `INSTALL_TEX=none|base|extra|full`: controls TeX Live installation using `scripts/install_texlive_variant.sh`. The default is `none`; `base` installs a smaller TeX set, `extra` adds broader LaTeX packages and utilities, and `full` installs the full Ubuntu TeX Live distribution.
- `INSTALL_JAVA=true`: installs Java and runs `R CMD javareconf -e` using `scripts/install_java.sh`. This arg remains available for minimal images that need Java without the full R development dependency set.
- `INSTALL_SSH=true`: installs and configures OpenSSH Server under s6 supervision for the `rstudio` image using `scripts/install_ssh.sh`.
- `CACHE_REMOTE=true`: enables registry cache import/export. The default is `false`, which avoids reading or writing `cache-*` tags.

See `bake/README.md` for the complete build argument reference.

Boolean optional build args default to `false`, and `INSTALL_TEX` defaults to
`none`. Boolean values are case-insensitive for `true` and `false`, and `1`/`0`
are accepted as aliases. For example, `R_DEV_DEPS=TRUE`, `R_DEV_DEPS=True`,
`R_DEV_DEPS=TRuE`, and `R_DEV_DEPS=1` all enable the option. Metadata remains
canonical: `/usr/local/share/rstudio-server-build/modules.json` always renders
boolean values as lowercase JSON `true` or `false`, regardless of the input
style. With `R_BASE_MODE=base`,
the `r-base` image keeps only the base R environment even if optional module
args are set. The `rstudio` image can still install selected optional modules
on top of the inherited `r-base` image.

The RStudio Server image uses `DEFAULT_USER=rstudio` by default. If you build an
image with a different `DEFAULT_USER`, use the same value in Compose so runtime
paths, SSH keys, and login credentials target the correct user home.
Treat this as a hard requirement: if the build-time `DEFAULT_USER`, the Compose
`.env` value, and any exported shell `DEFAULT_USER` value do not match, Compose
startup or login can fail. Shell environment variables take precedence over
values loaded from `.env`, so check `env | grep DEFAULT_USER` when debugging a
user/path mismatch.

Image tags encode the R and Ubuntu versions, not the optional build modules.
Rebuilding the same tag with different build arguments can produce images with
different optional components. Inspect the metadata file inside the image to see
which optional modules were installed:

```sh
docker run --rm dncr/rstudio-server:${R_VERSION}-${UBUNTU_VERSION} \
  cat /usr/local/share/rstudio-server-build/modules.json
```

The same metadata path is available in `dncr/r-base` images. The
`image_chain` field is `r-base` for base-only images and `r-base + rstudio` when
the RStudio layer is added. `effective.modules` records the final image state,
while `components.r_base` and `components.rstudio` keep separate `requested` and
`modules` records for each layer. When RStudio skips a module because it was
already available from `r-base`, that decision is recorded under
`components.rstudio.skipped_from_base`.

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

docker buildx bake --file bake/image-builds.hcl --builder multiarch --set '*.platform=linux/arm64' --load r-base
```

This is optional and useful when you build frequently with the same variable set.
Use `--push` for multi-platform output. When using `--load`, add a
single-platform `--set` override and usually pass an explicit target.

## Experimental Shiny Server Files

Shiny Server support is kept outside the canonical `r-base` and `rstudio`
workflow. Related Dockerfile, bake, compose, and installer assets live under
their respective `experimental` directories:

- `dockerfiles/experimental/shiny-server.Dockerfile`
- `bake/experimental/shiny-server-AMD64.hcl`
- `bake/experimental/shiny-server-ARM64.hcl`
- `composer/experimental/shiny.yml`
- `scripts/experimental/docker.sh`
- `scripts/experimental/InstalleR-mlseq.R`
- `scripts/experimental/install_shiny_server.sh`

Treat these files as experimental until the Shiny Server package source and
platform support are verified for the target Ubuntu/R combination.
The canonical image build context excludes `scripts/experimental/` through
`.dockerignore`, so experimental image builds that depend on those scripts may
need a dedicated build context rule before use.

## Acknowledgement

The scripts in the `scripts` directory are copied from and adapted from the
[`rocker-org/rocker-versioned2`](https://github.com/rocker-org/rocker-versioned2)
project. They have been revised for this repository's needs while preserving
credit to the original project and maintainers. Thank you to the rocker-org
project for making these build scripts available.
