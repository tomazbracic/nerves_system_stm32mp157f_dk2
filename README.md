# nerves_system_stm32mp157f_dk2

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Custom Nerves system for the [STM32MP157F-DK2](https://www.st.com/en/evaluation-tools/stm32mp157f-dk2.html) Discovery Board.**

Created and maintained by [Tomaz Bracic](https://www.linkedin.com/in/tomazbracic/).

I built this because Nerves changed the way I think about embedded systems. The
combination of Elixir, OTP supervision trees, and immutable firmware is something
special — and I wanted to bring that to a board that nobody had packaged yet. The
STM32MP1 with its dual A7+M4 architecture deserves a Nerves system, and the
community deserves more hardware options. This is my way of giving something back.

This is an independent project built from scratch and shared with the community —
it is not officially maintained by or affiliated with the
[Nerves project](https://nerves-project.org/).

> **Disclaimer:** This software is provided as-is, without warranty of any kind.
> Use it at your own risk. The author assumes no responsibility or liability for
> any damage to hardware, data loss, or other issues arising from the use of this
> system. See [LICENSE](LICENSE) for the full terms.

---

## Hardware

The STM32MP157F-DK2 is a development board from STMicroelectronics featuring:

| | |
|---|---|
| **CPU** | Dual Cortex-A7 @ 800 MHz + Cortex-M4 @ 209 MHz (same die) |
| **RAM** | 512 MB DDR3L |
| **Storage** | microSD (no eMMC) |
| **Networking** | Gigabit Ethernet (RGMII), WiFi 802.11b/g/n, BLE 4.1 |
| **Display** | 4" touchscreen (480x800, MIPI DSI) |
| **USB** | 4x USB-A host, 1x micro-USB (ST-LINK) |
| **Debug** | On-board ST-LINK/V2.1 (serial console + JTAG) |
| **Crypto** | Hardware cryptographic acceleration (F variant) |
| **GPIO** | Raspberry Pi-compatible + Arduino Uno V3 headers |

## What Works

| Feature | Status | Notes |
|---------|--------|-------|
| Ethernet (DHCP) | Working | Gigabit, RGMII |
| WiFi | Kernel driver enabled | Needs VintageNetWiFi config |
| BLE | Kernel driver enabled | BRCMFMAC + HCI UART |
| SSH | Working | Key auth via nerves_ssh |
| mDNS | Working | `nerves-stm32mp1.local` |
| OTA updates | Working | A/B slot switching with fwup |
| Serial console | Working | `/dev/ttySTM0` via ST-LINK |
| Display (DSI) | Kernel driver enabled | Needs Scenic/Surface config |
| Touch (Goodix) | Kernel driver enabled | I2C on the DSI panel |
| M4 remoteproc | Kernel driver enabled | Load firmware via `/sys/class/remoteproc/` |
| RPMsg (A7-M4) | Kernel driver enabled | `/dev/rpmsg_ctrl0` |
| USB host | Working | 4 ports |
| App partition | Working | F2FS at `/root`, persists across OTA |

## Known Limitations

- **Boot-counting auto-revert:** U-Boot 2025.10 ignores the saved env's `bootcmd` (likely CRC/format mismatch with the UBootEnv Elixir library). Manual revert via `Nerves.Runtime.revert()` works. Tracked for investigation.
- **Toolchain:** Uses Bootlin GCC 14.3 instead of the standard Nerves toolchain. The Nerves GCC 13.2 toolchain produces U-Boot binaries that hang silently on STM32MP1.

## Prerequisites

Building from source requires these host packages (Ubuntu/Debian):

```bash
sudo apt-get install git build-essential bc libssl-dev libncurses5-dev \
  unzip wget cpio rsync file python3 cmake u-boot-tools device-tree-compiler \
  squashfs-tools dosfstools mtools gdisk \
  flex bison texinfo help2man gawk libtool-bin
```

You also need Elixir, Erlang/OTP, and the Nerves tools:

```bash
mix archive.install hex nerves_bootstrap
```

## Quickstart

### 1. Create a new Nerves project

```bash
mix nerves.new my_firmware --target stm32mp157f_dk2
cd my_firmware
```

Or add the system to an existing project's `mix.exs`:

```elixir
defp deps do
  [
    {:nerves_system_stm32mp157f_dk2,
     github: "tomazbracic/nerves_system_stm32mp157f_dk2", tag: "v1.0.0",
     runtime: false, targets: :stm32mp157f_dk2}
  ]
end
```

### 2. Set the target and fetch dependencies

```bash
export MIX_TARGET=stm32mp157f_dk2
mix deps.get
```

### 3. Build firmware

```bash
mix firmware
```

> **Note:** The first build compiles the entire system from source (Linux kernel,
> TF-A, U-Boot, Erlang/OTP). This takes approximately 45 minutes. Subsequent
> builds are incremental and much faster.

### 4. Flash to microSD

Insert a microSD card and find its device path (usually `/dev/sda` for USB readers
or `/dev/mmcblk0` for built-in readers):

```bash
# IMPORTANT: Unmount all partitions first
sudo umount /dev/sda*

# Flash the firmware
mix burn
```

### 5. Boot and connect

Insert the microSD into the DK2, connect Ethernet, and power on.

**Via SSH (recommended):**
```bash
ssh nerves-stm32mp1.local
```

**Via serial console:**
```bash
picocom -b 115200 /dev/ttyACM0
```

## Boot Chain

```
ROM -> TF-A (BL2) -> FIP (sp_min + U-Boot) -> Linux -> erlinit -> BEAM VM
```

- **ROM:** Reads boot pins, finds `fsbl` partition on microSD
- **TF-A v2.10:** Initializes DDR, PMIC, clocks. Loads FIP from microSD
- **U-Boot 2025.10:** Loads kernel + DTB from SquashFS rootfs, boots Linux
- **Linux 6.6.80:** Mounts SquashFS root, starts erlinit
- **erlinit:** Mounts app partition, starts BEAM with Shoehorn

## Partition Layout

| # | Name | Size | Filesystem | Purpose |
|---|------|------|------------|---------|
| 0 | fsbl1 | 256 KB | raw | TF-A (primary) |
| 1 | fsbl2 | 256 KB | raw | TF-A (backup) |
| 2 | fip | 4 MB | raw | FIP (sp_min + U-Boot + DTB) |
| 3 | rootfs-a | 256 MB | SquashFS | Firmware slot A |
| 4 | rootfs-b | 256 MB | SquashFS | Firmware slot B |
| 5 | app | 512+ MB | F2FS | Persistent application data |

## Device Tree

This system uses `stm32mp157c-dk2.dts` from the mainline Linux kernel. The F
variant (STM32MP157F) does not have its own DTS file in mainline — the C and F
variants are software-compatible. The F variant adds hardware crypto acceleration
and a higher temperature rating, but the peripheral set and pin assignments are
identical.

## Deep Dive

This system was built from scratch as a learning project. The full journey —
including 25+ build errors, device tree discoveries, and boot chain debugging —
is documented in a blog series:

1. [Why Build a Custom Nerves Gateway](https://github.com/tomazbracic/stm32-moj/blob/main/docs/blog/01-why-build-a-custom-nerves-gateway.md)
2. [The Boot Chain](https://github.com/tomazbracic/stm32-moj/blob/main/docs/blog/02-the-boot-chain.md)
3. [Device Trees Demystified](https://github.com/tomazbracic/stm32-moj/blob/main/docs/blog/03-device-trees-demystified.md)
4. [Building the Nerves System](https://github.com/tomazbracic/stm32-moj/blob/main/docs/blog/04-building-the-nerves-system.md)
5. [From Learning Project to Community System](https://github.com/tomazbracic/stm32-moj/blob/main/docs/blog/05-from-learning-project-to-community-system.md)

## Contributing

Contributions are welcome! If you have an STM32MP157F-DK2 (or the C variant —
they're compatible) and want to help:

- Report issues with your hardware revision and serial console output
- Test WiFi, BLE, display, or M4 remoteproc and share results
- Improve documentation

## License

Copyright 2026 Tomaz Bracic.

Licensed under the Apache License, Version 2.0 — see [LICENSE](LICENSE) for details.

This software is provided on an "AS IS" basis, without warranties or conditions
of any kind, either express or implied. See the License for the specific language
governing permissions and limitations.
