# 本地启动指南

本文档记录如何在本地启动 `claude-code-local`，并避免与系统全局安装的 `claude` 命令冲突。

---

## 环境要求

| 工具 | 说明 |
|------|------|
| `bun` | 构建和运行时，版本不限 |
| `npm` | 用于安装依赖（bun install 不可用时的备选） |
| `node` | >= 18.0.0 |

检查是否已安装：

```bash
bun --version
npm --version
node --version
```

---

## 本地环境配置

项目根目录下有一个 `.env.claude.local` 文件，**不提交到 git**（已在 `.gitignore` 中排除）。

该文件包含三个关键环境变量：

```bash
# .env.claude.local
ANTHROPIC_API_KEY='<你的 API Key>'
ANTHROPIC_BASE_URL='https://api.longcat.chat/anthropic'   # 自定义 API 代理地址
ANTHROPIC_MODEL='LongCat-Flash-Thinking'                   # 使用的模型名称
```

- **`ANTHROPIC_BASE_URL`**：指向自定义 API 代理，而非 Anthropic 官方 `https://api.anthropic.com`。
- **`ANTHROPIC_MODEL`**：覆盖默认模型，使用代理服务提供的模型。
- **`ANTHROPIC_API_KEY`**：对应代理服务的 API Key，与官方 Key 格式不同（`ak_` 前缀）。

如果 `.env.claude.local` 不存在，`local-claude.sh` 会自动创建一个包含上述默认值的文件。

---

## 启动方式

### 方式一：子 Shell 隔离（推荐，不影响全局环境）

```bash
bash local-claude.sh
```

脚本会：
1. 检查并安装依赖（`node_modules/`）
2. 检查并构建 `cli.js`（若源码有变动则自动重新构建）
3. 确保 `.env.claude.local` 存在
4. 在 `.local/bin/claude` 写入一个包装脚本（wrapper）
5. 启动一个新的子 Shell，并将 `.local/bin` 置于 `PATH` 最前面

在子 Shell 中，`claude` 命令指向本地版本，退出子 Shell 后恢复原有全局 `claude`：

```bash
# 进入子 Shell 后验证
which claude
# 输出应为：/path/to/claude-code-local/.local/bin/claude

claude --version
# 退出子 Shell
exit
```

---

### 方式二：在当前 Shell 中激活（临时，不推荐长期使用）

```bash
source local-claude.sh
```

使用 `source`（或 `.`）执行脚本，会在**当前 Shell** 中修改 `PATH`，而不是启动子 Shell。
关闭终端或新开 Tab 后失效，不影响其他终端会话。

```bash
# 激活后验证
which claude
# 输出应为：/path/to/claude-code-local/.local/bin/claude
```

---

### 方式三：直接用 bun 运行（最轻量）

无需任何 PATH 操作，直接调用：

```bash
cd /Users/saiph/Downloads/claude-code-local

# 手动加载环境变量后运行
set -a && source .env.claude.local && set +a
bun cli.js
```

或者单行：

```bash
env $(grep -v '^#' /Users/saiph/Downloads/claude-code-local/.env.claude.local | xargs) bun /Users/saiph/Downloads/claude-code-local/cli.js
```

---

## 防止与全局 claude 冲突

### 冲突原理

系统全局安装的 `claude`（通常位于 `/usr/local/bin/claude` 或 `~/.npm-global/bin/claude`）会读取系统级环境变量（`ANTHROPIC_API_KEY`、`ANTHROPIC_BASE_URL` 等）。

本地版本的隔离方案是：

1. **独立 wrapper 脚本**：`.local/bin/claude` 在启动时先 `source .env.claude.local`，再 `exec bun cli.js`，环境变量只在该进程生效。
2. **PATH 优先级**：子 Shell 中 `.local/bin` 在 `PATH` 最前面，`claude` 命令解析到本地版本。
3. **不修改全局配置**：脚本不写入 `~/.bashrc`、`~/.zshrc`，不修改全局 `npm` 或 `bun` 配置。

### 验证隔离效果

```bash
# 在子 Shell 外（全局环境）
which claude              # 应指向全局安装路径
echo $ANTHROPIC_BASE_URL  # 应为空或官方地址

# 执行脚本进入子 Shell
bash local-claude.sh

# 在子 Shell 内
which claude              # 应指向 .local/bin/claude
echo $ANTHROPIC_BASE_URL  # 应为 https://api.longcat.chat/anthropic
```

### 常见问题

**Q: 子 Shell 中 `claude` 仍然是全局版本？**

检查 wrapper 是否已生成：

```bash
ls -la .local/bin/claude
```

如果不存在，重新运行 `bash local-claude.sh`。

**Q: 构建失败？**

确保 `bun` 已安装，然后手动构建：

```bash
bun run build
```

**Q: 依赖安装失败（网络问题）？**

脚本会自动重试 npmmirror 镜像源。也可手动指定：

```bash
npm install --registry=https://registry.npmmirror.com
```

**Q: `.env.claude.local` 中的 API Key 需要更新？**

直接编辑文件：

```bash
vi .env.claude.local
```

修改后无需重新运行 `local-claude.sh`，下次启动 `claude` 时 wrapper 会重新 source 该文件。

---

## 目录结构说明

```
claude-code-local/
├── local-claude.sh        # 本地启动脚本（核心）
├── .env.claude.local      # 本地环境变量（不提交 git）
├── .local/
│   └── bin/
│       └── claude         # 自动生成的 wrapper 脚本
├── cli.js                 # 构建产物（不提交 git）
├── src/                   # 源码
└── package.json
```

---

## 快速参考

| 操作 | 命令 |
|------|------|
| 首次启动（推荐） | `bash local-claude.sh` |
| 当前 Shell 激活 | `source local-claude.sh` |
| 直接运行（不改 PATH） | `set -a && source .env.claude.local && set +a && bun cli.js` |
| 手动构建 | `bun run build` |
| 验证当前 claude 版本 | `which claude && claude --version` |
| 退出本地子 Shell | `exit` |
