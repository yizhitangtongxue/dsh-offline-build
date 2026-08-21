# DeepSeek Harness 离线包使用说明

本产物由 GitHub Actions 构建，目标平台为 **Linux x86_64**。包内已包含：

- Node.js 22 运行时；
- DeepSeek Harness 官方 WebUI；
- `zhu1090093659/dsh-web-ui` 对应的聚合包 `@linxin666/dsh-web-ui-all`；
- 任务看板、Git 图谱、插件管理器、右侧栏、皮肤中心等全部聚合插件；
- 当前 profile 的完整依赖与原生模块；
- 本地离线插件安装脚本。

## 安全说明

构建过程及产物中**不包含 GitHub Token、DeepSeek API Key 或其他凭据**。请在内网启动后，通过 WebUI 的“设置 → 模型”手动输入模型 Key。

## 启动

```bash
chmod +x start.sh bin/node bin/pnpm install-plugin-offline.sh
./start.sh
```

默认地址：`http://127.0.0.1:3080`

自定义：

```bash
DSH_HOST=0.0.0.0 DSH_PORT=3080 DSH_WORKSPACE=/path/to/project ./start.sh
```

当绑定 `0.0.0.0` 时，请只在可信内网使用，并配置防火墙或反向代理认证。

## 离线安装其他插件

### 推荐方式：GitHub 构建阶段预装

手动运行 Actions 时，在 `extra_plugins` 输入框填写 npm 插件包，一行一个，例如：

```text
some-dsh-plugin@1.2.3
another-plugin@0.4.0
```

GitHub 会联网安装、构建原生依赖并一起打包，内网无需安装。

### 内网安装本地 tgz

```bash
./install-plugin-offline.sh /media/usb/plugin.tgz
```

插件 tgz 的外部依赖必须已经存在于包内的 pnpm 存储中，否则无网环境无法补齐。依赖复杂的插件应使用上面的 GitHub 预装方式。

## 验证

```bash
./verify.sh
```

成功时应看到：CLI 可执行、profile 包含 `@linxin666/dsh-web-ui-all`、关键插件配置存在。
