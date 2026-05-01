# Compose Environment Variables

This file documents the variables defined in `.env_example`. Copy
`.env_example` to `.env`, then edit `.env` for your local machine.

```sh
cp .env_example .env
```

## Image Selection

`R_VERSION` selects the R version component of the image tag.

Example:

```env
R_VERSION=4.6.0
```

`UBUNTU_VERSION` selects the Ubuntu codename component of the image tag.

Example:

```env
UBUNTU_VERSION=noble
```

Together these variables pull:

```text
dncr/rstudio-server:${R_VERSION}-${UBUNTU_VERSION}
```

## Compose Names

`COMPOSE_PROJECT_NAME` controls the Docker Compose project name. This affects
network and resource names created by Compose.

`CONTAINER_NAME` controls the explicit container name for the RStudio service.
Change it when running multiple RStudio containers at the same time.

## Host Binding

`BIND_ADDRESS` controls the host network interface used for published ports.
Keep `127.0.0.1` for local-only access. Use `0.0.0.0` only when the service
must be reachable from other machines on the network.

`PORT` maps the host port to RStudio Server's container port `8787`.

`SSH_PORT` maps the host port to the container SSH port `22`. This only works
when the image was built with `SSH=true`.

## Runtime User

`DEFAULT_USER` is the RStudio login user. Published images use `rstudio` by
default. If you build a custom image with a different `DEFAULT_USER`, set the
same value in `.env` so Compose volume targets and runtime configuration match
the image.

Do not use `USER` or `HOME` for Compose interpolation. Host shells commonly
export those names, and shell variables take precedence over `.env` values.
The same precedence applies to `DEFAULT_USER`: an exported shell value overrides
the value in `.env`. Keep the build-time value, `.env` value, and shell
environment value aligned, or unset the shell value before running Compose.

`USERID` and `GROUPID` let the container runtime user match a host UID/GID when
needed for mounted volume ownership.

## Authentication

`PASSWORD` is the RStudio login password for `DEFAULT_USER`.

`ROOT=true` grants the runtime user passwordless sudo during container startup.
Keep it `false` unless the session needs administrative package installation.

`DISABLE_AUTH=true` disables RStudio authentication. Use this only in trusted,
local, isolated environments.

## Volumes

`WORKDIR` is the host directory mounted into the container at
`/home/${DEFAULT_USER}/externalvolume`. Relative paths are resolved by Docker
Compose relative to the compose file location.

`SSH_PUBLIC_KEY` must point to an existing public key file on the host. It is
mounted read-only as `/home/${DEFAULT_USER}/.ssh/authorized_keys`. SSH access also
requires an image built with `SSH=true`.

Because the Compose template always declares the SSH key mount, an invalid
`SSH_PUBLIC_KEY` path can interrupt `docker compose up`. Confirm that
`SSH=true` was used for the image and that the key path and filename are
correct before connecting over SSH.

## Restart Policy

`RESTART_POLICY` sets the service restart policy. The default
`unless-stopped` restarts the container after Docker restarts unless you stopped
it manually.

## Build-Time Options

The `.env_example` file controls Compose runtime behavior. It does not rebuild
the image. Optional image features are controlled at build time through
the bake files under `bake/`:

```text
R_BASE_MODE
R_DEV_DEPS
TEX
JAVA
SSH
```

`R_BASE_MODE=base` keeps `r-base` minimal and ignores optional module args for
that target. `R_BASE_MODE=dev` enables r-base development mode and forces
`R_DEV_DEPS=true` inside the `r-base` image, even if `R_DEV_DEPS=false` was
provided. Other module args such as `TEX` still depend on their own values. The
`rstudio` target can install selected modules on top of the inherited `r-base`
image and skips modules already recorded in metadata.

Use `bake/image-builds.hcl` for the chained workflow. Use `bake/r-base.hcl` and
`bake/rstudio.hcl` when you want to push `r-base` first and later build
`rstudio` from the published `dncr/r-base:${R_VERSION}-${UBUNTU_VERSION}` image.

`R_DEV_DEPS=true` also forces Java installation during the image build, even
when `JAVA=false`. Keep `JAVA` for images that need Java without the full R
development dependency set. For `r-base`, `R_BASE_MODE=dev` forces
`R_DEV_DEPS=true`; for `rstudio`, `R_DEV_DEPS` follows the value you provide.

`TEX` accepts `none`, `base`, `extra`, or `full`; the default is
`none`.

Image tags encode R and Ubuntu versions, not optional modules. Inspect
`/usr/local/share/rstudio-server-build/modules.json` inside an image to see the
actual optional module state, build user, RStudio version, and requested TeX
setting. Image-specific fields that do not apply are stored as JSON `null`;
`requested` records build requests and `modules` records what is actually
installed.

See the root `README.md` for build examples.
