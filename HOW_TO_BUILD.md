# How to Build the Base System

## Understanding the Build Architecture

A Nerves system (base image) **cannot be built standalone**. You cannot run
`mix compile` inside this folder and get a working system. This is a fundamental
aspect of how Nerves works and it's confusing the first time you encounter it.

Here's why: Nerves systems are Buildroot configurations — they define what
kernel, bootloaders, packages, and rootfs to build. But Buildroot is triggered
by the `nerves_system_br` dependency, which is only activated when a **firmware
app** depends on this system with `nerves: [compile: true]`.

### The Three Pieces

```
nerves_system_stm32mp157f_dk2/     ← THE BASE SYSTEM (you edit files here)
  nerves_defconfig                   Config files that define the system
  linux-6.6.defconfig                Kernel, bootloaders, packages,
  fwup.conf                         partition layout, boot scripts,
  uboot/uboot.fragment              rootfs overlay, etc.
  rootfs_overlay/
  ...

phase1_test_firmware/              ← BUILD HARNESS (you build from here)
  mix.exs                           A minimal Nerves app that depends on
    {:nerves_system_stm32mp157f_dk2, the base system with compile: true.
     path: "../nerves_system_stm32mp157f_dk2", Its only job is to trigger the
     nerves: [compile: true]}        Buildroot build. Not a real app.

Your real firmware app/             ← YOUR PRODUCT (a separate project)
  mix.exs                           Your actual application code.
    {:nerves_system_stm32mp157f_dk2, Depends on the PUBLISHED system
     github: "tomazbracic/...",      from GitHub. Downloads pre-built
     tag: "v1.3.0"}                  artifacts. No compile: true.
```

### When You Need to Change the Base System

1. Edit the relevant file in `nerves_system_stm32mp157f_dk2/`
2. Build from `phase1_test_firmware/`:
   ```bash
   cd phase1_test_firmware
   export MIX_TARGET=stm32mp157f_dk2
   mix firmware
   ```
3. This triggers Buildroot inside the system's `.nerves/artifacts/` directory
4. The build takes 5-45 minutes depending on what changed:
   - Kernel config change → ~15 min (kernel recompile)
   - U-Boot fragment change → ~5 min (U-Boot recompile only)
   - nerves_defconfig change (new package) → ~45 min (full rebuild)
   - rootfs_overlay or fwup.conf change → ~2 min (just re-packages)

### When You Need to Force a Full Rebuild

If the build doesn't pick up your changes, or you changed the defconfig:

```bash
# Delete the system's build artifacts (forces full rebuild)
rm -rf ~/razvoj/elixir_projects/nerves/stm32-moj/nerves_system_stm32mp157f_dk2/.nerves/artifacts/nerves_system_stm32mp157f_dk2-portable-*

# Delete the firmware app's build
cd phase1_test_firmware
rm -rf _build

# Rebuild
export MIX_TARGET=stm32mp157f_dk2
mix firmware
```

### Publishing a New Release

After the build succeeds and you've tested the firmware on the board:

```bash
# 1. Go to the system directory
cd nerves_system_stm32mp157f_dk2

# 2. Fetch deps (needed for mix nerves.artifact)
mix deps.get

# 3. Package the artifact tarball
mix nerves.artifact

# 4. Delete old tarballs (so you don't upload the wrong one)
rm -f nerves_system_stm32mp157f_dk2-portable-<old-version>-*.tar.gz

# 5. Verify only one tarball exists
ls -lh nerves_system_stm32mp157f_dk2-portable-*.tar.gz

# 6. Update VERSION, CHANGELOG.md, README.md with new version

# 7. Commit, tag, push
git add -A
git status                    # verify no build artifacts or logs
git commit -m "Description of changes, bump to vX.Y.Z"
git tag vX.Y.Z
git push
git push origin vX.Y.Z

# 8. Create GitHub release with artifact
gh release create vX.Y.Z nerves_system_stm32mp157f_dk2-portable-*.tar.gz \
  --title "vX.Y.Z" \
  --notes "Description of changes"
```

### What Goes Where

| I want to... | Edit in... |
|---|---|
| Change kernel drivers | `linux-6.6.defconfig` |
| Change U-Boot behavior | `uboot/uboot.fragment` |
| Change boot environment | `uboot/uboot.env` |
| Change partition layout | `fwup_include/fwup-common.conf` |
| Change flash/OTA tasks | `fwup.conf` |
| Change erlinit (init system) | `rootfs_overlay/etc/erlinit.config` |
| Change IEx startup | `rootfs_overlay/etc/iex.exs` |
| Add Buildroot packages | `nerves_defconfig` |
| Change post-build steps | `post-build.sh` |
| Bump version | `VERSION` |

### Common Mistakes

**"I changed a file but the build didn't pick it up"**
→ Delete `.nerves/artifacts/` and `_build/`, rebuild from `phase1_test_firmware/`

**"mix compile in the system directory does nothing useful"**
→ Correct. You must build from `phase1_test_firmware/`. The system directory is
not a standalone buildable project.

**"I uploaded the wrong artifact to GitHub"**
→ Delete old tarballs before running `mix nerves.artifact`. Check `ls *.tar.gz`
before uploading. The filename includes the version and checksum.

**"Users get checksum mismatch errors"**
→ They have stale cached artifacts. Tell them to:
```bash
rm -rf ~/.nerves/dl/nerves_system_stm32mp157f_dk2-*
rm -rf ~/.nerves/artifacts/nerves_system_stm32mp157f_dk2-*
rm -rf _build deps mix.lock
mix deps.get
```
