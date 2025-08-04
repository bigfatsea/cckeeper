# CC Keeper

🤖 **自动保持 Claude Code 计费块活跃**

Claude Code 按5小时计费块收费。CC Keeper 监控您的使用情况，并在需要时激活新块（每次激活仅需约5个token）。

## 前置要求

- Node.js（v14 或更高版本）
- 已安装 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)

## 快速开始

```bash
# 克隆并设置
git clone https://github.com/user/cckeeper.git
cd cckeeper
npm install
chmod +x cckeeper

# 测试运行
./cckeeper

# 启动守护进程模式
./cckeeper -d
```

## 作为后台服务运行

```bash
# 在后台运行守护进程
nohup ./cckeeper -d > ~/logs/cckeeper.log 2>&1 &

# 登录时自动启动（添加到 ~/.zshrc 或 ~/.bashrc）
cd /path/to/cckeeper && nohup ./cckeeper -d > ~/logs/cckeeper.log 2>&1 &
```

## 配置

通过命令行选项配置：

| 选项 | 描述 | 默认值 |
|------|------|--------|
| `--session-duration <min>` | 计费块持续时间（分钟） | `300`（5小时） |
| `--claude-command <cmd>` | Claude CLI 命令 | `"claude --model Sonnet"` |
| `--activation-command <cmd>` | 激活块的命令 | `"1+1"` |
| `--log-level <level>` | 日志级别：silent、info、verbose | `"info"` |
| `--proxy <url>` | HTTP 代理 URL（例如：`http://localhost:7890`） | 无 |
| `--schedule <cron>` | 守护进程的 Cron 表达式 | `"30 0,4-23 * * *"` |

**Cron 调度示例：**
- `"0 * * * *"` - 每小时
- `"*/15 * * * *"` - 每15分钟
- `"30 9-17 * * *"` - 工作时间（上午9点-下午5点）
- `"0 9 * * 1-5"` - 工作日上午9点

## 命令

```bash
# 手动检查/激活
./cckeeper

# 强制激活新块
./cckeeper -f

# 运行守护进程模式
./cckeeper -d

# 自定义调度（每2小时）
./cckeeper -d --schedule "0 */2 * * *"

# 守护进程管理
ps aux | grep cckeeper        # 检查状态
pkill -f cckeeper            # 停止守护进程
tail -f ~/logs/cckeeper.log  # 查看日志
```

## 故障排除

**"claude command not found"**
- 先安装 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- 或指定完整路径：`--claude-command "/path/to/claude"`

**"cron-parser module not found"**
- 在 cckeeper 目录中运行 `npm install`

**守护进程问题**
```bash
# 检查是否运行
ps aux | grep cckeeper

# 查看日志
tail -f ~/logs/cckeeper.log

# 手动测试
./cckeeper --log-level verbose
```

## 许可证

[MIT 许可证](LICENSE)