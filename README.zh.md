# Claude Block Keeper

🤖 **自动保持 Claude Code 计费块活跃状态**

## 功能介绍

Claude Code 按 5 小时为一个计费块。这个工具按计划运行：
1. **检查** 是否有活跃的计费块
2. **激活** 新块（如果没有活跃块）（仅使用约 5 个 token）
3. **防止** 计费间隔，最大化您的 token 使用效率
4. **智能运行** 使用 cron 风格调度（默认：凌晨及4am-11pm的30分）

## 安装步骤

### 步骤 1：下载
```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/user/claude-keeper/main/claude-keeper
curl -O https://raw.githubusercontent.com/user/claude-keeper/main/claude-keeper-daemon.sh
chmod +x claude-keeper claude-keeper-daemon.sh
```

### 步骤 2：测试
```bash
# 测试脚本
./claude-keeper --help
./claude-keeper
```

### 步骤 3：启动守护进程

#### **macOS/Linux（推荐）**
```bash
# 在后台启动守护进程
nohup ./claude-keeper-daemon.sh &

# 检查是否正在运行
ps aux | grep claude-keeper-daemon

# 查看日志
tail -f claude-keeper.log
```

#### **Windows**
```bash
# 运行守护进程（保持终端打开）
.\claude-keeper-daemon.sh

# 或创建定时任务在启动时运行守护进程
```

#### **开机自启动（可选）**
添加到您的 shell 配置文件（`~/.zshrc`、`~/.bashrc` 等）：
```bash
# 如果守护进程未运行则自动启动
if ! pgrep -f claude-keeper-daemon >/dev/null; then
    cd /path/to/claude-keeper && nohup ./claude-keeper-daemon.sh &
fi
```

## 配置（可选）

在脚本旁边创建 `config.json` 文件：

```json
{
  "sessionDuration": 18000000,
  "claudeCommand": "claude",
  "activationCommand": "1+1",
  "logLevel": "info",
  "proxy": null,
  "forceMode": false,
  "schedule": "30 0,4-23 * * *"
}
```

| 选项 | 描述 | 默认值 |
|------|------|--------|
| `sessionDuration` | 计费块持续时间（毫秒） | `18000000`（5小时） |
| `claudeCommand` | Claude CLI 命令或完整路径 | `"claude"` |
| `activationCommand` | 激活块的命令 | `"1+1"` |
| `logLevel` | 日志级别：`silent`、`info`、`verbose` | `"info"` |
| `proxy` | Claude CLI 的代理 URL | `null` |
| `forceMode` | 始终激活而不检查 | `false` |
| `schedule` | 运行时间的 Cron 表达式 | `"30 0,4-23 * * *"` |

### 调度示例
- `"30 0,4-23 * * *"` - 凌晨30分、4am-11pm的30分（默认）
- `"0 */2 * * *"` - 每2小时
- `"0 9-17 * * 1-5"` - 每小时，9am-5pm，周一到周五
- `"*/30 * * * *"` - 每30分钟

## 使用方法

```bash
# 手动运行（检查并在需要时激活）
./claude-keeper

# 强制激活新块
./claude-keeper --force

# 显示当前块状态
./claude-keeper --blocks

# 显示帮助
./claude-keeper --help

# 守护进程管理
nohup ./claude-keeper-daemon.sh &  # 启动守护进程
pkill -f claude-keeper-daemon      # 停止守护进程
ps aux | grep claude-keeper-daemon  # 检查状态
tail -f claude-keeper.log          # 查看日志
```

## 代理支持

如果您在企业防火墙后或需要使用代理，请在 config.json 中设置 `proxy` 选项：

```json
{
  "proxy": "http://proxy.company.com:8080"
}
```

**支持的代理格式：**
- `http://proxy.company.com:8080`
- `http://username:password@proxy.company.com:8080`  
- `https://proxy.company.com:8080`

配置后，脚本会自动为 Claude CLI 命令设置 `HTTP_PROXY` 和 `HTTPS_PROXY` 环境变量。

## 故障排除

### **"claude command not found"**
- 首先安装 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- 或在配置中设置完整路径：`"claudeCommand": "/完整/路径/到/claude"`

### **守护进程无法工作**
```bash
# 1. 先手动测试 claude-keeper
./claude-keeper

# 2. 检查守护进程是否运行
ps aux | grep claude-keeper-daemon

# 3. 查看守护进程日志
tail -f claude-keeper.log

# 4. 在前台运行守护进程以查看错误
./claude-keeper-daemon.sh
```

### **认证问题（macOS）**
- 守护进程在您的用户上下文中运行，具有完整的钥匙串访问权限
- 如果提示钥匙串访问，请点击“始终允许”
- 确保在启动守护进程时您已登录

### **调度无法工作**
- 检查您的 cron 表达式语法：`"schedule": "minute hour day month weekday"`
- 使用简单调度测试：`"*/5 * * * *"`（每5分钟）
- 查看守护进程日志以查看计算的下次运行时间：`tail -f claude-keeper.log`

### **代理无法工作**
- 验证代理 URL 格式：`http://host:port` 或 `https://host:port`
- 手动测试代理：`HTTP_PROXY=your-proxy-url claude --help`
- 使用详细日志查看是否使用了代理：`"logLevel": "verbose"`
- 检查代理是否需要身份验证：`http://username:password@host:port`

## 工作原理

- 🚀 **简单**：单文件，约200行代码
- ⚡ **高效**：每次激活仅使用约5个token
- 🔒 **可靠**：无环境依赖
- 🌍 **跨平台**：支持 Windows、macOS、Linux
- 📖 **透明**：手动设置，您完全掌控

## 项目结构

```
claude-keeper/
├── README.md              # 英文文档
├── README.zh.md           # 本文件
├── LICENSE                # MIT 许可证
├── claude-keeper          # 主执行文件（约200行）
├── claude-keeper-daemon.sh # 智能守护进程
├── config.json            # 配置文件
└── .gitignore            # Git 忽略规则
```

## 为什么选择手动设置？

**手动设置优于自动化复杂性：**

✅ **透明** - 您清楚知道发生了什么  
✅ **可靠** - 更少的故障点和依赖  
✅ **可定制** - 设置您自己的时间表和路径  
✅ **易调试** - 容易测试和故障排除  

❌ **自动化** - 复杂、脆弱、平台特定  

## 贡献

1. Fork 仓库
2. 创建功能分支
3. 进行更改
4. 全面测试
5. 提交 pull request

**保持简单！** 本项目遵循 KISS 原则。

## 许可证

[MIT 许可证](LICENSE) - 自由使用和修改。

## 支持

- 🐛 **问题报告**：[GitHub Issues](https://github.com/user/claude-keeper/issues)
- 💡 **功能建议**：[GitHub Discussions](https://github.com/user/claude-keeper/discussions)
- 📖 **文档**：本 README

---

**⚡ 基于 KISS 原则构建：最大简洁性，零过度工程。**