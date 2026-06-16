#!/bin/bash

#

# https://github.com/P3TERX/Actions-OpenWrt

# File name: diy-part1.sh

# Description: OpenWrt DIY script part 1 (Before Update feeds)

#

# This is free software, licensed under the MIT License.

#

set -e

echo "============================================================"
echo " DIY PART1: Add extra packages before feeds update"
echo "============================================================"

mkdir -p package

# ============================================================

# Keep local luci-compat package if exists

# ============================================================

if [ -d "$GITHUB_WORKSPACE/package/luci-compat-keep" ]; then
echo "Copy local luci-compat-keep"
rm -rf package/luci-compat-keep
cp -r "$GITHUB_WORKSPACE/package/luci-compat-keep" package/
fi

# ============================================================

# Clean old extra packages

# ============================================================

rm -rf package/passwall
rm -rf package/passwall-packages
rm -rf package/nikki
rm -rf package/luci-theme-aurora
rm -rf package/luci-app-aurora-config
rm -rf package/luci-theme-argon
rm -rf package/luci-app-argon-config
rm -rf package/luci-app-bandix
rm -rf package/openwrt-bandix

# ============================================================

# PassWall

# ============================================================

echo "Clone PassWall"

git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall.git package/passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages.git package/passwall-packages

# ============================================================

# Nikki

# ============================================================

echo "Clone Nikki"

git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/nikki

# ============================================================

# LuCI Themes: Aurora / Argon

# ============================================================

echo "Clone Aurora theme"

git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora.git package/luci-theme-aurora
git clone --depth=1 https://github.com/eamonxg/luci-app-aurora-config.git package/luci-app-aurora-config

echo "Clone Argon theme"

git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# ============================================================

# Bandix

# ============================================================

echo "Clone Bandix"

git clone --depth=1 https://github.com/timsaya/luci-app-bandix.git package/luci-app-bandix
git clone --depth=1 https://github.com/timsaya/openwrt-bandix.git package/openwrt-bandix

# ============================================================

# Remove git metadata from local packages

# ============================================================

find package -name ".git" -type d -prune -exec rm -rf {} + || true

echo "============================================================"
echo " DIY PART1 done"
echo "============================================================"
