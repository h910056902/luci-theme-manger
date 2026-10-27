import re
import sys
from pathlib import Path

p = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/_uboot/fip.bin')
data = p.read_bytes()
print(f'file={p} size={len(data)}')

# printable ascii strings >= 5
strs = re.findall(rb'[ -~]{5,}', data)
texts = [s.decode('latin-1') for s in strs]
joined = '\n'.join(texts)
print(f'strings={len(texts)}')

KEYS = [
    'U-Boot 20', 'U-Boot 201', 'U-Boot 1.', 'VERSION', 'uboot', 'U-BOOT',
    'Autoboot', 'Hit any key', 'bootdelay', 'bootmenu', 'BOOTMENU',
    'tftpboot', 'tftp', 'dhcp', 'ping', 'nfs', 'wget', 'httpd', 'fastboot',
    'saveenv', 'setenv', 'printenv', 'env default', 'mtdparts', 'mtd ',
    'bootm', 'booti', 'bootz', 'boot_fit', 'fit_', 'FIT', 'signature',
    'secure', 'verify', 'Anti-rollback', 'ATF', 'BL31', 'openssl',
    'MTK', 'MT7987', 'mt7987', 'nmbm', 'spi-nand', 'spi-nor', 'snand',
    'web failsafe', 'Web', 'recovery', 'Rescue', 'reset', 'gpio',
]

print('\n== token hits ==')
for k in KEYS:
    c = joined.count(k)
    if c:
        print(f'  {k!r}: {c}')

print('\n== version-ish lines ==')
seen = set()
for t in texts:
    if re.search(r'U-Boot\s+20\d\d', t) or 'Das U-Boot' in t:
        k = t.strip()[:120]
        if k not in seen:
            seen.add(k)
            print('  ' + k)

print('\n== command-ish strings (cmd_/do_ table hints) ==')
hints = set()
for t in texts:
    for m in re.finditer(r'(bootmenu|tftpboot|fastboot|httpd|dhcp|wget|saveenv|printenv|mtdparts|bootm|booti|nmbm)\b', t):
        hints.add(m.group(1))
print('  ' + ', '.join(sorted(hints)) if hints else '  none')

print('\n== 前 40 条较长字符串 ==')
for t in texts[:40]:
    if len(t) >= 8:
        print('  ' + t[:110])
