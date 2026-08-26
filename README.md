# DSH Offline Build

使用 GitHub Actions 免费构建一个可带入无互联网内网环境运行的 **DeepSeek Harness WebUI + dsh-web-ui 全家桶**。

## 上游来源

- DeepSeek Harness：<https://github.com/deepseek-ai/deepseek-harness>
- 多面板 WebUI：<https://github.com/zhu1090093659/dsh-web-ui>
- 聚合插件：`@linxin666/dsh-web-ui-all`

## 当前构建内容

每次 Actions 会同时生成五个版本：

1. **x86_64 便携压缩包** `dsh-offline-linux-x64`：无需 Docker，解压后运行 `start.sh`；
2. **ARM64 便携压缩包** `dsh-offline-linux-arm64`：适用于 ARM64 Linux，解压后运行 `start.sh`；
3. **x86_64 Docker 离线镜像** `dsh-offline-docker-linux-x64`；
4. **ARM64 Docker 离线镜像** `dsh-offline-docker-linux-arm64`；
5. **Windows x86_64 便携包** `dsh-offline-windows-x64`：在 Windows 10/11 解压后运行 `verify.cmd` 和 `start.cmd`。

ARM64 版本由 GitHub Actions 的原生 `ubuntu-24.04-arm` Runner 构建，在真实 ARM64 CPU 上重新安装、编译原生依赖并启动 WebUI 验证，不使用 QEMU，也不是把 x86_64 包简单改名。

共同包含：

- Linux x86_64 或 ARM64；
- Node.js 22 便携运行时；
- `@deepseek-ai/dsh@0.1.1-rc.2`；
- `@linxin666/dsh-web-ui-all@0.3.5`；
- 任务看板、Git 图谱、插件管理器、右侧栏、皮肤中心、远程 UI、SSH 等聚合插件；
- 已构建的原生依赖；
- 离线启动、验证和本地插件安装脚本。

## 安全

本仓库、workflow 和构建产物均不写入 GitHub PAT、DeepSeek API Key 或其他用户凭据。GitHub Actions 检出仓库时使用平台临时 `GITHUB_TOKEN`，该临时令牌不会被复制到产物。

模型 API Key 只在内网运行后，通过 WebUI 的“设置 → 模型”手动输入。

## 构建

1. 打开仓库的 **Actions**；
2. 选择 **Build DSH Offline Bundle**；
3. 点击 **Run workflow**；
4. 可在 `extra_plugins` 中填写希望预装的额外 npm 插件，一行一个；
5. 等待四个构建任务完成真实 WebUI 启动测试；
6. 打开仓库的 **Releases → Latest**，按机器架构和运行方式下载：
   - `dsh-offline-linux-x64`：x86_64 便携压缩包；
   - `dsh-offline-linux-arm64`：ARM64 便携压缩包；
   - `dsh-offline-docker-linux-x64`：x86_64 Docker 离线镜像；
   - `dsh-offline-docker-linux-arm64`：ARM64 Docker 离线镜像；
   - `dsh-offline-windows-x64`：Windows x86_64 非 Docker 便携包。

大型离线包直接上传到 GitHub Release，不使用 Actions Artifact 存储。只有五个平台全部构建和冒烟测试成功，Draft Release 才会正式发布；任一平台失败都会删除草稿。发布成功后，workflow 还会清空仓库中遗留的全部 Actions Artifact，避免产生 Artifact 存储费用。

## 自动跟踪上游更新

`Sync Upstream DSH Versions` workflow 每小时查询一次 npm 官方 Registry 的 `latest` 标签：

- `@deepseek-ai/dsh`；
- `@linxin666/dsh-web-ui-all`。

发现新版本时，GitHub Runner 会先执行 Linux Canary：真实安装 DSH 与 WebUI 候选版、加载核心插件并启动 HTTP 服务。Canary 通过后，`github-actions[bot]` 才会同时更新普通版本配置、运行时 `package.json`、Dockerfile 和本文档中的固定版本号，提交到 `main`，然后自动触发所有 Linux、ARM64、Windows 与 Docker 离线包重建。候选版安装或启动失败时会被拒绝，不会污染 `main`；版本没有变化时也不会提交或重复构建。

需要立即检查时，可在 Actions 中手动运行 **Sync Upstream DSH Versions**。构建仍使用提交到仓库的固定版本号，因此每个历史提交都可复现。

## 内网运行：便携压缩包

从 GitHub Release 下载并解压 tar.gz：

```bash
sha256sum -c dsh-offline-linux-x64.tar.gz.sha256
mkdir dsh-offline
tar -xzf dsh-offline-linux-x64.tar.gz -C dsh-offline
cd dsh-offline
./verify.sh
./start.sh
```

浏览器访问：`http://127.0.0.1:3080`

官方 DSH 为防止远程代码执行，便携版只允许监听 `127.0.0.1`，不能直接设置 `DSH_HOST=0.0.0.0`。需要可信内网其他设备访问时，请使用下方 Docker 版；Docker 镜像内置 Nginx，将外部 `0.0.0.0:3080` 安全转发到只监听本地的 DSH。

## Windows x86_64 非 Docker 版

从 GitHub Release 下载 Windows 文件：

```text
dsh-offline-windows-x64.7z
dsh-offline-windows-x64.7z.sha256
```

使用 7-Zip 解压到短路径，例如 `C:\dsh`，然后依次双击：

```text
verify.cmd
start.cmd
```

浏览器访问：`http://127.0.0.1:3080`。

也可以指定工作目录和端口；推荐调用 `start.cmd`，它只对本次进程使用 `ExecutionPolicy Bypass`，不会修改系统策略：

```powershell
.\start.cmd -Workspace 'D:\projects' -Port 3080
```

Windows 包内已包含 `node.exe`、DSH、pnpm、WebUI 插件及 Windows 原生依赖，不需要另外安装 Node.js。

## 内网运行：Docker 离线镜像

校验并导入镜像。x86_64 使用：

```bash
sha256sum -c dsh-offline-docker-linux-x64.tar.gz.sha256
gzip -dc dsh-offline-docker-linux-x64.tar.gz | docker load
```

ARM64 使用：

```bash
sha256sum -c dsh-offline-docker-linux-arm64.tar.gz.sha256
gzip -dc dsh-offline-docker-linux-arm64.tar.gz | docker load
docker tag dsh-offline-webui:arm64 dsh-offline-webui:latest
```

挂载一个宿主机目录到容器的 `/workspace`：

```bash
mkdir -p /srv/dsh-workspace

docker run -d \
  --name dsh-webui \
  --restart unless-stopped \
  -p 3080:3080 \
  -v /srv/dsh-workspace:/workspace \
  -v dsh-data:/data \
  dsh-offline-webui:latest
```

- `/srv/dsh-workspace`：你希望 DSH 读取和修改的宿主机目录，可换成任意绝对路径；
- `/workspace`：容器内工作区；
- `dsh-data:/data`：持久保存模型配置、会话和插件 profile；
- 容器内由 Nginx 监听 `0.0.0.0:3080`，再转发给只监听 `127.0.0.1:3081` 的 DSH；
- WebUI：`http://内网服务器IP:3080`。

查看日志：

```bash
docker logs -f dsh-webui
```

停止与再次启动：

```bash
docker stop dsh-webui
docker start dsh-webui
```

也可以使用同一 GitHub Release 附带的 Compose 文件：

```bash
mkdir -p workspace
docker compose -f docker-compose.offline.yml up -d
```

Compose 默认挂载当前目录下的 `./workspace` 到容器 `/workspace`。

## 安装其他插件

最可靠的离线方式是在 Actions 的 `extra_plugins` 输入框中预装。GitHub runner 会联网下载依赖、构建原生模块，再一并放入离线包。

对于依赖已经齐全的本地插件 tgz，也可以在内网运行：

```bash
./install-plugin-offline.sh /media/usb/plugin.tgz
```

详细说明见构建产物内的 `README.md`。
