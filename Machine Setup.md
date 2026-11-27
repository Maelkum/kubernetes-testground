# Machine Setup

In order to follow through on the Kelsey Hightower's "Kubernetes the Hard Way" tutorial, you need four Linux machines:
- Jumpbox
- Server
- and two Nodes

For this we created four Linux VMs on QEMU running Debian 12 (bookworm).

## Prerequisites

Install the following tools:
- QEMU
- edk2-aarch64
- xorriso

## Raw VM Setup

### Disk Setup

The image we're working with is Debian 12 ARM64.

```sh
# Download Debian 12 ARM64 generic ISO:
curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-arm64.qcow2
```

We now create disks for our VMs.
All disks are qcow2.

Usage is `qemu-img create -f <format> -b <backing_file> <filename> [SIZE]`.
Backing file is the Debian image we have, so our target image is copy-on-write on top of the backing file.

```sh
qemu-img create -f qcow2 -F qcow2 -b debian-12-generic-arm64.qcow2 jumpbox.qcow2 10G
qemu-img create -f qcow2 -F qcow2 -b debian-12-generic-arm64.qcow2 server.qcow2 20G
qemu-img create -f qcow2 -F qcow2 -b debian-12-generic-arm64.qcow2 node0.qcow2 20G
qemu-img create -f qcow2 -F qcow2 -b debian-12-generic-arm64.qcow2 node1.qcow2 20G
```

### UEFI Setup

Apple Silicon (ARM64) requires UEFI to boot.
QEMU provides UEFI firmware, but it needs two files:

1. Read only UEFI code
2. Read-Write "variable store" - like the VM's BIOS setting

In a Homebrew installed QEMU, the read-only code can be found at `$(brew --prefix qemu)/share/qemu/edk2-aarch64-code.fd`.

We now create four blank 64 MB variable stores - one for each of the VMs.

```sh
dd if=/dev/zero of=jumpbox-flash1.img bs=1M count=64
```

### QCOW2 - QEMU Copy-On-Write v2

QCOW2 is a virtual disk image format used primarily by QEMU.
Disk files grow as needed.

It's possible to have a read-only base image - in our case - the Debian image, and have layers on top of it, representing individual disks for each VM.

## Accounts and SSH setup - Cloud-nit

We are running a headless VM, so we will setup Cloud-Init to initialize accounts, SSH access and the network.
You can read more about cloud-init [here](https://cloud-init.io/) and the docs are [here](https://docs.cloud-init.io/en/latest/).
It's a way to set up a newly created machine automagically, so it can be ready for use on boot.

Cloud-init relies on two files - `user-data` and `meta-data`.

```bash
$ tree ./cidata/jumpbox
./cidata/jumpbox
├── meta-data
└── user-data

1 directory, 2 files

$ cat ./cidata/jumpbox/user-data
#cloud-config
users:
  - name: k8s
    sudo: 'ALL=(ALL) NOPASSWD:ALL'
    groups: users, admin, sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 <key-data> user@hostname.local

packages:
  - avahi-daemon
  - qemu-guest-agent

runcmd:
  - systemctl enable avahi-daemon
  - systemctl start avahi-daemon
  - mkdir -p /mnt/shared
  - mount -t 9p -o trans=virtio,version=9p2000.L host0 /mnt/shared

$ cat ./cidata/jumpbox/meta-data
instance-id: jumpbox
local-hostname: jumpbox
```

Cloud-init gets loaded on the machine by creating an ISO with the data, and on first boot the OS will pick up the action it needs to do and do it.
Be careful - if something goes wrong and you want to fix it - the second boot will not run the cloud-init actions (else on each boot we'd try to create users, services etc).

## Booting the VM

This command starts a VM.
Cloud-init ISO is provided via a CD ROM.
We provide relevant images:
- our copy-on-write disk image (e.g. `jumpbox.qcow2`)
- our UEFI image - `edk2-aarch64-code.fd`
- our variable store - `jumpbox-flash1.img`

We also specify the location to our shared directory.

```sh
$ qemu-system-aarch64 \
  -machine virt,accel=hvf -cpu host -smp 1 -m 512M -nographic \
  -drive if=pflash,format=raw,file=edk2-aarch64-code.fd,readonly=on \
  -drive if=pflash,format=raw,file=jumpbox-flash1.img \
  -drive file=jumpbox.qcow2,if=virtio \
  -cdrom jumpbox-cidata.iso \
  -netdev vmnet-shared,id=net0 -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:01 \
  -virtfs local,path=../shared,mount_tag=host0,security_model=mapped-xattr,id=host0
```

One thing to note - in case you copy the boot command - make sure to change the MAC address when booting different VMs.
Otherwise network will have issues because there are multiple devices on the network with the same MAC address.
