# Hardware testing

No hardware compatibility claims are made yet. Run
`bash scripts/collect-hardware-info.sh` on the target live system and save the
output with the test notes. The report intentionally omits host name, network
addresses, and device serial numbers, but hardware models and PCI/USB IDs can
still be identifying; review it before sharing.

For each test, record the device model/ID, antiX/ZAOD image checksum, kernel
version, steps, result, and any missing firmware or errors. Use `Pass`, `Fail`,
or `Not tested`; do not infer support from a detected device alone.

| Area | Test | Result / notes |
| --- | --- | --- |
| Display and graphics | Check native resolution, brightness keys, acceleration, external display, and suspend/resume display recovery. | Not tested |
| Keyboard and touchpad | Check all keys, function keys, gestures, click, and tap behavior. | Not tested |
| Wi-Fi and Ethernet | Connect, renew address, transfer data, reconnect after sleep; note chipset and firmware. | Not tested |
| Bluetooth | Pair and reconnect a known device; test audio/input profiles if available. | Not tested |
| Speakers and microphone | Play audio and record a short local test; check mute/volume controls. | Not tested |
| Camera | Enumerate and test the camera with a local application; record privacy switch behavior. | Not tested |
| USB devices | Test storage, keyboard/mouse, and available USB peripherals; verify safe removal. | Not tested |
| Suspend and resume | Repeat suspend/resume on AC and battery; check Wi-Fi, audio, display, and input afterward. | Not tested |
| Shutdown | Shut down and power off cleanly; check for hangs or filesystem errors. | Not tested |

Never test suspend, shutdown, or boot changes on a machine containing
unbacked-up data. A successful VM boot does not establish real-hardware support.