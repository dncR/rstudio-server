# Creating Docker Container for Development Environment

This directory contains Docker Compose templates for running the published
`dncr/rstudio-server` images as a local RStudio Server development environment.
The image is built from Ubuntu, R, and RStudio Server and supports both
`linux/amd64` and `linux/arm64` through Docker's platform-aware image pull.

## Configuration Files

Local runtime configuration is intentionally separated from publishable examples:

- `.env_example`: version-controlled example environment file.
- `rstudio_example.yml`: version-controlled example Compose file.
- `.env`: local environment file, ignored by git.
- `rstudio.yml`: local Compose file, ignored by git.

See `ENVIRONMENT.md` for the full `.env_example` reference.

Create local files from the examples before running Compose:

```sh
cd composer
cp .env_example .env
cp rstudio_example.yml rstudio.yml
```

Then edit `.env` for your machine. At minimum, change:

- `PASSWORD`: password used to log in to RStudio Server.
- `SSH_PUBLIC_KEY`: absolute path to an existing host public key.
- `WORKDIR`: host directory mounted into the container workspace.

## Environment Variables

The Compose file pulls this image tag:

```text
dncr/rstudio-server:${R_VERSION}-${UBUNTU_VERSION}
```

Important variables in `.env`:

- `R_VERSION`: R version tag component, for example `latest` or `4.6.0`.
- `UBUNTU_VERSION`: Ubuntu codename tag component, for example `noble`.
- `BIND_ADDRESS`: host interface to bind; keep `127.0.0.1` for local-only access.
- `PORT`: host port mapped to RStudio Server port `8787`.
- `SSH_PORT`: host port mapped to SSH port `22`.
- `DEFAULT_USER`: RStudio login user. The default published images use `rstudio`.
- `PASSWORD`: RStudio login password.
- `ROOT`: set to `true` only if the runtime user needs passwordless sudo.
- `WORKDIR`: host directory mounted at `/home/${DEFAULT_USER}/externalvolume`.
- `SSH_PUBLIC_KEY`: host public key mounted as `authorized_keys` for SSH access.

Do not use `USER` or `HOME` for Compose interpolation in this file. Those names
are commonly exported by the host shell and can override `.env` values during
Compose interpolation. Use `DEFAULT_USER` for the RStudio login user.

## Running the Container

Pull the configured image:

```sh
docker compose --env-file .env -f rstudio.yml pull
```

Start the container:

```sh
docker compose --env-file .env -f rstudio.yml up -d
```

Open RStudio Server at:

```text
http://127.0.0.1:${PORT}
```

Log in with the username from `DEFAULT_USER` and the password from `PASSWORD`.

Stop the container:

```sh
docker compose --env-file .env -f rstudio.yml down
```

## SSH Access

SSH access requires an image built with `INSTALL_SSH=true`. The Compose template
can map the port and key for SSH, but a minimal RStudio image does not install
the OpenSSH server unless that build arg is enabled.

The example Compose file maps the host public key specified by
`SSH_PUBLIC_KEY` to:

```text
/home/${DEFAULT_USER}/.ssh/authorized_keys
```

Before starting the container, make sure the public key exists:

```sh
ls -la /absolute/path/to/id_ed25519.pub
```

If you need a new Ed25519 key:

```sh
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Then update `SSH_PUBLIC_KEY` in `.env`.

## Local Builds

This Compose workflow is for running pre-built images from Docker Hub. If you
want to rebuild images locally, use the canonical bake workflow in the root
README and `../bake/image-builds.hcl`.

For a local image with SSH support:

```sh
R_VERSION=4.6.0 UBUNTU_VERSION=noble INSTALL_SSH=true \
docker buildx bake --file ../bake/image-builds.hcl --set '*.platform=linux/arm64' --load rstudio
```

Published tags encode the R and Ubuntu versions, not optional build modules.
Check the image metadata to see which optional modules were included:

```sh
docker run --rm dncr/rstudio-server:${R_VERSION}-${UBUNTU_VERSION} \
  cat /usr/local/share/rstudio-server-build/modules.json
```

## Post-Installation Notes

For image-level dependencies, prefer changing the Dockerfile or build scripts
and rebuilding the image. For one-off runtime changes, set `ROOT=true` in
`.env`, restart the container, and use `sudo` inside the RStudio session.

If TeX was installed during image build with `TEX_VARIANT=base`,
`TEX_VARIANT=extra`, or `TEX_VARIANT=full`, do not run post-install TeX setup
again. Check availability first:

```sh
pdflatex --version
```

The installation scripts are adapted from the
[Rocker Project](https://github.com/rocker-org/rocker-versioned2).
