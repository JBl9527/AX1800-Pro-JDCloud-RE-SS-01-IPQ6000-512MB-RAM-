# 京东云亚瑟 AX1800 Pro 纯净原版 OpenWrt 固件云编译 (GitHub Actions)

[![Build AX1800 Pro OpenWrt](https://github.com/JBl9527/AX1800-Pro-JDCloud-RE-SS-01-IPQ6000-512MB-RAM-/actions/workflows/build-openwrt.yml/badge.svg)](https://github.com/JBl9527/AX1800-Pro-JDCloud-RE-SS-01-IPQ6000-512MB-RAM-/actions/workflows/build-openwrt.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![OpenWrt](https://img.shields.io/badge/OpenWrt-Vanilla-blue.svg)](https://openwrt.org/)

专为 **京东云无线宝·亚瑟 AX1800 Pro (JDCloud RE-SS-01 / IPQ6000 SoC / 512MB RAM)** 量身定制的 GitHub Actions 自动化编译工程。

本项目致力于打造一个**极其纯净、极低内存占用、完美支持 U-Boot 大分区**的原版 OpenWrt 固件底座。除精美现代的 **Argon 主题插件** 外，**不预装任何第三方臃肿插件**，空载运存占用仅 ~50MB，为后续自主安装插件预留出 440MB+ 充裕内存！

---

## 🎯 核心优化与特性

### 1. 🍃 极致纯净，除主题外零冗余插件
- **精简极致**：剔除 Docker、各类臃肿代理、文件下载服务等所有杂项，保证系统最干净的原汁原味状态。
- **现代化 UI**：集成社区最高颜值的官方 `luci-theme-argon` 与配套 `luci-app-argon-config`，支持暗色/亮色自适应模式。
- **中文原生支持**：预设原生简体中文（zh-cn）语言环境与标准时区（Asia/Shanghai CST-8）。

### 2. 🚀 完美适配 U-Boot 大分区
- **专用大分区镜像**：默认将 Rootfs 分区编译参数设定为 `512MB`（可随 GitHub Actions 工作流参数自定义调整），完全适配刷了大分区 GPT 表的 U-Boot 引导。
- **eMMC 大容量释放**：亚瑟板载 64G/128G eMMC 存储，固件内置分区工具（`parted`, `e2fsprogs`, `block-mount`），并内置 `/usr/bin/expand-emmc.sh` 一键挂载工具，轻松利用板载超大存储空间。

### 3. ⚡ 512MB 物理运存深度调优
- **DTS 512MB 内存节点防死锁**：在构建脚本中自动校对并纠正部分社区 DTS 将 512MB 误写为 1024MB 导致的开机无限重启问题。
- **zram 压缩弹性交换空间**：开启 `zram-swap`（256MB，采用极低 CPU 开销的 lz4 算法），在高负荷运行或多包并发更新时充当弹性缓冲区，彻底杜绝 OOM 内核崩溃。
- **激进虚拟内存回收**：
  - `vm.vfs_cache_pressure = 150`：快速回收闲置的目录项与索引缓存；
  - `vm.swappiness = 30`：优先保留物理可用内存；
  - `vm.min_free_kbytes = 8192`：预留 8MB 内存底线，保障网络包收发零丢包。
- **系统空闲内存**：开机后物理内存占用仅约 **50MB - 70MB**，剩余可用内存高达 **440MB+**。

### 4. 📶 高通 NSS 硬件加速与 Wi-Fi 满血优化
- **NSS 满血加速驱动**：搭载 `kmod-qca-nss-drv` 与 `kmod-qca-nss-ecm`，千兆 NAT 转发由专用网络协处理器卸载，CPU 占用率趋近于 0，温度大幅降低。
- **Wi-Fi 射频调优**：预置高通原厂 `ath11k` 固件与 AX1800 Pro 硬件校准 BDF，5GHz 功率与信道合理分配，彻底解决驱动默认未指定发射功率导致的无线过热掉速。

---

## 🛠️ 仓库目录结构

```text
.
├── .github/
│   └── workflows/
│       ├── build-openwrt.yml       # GitHub Actions 自动化编译主流水线
│       └── clean-runs.yml         # 定时自动清理历史 Actions 记录工作流
├── configs/
│   └── jdc_ax1800pro.config       # AX1800 Pro 专用极简种子配置文件
├── files/                         # 打包进固件的文件系统
│   ├── etc/
│   │   ├── banner                 # 终端登录 ASCII Banner
│   │   ├── sysctl.d/
│   │   │   └── 99-memory-opt.conf # 512MB 低内存内核调优参数
│   │   └── uci-defaults/
│   │       └── 99-custom-init     # 首次开机自运行初始化脚本 (主题/中文/zram等)
│   └── usr/
│       └── bin/
│           └── expand-emmc.sh     # 固件内内置的 eMMC 大分区一键挂载脚本
├── scripts/
│   ├── diy-part1.sh               # feeds 更新前钩子 (注入 Argon 主题源)
│   ├── diy-part2.sh               # 编译前钩子 (DTS 校验、大分区镜像大小、WiFi调优)
│   └── expand-emmc.sh             # 独立 eMMC 大分区存储挂载脚本
├── LICENSE
└── README.md
```

---

## 🚀 如何在 GitHub Actions 中一键编译

1. **Fork 本仓库**：点击本页面右上角 `Fork`，复制到你个人的 GitHub 账号中。
2. **开启 Actions 权限**：进入你 Fork 后的仓库，切换至 **Actions** 标签页，点击绿色按钮 `I understand my workflows, go ahead and enable them` 启用工作流。
3. **启动编译**：
   - 点击左侧的 **Build AX1800 Pro OpenWrt** 工作流；
   - 点击右侧的 **Run workflow** 下拉按钮；
   - 选择配置参数（支持默认值，无需修改即可直接开跑）：
     - **源码仓库**：默认 `https://github.com/LiBwrt-op/openwrt-6.x`（含 NSS 满血硬件加速与大分区支持）
     - **源码分支**：默认 `25.12-nss`
     - **Rootfs 大小**：默认 `512`（MB）
     - **发布到 Release**：勾选 `true`
   - 点击绿色的 **Run workflow** 开始编译。
4. **下载固件**：
   - 编译时间通常在 **1.5 ~ 2.5 小时**（取决于 GitHub Actions 服务器分配配置）；
   - 编译完成后，在仓库右侧的 **Releases** 即可直接下载固件文件。

---

## 💻 固件刷机指引

### 1. 默认网络信息
- **默认管理地址**：`192.168.1.1`
- **默认用户名**：`root`
- **默认密码**：（空，直接回车）
- **默认无线**：首次开机默认关闭，请在 LuCI「网络 -> 无线」中启用并设置 WPA2 密码后再使用

### 2. 使用 U-Boot 大分区刷入（首次刷机）
> ⚠️ **强烈注意**：从原厂或其他第三方固件刷入，**禁止**在原有系统后台直接使用 `sysupgrade` 升级，必须通过 U-Boot 刷入！

1. 确保路由器已刷入支持大分区的第三方 U-Boot（如加菲猫版或社区常见不死 U-Boot）；
2. 路由器彻底断电；
3. 用卡针长按路由器背部的 **Reset（重置）** 按钮，插上电源线通电；
4. 保持按住 Reset 键约 5~8 秒，待指示灯变为 **蓝色常亮** 后松开；
5. 用网线将电脑网口连接到路由器的 **LAN 口**，并将电脑 IPv4 手动设置为静态 IP：
   - IP 地址：`192.168.1.2`
   - 子网掩码：`255.255.255.0`
   - 网关：`192.168.1.1`
6. 在浏览器无痕模式下访问 `http://192.168.1.1` 进入 U-Boot Web 恢复页面；
7. 选择编译生成的以 **`-factory.bin`** 结尾的固件文件上传；
8. 点击 Update / 刷入，耐心等待 3~5 分钟，指示灯变绿并自动重启；
9. 将电脑 IP 改回“自动获取（DHCP）”，浏览器访问 `192.168.1.1` 即可进入全新的 Argon 主题 LuCI 管理界面！

### 3. 同系统后续在线升级
如果当前已在运行本固件，后续编译了更新的版本，可直接在 OpenWrt 网页后台：
`系统` -> `备份/升级` -> 上传以 **`-sysupgrade.bin`** 结尾的固件进行无缝升级。

---

## 📦 eMMC 大分区存储挂载与后续安装插件

由于本固件未预装任何冗余软件，您可以充分享受原版 OpenWrt 的强大包管理功能：

### 1. 挂载板载 eMMC 大存储（64G/128G）
固件已内置一键挂载脚本。通过 SSH 登录路由器终端：
```bash
ssh root@192.168.1.1
```
执行预置的扩容挂载脚本：
```bash
expand-emmc.sh
```
脚本将自动格式化并把大分区持久化挂载至 `/mnt/emmc`。

### 2. 安装自定义插件
固件已配置标准软件源，安装插件极其轻松。例如：
```bash
opkg update
# 搜索插件
opkg list | grep luci-app
# 安装你需要的任意插件（例如定时重启、UPnP等）
opkg install luci-app-upnp luci-i18n-upnp-zh-cn
opkg install luci-app-autoreboot luci-i18n-autoreboot-zh-cn
```
由于系统空闲内存高达 440MB+，即使后续运行复杂的现代应用也能游刃有余、轻快稳定！

### 3. 安装代理软件（nikki / momo / PassWall）

本固件已内置透明代理所需的全部内核模块（`kmod-nft-tproxy`、`kmod-nft-socket`、`kmod-tun` 等），可直接用一键脚本安装：

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/JBl9527/update_plugins.sh/main/update_plugins.sh)"
# 国内网络慢可用 jsDelivr：
# sh -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/JBl9527/update_plugins.sh@main/update_plugins.sh)"
```

> ⚠️ **NSS 硬件加速与透明代理二选一**：本固件默认启用 `qca-nss-ecm` 硬件转发加速，它会把连接卸载到 NSS 协处理器、旁路 netfilter，导致 nikki/momo 的 TPROXY 规则看不到被卸载的流量（表现为部分流量不走代理）。启用透明代理前请先停用它：
>
> ```sh
> /etc/init.d/qca-nss-ecm stop
> /etc/init.d/qca-nss-ecm disable
> ```
>
> 说明：daed 需要内核 BTF，本固件的 NSS 内核未开启该选项，不可用；nikki / momo / passwall / openclash 均可正常安装。

---

## ⚖️ 免责声明
- 刷机有风险，操作需谨慎。刷机前请务必完整备份原机 `CDT` 等关键底层分区数据。
- 本项目开源免费，仅供学习交流使用。
