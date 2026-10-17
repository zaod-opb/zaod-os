#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

bash -n scripts/check-prerequisites.sh scripts/verify-iso.sh scripts/collect-hardware-info.sh
bash -n tests/checks.sh
grep -q 'exec icewm-session' config/desktop/xinitrc
grep -q 'zaod-wallpaper.svg' config/desktop/icewm/preferences
grep -q '^TaskBarShowMEMStatus=0$' config/desktop/icewm/preferences
test -s branding/zaod-wallpaper.svg
grep -q 'xorg' config/packages/desktop.txt
grep -q 'spacefm' config/packages/desktop.txt
grep -q 'xterm' config/packages/desktop.txt

if scripts/verify-iso.sh >/dev/null 2>&1; then
    printf 'verify-iso.sh unexpectedly accepted missing arguments\n' >&2
    exit 1
else
    status=$?
    if [[ $status -ne 2 ]]; then
        printf 'verify-iso.sh returned %s for missing arguments (expected 2)\n' "$status" >&2
        exit 1
    fi
fi

test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
mkdir "$test_dir/mock-bin"
printf 'synthetic test payload\n' > "$test_dir/test.iso"
(
    cd "$test_dir"
    sha256sum test.iso > test.iso.sha256
)
printf '%s\n' '#!/usr/bin/env bash' 'printf "El Torito boot img: test BIOS\\n"' > "$test_dir/mock-bin/xorriso"
chmod +x "$test_dir/mock-bin/xorriso"
PATH="$test_dir/mock-bin:$PATH" scripts/verify-iso.sh "$test_dir/test.iso" "$test_dir/test.iso.sha256" >/dev/null
printf '%064d  test.iso\n' 0 > "$test_dir/bad.sha256"
if PATH="$test_dir/mock-bin:$PATH" scripts/verify-iso.sh "$test_dir/test.iso" "$test_dir/bad.sha256" >/dev/null 2>&1; then
    printf 'verify-iso.sh accepted an incorrect checksum\n' >&2
    exit 1
fi

inventory=$(scripts/collect-hardware-info.sh)
grep -q '^ZAOD OS hardware inventory$' <<<"$inventory"
grep -q '^## PCI devices and drivers$' <<<"$inventory"

printf 'All repository smoke checks passed.\n'