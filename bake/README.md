# Build Arguments Reference

This manual documents the environment variables consumed by the bake workflows in
this directory. Pass values inline before `docker buildx bake`, or export them
from a local environment file.

Run bake commands from the project root directory. These HCL files use
`context = "."`, so Dockerfile paths such as `dockerfiles/r-base.Dockerfile` are
resolved relative to the directory where `docker buildx bake` is executed. If you
run bake from another directory, update the relevant `context` values or adjust
the relative paths before building.

Example:

```sh
R_VERSION=4.6.0 UBUNTU_VERSION=noble R_BASE_MODE=dev INSTALL_TEX=base \
docker buildx bake --file bake/image-builds.hcl --builder multiarch --push r-base
```

## Workflow Files

The repository provides three bake files:

| File | Purpose |
| --- | --- |
| `bake/image-builds.hcl` | Canonical chained workflow. The `rstudio` target uses the local `r-base` target through BuildKit context wiring. |
| `bake/r-base.hcl` | Standalone `r-base` build and push workflow. |
| `bake/rstudio.hcl` | Standalone `rstudio` build workflow that uses the already-published `dncr/r-base:${R_VERSION}-${UBUNTU_VERSION}` image. |

Use `image-builds.hcl` when you want one reproducible chained build. Use the
separate files when you want to build and push `r-base` first, then build
`rstudio` later without solving the local `r-base` target again.

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
| `R_BASE_MODE` | `base` | `r-base` | `base`, `dev` | Controls whether optional modules are allowed in `r-base`. `base` ignores optional module args for `r-base`; `dev` enables r-base development mode and forces `R_DEV_DEPS=true` for the `r-base` image. |
| `R_DEV_DEPS` | `false` | `r-base`, `rstudio` | `true`, `false` | Installs R package development system dependencies, `qpdf` and `ghostscript-x` for package checks, and preinstalls `devtools` and `BiocManager`. Also forces Java installation during the same image build. In `r-base`, `R_BASE_MODE=dev` forces this behavior even if `R_DEV_DEPS=false`. |
| `INSTALL_TEX` | `none` | `r-base`, `rstudio` | `none`, `base`, `extra`, `full` | Controls TeX Live installation. `none` skips TeX, `base` installs a smaller TeX set, `extra` adds broader LaTeX packages and utilities, and `full` installs Ubuntu's `texlive-full`. |
| `INSTALL_JAVA` | `false` | `r-base`, `rstudio` | `true`, `false` | Installs Java and runs `R CMD javareconf -e`. This is forced to `true` when `R_DEV_DEPS=true`. |
| `INSTALL_SSH` | `false` | `rstudio` | `true`, `false` | Installs and configures OpenSSH Server under s6 supervision. This is only applied to the `rstudio` image. |

Shell environment variables are read by `docker buildx bake` before defaults in
this file. If `DEFAULT_USER`, `INSTALL_TEX`, or another build argument is
exported in your shell, that value overrides the HCL default. Check the active
environment before debugging unexpected build output.

## Target Behavior

### `r-base`

The default `r-base` image is minimal:

```sh
docker buildx bake --file bake/image-builds.hcl r-base --push
```

With `R_BASE_MODE=base`, optional module args are ignored for `r-base` even if
they are set:

```sh
R_BASE_MODE=base R_DEV_DEPS=true INSTALL_TEX=full \
docker buildx bake --file bake/image-builds.hcl r-base --push
```

Use `R_BASE_MODE=dev` to enable r-base development mode. This always installs
`R_DEV_DEPS` in `r-base`, even when `R_DEV_DEPS=false`; other module args such as
`INSTALL_TEX` still depend on their own values:

```sh
R_BASE_MODE=dev INSTALL_TEX=base \
docker buildx bake --file bake/image-builds.hcl r-base --push
```

### `rstudio`

When using `bake/image-builds.hcl`, the `rstudio` image inherits from the local
`r-base` target through the bake context wiring. It can install selected
optional modules on top of the inherited base image:

```sh
INSTALL_SSH=true INSTALL_TEX=base \
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

Fields that are not defined for the image being built are stored as JSON `null`.
For example, `default_user` and `rstudio_version` are `null` in `r-base`
metadata, then the `rstudio` build rewrites them with the actual build values.
The `requested` section records build-time requests, while `modules` records the
modules actually installed in the image.

Example:

```json
{
  "schema_version": 4,
  "image": "rstudio",
  "r_version": "4.6.0",
  "ubuntu_version": "noble",
  "default_user": "rstudio",
  "rstudio_version": "2026.04.0+526",
  "r_base_mode": "dev",
  "requested": {
    "tex": "base"
  },
  "modules": {
    "r_dev_deps": true,
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
