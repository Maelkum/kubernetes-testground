#!/bin/sh

qemu-system-aarch64 \
  -machine virt,accel=hvf -cpu host -smp 1 -m 2G -nographic \
  -drive if=pflash,format=raw,file=edk2-aarch64-code.fd,readonly=on \
  -drive if=pflash,format=raw,file=server-flash1.img \
  -drive file=server.qcow2,if=virtio \
  -cdrom server-cidata.iso \
  -netdev vmnet-shared,id=net0 -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:02 \
  -virtfs local,path=../shared,mount_tag=host0,security_model=mapped-xattr,id=host0
