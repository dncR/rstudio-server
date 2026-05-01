# Creating Docker Container for Development Environment

This directory contains Docker Compose templates for running the published
the configured `${RSTUDIO_IMAGE_REPO}` image as a local RStudio Server
development environment.
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
${RSTUDIO_IMAGE_REPO}:${R_VERSION}-${UBUNTU_VERSION}
```

Important variables in `.env`:

- `R_VERSION`: R version tag component, for example `latest` or `4.6.0`.
- `UBUNTU_VERSION`: Ubuntu codename tag component, for example `noble`.
- `RSTUDIO_IMAGE_REPO`: Docker image repository for RStudio. The default is `dncr/rstudio-server`.
- `BIND_ADDRESS`: host interface to bind; keep `127.0.0.1` for local-only access.
- `PORT`: host port mapped to RStudio Server port `8787`.
- `SSH_PORT`: host port mapped to SSH port `22`.
- `DEFAULT_USER`: RStudio login user. The default published images use `rstudio`.
- `PASSWORD`: RStudio login password.
- `ROOT`: set to `true` only if the runtime user needs passwordless sudo.
- `DISABLE_AUTH`: set to `true` only for trusted, isolated environments.
- `WORKDIR`: host directory mounted at `/home/${DEFAULT_USER}/externalvolume`.
- `SSH_PUBLIC_KEY`: host public key mounted as `authorized_keys` for SSH access.

Boolean runtime values are case-insensitive for `true` and `false`; `1` and `0`
are also accepted. For example, `ROOT=TRUE`, `ROOT=True`, `ROOT=TRuE`, and
`ROOT=1` all enable passwordless sudo.

Use Docker Hub repository names in `owner/name` form for `RSTUDIO_IMAGE_REPO`,
without a leading `docker.io/` prefix.

Do not use `USER` or `HOME` for Compose interpolation in this file. Those names
are commonly exported by the host shell and can override `.env` values during
Compose interpolation. Use `DEFAULT_USER` for the RStudio login user.

If you use a custom image built with a non-default `DEFAULT_USER`, the value in
`.env`, the value used during build, and any exported shell `DEFAULT_USER` value
must match. If they do not match, Compose can mount files into the wrong home
directory or the container startup can fail. Shell environment variables override
values from `.env`, so unset conflicting shell variables before running Compose.

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

The Compose file always includes the SSH port and public-key mount. If the image
was not built with `INSTALL_SSH=true`, SSH connections to `SSH_PORT` will fail.
If `SSH_PUBLIC_KEY` does not point to an existing public key file, or if the path
or filename is wrong, `docker compose up` can fail before the container starts.
Verify both the image metadata and the key path before treating SSH as available.

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
README and run build commands from the project root directory. The bake files use
`context = "."`; running them from `composer/` will make Docker resolve
`dockerfiles/` and `scripts/` relative to `composer/` unless you update the
context paths.

For a local image with SSH support:

```sh
cd ..
R_VERSION=4.6.0 UBUNTU_VERSION=noble INSTALL_SSH=true \
docker buildx bake --file bake/image-builds.hcl --set '*.platform=linux/arm64' --load rstudio
```

Boolean build args such as `R_DEV_DEPS`, `INSTALL_JAVA`, and `INSTALL_SSH` accept
case-insensitive `true`/`false` and numeric `1`/`0`. `CACHE_REMOTE` follows the
same boolean rules and controls registry cache import/export only. It defaults
to `false`, so local `--load` builds do not write the configured registry cache
refs unless you explicitly set `CACHE_REMOTE=true`. The generated `modules.json`
still stores boolean metadata as lowercase JSON `true` or `false`, regardless of
the input style.

`--push` publishes the final image tag to a registry. `--load` loads a
single-platform final image into the local Docker image store. Registry cache is
separate from both and is controlled by `CACHE_REMOTE`.

Published tags encode the R and Ubuntu versions, not optional build modules.
Check the image metadata to see which optional modules, build user, RStudio
version, and requested TeX setting were included. `image_chain` identifies
whether the image is `r-base` only or `r-base + rstudio`; `effective.modules`
shows the final image state, and `components` keeps separate requested/installed
records for each layer:

```sh
docker run --rm ${RSTUDIO_IMAGE_REPO:-dncr/rstudio-server}:${R_VERSION}-${UBUNTU_VERSION} \
  cat /usr/local/share/rstudio-server-build/modules.json
```

## Post-Installation Notes

For image-level dependencies, prefer changing the Dockerfile or build scripts
and rebuilding the image. For one-off runtime changes, set `ROOT=true` in
`.env`, restart the container, and use `sudo` inside the RStudio session.

If TeX was installed during image build with `INSTALL_TEX=base`,
`INSTALL_TEX=extra`, or `INSTALL_TEX=full`, do not run post-install TeX setup
again. Check availability first:

```sh
pdflatex --version
```

The installation scripts are adapted from the
[Rocker Project](https://github.com/rocker-org/rocker-versioned2).
