#!/bin/sh
echo "== container =="
docker ps -a 2>/dev/null | grep -E 'kpbuild|CONTAINER'
echo "== inner processes =="
docker exec kpbuild ps aux 2>/dev/null | head -15
echo "== source dir =="
docker exec kpbuild ls -l /build/ 2>/dev/null
docker exec kpbuild du -sh /build/linux-6.12.94 2>/dev/null
echo "== olddef log =="
docker exec kpbuild sh -c 'ls -l /tmp/olddef.log /tmp/mp.log 2>/dev/null; echo ---; tail -15 /tmp/olddef.log 2>/dev/null; echo ---; tail -15 /tmp/mp.log 2>/dev/null'
echo "== kernelrelease (if ready) =="
docker exec kpbuild sh -c 'cd /build/linux-6.12.94 && make -s kernelrelease 2>&1 | head -3'
echo "== disk/mem =="
df -h /overlay | tail -1
free -m | head -2
uptime
