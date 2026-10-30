# veth.ko 自编译与 ABI 对齐（解锁 Docker bridge 网络）

设备：NRadio C2000（NROS 3.0.0.n0.c1-preview，OpenWrt 25.12-SNAPSHOT，内核 **6.12.94**，
mediatek/filogic aarch64，GCC 14.3.0 构建）。

## 1. 背景

厂商内核 `CONFIG_VETH is not set`，而 Docker 的 `bridge` 网络必须创建 veth 网卡对
（容器端 + 宿主机端），因此：

- 默认 `bridge` 网络不可用，容器创建时报：
  `failed to add the host (veth…) <=> sandbox (veth…) pair interfaces: operation not supported`
- 只能 `--network host`，`-p` 端口映射不可用。

内核没有 veth 代码，apk 源里也没有对应 kmod 包（厂商内核没开该特性）。
**唯一可行路线：自编译一个与运行内核 ABI 完全一致的 `veth.ko` 模块并加载。**

## 2. 关键难点：ABI 必须精确匹配

内核没开 `CONFIG_MODVERSIONS`/`CONFIG_MODULE_SIG`，模块加载只校验：

1. `vermagic`（`6.12.94 SMP mod_unload aarch64`）
2. `.gnu.linkonce.this_module` 段大小 == 内核 `sizeof(struct module)`
3. 符号名能解析（无 CRC）

**但真正的坑是 `struct net_device` 布局**：`netdev_priv()` =
`(char *)dev + ALIGN(sizeof(struct net_device), NETDEV_ALIGN)`。
如果模块编译时 `sizeof(struct net_device)` 与厂商内核不一致，模块能加载，
但一创建 veth 就会因为私有区偏移错位而**内核崩溃重启**（实测踩过）。

### 2.1 定位出厂商内核的 `sizeof(net_device) = 2368`

厂商模块被 strip 过，但 `tun.ko` 里 `netdev_priv` 的偏移常量还在：

```
objdump -d /lib/modules/6.12.94/tun.ko | grep '#0x940'
    add x22, x19, #0x940      ← 0x940 = 2368
```

而 `linux-6.12.94.tar.xz` 原版源码 + `/proc/config.gz` 配置编译出来是 **2344**，
差 **24 字节**。逐项对出原因（都是 OpenWrt 对内核头文件的补丁/配置，与 DTS、驱动无关）：

| 差异 | 来源 | 对 `struct net_device` 影响 |
| --- | --- | --- |
| `CONFIG_CFG80211_HEADERS=y` | OpenWrt `generic/pending-6.12/731-net-permit-ieee80211_ptr-even-with-no-CFG82111-suppo.patch`（把字段 guard 从 `CONFIG_CFG80211` 改成 `CONFIG_CFG80211_HEADERS`；厂商 `CONFIG_CFG80211` 是关的） | `+ struct wireless_dev *ieee80211_ptr`（8B） |
| `CONFIG_WIRELESS_EXT=y` | OpenWrt target config（厂商配置里 =y；原版 Kconfig 中该符号无 prompt，`make olddefconfig` 会把它丢掉） | `+ wireless_handlers`、`+ wireless_data`（2×8B） |

合计 24B：2344 + 24 = **2368**，与厂商 `tun.ko` 的 `#0x940` 完全一致。
这两个补丁/配置应用后，编译出的模块 `sizeof(net_device)=2368`、`sizeof(sk_buff)=224`
（可用 `kp_probe.ko` 打印验证），创建 veth 不再崩。

> 其它 OpenWrt 私有配置（`CONFIG_SWCONFIG`、`NET_MEDIATEK_HNAT` 等）经核对
> **不影响** `struct net_device`/`struct sk_buff` 的布局；`721-net-add-packet-mangeling`
> 增加的字段是 `#ifdef CONFIG_ETHERNET_PACKET_MANGLE`，厂商配置未启用，无影响。

### 2.2 走过的弯路（留档，勿重复）

1. **直接拿官方 OpenWrt 25.12.S 6.12.103/108/112 的 `kmod-veth`**：
   vermagic 可二进制改成 6.12.94，但加载报
   `module veth: .gnu.linkonce.this_module section size must match ...`
   （官方 config 编译的 `struct module` 是 640B，厂商内核是 704B）→ **此路不通**。
2. **原版 6.12.94 源码 + /proc/config.gz 配置**：模块尺寸 704 能加载，
   但 `ip link add … type veth` 触发内核 panic 重启（net_device 2344 vs 2368）。
3. **本方案**（原版源码 + 上述两个 ABI 修正）→ 加载、建 pair、Docker bridge、重启全部通过。

## 3. 构建流程（可复现）

构建机：路由器本机的 aarch64 Alpine 容器（原生编译，无需交叉工具链）。

```sh
# 0) 准备（一次性，约 10-15 分钟；产物在 /overlay/kbuild）
mkdir -p /overlay/kbuild && cd /overlay/kbuild
curl -sL -o linux-6.12.94.tar.xz \
  https://mirrors.aliyun.com/linux-kernel/v6.x/linux-6.12.94.tar.xz
zcat /proc/config.gz > config-vendor
docker run -d --name kpbuild --network host -v /overlay/kbuild:/build alpine:latest sleep infinity
docker exec kpbuild apk add --no-cache build-base bison flex bc perl python3 xz patch
docker exec kpbuild tar -xf /build/linux-6.12.94.tar.xz -C /build
docker exec kpbuild sh -c 'cd /build/linux-6.12.94 && cp /build/config-vendor .config'

# 1) ABI 修正（关键！）
#   a. 应用 OpenWrt 731 补丁（CFG80211_HEADERS 字段）
#      补丁文件在 /overlay/kbuild/openwrt-25.12.5/target/linux/generic/pending-6.12/
docker exec kpbuild sh -c 'cd /build/linux-6.12.94 && \
  patch -p1 < /build/owrt-patches/731-cfg80211-headers.patch'
#   b. 让 WIRELESS_EXT 生效：原版 Kconfig 里该符号无 prompt，olddefconfig 会丢；
#      最省事是在 modules_prepare 后向 autoconf.h 追加（等价于 CONFIG_WIRELESS_EXT=y）
#      echo '#define CONFIG_WIRELESS_EXT 1' >> include/generated/autoconf.h

# 2) 生成内核头
docker exec kpbuild sh -c 'cd /build/linux-6.12.94 && make olddefconfig && make -j2 modules_prepare'
docker exec kpbuild sh -c 'cd /build/linux-6.12.94 && \
  grep -q "define CONFIG_WIRELESS_EXT" include/generated/autoconf.h || \
  echo "#define CONFIG_WIRELESS_EXT 1" >> include/generated/autoconf.h'

# 3) 外置编译 veth.ko
docker exec kpbuild sh -c 'mkdir -p /build/mod && cd /build/mod && \
  cp /build/linux-6.12.94/drivers/net/veth.c . && printf "obj-m := veth.o\n" > Makefile && \
  make -C /build/linux-6.12.94 M=/build/mod ARCH=arm64 KBUILD_MODPOST_WARN=1 modules'

# 4) 校验 + 安装
docker exec kpbuild sh -c 'strings /build/mod/veth.ko | grep ^vermagic'   # 6.12.94 SMP mod_unload aarch64
cp /overlay/kbuild/mod/veth.ko /lib/modules/$(uname -r)/veth.ko
insmod /lib/modules/$(uname -r)/veth.ko
ip link add testv0 type veth peer name testv1 && ip link del testv0   # 不崩溃即 ABI 正确
```

> 说明：`KBUILD_MODPOST_WARN=1` 是因为只 `modules_prepare` 没有完整内核的
> `Module.symvers`，modpost 会把所有外部符号当未定义；内核无 MODVERSIONS，
> 符号在加载时按名字解析，实际可用。若担心，可先完整编译内核生成 Module.symvers。

## 4. 已部署文件与开机加载

| 文件 | 作用 |
| --- | --- |
| `/lib/modules/6.12.94/veth.ko` | 自编译模块（234 KB，vermagic 6.12.94 SMP mod_unload aarch64） |
| `/etc/init.d/kp-veth` | `START=98`，开机 `insmod` 该模块（在 S99 dockerd 之前） |
| `/etc/rc.d/S98kp-veth` | 已 `enable` |
| `/overlay/kbuild/`（约 1.7 GB） | 构建环境（内核源码+OpenWrt 源码+工具链容器镜像）；可用于下次重编，也可删除 |

本目录同时归档了：

- `veth-6.12.94-abi-fixed.ko`：最终可用的模块（与路由器上一致）；
- `analyze_and_patch.py` / `analyze_modules.py`：vermagic 修补 + 官方/厂商模块 ABI 对比工具；
- `owrt-patches/`：OpenWrt 6.12 中与 net_device 布局相关的补丁（731/721/651/655）；
- `build_stage2/3/4_inner.sh`、`enable_bridge.sh`、`persist_veth.sh`、`test_bridge.sh`、
  `verify_postboot.sh`、`deploy_final.sh`：本次从建环境到落地验证的完整脚本记录。

加载后 `lsmod` 可见 `veth 28672 0`；Docker `bridge` 网络自动创建 docker0（172.17.0.1/16）。

## 5. 验证（重启后实测）

```
lsmod | grep veth                      # veth …（S98 自动加载）
docker network ls                      # bridge / host / none
docker run -d -p 18081:80 busybox:latest sh -c 'mkdir -p /www; echo bridge-postboot-ok > /www/index.html; httpd -f -p 80 -h /www'
curl http://192.168.66.1:18081/        # bridge-postboot-ok
docker run --rm busybox:latest wget -qO- http://www.baidu.com/   # 容器 DNS+出网正常
容器互 ping / 互访                     # 172.17.0.0/16 内互通
```

截图：`../docker-deps/screenshots/docker-page-overview-bridge.png`

## 6. 固件升级 / 内核变化时

- 内核版本变化后旧模块 **vermagic 不匹配会拒绝加载**（安全失败，不会崩）。
  此时 bridge 容器会启动失败（veth 缺失），需按第 3 节用**新内核源码 + 新 /proc/config.gz**
  重新编译；ABI 修正（731 补丁 + WIRELESS_EXT）大概率仍然需要，按新 OpenWrt 版本的
  `target/linux/generic/pending-*` 重新取补丁。
- 若不想再维护：`/etc/init.d/kp-veth disable`，并回滚
  `/etc/docker/daemon.json`（备份 `daemon.json.kp-hostonly.bak`）回到 host 网络模式。

## 7. 风险与已知限制

- 自编译模块来自 **原版 linux-6.12.94 源码** + ABI 修正，不是厂商编译产物；
  内核版本/配置一致时验证通过，但属"非常规维护手段"，升级后必须重编。
- macvlan / ipvlan / vxlan / IPVS 依旧没有（内核未编，不建议继续加模块）。
- `bridge-nf-call-iptables` 保持 0（避免 LAN↔WiFi 桥接流量被 iptables 过滤影响）。
- DNS：容器默认 223.5.5.5/119.29.29.29，被 OpenClash 的 53 劫持转到本机 dnsmasq；
  已把 `dhcp.@dnsmasq[0].localservice=0` 让 docker0 网段可查询。
- 如果极端情况下需要回滚内核模块：删 `/etc/rc.d/S98kp-veth` 后重启即可（模块本身不会
  在加载时崩溃；崩溃只发生在创建 veth 时，而那时 Docker 启动 bridge 容器才会触发）。
