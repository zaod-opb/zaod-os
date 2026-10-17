# Build and boot guide

## Current status

There is no supported ZAOD ISO build command yet. The current development
container runs Ubuntu 24.04 as an unprivileged user. Passwordless `sudo` was
able to attach, mount, write, unmount, and detach a disposable loop-backed ext4
image. The required ISO/squashfs utilities are absent, and GitHub Actions
`ubuntu-24.04` capabilities have not yet been tested. The workspace has about
19 GB free, but that does not prove a complete image build will fit.

This is an explicit blocker, not a successful build. Do not rename the untouched
antiX ISO as ZAOD or treat the checked-in configuration as already installed in
an image.

## Selected source and integrity

The current base selection is `antiX-26.1_x64-core.iso`, linked from the
[official antiX download page](https://antixlinux.com/download/) and hosted in
the [official antiX SourceForge release directory](https://sourceforge.net/projects/antix-linux/files/Final/antiX-26.1/).
The release directory provides `.sha256` and `.sig` sidecars. The official
download page publishes SHA-256
`4f17a36c506a6771460545e18de6f5ea08f5664bca0e0bc285be52b41f5be762` for this
Core ISO. Retrieve the ISO and sidecars from the official release directory.
AntiX documents this signature procedure and key ID `A80582E000067FDD`:

```sh
gpg --no-default-keyring --keyring gnupg-ring:trustedkeys.gpg \
   --keyserver hkps://keys.openpgp.org --recv-keys A80582E000067FDD
gpgv --keyring trustedkeys.gpg antiX-26.1_x64-core.iso.sig antiX-26.1_x64-core.iso
```

The same procedure is published on the [antiX download page](https://antixlinux.com/download/).
Before use:

1. Check the ISO against the published SHA-256 sidecar with
   `bash scripts/verify-iso.sh antiX-26.1_x64-core.iso antiX-26.1_x64-core.iso.sha256`.
2. Authenticate the detached signature with the published key ID above. The
   verifier uses `gpgv` and an explicit keyring; it does not silently trust a
   default user keyring.
3. Keep a note of the verified filename, SHA-256, signature result, source URL,
   and verification date with any eventual build output.

The checksum catches transfer or storage corruption. It is not a substitute
for authenticating the signing key.

## Builder requirements

An eventual image builder must be a disposable Linux environment with root,
working loop/mount and chroot capabilities, the exact image tools required by
the chosen antiX-26.1-compatible workflow, and enough scratch space for the
download, expanded root filesystem, and rebuilt image. Start with at least
15 GiB free and measure actual use before adopting that as a requirement. Never
run the builder on the developer's FydeOS installation or write to a physical
disk/USB device as part of image construction.

`sudo -n env MIN_FREE_GIB=5 bash scripts/check-prerequisites.sh "$RUNNER_TEMP"`
checks basic Linux tooling, root/loop access, and free space. It is diagnostic
only: it does not install packages or configure the host. Passing it would not
prove that the ISO build procedure works.

GitHub-hosted Linux runners may be a free option when the repository and account
are eligible and quota is available. The manual
`.github/workflows/runner-probe.yml` workflow checks sudo, loop support, disk
space, filesystem tools, and ISO generation on that actual runner. Do not
assume Codespaces and Actions have identical capabilities.

## Image construction and boot test

AntiX's documented live remaster workflow uses a running LiveUSB/LiveHD
development system; `iso-snapshot` likewise creates a live CD from a running
system. The official `Build-iso` project builds antiX from its Debian package
and template inputs rather than remastering a downloaded Core ISO. None of these
is a documented unattended remaster path for a GitHub-hosted runner. Any ZAOD
ISO editing method must therefore be validated explicitly against a disposable
copy of the verified 26.1 ISO. Preserve the original boot catalog and boot
images, and check both BIOS/UEFI paths and live filesystem metadata before
publishing an artifact.

Boot tests must use a virtual machine with a disposable disk or physical USB
written only after explicit human confirmation. No script in this repository
writes an ISO to a disk or USB device.

## USB use (not yet tested)

Once a built ISO has passed signature/provenance, checksum, El Torito, and VM
boot checks, use antiX's current USB-writing documentation for the selected
release. Confirm the target device by model and capacity immediately before
writing. USB creation overwrites its target; no ZAOD helper performs this step.