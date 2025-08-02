# Claude Block Keeper 重构计划

## 项目概述

Claude Block Keeper 是一个开源工具，用于自动维护 Claude Code 活跃计费块，通过定时检查并在必要时激活新块，确保不错过任何 5 小时计费周期，最大化 token 配额利用。

## 当前问题分析

### 文件结构复杂度
```
当前: 4个文件，~1200行代码
├── claude-block-keeper.js      (249行) - 核心逻辑
├── start-block-keeper.sh       (305行) - 启动脚本  
├── setup-block-keeper.sh       (216行) - 安装脚本
└── claude-block-keeper-setup.md (435行) - 配置文档
```

### 核心问题
1. **过度工程化**: 多层包装、复杂的环境设置、自动化安装脚本
2. **平台耦合**: 硬编码路径、macOS特定逻辑、环境依赖
3. **非标准结构**: 缺少README、LICENSE、package.json等开源项目标准文件
4. **维护困难**: 多文件架构、重复功能、调试复杂

## KISS 重构方案

### 核心理念: **手动简单 > 自动复杂**

> "If you can copy/paste it in 30 seconds, don't spend 3 hours automating it."

### 新架构设计

#### 极简项目结构
```
claude-keeper/
├── README.md              # 完整使用文档
├── LICENSE                # MIT 开源许可证  
├── claude-keeper          # 单一可执行文件 (~200行)
├── package.json           # NPM 元数据
└── config.example.json    # 配置示例
```

#### 单文件脚本 `claude-keeper`
```javascript
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

// 配置默认值
const DEFAULT_CONFIG = {
  sessionDuration: 5 * 60 * 60 * 1000, // 5小时
  claudeCommand: 'claude',              // Claude CLI 命令
  activationCommand: '1+1',             // 激活命令
  logLevel: 'info'                      // 日志级别
};

class ClaudeKeeper {
  constructor() {
    this.config = this.loadConfig();
  }

  loadConfig() {
    const configPath = path.join(__dirname, 'config.json');
    if (fs.existsSync(configPath)) {
      return { ...DEFAULT_CONFIG, ...JSON.parse(fs.readFileSync(configPath, 'utf8')) };
    }
    return DEFAULT_CONFIG;
  }

  log(level, message) {
    if (this.config.logLevel === 'silent') return;
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${message}`);
  }

  getLatestActivity() {
    // 查找 Claude 配置目录下的 JSONL 文件
    // 解析最新活动时间
    // 返回 { timestamp, data } 或 null
  }

  activateBlock() {
    try {
      this.log('info', 'Activating new block...');
      execSync(`${this.config.claudeCommand} --dangerously-skip-permissions "${this.config.activationCommand}"`, 
               { timeout: 30000 });
      this.log('info', 'Block activated');
      return true;
    } catch (err) {
      this.log('error', `Failed: ${err.message}`);
      return false;
    }
  }

  run() {
    const activity = this.getLatestActivity();
    const now = Date.now();
    
    if (!activity || (now - activity.timestamp) > this.config.sessionDuration) {
      this.activateBlock();
    } else {
      this.log('info', 'Block is active');
    }
  }
}

// CLI 界面
const args = process.argv.slice(2);
if (args.includes('--help')) {
  console.log(`
Claude Block Keeper - Keep Claude Code blocks active

Usage:
  claude-keeper              Check and activate if needed
  claude-keeper --force      Force activate new block
  claude-keeper --help       Show this help
  
Config file: config.json (optional)
`);
} else if (args.includes('--force')) {
  new ClaudeKeeper().activateBlock();
} else {
  new ClaudeKeeper().run();
}
```

### 跨平台安装方案 (手动 > 自动)

#### 通用安装步骤
```bash
# 1. 下载文件
curl -O https://raw.githubusercontent.com/user/claude-keeper/main/claude-keeper
chmod +x claude-keeper

# 2. 测试运行
./claude-keeper --help
./claude-keeper

# 3. 根据平台设置定时任务 (见下方)
```

#### Windows 设置 (Task Scheduler)
```
1. 打开"任务计划程序" (taskschd.msc)
2. 创建基本任务
   - 名称: Claude Block Keeper
   - 触发器: 每日
   - 开始时间: 00:30
   - 重复间隔: 1小时
   - 持续时间: 1天
3. 操作: 启动程序
   - 程序: node
   - 参数: C:\path\to\claude-keeper
```

#### macOS/Linux 设置 (Crontab)
```bash
# 编辑 crontab
crontab -e

# 添加这一行 (每小时第30分钟运行)
30 * * * * /usr/bin/node /full/path/to/claude-keeper >/dev/null 2>&1

# 保存退出
```

#### 获取完整路径命令
```bash
# 获取 node 路径
which node

# 获取脚本路径
pwd
realpath claude-keeper
```

### 配置文件 (`config.json`) - 可选
```json
{
  "sessionDuration": 18000000,
  "claudeCommand": "/usr/local/bin/claude",
  "activationCommand": "1+1",
  "logLevel": "info"
}
```

### 开源项目标准文档

#### README.md 结构
```markdown
# Claude Block Keeper

🤖 Automatically keep Claude Code billing blocks active

## What it does

Claude Code bills in 5-hour blocks. This tool runs every hour and:
1. Checks if you have an active billing block
2. If not, runs a simple command to start a new block
3. Prevents billing gaps and maximizes your token usage

## Installation

### Step 1: Download
```bash
curl -O https://raw.githubusercontent.com/user/claude-keeper/main/claude-keeper
chmod +x claude-keeper
```

### Step 2: Test
```bash
./claude-keeper --help
./claude-keeper
```

### Step 3: Schedule (choose your platform)

#### Windows
1. Open Task Scheduler (`Win+R` → `taskschd.msc`)
2. Create Basic Task
3. Set to run `node C:\path\to\claude-keeper` every hour

#### macOS/Linux  
```bash
# Add to crontab
crontab -e

# Add this line:
30 * * * * /usr/bin/node /full/path/to/claude-keeper >/dev/null 2>&1
```

## Configuration (Optional)

Create `config.json` next to the script:

```json
{
  "sessionDuration": 18000000,
  "claudeCommand": "claude",
  "activationCommand": "1+1",
  "logLevel": "info"
}
```

## Troubleshooting

**"claude command not found"**
- Install Claude Code CLI first
- Or set full path in config: `"claudeCommand": "/full/path/to/claude"`

**Cron not working**
- Use full paths: `which node` and `realpath claude-keeper` 
- Test manually first: `/usr/bin/node /full/path/to/claude-keeper`

**Windows Task not working**  
- Use full paths in Task Scheduler
- Test in Command Prompt first

## How it works

- **Efficient**: Uses only ~5 tokens per activation
- **Reliable**: Single file, minimal dependencies
- **Cross-platform**: Windows, macOS, Linux support
- **Simple**: 200 lines of code, manual setup

## License

MIT
```

#### package.json
```json
{
  "name": "claude-keeper",
  "version": "1.0.0", 
  "description": "Keep Claude Code blocks active automatically",
  "main": "claude-keeper",
  "keywords": ["claude", "automation", "billing"],
  "author": "Community",
  "license": "MIT",
  "engines": {
    "node": ">=14.0.0"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/user/claude-keeper.git"
  }
}
```

## 为什么选择手动设置?

### 自动化的代价
- **复杂性**: 需要处理各种平台差异
- **权限问题**: 自动修改 crontab/Task Scheduler 需要特殊权限
- **调试困难**: 自动化失败时用户难以排查
- **维护负担**: 需要测试多种环境组合

### 手动设置的优势  
- **透明**: 用户知道具体做了什么
- **可控**: 用户可以自定义时间、路径
- **可靠**: 减少了环境依赖和权限问题
- **通用**: 适用于所有环境和配置

## 预期效果

### 代码量对比
- **当前**: 1200行，4个文件，复杂安装
- **重构后**: 200行，1个文件，手动安装
- **减少**: 83% 代码量

### 复杂度对比
- **安装**: 从脚本自动化 → 简单的复制粘贴
- **维护**: 从多文件调试 → 单文件排查  
- **配置**: 从分散配置 → 单一JSON文件
- **跨平台**: 从平台特定代码 → 通用手动指令

### 用户体验提升
- **安装速度**: 2分钟内完成 (下载 + 测试 + 设置定时任务)
- **故障排查**: 单文件，问题定位简单
- **自定义**: 用户可轻松修改时间、命令等

## 实施计划

### 第1阶段: 核心简化 (半天)
1. 重写为单文件 `claude-keeper` (~200行)
2. 移除所有自动化安装逻辑
3. 简化配置为单一 JSON 文件
4. 基本功能测试

### 第2阶段: 跨平台文档 (半天)
1. 编写 Windows Task Scheduler 指令
2. 编写 macOS/Linux Crontab 指令  
3. 添加故障排查指南
4. 创建配置示例

### 第3阶段: 开源标准化 (半天)
1. 完善 README.md
2. 添加 LICENSE 文件
3. 创建 package.json
4. 设置 GitHub 仓库

### 第4阶段: 测试验证 (半天)
1. Windows/macOS/Linux 环境测试
2. 不同 Node.js 版本测试
3. 文档准确性验证
4. 社区反馈收集

## 成功标准

### 简洁性
- ✅ 单文件解决方案
- ✅ 200行以内代码
- ✅ 零自动化复杂度
- ✅ 2分钟安装完成

### 可靠性  
- ✅ 跨平台兼容 (Windows/macOS/Linux)
- ✅ 零环境依赖
- ✅ 明确的错误信息
- ✅ 简单的故障排查

### 开源标准
- ✅ 完整的 README 文档
- ✅ 标准项目结构
- ✅ MIT 开源许可证
- ✅ 社区友好的文档

## 总结

这个重构计划的核心是 **手动简单胜过自动复杂**:

### 极致简化
1. **从 4 个文件到 1 个文件**
2. **从 1200 行到 200 行代码** (83% 减少)
3. **从自动安装到手动设置** (2分钟完成)
4. **从平台特定到通用指令**

### KISS 原则体现
- **删除**: 所有自动化安装代码
- **简化**: 单文件架构，最小依赖
- **手动**: 让用户复制粘贴简单命令
- **透明**: 用户完全了解系统做了什么

### 核心价值
专注于唯一重要的事情：**让 Claude 块保持活跃**。其他一切都是次要的。

通过选择手动设置而非自动化，我们获得了更高的可靠性、更好的用户体验和更简单的维护 - 这正是 KISS 原则的精髓。