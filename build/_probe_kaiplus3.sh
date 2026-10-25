#!/bin/sh
echo "== 依赖视图 =="
ls -l /usr/lib/lua/luci/view/tasks/embed.htm 2>/dev/null || echo "缺 view/tasks/embed.htm"
echo "== 模型 =="
ls -l /usr/lib/lua/luci/model/kaiplus.lua 2>/dev/null || echo "缺 model/kaiplus.lua"
echo "== 缓存里的节点路径 =="
grep -o 'kaiplus[a-z_/]*' /tmp/luci-indexcache-bootstrap 2>/dev/null | sort -u | head -10
echo "== 菜单入口标题 =="
grep -o 'KaiPlus' /tmp/luci-indexcache-bootstrap 2>/dev/null | head -2
echo "== 配置内容 =="
cat /etc/config/kaiplus 2>/dev/null
echo "== 服务状态 =="
pidof kaiplus >/dev/null 2>&1 && echo "kaiplus 运行中" || echo "kaiplus 未运行"
