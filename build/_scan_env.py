import sys
from pathlib import Path

p = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/_uboot/env.bin')
data = p.read_bytes()
print(f'file={p} size={len(data)} (0x{len(data):x})')


def ascii_dump(chunk: bytes) -> str:
    return ''.join(chr(b) if 0x20 <= b <= 0x7e else '.' for b in chunk)


def show(off, n=64):
    print(f'  0x{off:04x}: ' + ascii_dump(data[off:off + n]))


print('\n== head 96 bytes ==')
show(0, 96)

print('\n== bootdelay offsets ==')
hits = []
idx = 0
while True:
    i = data.find(b'bootdelay', idx)
    if i < 0:
        break
    hits.append(i)
    idx = i + 1
if not hits:
    print('  none')
for h in hits:
    print(f'  0x{h:04x} ({h})')

print('\n== both 32KB halves ==')
for name, off in (('half0', 0), ('half1', 0x8000)):
    seg = data[off:off + 0x8000]
    nonempty = sum(1 for b in seg if b not in (0x00, 0xFF))
    print(f'  {name} @0x{off:04x}: non-empty = {nonempty}')

print('\n== verdict ==')
if len(hits) >= 2 and hits[1] >= 0x4000:
    print('  -> redundant env (2 copies), single-copy corruption recoverable')
elif len(hits) == 1:
    print('  -> single env copy, no redundancy')
else:
    print('  -> cannot determine')

print('\n== tail @0x0300 ==')
show(0x300, 64)
