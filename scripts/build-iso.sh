#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    printf 'Usage: %s BASE.iso BASE.iso.sha256 BASE.iso.sig GPG-KEYRING OUTPUT.iso\n' "$0"
}

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

if [[ $# -ne 5 || ${1:-} == -h || ${1:-} == --help ]]; then
    usage >&2
    exit 2
fi
if [[ $EUID -ne 0 ]]; then
    fail 'run this builder as root in a disposable Linux environment'
fi

repo_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
base_iso=$(realpath -- "$1")
checksum_file=$(realpath -- "$2")
signature=$(realpath -- "$3")
keyring=$(realpath -- "$4")
output_iso=$(realpath -m -- "$5")
output_dir=$(dirname -- "$output_iso")
output_name=$(basename -- "$output_iso")
work_parent=${TMPDIR:-/tmp}
minimum_gib=${MIN_FREE_GIB:-10}
processors=${SQUASHFS_PROCESSORS:-2}

[[ -d $work_parent && -w $work_parent ]] || fail "temporary directory is not writable: $work_parent"
[[ ! -e $output_iso ]] || fail "refusing to overwrite existing output: $output_iso"
[[ $output_iso != "$base_iso" ]] || fail 'output ISO must differ from the source ISO'
[[ $processors =~ ^[1-9][0-9]*$ ]] || fail 'SQUASHFS_PROCESSORS must be a positive integer'

for utility in xorriso unsquashfs mksquashfs sha256sum md5sum gpgv chroot mount umount mountpoint setfacl rsvg-convert; do
    command -v "$utility" >/dev/null 2>&1 || fail "required command is missing: $utility"
done

MIN_FREE_GIB=$minimum_gib "$repo_root/scripts/check-prerequisites.sh" "$work_parent"
"$repo_root/scripts/verify-iso.sh" "$base_iso" "$checksum_file" "$signature" "$keyring"

mkdir -p -- "$output_dir"
work_dir=$(mktemp -d "$work_parent/zaod-build.XXXXXX")
chmod 0700 "$work_dir"
setfacl -k -- "$work_dir"
rootfs="$work_dir/rootfs"

cleanup() {
    local result=$?
    trap - EXIT
    set +e
    for mount_path in "$rootfs/sys" "$rootfs/proc" "$rootfs/dev"; do
        if mountpoint -q "$mount_path"; then
            umount -R "$mount_path"
        fi
    done
    rm -rf -- "$work_dir"
    exit "$result"
}
trap cleanup EXIT

source_boot=$(xorriso -indev "$base_iso" -report_el_torito plain 2>&1)
source_system=$(xorriso -indev "$base_iso" -report_system_area plain 2>&1)
for boot_mode in BIOS UEFI; do
    grep -q "El Torito boot img.*$boot_mode" <<<"$source_boot" \
        || fail "source ISO does not report a $boot_mode El Torito image"
done
grep -q 'MBR isohybrid' <<<"$source_system" || fail 'source ISO lacks its isohybrid MBR'
grep -q 'GPT' <<<"$source_system" || fail 'source ISO lacks its GPT layout'

xorriso -osirrox on -indev "$base_iso" \
    -extract /antiX/linuxfs "$work_dir/linuxfs" \
    -extract /antiX/linuxfs.info "$work_dir/linuxfs.info" \
    -extract /antiX/linuxfs.md5 "$work_dir/linuxfs.md5"
(
    cd "$work_dir"
    md5sum --check linuxfs.md5
)

squashfs_info=$(unsquashfs -s "$work_dir/linuxfs" 2>&1)
compression=$(awk '$1 == "Compression" { print $2; exit }' <<<"$squashfs_info")
block_size=$(awk '$1 == "Block" && $2 == "size" { print $3; exit }' <<<"$squashfs_info")
[[ $compression =~ ^[[:alnum:]_-]+$ ]] || fail 'could not read the source SquashFS compressor'
[[ $block_size =~ ^[0-9]+$ ]] || fail 'could not read the source SquashFS block size'

unsquashfs -no-progress -processors "$processors" -d "$rootfs" "$work_dir/linuxfs"

mapfile -t packages < <(sed -E '/^[[:space:]]*(#|$)/d' "$repo_root/config/packages/desktop.txt")
(( ${#packages[@]} > 0 )) || fail 'desktop package manifest is empty'
for package in "${packages[@]}"; do
    [[ $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || fail "invalid package name in manifest: $package"
done

resolv_backup="$work_dir/resolv.conf.original"
policy_path="$rootfs/usr/sbin/policy-rc.d"
policy_backup="$work_dir/policy-rc.d.original"
had_resolv=0
had_policy=0
if [[ -e $rootfs/etc/resolv.conf || -L $rootfs/etc/resolv.conf ]]; then
    cp -a -- "$rootfs/etc/resolv.conf" "$resolv_backup"
    had_resolv=1
fi
if [[ -e $policy_path || -L $policy_path ]]; then
    cp -a -- "$policy_path" "$policy_backup"
    had_policy=1
fi

printf '#!/bin/sh\nexit 101\n' > "$work_dir/policy-rc.d"
install -o root -g root -m 0755 "$work_dir/policy-rc.d" "$policy_path"
rm -f -- "$rootfs/etc/resolv.conf"
install -o root -g root -m 0644 /etc/resolv.conf "$rootfs/etc/resolv.conf"

mount --rbind /dev "$rootfs/dev"
mount --make-rslave "$rootfs/dev"
mount --rbind /proc "$rootfs/proc"
mount --make-rslave "$rootfs/proc"
mount --rbind /sys "$rootfs/sys"
mount --make-rslave "$rootfs/sys"

chroot "$rootfs" env DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Use-Pty=0 update
chroot "$rootfs" env DEBIAN_FRONTEND=noninteractive apt-get \
    -o Dpkg::Use-Pty=0 install --yes --no-install-recommends "${packages[@]}"
chroot "$rootfs" apt-get clean

if (( had_policy )); then
    rm -f -- "$policy_path"
    cp -a -- "$policy_backup" "$policy_path"
else
    rm -f -- "$policy_path"
fi
rm -f -- "$rootfs/etc/resolv.conf"
if (( had_resolv )); then
    cp -a -- "$resolv_backup" "$rootfs/etc/resolv.conf"
fi

for package in "${packages[@]}"; do
    status=$(chroot "$rootfs" dpkg-query -W -f='${db:Status-Status}' "$package")
    [[ $status == installed ]] || fail "package did not install: $package"
done

rsvg-convert --output="$work_dir/zaod-wallpaper.png" "$repo_root/branding/zaod-wallpaper.svg"
install -D -o root -g root -m 0644 "$work_dir/zaod-wallpaper.png" \
    "$rootfs/usr/share/backgrounds/zaod-os/zaod-wallpaper.png"
install -D -o root -g root -m 0755 "$repo_root/config/desktop/xinitrc" \
    "$rootfs/etc/skel/.xinitrc"
install -D -o root -g root -m 0644 "$repo_root/config/desktop/icewm/menu" \
    "$rootfs/etc/skel/.icewm/menu"
install -D -o root -g root -m 0644 "$repo_root/config/desktop/icewm/preferences" \
    "$rootfs/etc/skel/.icewm/preferences"

for mount_path in "$rootfs/sys" "$rootfs/proc" "$rootfs/dev"; do
    umount -R "$mount_path"
    mountpoint -q "$mount_path" && fail "chroot bind mount remains active: $mount_path"
done

uncompressed_kb=$(du -skx -- "$rootfs" | awk '{ print $1 }')
printf 'UncompressedSizeKB=%s.00\n' "$uncompressed_kb" > "$work_dir/linuxfs.info"
mksquashfs "$rootfs" "$work_dir/linuxfs.new" -noappend \
    -comp "$compression" -b "$block_size" -processors "$processors" -xattrs -exports
mv -- "$work_dir/linuxfs.new" "$work_dir/linuxfs"
(
    cd "$work_dir"
    md5sum linuxfs > linuxfs.md5
    md5sum --check linuxfs.md5
)

xorriso -indev "$base_iso" -outdev "$output_iso" -boot_image any replay \
    -map "$work_dir/linuxfs" /antiX/linuxfs \
    -map "$work_dir/linuxfs.info" /antiX/linuxfs.info \
    -map "$work_dir/linuxfs.md5" /antiX/linuxfs.md5

output_boot=$(xorriso -indev "$output_iso" -report_el_torito plain 2>&1)
output_system=$(xorriso -indev "$output_iso" -report_system_area plain 2>&1)
for boot_mode in BIOS UEFI; do
    grep -q "El Torito boot img.*$boot_mode" <<<"$output_boot" \
        || fail "output ISO lost its $boot_mode El Torito image"
done
grep -q 'MBR isohybrid' <<<"$output_system" || fail 'output ISO lost its isohybrid MBR'
grep -q 'GPT' <<<"$output_system" || fail 'output ISO lost its GPT layout'

base_volume=$(sed -n "s/^Volume id[[:space:]]*: '\(.*\)'/\1/p" <<<"$source_boot")
output_volume=$(sed -n "s/^Volume id[[:space:]]*: '\(.*\)'/\1/p" <<<"$output_boot")
[[ -n $base_volume && $base_volume == "$output_volume" ]] \
    || fail 'output ISO volume ID differs from the verified antiX base'

for boot_member in \
    /boot/isolinux/isolinux.cfg \
    /boot/syslinux/syslinux.cfg \
    /boot/grub/grub.cfg \
    /boot/grub/config \
    /boot/grub/efi.img; do
    member_name=${boot_member//\//_}
    xorriso -osirrox on -indev "$base_iso" \
        -extract "$boot_member" "$work_dir/base$member_name"
    xorriso -osirrox on -indev "$output_iso" \
        -extract "$boot_member" "$work_dir/output$member_name"
    if [[ -d $work_dir/base$member_name ]]; then
        diff -qr -- "$work_dir/base$member_name" "$work_dir/output$member_name"
    else
        cmp -- "$work_dir/base$member_name" "$work_dir/output$member_name"
    fi
done

(
    cd "$output_dir"
    sha256sum -- "$output_name" > "$output_name.sha256"
)
setfacl -b -- "$output_iso" "$output_iso.sha256"
chmod 0644 -- "$output_iso" "$output_iso.sha256"
"$repo_root/scripts/verify-iso.sh" "$output_iso" "$output_iso.sha256"
printf 'Built ISO: %s\n' "$output_iso"
printf 'Checksum: %s\n' "$output_iso.sha256"