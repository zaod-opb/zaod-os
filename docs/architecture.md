# Architecture

## Base and ownership

ZAOD OS is intended to be a customized antiX live image, not a replacement for
antiX's kernel or live system. The initial target is the official 64-bit
antiX-26.1 Core ISO, based on Debian 13 (Trixie). IceWM is the antiX default
window manager. The kernel, init system, bootloader files, firmware, device
drivers, installer/recovery tools, and live boot behavior must remain from the
verified antiX base unless a specific, tested change is justified.

antiX Core is the minimal starting flavor. The desktop overlay is planned to
add X.Org, IceWM, SpaceFM, and XTerm, plus small hardware diagnostic utilities.
Network and live-session services should remain those supported by the selected
antiX image; ZAOD must not replace its init/service model or remove firmware to
save space.

## Source tree

- `branding/zaod-wallpaper.svg`: original ZAOD artwork, not a third-party asset.
- `config/packages/desktop.txt`: proposed package additions. Names and
  dependencies must be checked against the antiX-26.1 repositories before use.
- `config/desktop/xinitrc`: starts the IceWM session from `startx`.
- `config/desktop/icewm/`: initial IceWM menu and preferences, aligned with the
  file layout used by antiX's `desktop-defaults-icewm` package.
- `scripts/`: non-destructive host checks, ISO verification, and hardware
  collection. No script currently creates a customized ISO.
- `tests/`: smoke checks for shell syntax and the checked-in configuration.
- `docs/`: reproducibility, architecture, validation, and known gaps.

`kernel/`, `drivers/`, `rootfs/`, and `apps/` are deliberately absent: ZAOD has
not authored a kernel, drivers, or a root filesystem, and adding empty
directories would imply components that do not exist.

## Intended runtime

The configured session uses `startx` and `icewm-session`; it does not install a
display manager or start X automatically. A working live-image integration must
provide an explicit, tested way to start that session without overriding antiX
login, init, or live boot behavior. The file manager and terminal are separate
menu entries.

## Licensing and provenance

Only files authored for ZAOD are covered by the repository MIT license. antiX,
Debian packages, Linux, firmware, and any upstream boot assets keep their own
licenses and notices. Before redistributing a customized image, retain required
notices, publish the exact base version and source references, and confirm each
included package's redistribution terms. No upstream binaries or wallpaper are
copied into this repository.

## Build boundary

The upstream antiX `live-remaster` program documents saving changes into a
running live filesystem. That is not, by itself, a reproducible ISO constructor.
The older `remaster.sh` found in the upstream remaster repository describes
legacy ISO remastering and has not been validated for antiX-26.1. Until a
release-compatible construction method is established and tested, there is no
`build-iso.sh` and no claim that the overlay can be applied to the base image.