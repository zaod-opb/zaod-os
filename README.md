# ZAOD OS

ZAOD OS is planned as a lightweight live Linux system based on the official
antiX Core release. It will reuse antiX's kernel, boot infrastructure, drivers,
firmware, and live-system components; it is not a new kernel or a web desktop.

## Phase 1 status

This repository contains an executable ISO builder, initial IceWM configuration,
original wallpaper artwork, hardware diagnostics, and integrity checks. A local
build from the signed antiX base produced a checksum-verified ISO that boots in
QEMU/KVM to the antiX login console. IceWM login/startup, GitHub Actions, and
physical hardware remain unverified. See [known limitations](docs/limitations.md).

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
- `config/packages/`: minimal desktop and diagnostic additions resolved and
  installed from the base's Trixie repositories.
- `config/desktop/`: initial IceWM session and menu defaults.
- `docs/`: architecture, build status, hardware checklist, and limitations.
- `scripts/check-prerequisites.sh`: read-only assessment of a privileged ISO
  builder's tools, loop access, and free space.
- `scripts/build-iso.sh`: verifies, customizes, and validates a new ISO under a
  temporary build directory; it never writes a disk or USB device.
- `.github/workflows/build-iso.yml`: manual hosted build that verifies the
  official base and uploads only the ISO and checksum as a workflow artifact.
- `scripts/verify-iso.sh`: checksum and El Torito boot-record validation for an
  ISO; optional GPG signature verification.
- `scripts/collect-hardware-info.sh`: local hardware inventory for test reports.
- `tests/checks.sh`: shell/configuration smoke checks.

The custom ISO transformation preserves the verified antiX boot tree and uses
xorriso boot replay. It is not the upstream antiX `Build-iso` process or its
running-live-system remaster workflow. No antiX binaries are copied into the
repository.

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