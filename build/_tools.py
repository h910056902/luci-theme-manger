# -*- coding: utf-8 -*-
"""检查可用的解包工具与 Python 模块"""
import os
import shutil
import subprocess

print("== 可执行文件 ==")
for name in ["7z", "7za", "unsquashfs", "wsl", "tar", "bsdtar", "docker"]:
    p = shutil.which(name)
    print("  %-12s %s" % (name, p or "缺失"))

print("== 常见安装路径 ==")
for p in [
    r"C:\Program Files\7-Zip\7z.exe",
    r"C:\Program Files (x86)\7-Zip\7z.exe",
    r"C:\Program Files\NanaZip\NanaZip.exe",
    r"C:\Program Files\Bandizip\Bandizip.exe",
    r"C:\Program Files\WinRAR\WinRAR.exe",
    r"C:\Program Files (x86)\WinRAR\WinRAR.exe",
]:
    if os.path.exists(p):
        print("  存在:", p)

print("== Python 模块 ==")
for m in ["lzma", "zlib", "zstandard", "bz2", "lzo"]:
    try:
        __import__(m)
        print("  %-12s OK" % m)
    except Exception as e:
        print("  %-12s 缺失" % m)

print("== WSL 发行版 ==")
try:
    r = subprocess.run(["wsl", "-l", "-q"], capture_output=True, timeout=15)
    out = r.stdout.decode("utf-16-le", "ignore") if r.stdout[:2] == b"\xff\xfe" else r.stdout.decode("utf-8", "ignore")
    print("  ", out.strip() or "(空)")
except Exception as e:
    print("  WSL 不可用:", e)
