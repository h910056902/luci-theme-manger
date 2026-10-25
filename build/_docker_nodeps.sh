#!/bin/sh
echo "== 内核模块 =="
lsmod 2>/dev/null | grep -E 'veth|dm_' | head -4 || echo "  未见 veth/dm 模块"
ls /lib/modules/*/veth* /lib/modules/*/dm-* 2>/dev/null | head -4

echo "== --nodeps 安装 =="
opkg install --nodeps libdevmapper containerd dockerd 2>&1 | tail -8

echo "== 安装结果 =="
opkg list-installed 2>/dev/null | grep -E '^(containerd|dockerd|libdevmapper)' | head -5

echo "== 启动 dockerd =="
[ -x /etc/init.d/dockerd ] && {
	/etc/init.d/dockerd enable 2>/dev/null
	/etc/init.d/dockerd start 2>&1 | head -4
	sleep 5
	pidof dockerd >/dev/null 2>&1 && echo "  DOCKERD_OK $(pidof dockerd)" || { echo "  DOCKERD_FAIL"; logread | grep -i docker | tail -5; }
}
