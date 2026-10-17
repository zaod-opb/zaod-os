#!/usr/bin/env bash
set -u

usage() {
    printf 'Usage: %s [existing-work-directory]\n' "$0"
    printf 'Checks a Linux host for basic ISO remastering prerequisites.\n'
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage
    exit 0
fi

if [[ $# -gt 1 ]]; then
    usage >&2
    exit 2
fi

work_dir=${1:-$PWD}
if [[ ! -d $work_dir ]]; then
    printf 'FAIL: work directory does not exist: %s\n' "$work_dir" >&2
    exit 2
fi

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() {
    printf 'FAIL: %s\n' "$1"
    failures=$((failures + 1))
}

if [[ $(uname -s) == Linux ]]; then
    pass 'Linux host'
else
    fail 'Linux host required'
fi

for utility in xorriso unsquashfs mksquashfs sha256sum gpg chroot mount umount losetup; do
    if command -v "$utility" >/dev/null 2>&1; then
        pass "command available: $utility"
    else
        fail "missing command: $utility"
    fi
done

if [[ $EUID -eq 0 ]]; then
    pass 'effective UID is root'
else
    fail 'root privileges required for filesystem/chroot operations'
fi

cap_eff=$(awk '/^CapEff:/ { print $2 }' /proc/self/status 2>/dev/null || true)
if [[ $EUID -eq 0 && -c /dev/loop-control && $cap_eff =~ ^[[:xdigit:]]+$ ]] \
    && (( (16#$cap_eff & 0x200000) != 0 )); then
    pass 'loop-control device and CAP_SYS_ADMIN available'
else
    fail 'usable loop/mount access unavailable (requires root and CAP_SYS_ADMIN)'
fi

available_bytes=$(df -P -B1 -- "$work_dir" 2>/dev/null | awk 'NR == 2 { print $4 }')
minimum_gib=${MIN_FREE_GIB:-15}
if [[ ! $minimum_gib =~ ^[0-9]+$ ]]; then
    printf 'FAIL: MIN_FREE_GIB must be a non-negative integer\n' >&2
    exit 2
fi
minimum_bytes=$((minimum_gib * 1024 * 1024 * 1024))
if [[ $available_bytes =~ ^[0-9]+$ ]] && (( available_bytes >= minimum_bytes )); then
    available_gib=$((available_bytes / 1024 / 1024 / 1024))
    pass "free space: ${available_gib} GiB (minimum ${minimum_gib} GiB)"
else
    fail "at least ${minimum_gib} GiB free space required at $work_dir"
fi

if (( failures > 0 )); then
    printf 'Prerequisite check failed: %d issue(s). No host changes were made.\n' "$failures" >&2
    exit 1
fi

printf 'Prerequisite check passed. This does not validate an ISO build procedure.\n'