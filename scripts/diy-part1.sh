#!/bin/bash
# =================================================================
# DIY Script Part 1: 在 feeds 更新前执行
# 作用: 添加第三方软件包 feed 源或直接克隆主题等必要组件
# =================================================================

echo ">>> [DIY-Part1] 开始执行 feeds 前置配置..."

# 1. 确保 Argon 主题及配置插件可用 (官方最新版本)
if [ ! -d "package/luci-theme-argon" ]; then
    echo ">>> 克隆 luci-theme-argon 主题..."
    git clone --depth 1 -b master https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
fi

if [ ! -d "package/luci-app-argon-config" ]; then
    echo ">>> 克隆 luci-app-argon-config 配置插件..."
    git clone --depth 1 -b master https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config
fi

echo ">>> [DIY-Part1] 完成！"
