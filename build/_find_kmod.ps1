$ErrorActionPreference = 'Continue'
$targets = @(
    'mediatek/mt7622',
    'mvebu/cortexa53',
    'mediatek/mt7623',
    'mediatek/mt7629',
    'mediatek/filogic'
)
$out = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build\_kmod_hits.txt'
Remove-Item $out -Force -ErrorAction SilentlyContinue

foreach ($t in $targets) {
    $url = "https://downloads.openwrt.org/releases/21.02.7/targets/$t/packages/Packages.gz"
    $gz = Join-Path $env:TEMP ("pk_" + ($t -replace '/', '_') + ".gz")
    $txt = Join-Path $env:TEMP ("pk_" + ($t -replace '/', '_') + ".txt")
    curl.exe -s -m 30 -o $gz $url 2>$null | Out-Null
    if (-not (Test-Path $gz)) { continue }
    if ((Get-Item $gz).Length -lt 200) { Write-Host ("  " + $t + ": 404"); continue }

    # gzip 解压
    $in = [IO.File]::OpenRead($gz)
    $gs = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress)
    $sr = New-Object IO.StreamReader($gs)
    $content = $sr.ReadToEnd()
    $sr.Close(); $gs.Close(); $in.Close()
    Set-Content -Path $txt -Value $content -Encoding UTF8

    $lines = Get-Content $txt -Encoding UTF8
    $ver = ($lines | Select-String -Pattern '^Depends: kernel \(=([^\)]+)\)' | Select-Object -First 1).Matches.Groups[1].Value
    $vh = $lines | Select-String -Pattern '^Filename: .*kmod-veth' | Select-Object -First 1
    $dh = $lines | Select-String -Pattern '^Filename: .*kmod-dummy' | Select-Object -First 1
    Write-Host ("== " + $t + "  kernel=" + $ver)
    if ($vh) { Write-Host ("   veth -> " + $vh.Line.Replace('Filename: ', '')); Add-Content $out ($t + "|" + $ver + "|" + $vh.Line.Replace('Filename: ', '')) }
    if ($dh) { Write-Host ("   dummy-> " + $dh.Line.Replace('Filename: ', '')) }
}
