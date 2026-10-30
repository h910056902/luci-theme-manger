import struct, glob, os, sys, hashlib

BASE = r"C:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build\kernel-veth"

def secs(path):
    d = open(path, "rb").read()
    is64 = d[4] == 2
    endi = "<" if d[5] == 1 else ">"
    e_shoff = struct.unpack_from(endi + "Q", d, 0x28)[0]
    e_shentsize = struct.unpack_from(endi + "H", d, 0x3A)[0]
    e_shnum = struct.unpack_from(endi + "H", d, 0x3C)[0]
    e_shstrndx = struct.unpack_from(endi + "H", d, 0x3E)[0]
    out = {}
    shstr_off = None
    rows = []
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        name, typ, flags, addr, offset, size, link, info, align, entsize = struct.unpack_from(endi + "IIQQQQIIQQ", d, off)
        rows.append((name, typ, offset, size, link))
    shstr_off = rows[e_shstrndx][2]
    for name, typ, offset, size, link in rows:
        end = d.find(b"\0", shstr_off + name)
        nm = d[shstr_off + name:end].decode()
        out[nm] = {"offset": offset, "size": size, "type": typ}
    return d, out

def modinfo(d, s):
    off = s[".modinfo"]["offset"]; size = s[".modinfo"]["size"]
    blob = d[off:off+size]
    fields = {}
    for part in blob.split(b"\0"):
        if b"=" in part:
            k, v = part.split(b"=", 1)
            fields[k.decode()] = v.decode(errors="replace")
    return fields

files = {
    "vendor_nf_nat": os.path.join(BASE, "nf_nat-vendor-6.12.94.ko"),
    "official_nf_nat": os.path.join(BASE, "nf_nat-official-6.12.94.ko"),
    "vendor_ip_tables": os.path.join(BASE, "ip_tables-vendor-6.12.94.ko"),
    "official_veth": os.path.join(BASE, "veth-official-6.12.94.ko"),
    "vanilla_veth": os.path.join(BASE, "veth-6.12.94.ko"),
    "official_veth_612103": os.path.join(BASE, "veth-6.12.103.ko"),
}
print(f"{'module':22s} {'this_module_size':>16s} {'vermagic':30s} {'srcversion':16s} {'size':>7s}")
for name, path in files.items():
    if not os.path.exists(path):
        print(f"{name:22s} MISSING {path}")
        continue
    d, s = secs(path)
    tm = s.get(".gnu.linkonce.this_module", {}).get("size", -1)
    mi = modinfo(d, s)
    print(f"{name:22s} {tm:>16d} {mi.get('vermagic','?'):30s} {mi.get('srcversion','?'):16s} {len(d):>7d}")

print()
print("== srcversion details ==")
for name in ["vendor_nf_nat", "official_nf_nat"]:
    d, s = secs(files[name]); mi = modinfo(d, s)
    print(name, {k: mi.get(k) for k in ("name","vermagic","srcversion","depends","retpoline","intree")})

print()
print("== byte diff official vs vendor nf_nat.ko ==")
a = open(files["vendor_nf_nat"], "rb").read()
b = open(files["official_nf_nat"], "rb").read()
print("sizes:", len(a), len(b))
if len(a) == len(b):
    diffs = [i for i in range(len(a)) if a[i] != b[i]]
    print("diff bytes:", len(diffs))
    if diffs:
        print("first diff offsets:", diffs[:20])
        print("last diff offsets:", diffs[-10:])
        # ranges
        ranges = []
        start = prev = diffs[0]
        for x in diffs[1:]:
            if x != prev + 1:
                ranges.append((start, prev)); start = x
            prev = x
        ranges.append((start, prev))
        print("diff ranges:", ranges[:20], "..." if len(ranges) > 20 else "")
else:
    print("size differs -> cannot byte-compare directly")
