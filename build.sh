#!/bin/bash
set -e

# ================= CONFIG =================
DEVICE="lancelot"
MAINTAINER="bhodrolok"
BUILDTYPE="UNOFFICIAL"

# ================= REPO INIT =================
echo ">>> CrDroid manifest..."
repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --git-lfs --no-clone-bundle

# ================= MANIFEST =================
echo ">>> Setting up local manifests..."
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/roomservice.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="hub" fetch="https://github.com" />

  <!-- Device Trees -->
  <project path="device/xiaomi/lancelot" name="mk7x7/device_xiaomi_lancelot.git" remote="hub" revision="16.2" />
  <project path="device/xiaomi/merlinx" name="mk7x7/device_xiaomi_merlinx.git" remote="hub" revision="16.2" />

  <!-- Common Device Tree -->
  <project path="device/xiaomi/mt6768-common" name="mdmahadimahmud08-cloud/device_xiaomi_mt6768-common.git" remote="hub" revision="16.2" />

  <!-- Kernel -->
  <project path="kernel/xiaomi/mt6768" name="MrShockWAVEog/ximi-lancerlin-krenlol.git" remote="hub" revision="shockwave" />

  <!-- Vendor Trees -->
  <project path="vendor/xiaomi/mt6768-common" name="mk7x7/proprietary_vendor_xiaomi_mt6768-common.git" remote="hub" revision="16.2" />
  <project path="vendor/xiaomi/lancelot" name="mk7x7/proprietary_vendor_xiaomi_lancelot.git" remote="hub" revision="16.2" />
  <project path="vendor/xiaomi/merlinx" name="mk7x7/proprietary_vendor_xiaomi_merlinx.git" remote="hub" revision="16.2" />

  <!-- MTK Sepolicy -->
  <project path="device/mediatek/sepolicy_vndr" name="LineageOS/android_device_mediatek_sepolicy_vndr" remote="hub" revision="lineage-23.2" />

  <!-- Hardware -->
  <project path="hardware/xiaomi" name="LineageOS/android_hardware_xiaomi" remote="hub" revision="lineage-23.2" />
  <project path="hardware/mediatek" name="LineageOS/android_hardware_mediatek" remote="hub" revision="lineage-23.2" />
</manifest>
EOF

# ================= SYNC WITH RETRY =================
echo ">>> Syncing repos..."
if [ -f /opt/crave/resync.sh ]; then
    /opt/crave/resync.sh
else
    while true; do
        echo ">>> Syncing..."
        repo sync -c --force-sync --no-tags --no-clone-bundle -j$(nproc --all) 2>&1 | tee /tmp/sync.log
        if ! grep -qE "error:|fatal:|fail" /tmp/sync.log; then
            echo ">>> Sync completed successfully!"
            break
        fi
        echo ">>> Sync had errors, retrying in 10 seconds..."
        sleep 10
    done
fi

# ================= PATCH — NFC sepolicy fix =================
echo ">>> Patching NFC sepolicy..."
FILE="device/xiaomi/mt6768-common/sepolicy/vendor/file_contexts"
if [ -f "$FILE" ]; then
    sed -i '/\/dev\/nq-nci/d' "$FILE"
    echo ">>> NFC patch applied!"
else
    echo ">>> file_contexts not found, skipping NFC patch..."
fi

# ================= BUILD =================
echo ">>> Setting up build environment..."
. build/envsetup.sh

export ALLOW_MISSING_DEPENDENCIES=true
export CRDROID_BUILDTYPE="OFFICIAL"
export CRDROID_MAINTAINER="bhodrolok"
export TARGET_SUPPORTS_BLUR=false


echo ">>> Building LOS 23.2 for $DEVICE..."
brunch $DEVICE user
m -j$(nproc --all)
