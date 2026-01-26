#!/bin/bash

# git clone -b openwrt-24.10-6.6 --single-branch --filter=blob:none https://github.com/padavanonly/immortalwrt-mt798x-24.10 immortalwrt-mt798x-24.10
# cd immortalwrt-mt798x-24.10

# git config --local https.proxy socks5://host.docker.internal:1080

# ./scripts/feeds update -a
# ./scripts/feeds install -a

# theme
rm -rf feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# passwall
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang

rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages

rm -rf feeds/luci/applications/luci-app-passwall
# git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci
git clone https://github.com/Openwrt-Passwall/openwrt-passwall2 package/passwall-luci

# tailscale
# sed -i '/\/etc\/init\.d\/tailscale/d;/\/etc\/config\/tailscale/d;' feeds/packages/net/tailscale/Makefile
# git clone https://github.com/asvow/luci-app-tailscale package/luci-app-tailscale

# Modify default IP
sed -i 's/192.168.6.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# defconfig
# cp -f ../.config .config
# cp -f defconfig/mt7981-ax3000.config .config
sed -i 's|IMG_PREFIX:=|IMG_PREFIX:=$(shell TZ="Asia/Shanghai" date +"%Y%m%d")-24.10-6.6-|' include/image.mk
# make menuconfig

# compile and build
# make download -j8
# make -j$(nproc)
# 修复rust编译时LLVM CI包404问题
echo "=== 修复rust编译的LLVM CI下载404问题 ==="
RUST_DIR="$PWD/feeds/packages/lang/rust"
# 找到rust源码目录（编译时会下载到build_dir）
RUST_SRC_DIR="$PWD/build_dir/target-aarch64_cortex-a53_musl/host/rustc-1.89.0-src"

# 提前创建rust源码目录（确保配置文件能被修改）
mkdir -p $RUST_SRC_DIR

# 写入bootstrap.toml，禁用download-ci-llvm
cat > $RUST_SRC_DIR/bootstrap.toml << EOF
[llvm]
download-ci-llvm = false
EOF

# 同时修改feeds中rust包的Makefile，强制使用本地LLVM构建
sed -i '/PKG_BUILD_DEPENDS/s/$/ llvm/' $RUST_DIR/Makefile
echo "✅ Rust LLVM CI下载禁用完成"
