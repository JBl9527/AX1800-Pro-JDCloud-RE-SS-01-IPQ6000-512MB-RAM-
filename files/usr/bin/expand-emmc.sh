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

# 选择目标数据分区：优先 partlabel 为 rootfs_data 的分区；否则选容量最大的分区。
# 不再取"编号最后一个"——原厂 GPT 里小分区很多，编号顺序与用途无关，容易误选。
TARGET_PART=""
if [ -b "/dev/disk/by-partlabel/rootfs_data" ]; then
    TARGET_PART=$(readlink -f "/dev/disk/by-partlabel/rootfs_data")
fi
if [ -z "$TARGET_PART" ] || [ ! -b "$TARGET_PART" ]; then
    TARGET_PART=""
    _best=0
    for _p in /dev/mmcblk0p*; do
        [ -b "$_p" ] || continue
        _sz=$(lsblk -b -n -o SIZE "$_p" 2>/dev/null | head -n1)
        if [ -n "$_sz" ] && [ "$_sz" -gt "$_best" ]; then
            _best=$_sz
            TARGET_PART=$_p
        fi
    done
    unset _best _p _sz
fi

if [ -z "$TARGET_PART" ]; then
    echo "[错误] 未找到可用分区！"
    exit 1
fi

echo "[信息] 目标大容量分区为: $TARGET_PART"

# 安全校验：拒绝格式化系统分区，且分区需大于 1GB（防止误选小分区）
if grep -q "^$TARGET_PART " /proc/mounts 2>/dev/null; then
    _mp=$(grep "^$TARGET_PART " /proc/mounts 2>/dev/null | awk '{print $2}' | head -n1)
    case "$_mp" in
        /|/overlay|/rom)
            echo "[错误] 目标分区已挂载为系统分区 ($_mp)，拒绝格式化！"
            exit 1
            ;;
    esac
fi
_psz=$(lsblk -b -n -o SIZE "$TARGET_PART" 2>/dev/null | head -n1)
if [ -n "$_psz" ] && [ "$_psz" -lt 1073741824 ]; then
    echo "[错误] 目标分区仅 $((_psz/1048576))MB，小于 1GB，拒绝格式化（可能选错了分区）！"
    exit 1
fi
unset _mp _psz

read -p "是否格式化 $TARGET_PART 为 ext4 并挂载为数据盘存储？(y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "[取消] 用户终止操作。"
    exit 0
fi

# 格式化分区
echo "[1/3] 正在格式化 $TARGET_PART 为 ext4..."
mkfs.ext4 -F -L "eMMC_Storage" "$TARGET_PART"

# 获取 UUID
UUID=$(blkid -s UUID -o value "$TARGET_PART")
echo "[2/3] 分区 UUID: $UUID"

# 写入 fstab（按 target 精确删除旧的 /mnt/emmc 挂载项，避免误删用户其它挂载）
echo "[3/3] 写入 /etc/config/fstab 自动挂载..."
while _m=$(uci show fstab 2>/dev/null | grep -m1 "\.target='/mnt/emmc'$" | sed "s/\.target='\/mnt\/emmc'$//"); [ -n "$_m" ]; do
    uci -q delete "$_m" || break
done
unset _m
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
