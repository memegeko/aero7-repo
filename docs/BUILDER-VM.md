# Builder VM

Status: `MANUAL ACTION REQUIRED`

## Discovery Result

Discovery was run from the development host on 2026-07-20.

| Item | Result |
| --- | --- |
| `virsh --version` | 12.5.0 |
| `virt-install --version` | 5.1.0 |
| `qemu-system-x86_64` | `/usr/bin/qemu-system-x86_64` |
| `qm` | not installed |
| `VBoxManage` | not installed |
| Logical CPUs | 16 |
| Memory | 31 GiB total, about 18 GiB available during discovery |
| Swap | 15 GiB total |
| Root filesystem free | about 12 GiB |
| Home filesystem free | about 11 GiB |
| Large mounted storage | `/mnt/geeked_ass_drive`, about 6.7 TiB free |
| UEFI firmware | OVMF files present under `/usr/share/edk2/x64` and `/usr/share/ovmf/x64` |
| `libvirtd.service` | active |
| `virtqemud.service` | inactive |
| `virtnetworkd.service` | inactive |

`virt-host-validate` reported QEMU hardware virtualization and `/dev/kvm`
access as passing. It warned that the unprivileged user lacks the cgroup
`devices` controller and secure guest support.

The unqualified `virsh` connection showed no VMs, networks, or pools. The
system connection showed `archlinux-2` running, but most management calls such
as `net-list`, `pool-list`, `net-dumpxml`, and `pool-dumpxml` failed with:

```text
authentication failed: access denied by policy
```

`sudo -n true` failed because a password is required. Because this automation
cannot provide interactive host sudo credentials, the builder VM has not been
created yet.

## Selected Builder Resources

When libvirt management is available, use:

| Resource | Selected |
| --- | --- |
| VM name | `aero7-builder` |
| SSH alias | `aero7-builder` |
| vCPU | 8 |
| RAM | 8 GiB |
| Disk | 100 GiB qcow2 on `/mnt/geeked_ass_drive` or another libvirt-accessible storage path |
| Swap | 8 GiB |
| Network | libvirt default NAT |
| Firmware | UEFI with OVMF |
| Agent | `qemu-guest-agent` |
| User | `aero7build` |

The RAM selection stays under roughly 60 percent of currently available host
memory. The disk selection requires the large mounted storage or another pool
with sufficient space; `/home` and `/` do not have enough free space.

## Required Provisioning

Install current Arch Linux x86_64 from an official Arch cloud image and verify
the official checksum before booting it.

Inside the builder:

```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel devtools git namcap pacman-contrib gnupg jq rsync curl wget openssh github-cli python python-packaging shellcheck ccache qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent.service
```

Create:

```text
/srv/aero7-builder/
/srv/aero7-builder/chroots/
/srv/aero7-builder/sources/
/srv/aero7-builder/packages/
/srv/aero7-builder/repository/
/srv/aero7-builder/staging/
/srv/aero7-builder/logs/
```

Ownership must be `aero7build:aero7build` and paths must not be world-writable.

## Build Parallelism

Initial value:

```bash
export AERO7_MAKEFLAGS_JOBS=8
```

If the first build hits memory pressure or OOM, reduce to 4 and retry once.

## Runner Security

The builder VM must be dedicated to this repository. Do not mount host
directories into it, expose libvirt control to it, or run personal workloads on
it.
