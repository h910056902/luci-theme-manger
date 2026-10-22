# luci-theme-manager

> NRadio 8080 LuCI 项目（IDE 工程包）

> 来源：NRadio HC-WT9500 / OpenWrt 21.02-SNAPSHOT / LuCI git-26.253.32058
> 项目名称：`luci-theme-manager`
> 范围：`/overlay/nradio-apps/openwrt-luci-8080`（8080 端口独立 LuCI 实例私有目录）
> 生成时间：2026-10-20

这是一个**可直接用 IDE 打开/编辑的源码工程包**，不是固件，也不是可执行安装包。

## 1. 直接用 IDE 打开

1. 解压 `luci-theme-manager.zip`。
2. 打开解压后的 `luci-theme-manager` 文件夹：
   - **IntelliJ IDEA / PhpStorm / WebStorm**：`File → Open`，选择该文件夹（不要选单个文件）。
   - **VS Code / Cursor / Trae**：`File → Open Folder`。
   - **Sublime / Notepad++**：直接打开文件夹或拖入。
3. 文件编码统一为 **UTF-8**（`.editorconfig` 已配置），换行符为 LF。
4. LuCI 是 Lua + HTML 模板 + CSS/JS，没有 npm/Maven 构建步骤；安装 Lua 语法插件即可获得高亮。

## 2. 目录结构

```text
luci-theme-manager/
├── usr/lib/lua/luci/view/        # 8080 实例私有 LuCI 视图（htm 模板）
│   ├── admin_status/             # 首页 / 蜂窝 / 设备 / 短信 / 登录页
│   ├── quickstart/               # quickstart 首页与向导
│   ├── istorerouter/             # iStoreRouter 壳
│   ├── ttyd/                     # 终端页
│   └── themes/bootstrap/         # Argon 主题 header（含侧栏/首页/无线增强 JS）
├── www/
│   ├── cgi-bin/
│   │   ├── luci                  # 8080 主 CGI 入口（Lua）
│   │   └── mwrt-wifi             # 无线快速设置私有接口（Lua，需 755）
│   ├── luci-static/bootstrap/    # 主题 CSS/JS 资源（mwrt-* 自定义样式）
│   ├── logo/  fontawesome/  router3d/
│   └── luci-static/{argon,iform,istore,istorerouter,linkeasefile,natpierce,nradio,quickstart,resources}
│                                 # 原为指向 /www/luci-static 的符号链接，已复制为实体目录
├── .editorconfig
└── README-IDE.md
```

## 3. 与路由器路径对应

| 工程内路径 | 路由器路径 |
|---|---|
| `usr/lib/lua/luci/view/...` | `/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/...` |
| `www/cgi-bin/luci` | `/overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci` |
| `www/cgi-bin/mwrt-wifi` | `/overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/mwrt-wifi` |
| `www/luci-static/...` | `/overlay/nradio-apps/openwrt-luci-8080/www/luci-static/...` |
| `www/logo`、`fontawesome`、`router3d` | 同名路径 |

## 4. 编辑与部署注意

- 不要修改 `/usr/lib/lua/luci` 下的共享 LuCI 系统文件；本项目只包含 8080 实例私有覆盖层。
- 部署时保持文件编码 UTF-8、LF；`cgi-bin/luci`、`cgi-bin/mwrt-wifi` 需要 `755` 权限。
- `www/luci-static/{argon,iform,istore,...}` 在路由器上是指向 `/www/luci-static` 的符号链接，本工程为方便 Windows/IDE 阅读已复制为实体目录；**不要直接把实体目录覆盖回路由器**（会破坏符号链接），部署前请按需只同步 `bootstrap` 和自定义文件。
- 包内已排除 `theme-backup-*`、`*.bak*` 等历史备份；需要完整快照请使用同一目录下的 `luci-theme-manager-full.tar.gz`。
- `mwrt-wifi` 会写 `/etc/config/wireless` 并可执行 `wifi reload`，仅限内网管理，请勿暴露到公网。

## 5. 相关文件

| 文件 | 用途 |
|---|---|
| `luci-theme-manager.zip` | **推荐**：IDE 工程包（干净、无历史备份、符号链接已实体化） |
| `luci-theme-manager-full.tar.gz` | 路由器上 8080 私有目录的完整快照（含历史备份与符号链接，用于精确还原/对照） |
| `nradio-8080-theme.zip` | 仅本主题定制交付包（改动文件 + 报告 + 截图） |
