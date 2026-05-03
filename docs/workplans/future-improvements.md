# Future Improvements

## Runtime `DEFAULT_USER` Validation

The RStudio image is built with a `DEFAULT_USER` value and the Compose runtime
also receives a `DEFAULT_USER` value from `.env` or the shell environment. These
values must match for custom images. If they do not, mounted paths, SSH key
targets, and startup user configuration can point to a user home that does not
exist in the image.

Current documentation warns about this mismatch. A future improvement is to add
an explicit early validation in `scripts/init_userconf.sh` that checks whether
`DEFAULT_USER` exists before password, UID/GID, sudo, and SSH-related setup. If
the user is missing, the script should exit with a clear message explaining that
the build-time `DEFAULT_USER`, `.env` value, and exported shell value must be
aligned.
