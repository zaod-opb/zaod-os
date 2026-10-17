# Architecture

## Base and ownership

ZAOD OS is intended to be a customized antiX live image, not a replacement for
antiX's kernel or live system. The initial target is the official 64-bit
antiX-26.1 Core ISO, based on Debian 13 (Trixie). IceWM is the antiX default
window manager. The kernel, init system, bootloader files, firmware, device
drivers, installer/recovery tools, and live boot behavior must remain from the
verified antiX base unless a specific, tested change is justified.

antiX Core is the minimal starting flavor. The overlay adds the X server,
`xinit`, IceWM, SpaceFM, and XTerm, plus small hardware diagnostic utilities.
The manifest was resolved against the base's Debian Trixie and antiX repositories
and installed in the built rootfs. Network and live-session services remain
those of antiX; ZAOD does not replace the runit init model or remove firmware.

## Source tree

- `branding/zaod-wallpaper.svg`: original ZAOD artwork, not a third-party asset.
- `config/packages/desktop.txt`: tested package additions for the antiX 26.1
  rootfs.
- `config/desktop/xinitrc`: starts the IceWM session from `startx`.
- `config/desktop/icewm/`: initial IceWM menu and preferences, aligned with the
  file layout used by antiX's `desktop-defaults-icewm` package.
- `scripts/build-iso.sh`: verifies and extracts the signed base, updates only its
  live SquashFS, and replays the base boot metadata into a new ISO.
- `scripts/`: prerequisite, ISO integrity, and hardware diagnostics.
- `tests/`: smoke checks for shell syntax and the checked-in configuration.
- `docs/`: reproducibility, architecture, validation, and known gaps.

`kernel/`, `drivers/`, `rootfs/`, and `apps/` are deliberately absent: ZAOD has
not authored a kernel, drivers, or a root filesystem, and adding empty
directories would imply components that do not exist.

## Intended runtime

The configured session uses `startx` and `icewm-session`; it does not install a
display manager or start X automatically. The `.xinitrc`, IceWM menu, preferences,
and PNG wallpaper are placed in `/etc/skel` or the shared background directory.
The ISO booted to the antiX login prompt, but an authenticated session and
`startx` have not yet been verified. The file manager and terminal are separate
menu entries.

## Licensing and provenance

Only files authored for ZAOD are covered by the repository MIT license. antiX,
Debian packages, Linux, firmware, and any upstream boot assets keep their own
licenses and notices. Before redistributing a customized image, retain required
notices, publish the exact base version and source references, and confirm each
included package's redistribution terms. No upstream binaries or wallpaper are
copied into this repository.

## Build boundary

AntiX documents `live-remaster` for a running live system and `iso-snapshot` for
creating an image from a running system; neither constructs a remaster from the
downloaded Core ISO. The separate antiX `Build-iso` project builds from its own
Debian/template inputs. ZAOD therefore uses a custom, locally validated
transformation: extract `/antiX/linuxfs`, retain its zstd compression, 256 KiB
blocks, xattrs and exportability, then update only that member plus its size and
MD5 metadata in the original ISO. xorriso's documented `-boot_image any replay`
replays El Torito and system-area provisions. The builder checks BIOS, UEFI,
isohybrid MBR/GPT, ISO volume ID, and byte-identical boot configuration/EFI files
before accepting the result. This method is not endorsed by antiX and needs
continued testing across future releases.