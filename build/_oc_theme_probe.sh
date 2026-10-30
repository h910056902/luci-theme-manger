#!/bin/sh
echo "== 1. nradio 主题目录 =="
ls /www/luci-static/nradio/ 2>/dev/null
ls /www/luci-static/nradio/css/ 2>/dev/null | head
echo
echo "== 2. 主题 css 文件与体积 =="
find /www/luci-static/nradio -name '*.css' -maxdepth 3 2>/dev/null | head -10 | while read f; do echo "$f $(wc -c < "$f")"; done
echo
echo "== 3. body / :root 关键声明 =="
for f in $(find /www/luci-static/nradio -name '*.css' -maxdepth 3 2>/dev/null | head -6); do
	echo "--- $f"
	grep -o 'body[^{]*{[^}]*background[^}]*}' "$f" 2>/dev/null | head -2
	grep -o ':root{[^}]*}' "$f" 2>/dev/null | head -1 | head -c 600
	echo
done
echo
echo "== 4. 主色出现频次（nradio 主题） =="
grep -oh '#[0-9a-fA-F]\{6\}' /www/luci-static/nradio/css/*.css 2>/dev/null | sort | uniq -c | sort -rn | head -12
echo
echo "== 5. 字体栈 =="
grep -o 'font-family:[^;}]*' /www/luci-static/nradio/css/*.css 2>/dev/null | sort | uniq -c | sort -rn | head -5
echo
echo "== 6. 参考页（厂商状态页）是否也走同一主题 =="
head -c 400 /www/luci-static/nradio/css/style.css 2>/dev/null
