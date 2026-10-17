# Build and boot guide

## Current status

The builder was run successfully in the existing Ubuntu 24.04 x86_64 Codespaces
environment. Before downloading, `/tmp` had 41.16 GB free; the ISO was
703,594,496 bytes and the expanded rootfs measured 2.0 GiB. A conservative
10 GiB minimum was used. Passwordless sudo successfully attached, mounted,
wrote, unmounted, and detached a disposable loop-backed ext4 file. No host disk
or USB was modified.

GitHub Actions has not run: this workspace's integration received HTTP 403 when
dispatching the probe workflow. The ISO was built locally in `/tmp` and was not
uploaded as a workflow artifact.

## Selected source and integrity

The current base selection is `antiX-26.1_x64-core.iso`, linked from the
[official antiX download page](https://antixlinux.com/download/) and hosted in
the [official antiX SourceForge release directory](https://sourceforge.net/projects/antix-linux/files/Final/antiX-26.1/).
The release directory provides `.sha256` and `.sig` sidecars. The official
download page and downloaded sidecar both publish SHA-256
`4f17a36c506a6771460545e18de6f5ea08f5664bca0e0bc285be52b41f5be762` for this
Core ISO. The downloaded ISO passed this checksum and its detached signature.
AntiX documents this signature procedure and key ID `A80582E000067FDD`:

```sh
gpg --no-default-keyring --keyring gnupg-ring:trustedkeys.gpg \
   --keyserver hkps://keys.openpgp.org --recv-keys A80582E000067FDD
gpgv --keyring trustedkeys.gpg antiX-26.1_x64-core.iso.sig antiX-26.1_x64-core.iso
```

The same procedure is published on the [antiX download page](https://antixlinux.com/download/).
Before use:

1. Check the ISO against the published SHA-256 and verify its signature with
   `scripts/verify-iso.sh BASE.iso BASE.iso.sha256 BASE.iso.sig trustedkeys.gpg`.
2. Authenticate the detached signature with the published key ID above. The
   verifier uses `gpgv` and an explicit keyring; it does not silently trust a
   default user keyring.
3. Keep a note of the verified filename, SHA-256, signature result, source URL,
   and verification date with any eventual build output.

The checksum catches transfer or storage corruption. It is not a substitute
for authenticating the signing key.

The imported signing key fingerprint was
`30AA418A0C723D937B50A986A80582E000067FDD`, matching the issuer fingerprint in
the official `.sig` packet. `gpgv` reported `Good signature` for the Core ISO.

## Builder requirements

The builder requires a disposable Linux environment with root, loop/mount and
chroot capabilities; `xorriso`, squashfs-tools, GPG, ACL tools, and librsvg; and
at least 10 GiB free scratch space. It was run here with xorriso 1.5.6 and
squashfs-tools 4.6.1. Never run it on the developer's FydeOS installation or
write to a physical disk/USB device as part of image construction.

`sudo -n env MIN_FREE_GIB=10 bash scripts/check-prerequisites.sh /tmp` checks
basic Linux tooling, root/loop access, and free space. It is diagnostic only:
it does not install packages or configure the host. Passing it does not prove
that a complete ISO build will work.

The manual `.github/workflows/runner-probe.yml` workflow checks sudo, loop
support, disk space, filesystem tools, SVG conversion, and ISO generation. The
manual `.github/workflows/build-iso.yml` workflow downloads and verifies the
official base, runs the builder, and uploads only the ISO and checksum as an
artifact. Neither workflow has run yet; do not assume Codespaces and Actions
have identical capabilities.

## Image construction and boot test

AntiX's documented live remaster workflow uses a running LiveUSB/LiveHD
development system; `iso-snapshot` likewise creates a live CD from a running
system. The official `Build-iso` project builds from antiX package/template
inputs, not a downloaded Core ISO. The custom method implemented here replaces
only `/antiX/linuxfs`, `/antiX/linuxfs.info`, and `/antiX/linuxfs.md5` in a copy
of the verified ISO. It retains the original kernel, firmware, bootloader
configs, BIOS and UEFI boot images, MBR/GPT system area, ISO volume ID, and
unaltered ISO tree. It retains SquashFS zstd compression, block size, xattrs,
and exportability; the resulting BIOS/UEFI and hybrid metadata were checked.

Build a new image (the output must not already exist):

```sh
sudo -n env TMPDIR=/tmp MIN_FREE_GIB=10 SQUASHFS_PROCESSORS=2 \
   bash scripts/build-iso.sh \
   /tmp/antiX-26.1_x64-core.iso \
   /tmp/antiX-26.1_x64-core.iso.sha256 \
   /tmp/antiX-26.1_x64-core.iso.sig \
   /tmp/trustedkeys.gpg \
   /tmp/output/zaod-os-26.1-x86_64.iso
```

The final tested output was 923,074,560 bytes (880 MiB), with SHA-256
`c78c012049a8fad906391c328561d3c381044a76022dd6a1d301083fa2c450b1`. Its
`/antiX/linuxfs` MD5 companion also passed. The artifact remains in temporary
storage; it is not committed or published through Actions.

QEMU 8.2.2 successfully used KVM with a 2 GiB guest and read-only CD, no virtual
disk, or USB. The corrected ISO booted through its menu to the antiX login
console, without the D-Bus permission failure seen in the first build. HMP key
injection dropped characters during login, so authenticated shell, IceWM, file
manager, terminal, and networking tests remain pending. No script in this
repository writes an ISO to a disk or USB device.

## USB use (not yet tested)

Once a built ISO has passed signature/provenance, checksum, El Torito, and VM
boot checks, use antiX's current USB-writing documentation for the selected
release. Confirm the target device by model and capacity immediately before
writing. USB creation overwrites its target; no ZAOD helper performs this step.