# Deploy the single-page status dashboard.
# NOTE: two devices answer 192.168.66.1 on this PC; bind to the WLAN source.
$ErrorActionPreference = 'Stop'

$Router = '192.168.66.1'
$Bind   = '192.168.66.245'
$Base   = '/overlay/nradio-apps/openwrt-luci-8080'
$TS     = Get-Date -Format 'yyyyMMdd-HHmmss'

$sshOpts = @('-b', $Bind, '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=NUL', '-o', 'ConnectTimeout=8')
$scpOpts = @('-O', '-o', "BindAddress=$Bind", '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=NUL')

Write-Host '[1/4] backup'
ssh @sshOpts root@$Router "cp $Base/www/cgi-bin/luci /tmp/luci.$TS.bak; cp $Base/usr/lib/lua/luci/view/admin_status/index.htm /tmp/index.$TS.bak 2>/dev/null; cp $Base/usr/lib/lua/luci/view/themes/bootstrap/header.htm /tmp/header.$TS.bak; cp $Base/www/luci-static/bootstrap/css/mwrt-global-custom.css /tmp/css.$TS.bak; echo BACKUP=$TS"

Write-Host '[2/4] upload + syntax check'
scp @scpOpts 'www\cgi-bin\luci' "root@${Router}:/tmp/kp-luci.new"
scp @scpOpts 'usr\lib\lua\luci\view\admin_status\index.htm' "root@${Router}:/tmp/kp-index.new"
scp @scpOpts 'usr\lib\lua\luci\view\themes\bootstrap\header.htm' "root@${Router}:/tmp/kp-header.new"
scp @scpOpts 'www\luci-static\bootstrap\css\mwrt-status-custom.css' "root@${Router}:/tmp/kp-status.css"
scp @scpOpts 'www\luci-static\bootstrap\css\mwrt-global-custom.css' "root@${Router}:/tmp/kp-css.new"
ssh @sshOpts root@$Router "lua /tmp/loadcheck.lua /tmp/kp-luci.new; lua /tmp/tplcheck.lua /tmp/kp-index.new; lua /tmp/tplcheck.lua /tmp/kp-header.new"

Write-Host '[3/4] install'
ssh @sshOpts root@$Router "cp /tmp/kp-luci.new $Base/www/cgi-bin/luci && chmod 755 $Base/www/cgi-bin/luci; cp /tmp/kp-index.new $Base/usr/lib/lua/luci/view/admin_status/index.htm && chmod 644 $Base/usr/lib/lua/luci/view/admin_status/index.htm; cp /tmp/kp-header.new $Base/usr/lib/lua/luci/view/themes/bootstrap/header.htm && chmod 644 $Base/usr/lib/lua/luci/view/themes/bootstrap/header.htm; cp /tmp/kp-status.css $Base/www/luci-static/bootstrap/css/mwrt-status-custom.css && chmod 644 $Base/www/luci-static/bootstrap/css/mwrt-status-custom.css; cp /tmp/kp-css.new $Base/www/luci-static/bootstrap/css/mwrt-global-custom.css && chmod 644 $Base/www/luci-static/bootstrap/css/mwrt-global-custom.css; rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache /tmp/kp-status.json; ls -l $Base/www/luci-static/bootstrap/css/mwrt-status-custom.css $Base/usr/lib/lua/luci/view/admin_status/index.htm"

Write-Host '[4/4] done -> http://192.168.66.1:8080/cgi-bin/luci/admin/status/overview?v=20261020'
