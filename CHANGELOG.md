# Changelog

## v1.4.0

- **Feature:** Add Scenic UI support. Include cairo, freetype, libpng, and pixman
  packages in the base system. scenic_driver_local v0.11+ uses cairo-fb for
  software rendering on the DK2's 4-inch 480x800 DSI display — no GPU or mesa
  needed. The kernel already has DRM/DSI/panel/touch/fbdev/evdev drivers enabled.
  Just add `{:scenic, "~> 0.11"}` and `{:scenic_driver_local, "~> 0.11"}` to your
  firmware app and build a UI.

## v1.3.0

- **Fix:** Enable `CONFIG_CGROUP_SCHED=y` in kernel config to suppress
  `cgroup: Unknown subsys name 'cpu'` warning at boot.
- **Fix:** Add `ELIXIR_ERL_OPTIONS=+fnu` to erlinit.config to enable UTF-8
  filename encoding and suppress the latin1 warning from Elixir.

## v1.2.0

- **Fix:** Write `bootcmd` to U-Boot environment during `mix burn` using a
  pre-compiled env binary (mkenvimage). Previously, the saved env had no
  `bootcmd` so U-Boot dropped to a shell prompt instead of auto-booting.
  Uses the same approach as nerves_system_bbb — the env binary preserves
  U-Boot `${variable}` references that fwup's libconfuse parser would
  otherwise evaluate as empty host environment variables.
- The BootcmdMigration workaround module is no longer needed in firmware apps.

## v1.1.0

Bug fix release.

- **Fix:** Disable `CONFIG_ENV_REDUNDANT` in U-Boot. The upstream
  `stm32mp15_trusted_defconfig` enables redundant environment which adds a
  flags byte to the env header (5 bytes instead of 4). fwup and the UBootEnv
  Elixir library expect the non-redundant 4-byte format. This mismatch caused
  `Nerves.Runtime.KV.get_all()` to return `%{}` and broke OTA firmware updates.
- **Docs:** Added OTA upload instructions, `@all_targets` setup guidance, and
  KV store troubleshooting to README.

## v1.0.0

Initial release.

- Linux 6.6.80
- TF-A v2.10, U-Boot 2025.10
- Erlang/OTP 28
- Bootlin GCC 14.3 toolchain (armv7-eabihf-glibc-stable)
- Full DK2 hardware support: Ethernet, WiFi, BLE, display, touch, USB
- M4 remoteproc/RPMsg kernel support enabled (no firmware included)
- A/B firmware updates with fwup
- F2FS writable app partition at /root
- Nerves SSH, mDNS, NervesMOTD, Toolshed out of the box
