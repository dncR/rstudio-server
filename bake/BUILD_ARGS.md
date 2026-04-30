# Build Arguments Reference

This manual documents the environment variables consumed by
`bake/image-builds.hcl`. Pass values inline before `docker buildx bake`, or
export them from a local environment file.

Example:

```sh
R_VERSION=4.6.0 UBUNTU_VERSION=noble R_BASE_MODE=dev TEX_VARIANT=base \
docker buildx bake --file bake/image-builds.hcl --builder multiarch --push r-base
```

## Core Image Arguments

| Argument | Default | Targets | Accepted values | Description |
| --- | --- | --- | --- | --- |
| `DOCKER_HUB_REPO` | `ubuntu` | `r-base` | Docker Hub image repository name | Base OS repository used by `r-base.Dockerfile`. The default resolves to `ubuntu:${UBUNTU_VERSION}`. |
| `UBUNTU_VERSION` | `noble` | `r-base`, `rstudio` | Ubuntu codenames supported by the Dockerfiles, for example `noble` | Ubuntu version used in image tags, base image selection, CRAN binary URL construction, and metadata. |
| `R_VERSION` | `latest` | `r-base`, `rstudio` | `latest`, `devel`, `patched`, or an R version such as `4.6.0` | R version used by the R build scripts and image tags. |
| `R_HOME` | `/usr/local/lib/R` | `r-base` | Absolute in-container path | Installation path for source-built R. |
| `TZ` | `Etc/UTC` | `r-base` | Time zone database names | Time zone configured during the R base image build. |
| `R_LANG` | `en_US.UTF-8` | `r-base`, `rstudio` | Locale names | Locale passed to Dockerfiles as `LANG`. |
| `CRAN` | `https://p3m.dev/cran/__linux__/${UBUNTU_VERSION}/latest` | `r-base` | CRAN-compatible repository URL | Default CRAN mirror written into R configuration. |
| `DEBIAN_FRONTEND` | `noninteractive` | `r-base` | Usually `noninteractive` | Debian frontend used during apt-based image builds. |
| `RSTUDIO_VERSION` | `2026.04.0+526` | `rstudio` | `stable`, `preview`, `daily`, `latest`, or a Posit/RStudio Server version | RStudio Server version installed by `scripts/install_rstudio.sh`. |
| `DEFAULT_USER` | `rstudio` | `rstudio` | Linux username | Linux user created by `scripts/default_user.sh` for RStudio login and home-directory setup. Keep Compose `DEFAULT_USER` aligned with this value for custom images. |

## Optional Module Arguments

These arguments control optional modules. Tags do not encode module state.
Inspect `/usr/local/share/rstudio-server-build/modules.json` inside the image to
see which modules were installed.

| Argument | Default | Targets | Accepted values | Description |
| --- | --- | --- | --- | --- |
| `R_BASE_MODE` | `base` | `r-base` | `base`, `dev` | Controls whether optional modules are allowed in `r-base`. `base` ignores optional module args for `r-base`; `dev` allows selected modules to install. |
| `INSTALL_R_DEV_DEPS` | `false` | `r-base`, `rstudio` | `true`, `false` | Installs R package development system dependencies and preinstalls `devtools` and `BiocManager`. Also forces Java installation during the same image build. |
| `INSTALL_R_CMD_CHECK_DEPS` | `false` | `r-base`, `rstudio` | `true`, `false` | Installs `qpdf` and `ghostscript-x` for `R CMD check`, `devtools::check()`, and `rcmdcheck` workflows. |
| `TEX_VARIANT` | `none` | `r-base`, `rstudio` | `none`, `base`, `extra`, `full` | Controls TeX Live installation. `none` skips TeX, `base` installs a smaller TeX set, `extra` adds broader LaTeX packages and utilities, and `full` installs Ubuntu's `texlive-full`. |
| `INSTALL_JAVA` | `false` | `r-base`, `rstudio` | `true`, `false` | Installs Java and runs `R CMD javareconf -e`. This is forced to `true` when `INSTALL_R_DEV_DEPS=true`. |
| `INSTALL_SSH` | `false` | `rstudio` | `true`, `false` | Installs and configures OpenSSH Server under s6 supervision. This is only applied to the `rstudio` image. |

## Target Behavior

### `r-base`

The default `r-base` image is minimal:

```sh
docker buildx bake --file bake/image-builds.hcl r-base --push
```

With `R_BASE_MODE=base`, optional module args are ignored for `r-base` even if
they are set:

```sh
R_BASE_MODE=base INSTALL_R_DEV_DEPS=true TEX_VARIANT=full \
docker buildx bake --file bake/image-builds.hcl r-base --push
```

Use `R_BASE_MODE=dev` to allow selected optional modules in `r-base`:

```sh
R_BASE_MODE=dev INSTALL_R_DEV_DEPS=true TEX_VARIANT=base \
docker buildx bake --file bake/image-builds.hcl r-base --push
```

### `rstudio`

The `rstudio` image inherits from the local `r-base` target through the bake
context wiring. It can install selected optional modules on top of the inherited
base image:

```sh
INSTALL_SSH=true TEX_VARIANT=base \
docker buildx bake --file bake/image-builds.hcl rstudio --push
```

If `r-base` already installed a module, the `rstudio` scripts read
`modules.json` and skip duplicate installation. For TeX, `full` satisfies later
`base` and `extra` requests, while `base` can be upgraded to `extra` or `full`.

## Metadata

Optional module state is recorded at:

```text
/usr/local/share/rstudio-server-build/modules.json
```

Example:

```json
{
  "schema_version": 1,
  "image": "rstudio",
  "r_version": "4.6.0",
  "ubuntu_version": "noble",
  "r_base_mode": "dev",
  "modules": {
    "r_dev_deps": true,
    "r_cmd_check_deps": true,
    "tex": "base",
    "java": true,
    "ssh": true
  }
}
```

Read metadata from an image:

```sh
docker run --rm dncr/rstudio-server:${R_VERSION}-${UBUNTU_VERSION} \
  cat /usr/local/share/rstudio-server-build/modules.json
```

## Tag Semantics

Image tags encode only `R_VERSION` and `UBUNTU_VERSION`:

```text
dncr/r-base:${R_VERSION}-${UBUNTU_VERSION}
dncr/rstudio-server:${R_VERSION}-${UBUNTU_VERSION}
```

They do not encode optional module choices. Rebuilding the same tag with
different build arguments can produce images with different optional components.
Use `modules.json` to verify the actual image contents.
