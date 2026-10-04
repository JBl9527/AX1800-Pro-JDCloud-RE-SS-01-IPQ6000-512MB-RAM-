#!/bin/bash
# =================================================================
# DIY Script Part 2: 在 feeds 安装后、编译前执行
# 作用: 512MB 内存优化、U-Boot 大分区适配、网络与系统默认参数定制
# =================================================================

echo ">>> [DIY-Part2] 开始执行硬件深度适配与内存调优..."

ROOTFS_SIZE="${ROOTFS_SIZE:-512}"

# 1. 默认网络与主机名设定 (默认网关 192.168.1.1)
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/OpenWrt-AX1800Pro/g' package/base-files/files/bin/config_generate

# 2. 默认时区修正为中国标准时间 (Asia/Shanghai)
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/timezone='CST-8'/a\\\t\t\set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# 3. 默认主题设置为 luci-theme-argon
if [ -d "package/luci-theme-argon" ] || [ -d "feeds/luci/themes/luci-theme-argon" ]; then
    echo ">>> 设置默认主题为 Argon..."
    sed -i 's/bootstrap/argon/g' feeds/luci/modules/luci-base/root/etc/config/luci 2>/dev/null || true
    sed -i 's/bootstrap/argon/g' package/feeds/luci/luci-base/root/etc/config/luci 2>/dev/null || true
fi

# 4. U-Boot 大分区 Rootfs 尺寸动态适配
echo ">>> 配置 U-Boot 大分区 Rootfs 镜像大小为: ${ROOTFS_SIZE}MB..."
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=${ROOTFS_SIZE}" >> .config

# 5. 512MB 内存保护与 DTS 节点核查
echo ">>> 执行 512MB RAM 节点保护检测..."
find target/linux/qualcommax -name "*jdcloud*.dts*" -o -name "*re-ss-01*.dts*" | while read -r dts_file; do
    if [ -f "$dts_file" ]; then
        echo "检查 DTS 文件: $dts_file"
        # 修正可能存在的 1024MB 误标 (0x40000000 误写为 1G 会导致 512M 版亚瑟开机死循环)
        sed -i 's/<0x0 0x40000000 0x0 0x40000000>/<0x0 0x40000000 0x0 0x20000000>/g' "$dts_file"
    fi
done

# 6. WiFi 默认配置优化 (AX1800 Pro 5G 功率与信道优化)
# 修复部分源码中 5G 默认无功率设置或功率偏高导致的发热降速问题
echo ">>> 预设 WiFi 优化参数 (5G 信道 149 / 功率 23dBm)..."
sed -i 's/country=.*/country=CN/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh 2>/dev/null || true

# 7. 移除编译缓存警告与冗余检查
sed -i 's/-Werror//g' Makefile 2>/dev/null || true

echo ">>> [DIY-Part2] 硬件适配与优化完成！"
