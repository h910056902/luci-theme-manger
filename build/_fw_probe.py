# -*- coding: utf-8 -*-
"""固件格式识别 + 关键字扫描（只读，不修改原文件）"""
import os
import sys

PATH = sys.argv[1] if len(sys.argv) > 1 else r"C:\Users\91005\xwechat_files\wxid_zxntpxuhkfj022_ff51\msg\file\2026-10\Mwrt-c2000ultra-tf-1145-24-20261016(2).bin"

size = os.path.getsize(PATH)
print("file  :", PATH)
print("size  : %d bytes (%.2f MB)" % (size, size / 1048576.0))

with open(PATH, "rb") as f:
    head = f.read(256)

print("head  :", head[:64].hex(" "))
print("ascii :", "".join(chr(c) if 32 <= c < 127 else "." for c in head[:64]))

MAGICS = [
    (b"hsqs", "squashfs (LE)"),
    (b"sqsh", "squashfs (BE)"),
    (b"\x1f\x8b", "gzip"),
    (b"BZh", "bzip2"),
    (b"\xfd7zXZ", "xz"),
    (b"PK\x03\x04", "zip"),
    (b"ANDROID!", "android boot"),
    (b"\x27\x05\x19\x56", "uImage"),
    (b"\xd0\x0d\xfe\xed", "dtb"),
    (b"UBI#", "ubi"),
]
print("magic :", end=" ")
hit = False
for sig, name in MAGICS:
    if head.startswith(sig):
        print(name, end=" ")
        hit = True
if not hit:
    print("(未识别，继续看偏移)", end="")
print()

# 在头部 1MB 里找 ustar / squashfs 偏移
with open(PATH, "rb") as f:
    blob = f.read(1024 * 1024)
for sig, name in [(b"hsqs", "squashfs"), (b"ustar", "tar"), (b"\x1f\x8b\x08", "gzip"), (b"UBI#", "ubi")]:
    off = blob.find(sig)
    if off >= 0:
        print("offset:", name, "->", off)

MARKS = [
    b"openwrt-luci-8080",
    b"nradio_8080_sysauth",
    b"mwrt-wifi",
    b"mwrt-svc",
    b"/overlay/nradio-apps",
    b"luci-static",
    b"nradio_cellular",
    b"kp8080",
    b"squashfs",
    b"rootfs",
]
print("\n== 关键字扫描 ==")
found = {m: [] for m in MARKS}
chunk = 4 * 1024 * 1024
pos = 0
with open(PATH, "rb") as f:
    while True:
        buf = f.read(chunk)
        if not buf:
            break
        for m in MARKS:
            if len(found[m]) >= 5:
                continue
            start = 0
            while len(found[m]) < 5:
                i = buf.find(m, start)
                if i < 0:
                    break
                found[m].append(pos + i)
                start = i + 1
        pos += len(buf)

for m in MARKS:
    locs = found[m]
    name = m.decode("ascii", "replace")
    if locs:
        print("  %-24s %d 处  %s" % (name, len(locs), [hex(x) for x in locs]))
    else:
        print("  %-24s 未发现" % name)
