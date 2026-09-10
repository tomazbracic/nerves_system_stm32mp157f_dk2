#!/bin/sh

set -e

# Buildroot passes TARGET_DIR as $1, then BR2_ROOTFS_POST_SCRIPT_ARGS as $2+.
# NERVES_DEFCONFIG_DIR, HOST_DIR, and BINARIES_DIR are also available
# as environment variables.

# Copy U-Boot environment to the rootfs boot directory
if [ -f "$NERVES_DEFCONFIG_DIR/uboot/uEnv.txt" ]; then
    mkdir -p "$TARGET_DIR/boot"
    cp "$NERVES_DEFCONFIG_DIR/uboot/uEnv.txt" "$TARGET_DIR/boot/"
fi

# Create firmware directory for M4 coprocessor (used in Phase 2)
mkdir -p "$TARGET_DIR/lib/firmware"

# Copy the fwup includes to the images dir so fwup can find them
# at firmware build time (fwup.conf uses include() to reference these)
cp -rf "$NERVES_DEFCONFIG_DIR/fwup_include" "$BINARIES_DIR"

# Compile U-Boot environment text file into a binary image.
# mkenvimage creates a properly CRC'd env block that fwup can raw_write()
# to the env area. This avoids fwup's ${} variable interpolation which
# destroys U-Boot variable references like ${nerves_fw_active}.
# The -s flag must match CONFIG_ENV_SIZE (0x2000 = 8192 bytes).
# mkenvimage is provided by BR2_PACKAGE_HOST_UBOOT_TOOLS in the defconfig.
"$HOST_DIR/bin/mkenvimage" -s 0x2000 \
    -o "$BINARIES_DIR/uboot-env.bin" \
    "$NERVES_DEFCONFIG_DIR/uboot/uboot.env"

# Generate revert.fw for runtime firmware revert operations
# nerves_runtime uses this at /usr/share/fwup/revert.fw for
# Nerves.Runtime.revert() — manual rollback to previous firmware slot.
#
# Note: Firmware VALIDATION (Nerves.Runtime.validate_firmware) does NOT
# use this file. Modern nerves_runtime (0.13+) writes nerves_fw_validated=1
# directly to the U-Boot env via the UBootEnv library.
mkdir -p "$TARGET_DIR/usr/share/fwup"
NERVES_SDK_IMAGES="$BINARIES_DIR" "$HOST_DIR/usr/bin/fwup" \
    -c -f "$NERVES_DEFCONFIG_DIR/fwup-revert.conf" \
    -o "$TARGET_DIR/usr/share/fwup/revert.fw"
