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
when the image was built with `INSTALL_SSH=true`.

## Runtime User

`DEFAULT_USER` is the Linux user configured by the container startup scripts and
used for RStudio login.

Do not use `USER` for this purpose. Host shells commonly export `USER`, and
shell variables take precedence over `.env` values during Compose interpolation.

`CONTAINER_HOME` is the home directory for `DEFAULT_USER` inside the container.
Do not use `HOME` for this purpose for the same interpolation reason.

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
`${CONTAINER_HOME}/externalvolume`. Relative paths are resolved by Docker
Compose relative to the compose file location.

`SSH_PUBLIC_KEY` must point to an existing public key file on the host. It is
mounted read-only as `${CONTAINER_HOME}/.ssh/authorized_keys`. SSH access also
requires an image built with `INSTALL_SSH=true`.

## Restart Policy

`RESTART_POLICY` sets the service restart policy. The default
`unless-stopped` restarts the container after Docker restarts unless you stopped
it manually.

## Build-Time Options

The `.env_example` file controls Compose runtime behavior. It does not rebuild
the image. Optional image features are controlled at build time through
`bake/image-builds.hcl`:

```text
INSTALL_R_DEV_DEPS
INSTALL_R_CMD_CHECK_DEPS
TEX_VARIANT
INSTALL_JAVA
INSTALL_SSH
```

`INSTALL_R_DEV_DEPS=true` also forces Java installation during the image build,
even when `INSTALL_JAVA=false`. Keep `INSTALL_JAVA` for images that need Java
without the full R development dependency set.

See the root `README.md` for build examples.
