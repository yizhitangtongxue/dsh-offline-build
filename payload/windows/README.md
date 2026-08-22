# DeepSeek Harness Windows 离线版

目标平台：**Windows 10/11 x86_64（64 位）**。

包内包含 Node.js、pnpm、DeepSeek Harness、`dsh-web-ui-all` 和已构建的 Windows 原生依赖。无需在内网电脑安装 Node.js，也无需联网。

## 验证

双击：

```text
verify.cmd
```

或在 PowerShell 中：

```powershell
.\verify.ps1
```

## 启动

双击：

```text
start.cmd
```

默认访问：

```text
http://127.0.0.1:3080
```

指定工作目录和端口：

```powershell
.\start.ps1 -Workspace 'D:\projects' -Port 3080
```

为了防止远程代码执行，DSH 只监听 `127.0.0.1`。Windows 便携版默认只供本机浏览器访问。

## 模型凭据

本包不包含 GitHub Token、DeepSeek API Key 或其他凭据。启动后在 WebUI 的“设置 → 模型”中私下输入。

## 离线安装插件

插件及其依赖必须已包含在本地 `.tgz` 或当前离线存储中：

```powershell
.\install-plugin-offline.ps1 'D:\packages\plugin.tgz'
```

依赖复杂的插件建议在 GitHub Actions 的 `extra_plugins` 输入中预装后重新构建。

## 注意事项

- 建议解压到短路径，例如 `C:\dsh`；
- 不要直接在压缩包内运行；
- Windows Defender 首次扫描大量 Node.js 文件时可能需要一些时间；
- 配置和会话保存在解压目录的 `dsh-home` 中。
