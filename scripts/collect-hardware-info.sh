#!/usr/bin/env bash
set -u

section() {
    printf '\n## %s\n' "$1"
}

run_if_available() {
    local command_name=$1
    shift
    if command -v "$command_name" >/dev/null 2>&1; then
        "$command_name" "$@" 2>&1 || printf '(command exited with status %s)\n' "$?"
    else
        printf '(not installed: %s)\n' "$command_name"
    fi
}

printf 'ZAOD OS hardware inventory\n'
printf 'Review this report before sharing; it includes hardware models and IDs.\n'

section 'Kernel and architecture'
uname -srm

section 'Processor'
run_if_available lscpu

section 'Memory'
if [[ -r /proc/meminfo ]]; then
    awk '/^MemTotal:/ { printf "Installed memory: %.1f GiB\n", $2 / 1024 / 1024 }' /proc/meminfo
else
    printf '(memory information unavailable)\n'
fi

section 'PCI devices and drivers'
run_if_available lspci -nnk

section 'USB devices'
run_if_available lsusb

section 'Wireless radios'
run_if_available rfkill list
run_if_available iw dev

section 'Audio devices'
run_if_available aplay -l
run_if_available arecord -l

section 'Bluetooth controllers'
run_if_available bluetoothctl list

section 'Camera devices'
run_if_available v4l2-ctl --list-devices

section 'Storage device models (no serial numbers)'
run_if_available lsblk -dn -o NAME,TYPE,SIZE,TRAN,MODEL