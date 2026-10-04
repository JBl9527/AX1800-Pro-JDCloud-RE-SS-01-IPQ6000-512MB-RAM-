#!/bin/sh
# =================================================================
# 京东云亚瑟 AX1800 Pro eMMC 大分区存储一键扩容/挂载工具
# =================================================================

set -e

echo "========================================================"
echo "    京东云亚瑟 AX1800 Pro eMMC 存储扩容与挂载工具"
echo "========================================================"

if [ ! -b "/dev/mmcblk0" ]; then
    echo "[错误] 未检测到板载 eMMC 存储设备 (/dev/mmcblk0)！"
    exit 1
fi

echo "[信息] 检测到板载 eMMC 设备: /dev/mmcblk0"

# 查找可用数据大分区
TARGET_PART=$(ls -1 /dev/mmcblk0p* 2>/dev/null | sort -V | tail -n 1)

if [ -z "$TARGET_PART" ]; then
    echo "[错误] 未找到可用分区！"
    exit 1
fi

echo "[信息] 目标大容量分区为: $TARGET_PART"

# 格式化分区
echo "[1/3] 正在格式化 $TARGET_PART 为 ext4..."
mkfs.ext4 -F -L "eMMC_Storage" "$TARGET_PART"

# 获取 UUID
UUID=$(blkid -s UUID -o value "$TARGET_PART")
echo "[2/3] 分区 UUID: $UUID"

# 写入 fstab
echo "[3/3] 写入 /etc/config/fstab 自动挂载..."
uci -q delete fstab.@mount[-1] || true
uci add fstab mount
uci set fstab.@mount[-1].uuid="$UUID"
uci set fstab.@mount[-1].target="/mnt/emmc"
uci set fstab.@mount[-1].enabled="1"
uci commit fstab

mkdir -p /mnt/emmc
/etc/init.d/fstab restart

echo "========================================================"
echo "[成功] eMMC 大分区已成功挂载到 /mnt/emmc ！"
df -h /mnt/emmc
echo "========================================================"
