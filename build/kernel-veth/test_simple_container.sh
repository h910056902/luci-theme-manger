#!/bin/sh
set -u

echo "===== 1. docker pull nginx:alpine ====="
docker pull nginx:alpine 2>&1 | tail -6
echo
echo "===== 2. docker run (bridge + 端口映射) ====="
docker rm -f kp-nginx >/dev/null 2>&1
docker run -d --name kp-nginx -p 8088:80 nginx:alpine >/dev/null 2>&1
sleep 3
docker ps --format '  {{.Names}} | {{.Image}} | {{.Ports}} | {{.Status}}'
echo "  container ip: $(docker inspect kp-nginx --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)"
echo
echo "===== 3. 从路由器本机访问发布端口 ====="
curl -s -m 5 http://192.168.66.1:8088/ -o /tmp/kp-nginx.html -w '  HTTP %{http_code}, %{size_download} bytes\n'
grep -o '<title>[^<]*</title>' /tmp/kp-nginx.html | head -1
rm -f /tmp/kp-nginx.html
echo
echo "===== 4. 容器内 DNS / 出网 ====="
echo -n "  nginx 容器 wget 百度: "
docker exec kp-nginx sh -c 'wget -qO- -T 8 http://www.baidu.com/ 2>&1 | head -c 50'
echo
echo -n "  nginx 容器 -> router:80: "
docker exec kp-nginx sh -c 'wget -qO- -T 5 http://192.168.66.1/ 2>&1 | head -c 50'
echo
echo
echo "===== 5. 容器日志 ====="
docker logs kp-nginx 2>&1 | head -5
echo
echo "===== 6. 资源占用 ====="
docker stats --no-stream kp-nginx 2>&1 | head -3
echo
echo "===== 7. 清理容器（保留镜像） ====="
docker rm -f kp-nginx >/dev/null 2>&1
docker ps -a --format '  {{.Names}}' | head -3
echo
echo "===== 8. 镜像列表 ====="
docker images
