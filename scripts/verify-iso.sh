#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s ISO SHA256-SIDECAR [GPG-SIGNATURE GPG-KEYRING]\n' "$0"
}

if [[ ( $# -ne 2 && $# -ne 4 ) || ${1:-} == -h || ${1:-} == --help ]]; then
    usage >&2
    exit 2
fi

iso=$1
checksum_file=$2
signature=${3:-}
keyring=${4:-}

if [[ ! -f $iso || ! -r $iso ]]; then
    printf 'ISO is not a readable regular file: %s\n' "$iso" >&2
    exit 1
fi
if [[ ! -f $checksum_file || ! -r $checksum_file ]]; then
    printf 'Checksum sidecar is not a readable regular file: %s\n' "$checksum_file" >&2
    exit 1
fi

iso_name=$(basename -- "$iso")
expected=$(awk -v name="$iso_name" '
    NF == 1 && $1 ~ /^[[:xdigit:]]{64}$/ { print $1; exit }
    NF >= 2 {
        filename = $2
        sub(/^\*/, "", filename)
        if (filename == name) { print $1; exit }
    }
' "$checksum_file")
if [[ ! $expected =~ ^[[:xdigit:]]{64}$ ]]; then
    printf 'No SHA-256 entry for %s in %s\n' "$iso_name" "$checksum_file" >&2
    exit 1
fi

actual=$(sha256sum -- "$iso" | awk '{ print $1 }')
if [[ ${actual,,} != ${expected,,} ]]; then
    printf 'SHA-256 mismatch for %s\nExpected: %s\nActual:   %s\n' "$iso" "$expected" "$actual" >&2
    exit 1
fi
printf 'PASS: SHA-256 matches published sidecar for %s\n' "$iso"

if [[ -n $signature ]]; then
    if [[ ! -f $signature || ! -r $signature ]]; then
        printf 'Signature is not a readable regular file: %s\n' "$signature" >&2
        exit 1
    fi
    if [[ ! -f $keyring || ! -r $keyring ]]; then
        printf 'GPG keyring is not a readable regular file: %s\n' "$keyring" >&2
        exit 1
    fi
    if ! command -v gpgv >/dev/null 2>&1; then
        printf 'gpgv is required to check the supplied signature\n' >&2
        exit 1
    fi
    gpgv --keyring "$keyring" "$signature" "$iso"
fi

if ! command -v xorriso >/dev/null 2>&1; then
    printf 'xorriso is required to inspect ISO boot records\n' >&2
    exit 1
fi
report=$(xorriso -indev "$iso" -report_el_torito plain 2>&1) || {
    printf 'xorriso could not read the ISO image\n%s\n' "$report" >&2
    exit 1
}
if ! grep -q 'El Torito boot img' <<<"$report"; then
    printf 'No El Torito boot image was reported for %s\n%s\n' "$iso" "$report" >&2
    exit 1
fi
printf 'PASS: El Torito boot image record found\n'