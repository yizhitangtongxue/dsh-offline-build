# DSH Offline Build

使用 GitHub Actions 免费构建一个可带入无互联网内网环境运行的 **DeepSeek Harness WebUI + dsh-web-ui 全家桶**。

## 上游来源

- DeepSeek Harness：<https://github.com/deepseek-ai/deepseek-harness>
- 多面板 WebUI：<https://github.com/zhu1090093659/dsh-web-ui>
- 聚合插件：`@linxin666/dsh-web-ui-all`

## 当前构建内容

每次 Actions 会同时生成两个版本：

1. **便携压缩包** `dsh-offline-linux-x64`：无需 Docker，解压后运行 `start.sh`；
2. **Docker 离线镜像** `dsh-offline-docker-linux-x64`：内网执行 `docker load` 后运行。

共同包含：

- Linux x86_64；
- Node.js 22 便携运行时；
- `@deepseek-ai/dsh@0.1.1-rc.2`；
- `@linxin666/dsh-web-ui-all@0.2.7`；
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
5. 等待两个任务完成真实 WebUI 启动测试；
6. 按需要下载 Artifact：
   - `dsh-offline-linux-x64`：便携压缩包；
   - `dsh-offline-docker-linux-x64`：Docker 离线镜像。

## 内网运行：便携压缩包

解压下载的 Artifact，再解压其中的 tar.gz：

```bash
sha256sum -c dsh-offline-linux-x64.tar.gz.sha256
mkdir dsh-offline
tar -xzf dsh-offline-linux-x64.tar.gz -C dsh-offline
cd dsh-offline
./verify.sh
./start.sh
```

浏览器访问：`http://127.0.0.1:3080`

允许可信内网其他设备访问：

```bash
DSH_HOST=0.0.0.0 DSH_PORT=3080 ./start.sh
```

请配合内网防火墙或反向代理认证。

## 内网运行：Docker 离线镜像

校验并导入镜像：

```bash
sha256sum -c dsh-offline-docker-linux-x64.tar.gz.sha256
gzip -dc dsh-offline-docker-linux-x64.tar.gz | docker load
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

也可以使用 Artifact 附带的 Compose 文件：

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
