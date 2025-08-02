# Claude Block Keeper 配置指南

## 概述

Claude Block Keeper 是一个自动化脚本，用于维持 Claude Code 的活跃计费块，避免产生间隙块（gap block），从而最大化利用 token 配额。

## 工作原理

- 每小时的第 30 分钟运行（例如 10:30, 11:30, 12:30）
- 检查是否存在活跃的 5 小时计费块
- 如果没有活跃块，自动执行简单命令激活新块
- 所有操作输出到 stdout，可通过重定向保存为日志文件

## 架构组件

### 1. claude-block-keeper.js
核心逻辑脚本，负责：
- 读取 Claude Code 使用数据
- 检测活跃计费块状态
- 在需要时激活新的计费块

### 2. start-block-keeper.sh
启动脚本，负责：
- 设置执行环境（PATH、环境变量）
- 切换到正确的工作目录
- 调用 Node.js 脚本
- 处理日志输出和错误捕获
- 提供统一的执行接口

### 3. setup-block-keeper.sh
自动化配置脚本，负责：
- 验证脚本和环境
- 创建必要的目录结构
- 配置 crontab 定时任务
- 提供用户友好的安装体验

## 安装步骤

### 方式一：自动化安装（推荐）

使用提供的自动化配置脚本：

```bash
cd /path/to/ccusage
./setup-block-keeper.sh
```

脚本会自动：
- 验证 claude-block-keeper.js 路径
- 创建日志目录
- 设置执行权限
- 测试脚本运行
- 配置 crontab 任务
- 提供多种运行频率选择

按照脚本提示操作即可完成全部配置。

### 方式二：手动安装

#### 1. 确保脚本可执行

```bash
cd /path/to/ccusage
chmod +x claude-block-keeper.js
chmod +x start-block-keeper.sh
```

#### 2. 测试脚本

手动运行一次，确保工作正常：

```bash
# 使用启动脚本运行（推荐方式）
./start-block-keeper.sh

# 或直接运行 Node.js 脚本
./claude-block-keeper.js

# 启动脚本会自动处理日志输出，也可以手动指定日志文件
./start-block-keeper.sh /path/to/claude-block-keeper.js /path/to/custom.log
```

查看日志：

```bash
# 默认日志位置
tail -f logs/block-keeper.log

# 或查看自定义日志
tail -f /path/to/custom.log
```

## macOS Crontab 配置

### 方式一：直接文件安装（推荐）

使用文件方式直接安装 crontab，避免编辑器相关问题：

```bash
# 1. 创建 crontab 文件
cat > /tmp/my_crontab << 'EOF'
# Claude Block Keeper - 每小时第30分钟运行
30 * * * * /path/to/ccusage/start-block-keeper.sh
EOF

# 2. 安装 crontab
crontab /tmp/my_crontab

# 3. 验证安装
crontab -l

# 4. 清理临时文件
rm /tmp/my_crontab
```

**注意**：记得将 `/path/to/ccusage` 替换为实际的项目路径。

### 方式二：编辑器方式

```bash
crontab -e
```

**故障排查：crontab 编辑问题**

**问题 1：VSCode 打开而不是终端编辑器**

如果 `crontab -e` 打开 VSCode 而不是 vim/nano：

```bash
# 临时使用 vim
EDITOR=vim crontab -e

# 或临时使用 nano
EDITOR=nano crontab -e
```

**问题 2：显示 "no changes made to crontab"**

这通常是因为在 vim/nano 中没有正确保存文件。确保：

**在 vim 中**：
1. 按 `i` 进入插入模式
2. 输入 crontab 条目
3. 按 `ESC` 退出插入模式
4. 输入 `:wq` 保存并退出

**在 nano 中**：
1. 直接输入 crontab 条目
2. 按 `Ctrl+X` 退出
3. 按 `Y` 确认保存
4. 按 `Enter` 确认文件名

**问题 3：如果编辑器仍然有问题**

可以参考上面"方式一：直接文件安装"的方法来避免编辑器问题。

### 2. 添加定时任务

在编辑器中添加以下行（注意替换实际路径）：

```bash
# Claude Block Keeper - 每小时第30分钟运行（推荐方式）
30 * * * * /path/to/ccusage/start-block-keeper.sh

# 传统方式（直接调用 Node.js，不推荐）
# 30 * * * * cd /path/to/ccusage && /usr/bin/node claude-block-keeper.js >> /path/to/ccusage/logs/block-keeper.log 2>&1
```

**新方式优势**：
- **简化配置**：crontab 条目更简洁，只需要调用启动脚本
- **环境隔离**：启动脚本自动处理环境变量和路径设置
- **错误处理**：启动脚本提供更好的错误处理和日志记录
- **维护性**：修改执行逻辑只需要更新启动脚本，无需修改 crontab

**路径说明**：
- 将 `/path/to/ccusage` 替换为 ccusage 项目的实际路径
- 启动脚本会自动检测 Node.js 路径和处理环境设置

### 3. 保存并退出

- 如果使用 vim：按 `ESC`，输入 `:wq`，按回车
- 如果使用 nano：按 `Ctrl+X`，按 `Y`，按回车

### 4. 验证 crontab

```bash
crontab -l
```

应该能看到刚添加的任务。

## macOS 权限配置

### 1. 授予 cron 权限

macOS 可能需要授予 cron 访问权限：

1. 打开 **系统偏好设置** → **安全性与隐私** → **隐私**
2. 选择 **完全磁盘访问权限**
3. 点击锁图标解锁
4. 点击 `+` 添加 `/usr/sbin/cron`

### 2. 授予终端权限

确保终端应用有必要的权限：

1. 在 **隐私** 设置中
2. 选择 **完全磁盘访问权限**
3. 确保你的终端应用（Terminal.app 或 iTerm2）已被授权

## 使用 launchd（推荐方案）

对于 macOS，使用 launchd 比 crontab 更可靠。

### 1. 创建 plist 文件

创建文件 `~/Library/LaunchAgents/com.ccusage.blockkeeper.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ccusage.blockkeeper</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/ccusage/start-block-keeper.sh</string>
    </array>
    
    <key>StartCalendarInterval</key>
    <array>
        <!-- 每小时的第30分钟运行 -->
        <dict>
            <key>Minute</key>
            <integer>30</integer>
        </dict>
    </array>
    
    <key>WorkingDirectory</key>
    <string>/path/to/ccusage</string>
    
    <!-- 可选: 将输出保存到日志文件 -->
    <key>StandardOutPath</key>
    <string>/path/to/ccusage/logs/block-keeper.log</string>
    
    <key>StandardErrorPath</key>
    <string>/path/to/ccusage/logs/block-keeper-error.log</string>
    
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

**注意**：
- 将 `/path/to/ccusage` 替换为实际路径
- 如果要保存日志到文件，确保先创建 logs 目录：`mkdir -p /path/to/ccusage/logs`

### 2. 加载 launchd 任务

```bash
launchctl load ~/Library/LaunchAgents/com.ccusage.blockkeeper.plist
```

### 3. 管理 launchd 任务

```bash
# 查看任务状态
launchctl list | grep ccusage

# 停止任务
launchctl unload ~/Library/LaunchAgents/com.ccusage.blockkeeper.plist

# 重新加载任务
launchctl unload ~/Library/LaunchAgents/com.ccusage.blockkeeper.plist
launchctl load ~/Library/LaunchAgents/com.ccusage.blockkeeper.plist
```

## 日志管理

### 日志输出选项

#### 使用启动脚本（推荐）

启动脚本会自动处理日志输出：

```bash
# 使用默认日志文件（logs/block-keeper.log）
./start-block-keeper.sh

# 使用自定义日志文件
./start-block-keeper.sh /path/to/claude-block-keeper.js /path/to/custom.log

# 输出到标准输出
./start-block-keeper.sh /path/to/claude-block-keeper.js /dev/stdout
```

#### 直接运行 Node.js 脚本

脚本输出日志到 stdout，您可以根据需要选择保存方式：

```bash
# 选项 1: 不保存日志
./claude-block-keeper.js

# 选项 2: 保存到单一文件
./claude-block-keeper.js >> logs/block-keeper.log 2>&1

# 选项 3: 按月分割日志
# 创建日志目录
mkdir -p logs

# 运行并保存到按月分割的文件
./claude-block-keeper.js >> logs/block-keeper-$(date +%Y-%m).log 2>&1
```

### 查看日志

如果您选择保存日志：

```bash
# 实时查看日志
tail -f logs/block-keeper.log

# 查看最近的活动
tail -n 50 logs/block-keeper*.log
```

### 日志轮转

如果使用单一日志文件，建议使用 logrotate 或定期清理：

```bash
# 删除 3 个月前的日志
find logs -name "block-keeper*.log" -mtime +90 -delete
```

## 故障排查

### 1. 脚本没有运行

检查 crontab 日志：

```bash
# macOS
log show --predicate 'process == "cron"' --last 1h
```

### 2. 权限问题

确保脚本和日志目录有正确的权限：

```bash
chmod +x claude-block-keeper.js
chmod 755 logs
```

### 3. Claude 命令不可用

确保 Claude Code CLI 在 PATH 中：

```bash
which claude
```

如果找不到，需要在脚本中使用完整路径，或在 crontab 中设置 PATH。

### 4. 查看 launchd 错误

```bash
# 查看 launchd 错误日志（如果配置了 StandardErrorPath）
tail -f logs/block-keeper-error.log
```

## 环境变量配置

如果使用自定义的 Claude 数据目录，在 crontab 或 launchd 中设置环境变量：

### Crontab 方式

```bash
# 使用启动脚本（推荐）
30 * * * * CLAUDE_CONFIG_DIR=/custom/path /path/to/ccusage/start-block-keeper.sh

# 传统方式
# 30 * * * * CLAUDE_CONFIG_DIR=/custom/path cd /path/to/ccusage && /usr/bin/node claude-block-keeper.js >> logs/block-keeper.log 2>&1
```

### Launchd 方式

在 plist 文件中添加：

```xml
<key>EnvironmentVariables</key>
<dict>
    <key>CLAUDE_CONFIG_DIR</key>
    <string>/custom/path</string>
</dict>
```

## 安全建议

1. **最小权限**：脚本只需要读取 Claude 数据目录和写入日志的权限
2. **定期检查**：定期查看日志，确保脚本正常运行
3. **资源使用**：脚本设计为最小化 token 使用（每次激活仅使用约 5-10 tokens）

## 停止自动运行

### 停止 crontab

```bash
# 编辑 crontab 并删除相应行
crontab -e
```

### 停止 launchd

```bash
launchctl unload ~/Library/LaunchAgents/com.ccusage.blockkeeper.plist
rm ~/Library/LaunchAgents/com.ccusage.blockkeeper.plist
```

## 总结

通过配置 Claude Block Keeper，你可以：

- 自动维持 Claude Code 的活跃状态
- 避免因长时间不使用而产生间隙块
- 最大化利用每个 5 小时计费周期
- 通过日志跟踪所有自动化操作

脚本设计简单可靠，资源消耗极小，是优化 Claude Code 使用的实用工具。