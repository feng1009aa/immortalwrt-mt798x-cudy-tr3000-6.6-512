#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
set -euo pipefail  # 严格模式：命令失败/未定义变量立即终止

# ===================== 配置项 =====================
QMODEM_FEED="src-git qmodem https://github.com/FUjr/QModem.git;main"
FEEDS_CONF="feeds.conf.default"  # feeds配置文件路径（OpenWrt源码根目录）

# ===================== 核心逻辑 =====================
echo "=== 开始配置QModem软件源 ==="

# 1. 去重添加QModem源（先删除旧行，避免重复）
echo "Step 1: 去重添加QModem源到 $FEEDS_CONF"
sed -i '/src-git qmodem/d' "$FEEDS_CONF"  # 删除所有旧的qmodem源行
echo "$QMODEM_FEED" >> "$FEEDS_CONF"       # 追加新的qmodem源
# 验证添加结果
if grep -q "qmodem" "$FEEDS_CONF"; then
    echo "✅ QModem源添加成功，当前配置："
    grep "qmodem" "$FEEDS_CONF"
else
    echo "❌ QModem源添加失败，请检查文件权限！"
    exit 1
fi

# 2. 更新QModem Feeds（带容错和重试）
echo -e "\nStep 2: 更新QModem Feeds"
MAX_RETRY=3  # 最大重试次数
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRY ]; do
    if ./scripts/feeds update qmodem; then
        echo "✅ QModem Feeds更新成功！"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⚠️ QModem Feeds更新失败，重试第 $RETRY_COUNT 次（共 $MAX_RETRY 次）..."
        sleep 3  # 重试前等待3秒
    fi
done
if [ $RETRY_COUNT -eq $MAX_RETRY ]; then
    echo "❌ QModem Feeds更新失败（重试$MAX_RETRY次），终止流程！"
    exit 1
fi

# 3. 安装QModem Feeds包（先普通安装，失败则强制覆盖）
echo -e "\nStep 3: 安装QModem Feeds包"
if ./scripts/feeds install -a -p qmodem; then
    echo "✅ QModem包普通安装成功！"
else
    echo "⚠️ 普通安装失败，尝试强制覆盖安装..."
    if ./scripts/feeds install -a -f -p qmodem; then
        echo "✅ QModem包强制安装成功！"
    else
        echo "❌ QModem包强制安装也失败，请检查仓库是否存在！"
        exit 1
    fi
fi

echo -e "\n🎉 QModem软件源配置完成！"
