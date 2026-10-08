#!/bin/bash
set -euo pipefail
cd "${HOME}/mini_taller_qemu_demo"
exec qemu-system-aarch64   -M raspi3b   -cpu cortex-a53   -m 1G   -smp 4   -kernel kernel8-bullseye-uncompressed.img   -dtb bcm2710-rpi-3-b-bullseye.dtb   -sd raspios_bullseye_qemu.img   -append "console=ttyAMA0,115200 root=PARTUUID=0ee3e8a8-02 rootfstype=ext4 fsck.repair=yes rootwait rw"   -netdev user,id=net0   -device usb-net,netdev=net0   -nographic
