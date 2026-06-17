#!/bin/bash
#
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
# 512M stable build: drivers + Argon/Aurora themes only
#

set -e

echo "============================================================"
echo " DIY PART1: Add extra theme packages before feeds update"
echo " 512M stable build: no proxy plugins, no disk plugins"
echo "============================================================"

mkdir -p package

download_repo() {
  local owner="$1"
  local repo="$2"
  local dir="$3"
  local branch=""
  local url=""
  local tmp=""
  local ok="0"

  echo "============================================================"
  echo "Download ${owner}/${repo}"
  echo "Target ${dir}"
  echo "============================================================"

  rm -rf "$dir"

  for branch in main master; do
    url="https://codeload.github.com/${owner}/${repo}/tar.gz/refs/heads/${branch}"
    tmp="/tmp/${owner}-${repo}-${branch}.tar.gz"

    if curl -fsSL --retry 3 --connect-timeout 20 "$url" -o "$tmp"; then
      mkdir -p "$dir"
      tar -xzf "$tmp" -C "$dir" --strip-components=1
      rm -f "$tmp"
      ok="1"
      echo "Downloaded ${owner}/${repo} branch ${branch}"
      break
    fi

    rm -f "$tmp"
  done

  if [ "$ok" != "1" ]; then
    echo "Tarball failed, try git clone"
    git clone --depth=1 "https://github.com/${owner}/${repo}.git" "$dir"
  fi
}

# Keep local luci-compat package if exists
if [ -d "$GITHUB_WORKSPACE/package/luci-compat-keep" ]; then
  echo "Copy local luci-compat-keep"
  rm -rf package/luci-compat-keep
  cp -r "$GITHUB_WORKSPACE/package/luci-compat-keep" package/
fi

# Remove old/high-risk extra packages
rm -rf package/passwall package/passwall-packages
rm -rf package/nikki
rm -rf package/openclash package/homeproxy package/v2raya
rm -rf package/luci-app-bandix package/openwrt-bandix
rm -rf package/luci-theme-aurora package/luci-app-aurora-config
rm -rf package/luci-theme-argon package/luci-app-argon-config

# Themes only
download_repo "eamonxg" "luci-theme-aurora" "package/luci-theme-aurora"
download_repo "eamonxg" "luci-app-aurora-config" "package/luci-app-aurora-config"
download_repo "jerrykuku" "luci-theme-argon" "package/luci-theme-argon"
download_repo "jerrykuku" "luci-app-argon-config" "package/luci-app-argon-config"

# Remove git metadata
find package -name ".git" -type d -prune -exec rm -rf {} + || true

echo "============================================================"
echo " DIY PART1 done"
echo "============================================================"
