# Known limitations

## Phase 1 status and remaining gaps

- The GitHub Actions capability probe and artifact build workflow are registered
  but have not run. This workspace's integration returned HTTP 403 when
  dispatching the probe. The local image build and loop/mount operations did
  succeed.
- QEMU/KVM booted the corrected ISO through its boot menu to the antiX login
  console with 2 GiB guest RAM. The first image had D-Bus execute-bit damage
  from `/tmp`'s default ACL; the builder now clears that ACL before extraction,
  and the corrected image preserved `0755` D-Bus and runit executables.
- Authenticated login, `startx`, IceWM, file-manager/terminal launch, and network
  behavior remain unverified. QEMU HMP key injection dropped characters while
  interacting with the login prompt. The image is not claimed to have passed a
  desktop-start test.
- Boot-menu artwork remains antiX branded. Only ZAOD wallpaper and live-user
  IceWM defaults are integrated; BIOS/UEFI boot files and configs remain
  unchanged.
- The generated ISO is visible in the workspace's ignored `output/` directory.
  Its 880 MiB size exceeds GitHub's 100 MiB regular Git file limit, so the binary
  is not committed; use the Actions artifact workflow for repository-hosted
  download after a successful run.

## Environment and hardware

The present host is Ubuntu 24.04 x86_64 in a Codespaces container. Passwordless
`sudo` and loop mounts work. `/tmp` had 41.16 GB free before the build and the
customized SquashFS reports 2.62 GiB uncompressed; the output ISO is 880 MiB.
Target 2 GB RAM / 8 GB storage, live memory use, startup time, installed size,
and sustained performance have not been measured. A 2 GiB QEMU boot reached the
login console but does not establish hardware compatibility.

No target hardware has been tested. Firmware gaps, unsupported chipsets,
graphics acceleration, wireless behavior, suspend/resume, and power management
are unknown. Use the [hardware checklist](hardware-testing.md); do not claim
universal driver compatibility.

## Next phase requirements

Before calling Phase 1 complete, establish a current antiX-26.1-compatible
builder process, implement and test it in a root-capable Linux environment,
record provenance and output checksums, boot the image in a VM, and verify that
the desktop, file manager, terminal, networking, and recovery paths work. Then
measure live memory use, installed size, startup time, and storage needs on
representative low-end hardware. Phase 2 should begin only after those Phase 1
gates are met.