#!/bin/bash
# =================================================================
# DIY Script Part 2: 在 feeds 安装后、编译前执行
# 作用: 512MB 内存优化、U-Boot 大分区适配、网络与系统默认参数定制
# =================================================================

echo ">>> [DIY-Part2] 开始执行硬件深度适配与内存调优..."

ROOTFS_SIZE="${ROOTFS_SIZE:-512}"

# 1. 默认网络与主机名设定 (默认网关 192.168.1.1)
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

# 5. 512MB 内存 DTS 节点兜底校验
# 说明：仅当源码树内以 .dts 文件形式存在该设备 DTS 时本段才可能命中；
# LiBwrt 等树的 DTS 随内核补丁下发、本脚本执行时文件尚不存在，会走下方
# "未找到"提示分支，属预期。各目标树自带的 re-ss-01 定义本身即 512MB，
# 本段只是防社区 DTS 误标 1GB 的兜底，不要当作已生效的适配。
echo ">>> 执行 512MB RAM 节点兜底校验..."
_dts_files=$(find target/linux/qualcommax \( -name "*jdcloud*.dts*" -o -name "*re-ss-01*.dts*" \) 2>/dev/null)
if [ -z "$_dts_files" ]; then
    echo "[提示] 未找到 jdcloud/re-ss-01 的 DTS 文件（补丁下发型源码树属正常），跳过兜底校验。"
else
    for dts_file in $_dts_files; do
        echo "检查 DTS 文件: $dts_file"
        # 修正可能存在的 1024MB 误标 (0x40000000 误写为 1G 会导致 512M 版亚瑟开机死循环)
        sed -i 's/<0x0 0x40000000 0x0 0x40000000>/<0x0 0x40000000 0x0 0x20000000>/g' "$dts_file"
    done
fi
unset _dts_files

# 6. WiFi 默认参数不在这里改源码：
# 旧做法 sed mac80211.sh 的 country 行在新版源码中已无对应文本（空转），且其
# 注释宣称的"5G 信道 149 / 功率 23dBm"从未真正设置过。无线国家码等默认值
# 统一在 files/etc/uci-defaults/99-custom-init 中以 uci 方式设置（country_code=CN，
# 信道/功率保持驱动默认，避免超规格发射）。
echo ">>> WiFi 默认参数由 uci-defaults 设置，跳过源码 sed..."

# 7. 移除顶层 Makefile 的 -Werror（LiBwrt-op NSS 树部分软件包有警告会导致编译中断；
#    注意：这会同时掩盖真正的编译错误，定位疑难编译失败时可临时注释掉本行再编）
sed -i 's/-Werror//g' Makefile 2>/dev/null || true

echo ">>> [DIY-Part2] 硬件适配与优化完成！"
