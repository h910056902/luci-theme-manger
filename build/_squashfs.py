# -*- coding: utf-8 -*-
"""
极简 SquashFS 4.0 读取器（仅支持 gzip / xz / lzma 压缩）
用途：在 Windows 上直接列举 / 提取 OpenWrt 固件 rootfs 内的文件，不需要 unsquashfs。

用法：
    python _squashfs.py <rootfs.img> list [过滤子串]
    python _squashfs.py <rootfs.img> cat <绝对路径>
"""
import lzma
import struct
import sys
import zlib

SB_FMT = "<IIIIIHHHHHHQQQQQQQQ"
SB_SIZE = 96


class MetaRegion(object):
    """把一段元数据（inode 表 / 目录表）整体解压成连续字节流"""

    def __init__(self, f, start, end, comp):
        self.buf = bytearray()
        self.blocks = []  # (相对起始的块偏移, 在 buf 中的位置)
        self.comp = comp
        pos = start
        while pos < end:
            f.seek(pos)
            hdr = f.read(2)
            if len(hdr) < 2:
                break
            (v,) = struct.unpack("<H", hdr)
            size = v & 0x7FFF
            uncompressed = bool(v & 0x8000)
            data = f.read(size)
            self.blocks.append((pos - start, len(self.buf)))
            if uncompressed:
                self.buf.extend(data)
            else:
                self.buf.extend(decompress(data, comp))
            pos += 2 + size

    def at(self, block_rel, offset):
        for rel, out in self.blocks:
            if rel == block_rel:
                return out + offset
        raise ValueError("metadata block 0x%x 未找到" % block_rel)

    def read(self, idx, n):
        return bytes(self.buf[idx: idx + n])


def decompress(data, comp):
    if comp == 1:  # gzip
        return zlib.decompress(data)
    if comp == 4:  # xz
        return lzma.decompress(data, format=lzma.FORMAT_XZ)
    if comp == 2:  # lzma (legacy)
        return lzma.decompress(data, format=lzma.FORMAT_ALONE)
    raise NotImplementedError("压缩算法 %d 暂不支持" % comp)


class SquashFS(object):
    def __init__(self, path):
        self.f = open(path, "rb")
        sb = self.f.read(SB_SIZE)
        (self.magic, self.inodes, self.mkfs_time, self.block_size, self.fragments,
         self.comp, self.block_log, self.flags, self.no_ids, self.s_major,
         self.s_minor, self.root_inode, self.bytes_used, self.id_table,
         self.xattr_table, self.inode_table, self.dir_table,
         self.frag_table, self.export_table) = struct.unpack(SB_FMT, sb)
        if self.magic != 0x73717368:
            raise ValueError("不是 squashfs（magic=0x%08x）" % self.magic)
        end = self.frag_table or self.bytes_used
        self.inode_region = MetaRegion(self.f, self.inode_table, self.dir_table, self.comp)
        self.dir_region = MetaRegion(self.f, self.dir_table, end, self.comp)

    # ---------- inode ----------
    def _inode(self, ref):
        block_rel = ref >> 16
        offset = ref & 0xFFFF
        idx = self.inode_region.at(block_rel, offset)
        buf = self.inode_region.buf
        itype, mode, uid, gid, mtime, ino = struct.unpack_from("<HHHHII", buf, idx)
        p = idx + 16
        d = {"type": itype, "mode": mode, "inode": ino, "path": None}
        if itype in (1, 8):  # 目录
            if itype == 1:
                start_block, nlink, file_size, off, parent = struct.unpack_from("<IIHHI", buf, p)
            else:
                nlink, file_size, start_block, parent, i_count, off, xattr = struct.unpack_from(
                    "<IIIIHHI", buf, p)
            d.update(kind="dir", start=start_block, size=file_size, off=off)
        elif itype in (2, 9):  # 普通文件
            if itype == 2:
                blocks_start, fragment, block_offset, file_size = struct.unpack_from("<IIII", buf, p)
                p += 16
            else:
                blocks_start, file_size, sparse, nlink, fragment, block_offset, xattr = struct.unpack_from(
                    "<QQQIIII", buf, p)
                p += 40
            nb = file_size // self.block_size if fragment == 0xFFFFFFFF else file_size // self.block_size
            sizes = list(struct.unpack_from("<%dI" % nb, buf, p)) if nb else []
            d.update(kind="file", blocks_start=blocks_start, fragment=fragment,
                     block_offset=block_offset, size=file_size, sizes=sizes)
        elif itype in (3, 10):  # 符号链接
            nlink, tsize = struct.unpack_from("<II", buf, p)
            target = self.inode_region.read(p + 8, tsize).decode("utf-8", "replace")
            d.update(kind="link", target=target)
        else:
            d.update(kind="other")
        return d

    # ---------- directory ----------
    def _entries(self, inode):
        idx = self.dir_region.at(inode["start"], inode["off"])
        buf = self.dir_region.buf
        end = min(idx + inode["size"], len(buf))
        out = []
        while idx < end:
            count, start_block, base_inode = struct.unpack_from("<III", buf, idx)
            idx += 12
            for _ in range(count + 1):
                off, ino_delta, etype, name_size = struct.unpack_from("<HhHH", buf, idx)
                idx += 8
                name = bytes(buf[idx: idx + name_size + 1]).decode("utf-8", "replace")
                idx += name_size + 1
                out.append((name, (start_block << 16) | off, etype))
        return out

    def walk(self, ref=None, prefix="", depth=0):
        ref = self.root_inode if ref is None else ref
        inode = self._inode(ref)
        if inode["kind"] != "dir":
            return
        try:
            ents = self._entries(inode)
        except Exception as e:
            info = dict((k, v) for k, v in inode.items() if k != "sizes")
            sys.stderr.write("!! 目录解析失败 %s : %s  inode=%s\n" % (prefix or "/", e, info))
            return
        for name, child_ref, etype in ents:
            path = prefix + "/" + name if prefix else "/" + name
            yield path, child_ref, etype
            if etype == 1 and depth < 40:
                for item in self.walk(child_ref, path, depth + 1):
                    yield item

    # ---------- 取文件内容 ----------
    def read_file(self, ref):
        inode = self._inode(ref)
        if inode["kind"] != "file":
            return b""
        f = self.f
        out = bytearray()
        pos = inode["blocks_start"]
        for sz in inode["sizes"]:
            raw_sz = sz & 0xFFFFFF
            if raw_sz == 0:
                out.extend(b"\x00" * self.block_size)
                continue
            f.seek(pos)
            data = f.read(raw_sz)
            pos += raw_sz
            out.extend(data if (sz & 0x1000000) else decompress(data, self.comp))
        if inode["fragment"] != 0xFFFFFFFF:
            frag = self._fragment(inode["fragment"])
            f.seek(frag[0])
            raw = f.read(frag[1])
            data = decompress(raw, self.comp) if frag[2] != 0 else raw
            out.extend(data[inode["block_offset"]:])
        return bytes(out[: inode["size"]])

    def _fragment(self, idx):
        f = self.f
        f.seek(self.frag_table)
        ptr = struct.unpack("<Q", f.read(8))[0]
        f.seek(ptr)
        buf = f.read(16 * (idx + 1))
        start, size, unused = struct.unpack_from("<QII", buf, 16 * idx)
        return start, size & 0xFFFFFF, size & 0x1000000


def main():
    path = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "list"
    fs = SquashFS(path)
    print("squashfs %d.%d  block=%d  inodes=%d  comp=%d  bytes_used=%.1f MB" % (
        fs.s_major, fs.s_minor, fs.block_size, fs.inodes, fs.comp, fs.bytes_used / 1048576.0))
    print("tables: inode=0x%x dir=0x%x frag=0x%x export=0x%x id=0x%x xattr=0x%x" % (
        fs.inode_table, fs.dir_table, fs.frag_table, fs.export_table, fs.id_table, fs.xattr_table))
    print("meta  : inode_blocks=%d dir_blocks=%d  inode_buf=%d dir_buf=%d" % (
        len(fs.inode_region.blocks), len(fs.dir_region.blocks),
        len(fs.inode_region.buf), len(fs.dir_region.buf)))
    ri = fs._inode(fs.root_inode)
    print("root  :", {k: v for k, v in ri.items() if k != "sizes"})

    if mode == "list":
        needle = sys.argv[3] if len(sys.argv) > 3 else ""
        n = 0
        for p, ref, etype in fs.walk():
            if needle and needle not in p:
                continue
            n += 1
            print("%s%s" % (p, "/" if etype == 1 else ""))
        print("---- 共 %d 项 ----" % n)
    elif mode == "cat":
        target = sys.argv[3]
        for p, ref, etype in fs.walk():
            if p == target:
                sys.stdout.buffer.write(fs.read_file(ref))
                return
        print("未找到:", target)
    else:
        print("用法: _squashfs.py <img> list [过滤] | cat <路径>")


if __name__ == "__main__":
    main()
