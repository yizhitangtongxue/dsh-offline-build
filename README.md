# DSH Offline Build

使用 GitHub Actions 免费构建一个可带入无互联网内网环境运行的 **DeepSeek Harness WebUI + dsh-web-ui 全家桶**。

## 上游来源

- DeepSeek Harness：<https://github.com/deepseek-ai/deepseek-harness>
- 多面板 WebUI：<https://github.com/zhu1090093659/dsh-web-ui>
- 聚合插件：`@linxin666/dsh-web-ui-all`

## 当前构建内容

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
5. 等待构建与真实 WebUI 启动测试通过；
6. 下载 Artifact：`dsh-offline-linux-x64`。

## 内网运行

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

## 安装其他插件

最可靠的离线方式是在 Actions 的 `extra_plugins` 输入框中预装。GitHub runner 会联网下载依赖、构建原生模块，再一并放入离线包。

对于依赖已经齐全的本地插件 tgz，也可以在内网运行：

```bash
./install-plugin-offline.sh /media/usb/plugin.tgz
```

详细说明见构建产物内的 `README.md`。
