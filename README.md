# ZAOD OS

ZAOD OS is planned as a lightweight live Linux system based on the official
antiX Core release. It will reuse antiX's kernel, boot infrastructure, drivers,
firmware, and live-system components; it is not a new kernel or a web desktop.

## Phase 1 status

This repository currently contains initial IceWM configuration, original
wallpaper artwork, hardware diagnostics, and ISO provenance/integrity checks.
It does **not** yet contain a working ISO customization/build pipeline. The
available container is unprivileged and lacks loop-device access, and the
upstream antiX remaster utility examined here operates on a running live system
rather than constructing a distributable ISO. Passwordless sudo and a
temporary loop-backed filesystem mount have been verified in this workspace,
but the image tools and hosted-runner workflow remain untested. No ZAOD ISO has
been built or boot-tested. See [known limitations](docs/limitations.md).

## Base system

- Distribution: antiX Linux
- Selected base: antiX-26.1 Core, 64-bit (`antiX-26.1_x64-core.iso`), based on
  Debian 13 Trixie
- Official release page: <https://antixlinux.com/download/>
- Official release directory: <https://sourceforge.net/projects/antix-linux/files/Final/antiX-26.1/>

The release is pinned for this initial milestone. Update the version only after
checking the antiX release notes, ISO signatures, package repositories, and
boot layout.

## Repository map

- `branding/`: original ZAOD wallpaper artwork.
- `config/packages/`: proposed minimal desktop and diagnostic package set; it
  still needs resolution against the selected antiX repositories.
- `config/desktop/`: initial IceWM session and menu defaults.
- `docs/`: architecture, build status, hardware checklist, and limitations.
- `scripts/check-prerequisites.sh`: read-only assessment of a privileged ISO
  builder's tools, loop access, and free space.
- `scripts/verify-iso.sh`: checksum and El Torito boot-record validation for an
  ISO; optional GPG signature verification.
- `scripts/collect-hardware-info.sh`: local hardware inventory for test reports.
- `tests/checks.sh`: shell/configuration smoke checks.

There is intentionally no `build-iso.sh` yet: the supported, reproducible image
construction path for this exact antiX release has not been established. The
repository does not include copied antiX binaries or claim that the current
configuration has been integrated into the base image.

## Local checks

Run checks without installing packages or changing the host:

```sh
bash tests/checks.sh
```

Inspect available ISO-building prerequisites:

```sh
bash scripts/check-prerequisites.sh /path/to/existing/work-directory
```

The prerequisite check reports missing capabilities; it does not install
packages, mount filesystems, or alter boot settings. Read the [build guide](docs/build-guide.md)
before attempting to handle a base ISO.

## License

ZAOD-authored scripts and configuration are MIT-licensed. antiX and all included
upstream packages retain their respective licenses; see [architecture](docs/architecture.md)
for provenance and redistribution notes.