# Claude Block Keeper

🤖 **自动保持 Claude Code 计费块活跃状态**

## 功能介绍

Claude Code 按 5 小时为一个计费块。这个工具每小时运行一次：
1. **检查** 是否有活跃的计费块
2. **激活** 新块（如果没有活跃块）（仅使用约 5 个 token）
3. **防止** 计费间隔，最大化您的 token 使用效率

## 安装步骤

### 步骤 1：下载
```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/user/claude-keeper/main/claude-keeper
chmod +x claude-keeper
```

### 步骤 2：测试
```bash
# 测试脚本
./claude-keeper --help
./claude-keeper
```

### 步骤 3：设置定时任务（选择您的平台）

#### **Windows**
1. 打开任务计划程序（`Win+R` → `taskschd.msc`）
2. 创建基本任务
3. **名称**：Claude Block Keeper
4. **触发器**：每日，每 1 小时重复一次
5. **操作**：启动程序
   - **程序**：`node`
   - **参数**：`C:\完整\路径\到\claude-keeper`

#### **macOS/Linux**
```bash
# 首先获取完整路径
which node
realpath claude-keeper

# 添加到 crontab
crontab -e

# 添加以下行（替换为您的实际路径）：
30 * * * * /usr/bin/node /完整/路径/到/claude-keeper >/dev/null 2>&1
```

## 配置（可选）

在脚本旁边创建 `config.json` 文件：

```json
{
  "sessionDuration": 18000000,
  "claudeCommand": "claude",
  "activationCommand": "1+1",
  "logLevel": "info",
  "proxy": null
}
```

| 选项 | 描述 | 默认值 |
|------|------|--------|
| `sessionDuration` | 计费块持续时间（毫秒） | `18000000`（5小时） |
| `claudeCommand` | Claude CLI 命令或完整路径 | `"claude"` |
| `activationCommand` | 激活块的命令 | `"1+1"` |
| `logLevel` | 日志级别：`silent`、`info`、`verbose` | `"info"` |
| `proxy` | Claude CLI 的代理 URL | `null` |

## 使用方法

```bash
# 正常运行（检查并在需要时激活）
./claude-keeper

# 强制激活新块
./claude-keeper --force

# 显示帮助
./claude-keeper --help
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

### **Cron 无法工作**
```bash
# 1. 使用完整路径（不要使用 ~/ 或相对路径）
which node              # 使用这个完整路径
realpath claude-keeper  # 使用这个完整路径

# 2. 先手动测试
/usr/bin/node /完整/路径/到/claude-keeper

# 3. 检查 cron 日志（macOS）
log show --predicate 'process == "cron"' --last 1h
```

### **Windows 任务无法工作**
- 在任务计划程序中使用完整路径（不要使用相对路径）
- 先在命令提示符中测试：`node C:\完整\路径\到\claude-keeper`
- 确保 Node.js 在系统 PATH 中

### **权限问题（macOS）**
1. **系统偏好设置** → **安全性与隐私** → **隐私**
2. **完全磁盘访问权限** → 添加 `cron` 和您的终端应用

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
├── README.md              # 本文件
├── README.zh.md           # 中文文档
├── LICENSE                # MIT 许可证
├── claude-keeper          # 主执行文件（约200行）
├── package.json           # NPM 元数据
├── config.example.json    # 配置示例
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