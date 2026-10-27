#!/bin/sh
LOG=/overlay/dsmoke.log
: > "$LOG"
{
	echo "== 1. 拉取 hello-world =="
	docker pull hello-world 2>&1 | tail -4
	echo "== 2. host 网络运行 =="
	docker run --rm --network host hello-world 2>&1 | grep -E 'Hello from Docker|error' | head -3
	echo "== 3. bridge 网络（预期失败）=="
	docker run --rm hello-world 2>&1 | grep -iE 'error|not supported' | head -2
	echo "== 4. 清理 =="
	docker rm -f kp-demo >/dev/null 2>&1
	docker ps -a -q | wc -l
	docker images -q | wc -l
} >> "$LOG" 2>&1
echo done > /overlay/dsmoke.state
