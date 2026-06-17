#!/bin/bash
#
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# 512M stable build: full 4G drivers + Argon/Aurora + 小猫崽 badge
#

set -e

echo "============================================================"
echo " DIY PART2: TR3000 512M drivers + themes stable build"
echo " No PassWall / Nikki / Diskman / automount / proxy plugins"
echo "============================================================"

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

# Rust workaround CI compatibility
if [ -f feeds/packages/lang/rust/Makefile ]; then
  sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile
fi

# Remove high-risk/unwanted packages from workspace
rm -rf package/passwall package/passwall-packages
rm -rf package/nikki
rm -rf package/openclash package/homeproxy package/v2raya
rm -rf package/luci-app-bandix package/openwrt-bandix
rm -rf feeds/packages/net/xray-core feeds/packages/net/sing-box

# Add build date in image filename
if [ -f include/image.mk ] && ! grep -q 'BUILD_DATE := $(shell date +%Y%m%d)' include/image.mk; then
  perl -0pi -e 's/^(IMG_PREFIX:=.*)$/BUILD_DATE := \$(shell date +%Y%m%d)\n$1/m' include/image.mk
  perl -0pi -e 's/\$\(SUBTARGET\)/\$(SUBTARGET)-\$(BUILD_DATE)/g' include/image.mk
fi

# Basic path check
test -f target/linux/mediatek/image/filogic.mk
test -d target/linux/mediatek/dts

# TR3000 512MB DTS injection
download_repo "zhuannn" "cudy-tr3000-512" "mod512"

test -f mod512/openwrt-mod/cudy-tr3000-512.mk
test -n "$(find mod512 -name '*.dts' -print -quit)"

echo "========== MOD512 MK CHECK =========="
grep -E "cudy_tr3000-512mb-v1|DEVICE_DTS|IMAGE_SIZE|TARGET_DEVICES" mod512/openwrt-mod/cudy-tr3000-512.mk || true

if ! grep -q "cudy_tr3000-512mb-v1" target/linux/mediatek/image/filogic.mk; then
  cat mod512/openwrt-mod/cudy-tr3000-512.mk >> target/linux/mediatek/image/filogic.mk
fi

echo "========== COPY 512M DTS =========="
find mod512 -name "*.dts" -print0 | while IFS= read -r -d '' dtsfile; do
  echo "Copy DTS: $dtsfile"
  cp -f "$dtsfile" target/linux/mediatek/dts/
done

grep -q "cudy_tr3000-512mb-v1" target/linux/mediatek/image/filogic.mk
ls target/linux/mediatek/dts/ | grep -q "tr3000.*512"

# Built-in files
mkdir -p files/etc/uci-defaults
mkdir -p files/www/luci-static/custom

# Default system settings
cat > files/etc/uci-defaults/90-custom-defaults <<'DEFAULTS'
#!/bin/sh

uci -q set system.@system[0].hostname='CudyX'
uci -q set system.@system[0].zonename='Asia/Shanghai'
uci -q set system.@system[0].timezone='CST-8'
uci -q set network.lan.ipaddr='192.168.2.1'
uci -q set network.lan.netmask='255.255.255.0'
uci -q commit system
uci -q commit network

exit 0
DEFAULTS
chmod +x files/etc/uci-defaults/90-custom-defaults

# LuCI custom corner badge: 小猫崽
cat > files/www/luci-static/custom/xiaomaozai-badge.js <<'BADGEJS'
(function () {
  function addBadge() {
    if (document.getElementById('xiaomaozai-build-badge')) return;

    var badge = document.createElement('a');
    badge.id = 'xiaomaozai-build-badge';
    badge.href = 'https://github.com/asrtroh-netizen/immortalwrt-mt7981-cudy-tr3000';
    badge.target = '_blank';
    badge.rel = 'noopener noreferrer';
    badge.innerText = '小猫崽';

    badge.style.position = 'fixed';
    badge.style.right = '16px';
    badge.style.bottom = '10px';
    badge.style.zIndex = '99999';
    badge.style.padding = '6px 10px';
    badge.style.borderRadius = '10px';
    badge.style.background = 'rgba(30, 30, 46, 0.72)';
    badge.style.backdropFilter = 'blur(8px)';
    badge.style.color = '#b4befe';
    badge.style.fontSize = '12px';
    badge.style.lineHeight = '1';
    badge.style.textDecoration = 'none';
    badge.style.boxShadow = '0 4px 14px rgba(0,0,0,0.25)';
    badge.style.border = '1px solid rgba(180,190,254,0.35)';
    badge.style.fontFamily = 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';

    badge.onmouseenter = function () {
      badge.style.background = 'rgba(137, 180, 250, 0.22)';
      badge.style.color = '#ffffff';
    };

    badge.onmouseleave = function () {
      badge.style.background = 'rgba(30, 30, 46, 0.72)';
      badge.style.color = '#b4befe';
    };

    document.body.appendChild(badge);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addBadge);
  } else {
    addBadge();
  }
})();
BADGEJS

cat > files/etc/uci-defaults/93-xiaomaozai-badge <<'BADGEDEFAULT'
#!/bin/sh

JS='/luci-static/custom/xiaomaozai-badge.js'
TAG='<script src="/luci-static/custom/xiaomaozai-badge.js"></script>'

for f in \
  /usr/lib/lua/luci/view/themes/*/footer.htm \
  /usr/lib/lua/luci/view/themes/*/footer.ut \
  /usr/share/ucode/luci/template/themes/*/footer.ut \
  /usr/share/ucode/luci/template/themes/*/footer.htm
do
  [ -f "$f" ] || continue
  grep -q "$JS" "$f" && continue

  if grep -q '</body>' "$f"; then
    sed -i "s#</body>#$TAG\n</body>#g" "$f"
  else
    echo "$TAG" >> "$f"
  fi
done

exit 0
BADGEDEFAULT
chmod +x files/etc/uci-defaults/93-xiaomaozai-badge

# Clean high-risk config entries from 512m.config before defconfig
sed -i '/CONFIG_PACKAGE_.*passwall/d' .config || true
sed -i '/CONFIG_PACKAGE_.*PassWall/d' .config || true
sed -i '/CONFIG_PACKAGE_.*openclash/d' .config || true
sed -i '/CONFIG_PACKAGE_.*homeproxy/d' .config || true
sed -i '/CONFIG_PACKAGE_.*v2raya/d' .config || true
sed -i '/CONFIG_PACKAGE_.*nikki/d' .config || true
sed -i '/CONFIG_PACKAGE_.*Nikki/d' .config || true
sed -i '/CONFIG_PACKAGE_.*bandix/d' .config || true
sed -i '/CONFIG_PACKAGE_.*diskman/d' .config || true
sed -i '/CONFIG_PACKAGE_.*automount/d' .config || true
sed -i '/CONFIG_PACKAGE_block-mount/d' .config || true
sed -i '/CONFIG_PACKAGE_hd-idle/d' .config || true
sed -i '/CONFIG_PACKAGE_ntfs/d' .config || true
sed -i '/CONFIG_PACKAGE_ntfs3/d' .config || true
sed -i '/CONFIG_PACKAGE_xray/d' .config || true
sed -i '/CONFIG_PACKAGE_v2ray/d' .config || true
sed -i '/CONFIG_PACKAGE_sing-box/d' .config || true
sed -i '/CONFIG_PACKAGE_mihomo/d' .config || true
sed -i '/CONFIG_PACKAGE_clash/d' .config || true
sed -i '/CONFIG_PACKAGE_hysteria/d' .config || true
sed -i '/CONFIG_PACKAGE_tuic/d' .config || true
sed -i '/CONFIG_PACKAGE_naiveproxy/d' .config || true
sed -i '/CONFIG_PACKAGE_shadowsocks/d' .config || true
sed -i '/CONFIG_PACKAGE_geoview/d' .config || true

cat >> .config <<'PKGCONFIG'

# ============================================================
# TR3000 512M stable: full 4G/USB modem drivers + two themes
# ============================================================

# High-risk plugins disabled
# CONFIG_PACKAGE_luci-app-passwall is not set
# CONFIG_PACKAGE_luci-app-openclash is not set
# CONFIG_PACKAGE_luci-app-homeproxy is not set
# CONFIG_PACKAGE_luci-app-v2raya is not set
# CONFIG_PACKAGE_luci-app-nikki is not set
# CONFIG_PACKAGE_luci-app-diskman is not set
# CONFIG_PACKAGE_luci-app-bandix is not set
# CONFIG_PACKAGE_block-mount is not set
# CONFIG_PACKAGE_ntfs-3g is not set
# CONFIG_PACKAGE_ntfs3-mount is not set
# CONFIG_PACKAGE_xray-core is not set
# CONFIG_PACKAGE_sing-box is not set
# CONFIG_PACKAGE_mihomo is not set
# CONFIG_PACKAGE_geoview is not set

# Full 4G / LTE / USB modem drivers
CONFIG_PACKAGE_usbutils=y
CONFIG_PACKAGE_usb-modeswitch=y
CONFIG_PACKAGE_kmod-usb-core=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-net=y
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan=y
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-fibocom=y
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-quectel=y
CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=y
CONFIG_PACKAGE_kmod-usb-net-cdc-ncm=y
CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm=y
CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y
CONFIG_PACKAGE_kmod-usb-net-rndis=y
CONFIG_PACKAGE_kmod-usb-net-sierrawireless=y
CONFIG_PACKAGE_kmod-usb-net-kalmia=y
CONFIG_PACKAGE_kmod-usb-wdm=y
CONFIG_PACKAGE_kmod-usb-acm=y
CONFIG_PACKAGE_kmod-usb-serial=y
CONFIG_PACKAGE_kmod-usb-serial-option=y
CONFIG_PACKAGE_kmod-usb-serial-wwan=y
CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y
CONFIG_PACKAGE_kmod-usb-serial-sierrawireless=y
CONFIG_PACKAGE_kmod-usb-serial-ch341=y
CONFIG_PACKAGE_kmod-usb-serial-cp210x=y
CONFIG_PACKAGE_kmod-usb-serial-ftdi=y
CONFIG_PACKAGE_kmod-usb-serial-pl2303=y
CONFIG_PACKAGE_kmod-usb-serial-mos7720=y
CONFIG_PACKAGE_kmod-usb-serial-mos7840=y
CONFIG_PACKAGE_uqmi=y
CONFIG_PACKAGE_umbim=y
CONFIG_PACKAGE_comgt=y
CONFIG_PACKAGE_comgt-ncm=y
CONFIG_PACKAGE_chat=y
CONFIG_PACKAGE_wwan=y
CONFIG_PACKAGE_minicom=y
CONFIG_PACKAGE_picocom=y
CONFIG_PACKAGE_luci-proto-qmi=y
CONFIG_PACKAGE_luci-proto-mbim=y
CONFIG_PACKAGE_luci-proto-ncm=y

# Two LuCI themes
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-theme-aurora=y
CONFIG_PACKAGE_luci-app-aurora-config=y
CONFIG_PACKAGE_luci-theme-bootstrap=y

# Useful LuCI tools
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-filebrowser=y
CONFIG_PACKAGE_luci-app-commands=y

PKGCONFIG

make defconfig

# Early conflict check, fail fast instead of wasting hours
BAD_PATTERN='CONFIG_PACKAGE_(luci-app-passwall|luci-app-openclash|luci-app-homeproxy|luci-app-v2raya|luci-app-nikki|luci-app-diskman|luci-app-bandix|block-mount|ntfs-3g|ntfs3-mount|xray-core|sing-box|mihomo|geoview)=y'
if grep -E "$BAD_PATTERN" .config; then
  echo "ERROR: high-risk package still enabled. Stop early."
  exit 1
fi

# Final target checks
grep -q '^CONFIG_TARGET_mediatek_filogic_DEVICE_cudy_tr3000-512mb-v1=y' .config
grep -q '^CONFIG_TARGET_PROFILE="DEVICE_cudy_tr3000-512mb-v1"' .config
! grep -q '^CONFIG_TARGET_mediatek_filogic_DEVICE_cudy_tr3000-v1-256mb=y' .config

# Final driver/theme checks
grep -q '^CONFIG_PACKAGE_kmod-usb-net-qmi-wwan=y' .config
grep -q '^CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=y' .config
grep -q '^CONFIG_PACKAGE_kmod-usb-net-rndis=y' .config
grep -q '^CONFIG_PACKAGE_kmod-usb-wdm=y' .config
grep -q '^CONFIG_PACKAGE_kmod-usb-serial-option=y' .config
grep -q '^CONFIG_PACKAGE_luci-proto-qmi=y' .config
grep -q '^CONFIG_PACKAGE_luci-proto-mbim=y' .config
grep -q '^CONFIG_PACKAGE_luci-theme-argon=y' .config
grep -q '^CONFIG_PACKAGE_luci-theme-aurora=y' .config

echo "========== FINAL TARGET CHECK =========="
grep -E 'CONFIG_TARGET_mediatek_filogic_DEVICE_cudy_tr3000|CONFIG_TARGET_PROFILE' .config

echo "========== FINAL 4G DRIVER CHECK =========="
grep -E 'CONFIG_PACKAGE_(kmod-usb-net-qmi-wwan|kmod-usb-net-qmi-wwan-fibocom|kmod-usb-net-qmi-wwan-quectel|kmod-usb-net-cdc-mbim|kmod-usb-net-cdc-ncm|kmod-usb-net-cdc-ether|kmod-usb-net-rndis|kmod-usb-wdm|kmod-usb-serial|kmod-usb-serial-option|kmod-usb-serial-wwan|uqmi|umbim|wwan|usb-modeswitch|luci-proto-qmi|luci-proto-mbim|luci-proto-ncm)=y' .config || true

echo "========== FINAL THEME CHECK =========="
grep -E 'CONFIG_PACKAGE_(luci-theme-argon|luci-app-argon-config|luci-theme-aurora|luci-app-aurora-config)=y' .config || true

echo "========== FINAL CUSTOM FILE CHECK =========="
ls -lh files/etc/uci-defaults/90-custom-defaults
ls -lh files/etc/uci-defaults/93-xiaomaozai-badge
ls -lh files/www/luci-static/custom/xiaomaozai-badge.js

echo "OK: TR3000 512M drivers + Argon/Aurora + CudyX + 小猫崽 badge enabled."
