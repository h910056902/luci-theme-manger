# luci-theme-manager

NRadio HC-WT9500 / OpenWrt 21.02 / 8080 端口 LuCI 实例的**完整源码工程**。

## 用 IDEA 直接打开

- **IntelliJ IDEA / WebStorm / PhpStorm**：`File → Open`，选择本文件夹 `luci-theme-manager`
- **VS Code / Cursor / Trae**：`File → Open Folder`，选择本文件夹
- 无需解压、无需安装依赖；`.editorconfig` 已配置 UTF-8 + LF

## 内容

- `usr/lib/lua/luci/view/` — 8080 实例私有 LuCI 视图
- `www/cgi-bin/luci` — 8080 主 CGI 入口
- `www/cgi-bin/mwrt-wifi` — 无线快速设置私有接口
- `www/luci-static/bootstrap/` — Argon 主题 CSS/JS（含 `mwrt-*` 自定义样式）
- `www/luci-static/{argon,istore,quickstart,...}` — 原符号链接目标已实体化，可直接浏览
- `README-IDE.md` — 目录结构、路由器路径对应、部署注意事项

## 注意

本项目是 8080 实例**私有覆盖层**，不包含共享 LuCI 系统文件（`/usr/lib/lua/luci`）和路由器 `/etc/config` 配置。部署时 `cgi-bin/luci`、`cgi-bin/mwrt-wifi` 需要 `755` 权限。
