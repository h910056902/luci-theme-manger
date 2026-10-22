echo "== log tail =="
tail -3 /var/log/messages
echo "== log lines =="
wc -l /var/log/messages
echo "== iptables chains =="
iptables -L -n -v -x 2>/dev/null | grep -E '^Chain' | head -12
echo "== dhcp =="
head -3 /tmp/dhcp.leases
echo "== iwinfo rai1 =="
iwinfo rai1 info 2>/dev/null | head -4
