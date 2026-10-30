import struct
import sys
import re

KO = r"C:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build\kernel-veth\veth-6.12.103.ko"
KS = r"C:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build\kernel-veth\kallsyms.txt"
OUT = r"C:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build\kernel-veth\veth-6.12.94.ko"

data = bytearray(open(KO, "rb").read())
assert data[:4] == b"\x7fELF", "not ELF"
is64 = data[4] == 2
endi = "<" if data[5] == 1 else ">"
(e_shoff,) = struct.unpack_from(endi + "Q", data, 0x28)
(e_shentsize,) = struct.unpack_from(endi + "H", data, 0x3A)
(e_shnum,) = struct.unpack_from(endi + "H", data, 0x3C)
(e_shstrndx,) = struct.unpack_from(endi + "H", data, 0x3E)

# section headers
secs = []
for i in range(e_shnum):
    off = e_shoff + i * e_shentsize
    name, typ, flags, addr, offset, size, link, info, align, entsize = struct.unpack_from(
        endi + "IIQQQQIIQQ", data, off)
    secs.append(dict(name=name, type=typ, offset=offset, size=size, link=link, entsize=entsize))

shstr = secs[e_shstrndx]
def sname(idx):
    end = data.find(b"\0", shstr["offset"] + idx)
    return data[shstr["offset"] + idx:end].decode()

for s in secs:
    s["sname"] = sname(s["name"])

symtab = next((s for s in secs if s["type"] == 2), None)  # SHT_SYMTAB
assert symtab, "no symtab"
strtab = secs[symtab["link"]]
und = []
defined = []
for i in range(symtab["size"] // symtab["entsize"]):
    off = symtab["offset"] + i * symtab["entsize"]
    st_name, st_info, st_other, st_shndx, st_value, st_size = struct.unpack_from(endi + "IBBHQQ", data, off)
    if st_name == 0:
        continue
    end = data.find(b"\0", strtab["offset"] + st_name)
    nm = data[strtab["offset"] + st_name:end].decode(errors="replace")
    if st_shndx == 0:
        und.append(nm)
    else:
        defined.append(nm)

# kallsyms names
ks = set()
missing_addr = set()
with open(KS, "r", errors="replace") as f:
    for line in f:
        parts = line.split()
        if len(parts) >= 3:
            ks.add(parts[2])
        elif len(parts) == 2:
            ks.add(parts[1])

print("undefined symbols:", len(und))
unresolved = sorted(set(und) - ks)
print("NOT in /proc/kallsyms:", len(unresolved))
for u in unresolved:
    print("   ", u)
print()
print("defined symbols sample:", defined[:8])

# patch vermagic
old = b"vermagic=6.12.103 SMP mod_unload aarch64\0"
new = b"vermagic=6.12.94 SMP mod_unload aarch64\0"
print("old len", len(old), "new len", len(new))
occ = data.count(old)
print("vermagic occurrences:", occ)
if occ != 1:
    # try looser search
    idxs = [m.start() for m in re.finditer(rb"vermagic=[0-9][^\x00]*", data)]
    print("loose vermagic found at:", idxs, [data[i:i+50] for i in idxs])
    sys.exit(1)
idx = data.find(old)
data[idx:idx + len(new)] = new  # new is 1 byte shorter; trailing old byte left as garbage after NUL
open(OUT, "wb").write(data)
print("patched ->", OUT)
# verify
d2 = open(OUT, "rb").read()
i2 = d2.find(b"vermagic=")
print("new vermagic:", d2[i2:d2.find(b"\0", i2)].decode())
