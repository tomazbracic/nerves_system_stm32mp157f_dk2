#!/bin/sh

set -e

# Buildroot post-image scripts receive:
#   $1 = BINARIES_DIR (the images directory)
#   $2 = BR2_ROOTFS_POST_SCRIPT_ARGS (= NERVES_DEFCONFIG_DIR, our system directory)
#
# The nerves-common post-createfs.sh expects:
#   $1 = images directory (where to put the .fw output)
#   $2 = path to fwup.conf FILE (not the directory containing it)
#
# Our original script sourced (.) the nerves-common script and relied on
# positional parameter inheritance, but $2 was the defconfig DIRECTORY,
# not the fwup.conf FILE — causing "not found" because -f test fails on dirs.

FWUP_CONFIG="$2/fwup.conf"

# Execute (not source) the nerves-common script with correct arguments.
# BINARIES_DIR, BASE_DIR, BR2_EXTERNAL_NERVES_PATH are exported by Buildroot.
"$BR2_EXTERNAL_NERVES_PATH/board/nerves-common/post-createfs.sh" "$1" "$FWUP_CONFIG"
