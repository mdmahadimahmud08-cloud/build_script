#!/bin/bash
set -e

# ================= CONFIG =================
DEVICE="lancelot"
MAINTAINER="bhodrolok"
BUILDTYPE="UNOFFICIAL"

# ================= REPO INIT =================
echo ">>> Initializing LOS 23.2 manifest..."
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs

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
  <project path="device/xiaomi/mt6768-common" name="mk7x7/device_xiaomi_mt6768-common" remote="hub" revision="16.2" />

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

# ================= PATCH IMS BUG =================
echo ">>> Patching IMS bug in device tree..."
sed -i '/mediatek-maliLT\|mediatek-framework\|mediatek-telecom-common\|mediatek-telephony-base\|mediatek-telephony-common/d' device/xiaomi/lancelot/lineage_lancelot.mk

# ================= BUILD =================
echo ">>> Setting up build environment..."
source build/envsetup.sh

export LINEAGE_BUILDTYPE=$BUILDTYPE
export LINEAGE_MAINTAINER="$MAINTAINER"

echo ">>> Building LOS 23.2 for $DEVICE..."
breakfast $DEVICE
mka bacon -j$(nproc --all)
