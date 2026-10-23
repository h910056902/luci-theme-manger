# -*- coding: utf-8 -*-
"""用 PySquashfsImage 枚举 / 提取 OpenWrt 固件 rootfs"""
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

from PySquashfsImage import SquashFsImage

IMG = sys.argv[1]
MODE = sys.argv[2] if len(sys.argv) > 2 else "list"
ARG = sys.argv[3] if len(sys.argv) > 3 else ""


def walk(node, prefix="", depth=0):
    if depth > 40:
        return
    try:
        children = list(node.iterdir())
    except Exception as e:
        sys.stderr.write("!! 目录读取失败 %s : %s\n" % (prefix or "/", e))
        return
    for ch in children:
        p = (prefix + "/" + ch.name) if prefix else "/" + ch.name
        yield p, ch
        if ch.is_dir:
            for item in walk(ch, p, depth + 1):
                yield item


def read_node(node):
    if hasattr(node, "riter"):
        return b"".join(node.riter())
    if hasattr(node, "read_bytes"):
        return node.read_bytes()
    raise RuntimeError("无读取接口")


img = SquashFsImage.from_file(IMG)

if MODE == "list":
    n = 0
    for p, node in walk(img.root):
        if ARG and ARG not in p:
            continue
        n += 1
        print(p + ("/" if node.is_dir else ""))
    print("---- %d ----" % n)

elif MODE == "dump":
    for p, node in walk(img.root):
        if p == ARG:
            sys.stdout.buffer.write(read_node(node))
            break
    else:
        print("未找到", ARG)

elif MODE == "save":
    # save <镜像内路径> <本地路径>
    src, dst = sys.argv[3], sys.argv[4]
    for p, node in walk(img.root):
        if p == src:
            data = read_node(node)
            with open(dst, "wb") as f:
                f.write(data)
            print("saved", len(data), "bytes ->", dst)
            break
    else:
        print("未找到", src)
