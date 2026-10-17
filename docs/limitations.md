# Known limitations

## Phase 1 blockers

- The repository has no reproducible image-construction workflow or
  `scripts/build-iso.sh`. antiX's current live-remaster utility does not produce
  an ISO, and the upstream legacy ISO remaster script has not been shown to work
  with antiX-26.1.
- No antiX base ISO was downloaded, signature-verified, customized, or built in
  this environment.
- No ISO integrity check, VM boot, live desktop startup, installation, or USB
  boot test has been performed.
- The proposed package names/dependencies and overlay paths have not been
  checked against an antiX-26.1 Core session. In particular, IceWM startup,
  wallpaper rendering, session launch, network UI, and live-user behavior need
  integration testing.
- Boot-menu branding is deferred until the exact antiX-26.1 boot layout and
  supported modification method are verified. Existing antiX boot files must
  not be replaced speculatively.
- The wallpaper and source configuration are not yet installed into any image.

## Environment and hardware

The present host is Ubuntu 24.04 in a non-root container. Passwordless `sudo`
successfully mounted a disposable loop-backed filesystem, but `xorriso` and
squashfs tools are absent. The workspace filesystem reports about 18 GiB
available. The GitHub-hosted runner probe has not run yet. The development
device's FydeOS storage constraints and the target's 2 GB RAM / 8 GB storage
have not been measured or validated by a built system.

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