# CC Keeper

🤖 **Automatically keep Claude Code billing blocks active**

Claude Code bills in 5-hour blocks. CC Keeper monitors your usage and activates new blocks when needed (~5 tokens per activation).

## Prerequisites

- Node.js (v14 or higher)
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed

## Quick Start

```bash
# Clone and setup
git clone https://github.com/user/cckeeper.git
cd cckeeper
npm install
chmod +x cckeeper

# Test run
./cckeeper

# Start daemon mode
./cckeeper -d
```

## Running as Background Service

```bash
# Run daemon in background
nohup ./cckeeper -d > ~/logs/cckeeper.log 2>&1 &

# Auto-start on login (add to ~/.zshrc or ~/.bashrc)
cd /path/to/cckeeper && nohup ./cckeeper -d > ~/logs/cckeeper.log 2>&1 &
```

## Configuration

Configure via command line options:

| Option | Description | Default |
|--------|-------------|---------|
| `--session-duration <min>` | Block duration in minutes | `300` (5 hours) |
| `--claude-command <cmd>` | Claude CLI command | `"claude --model Sonnet"` |
| `--activation-command <cmd>` | Command to activate block | `"1+1"` |
| `--log-level <level>` | Log level: silent, info, verbose | `"info"` |
| `--proxy <url>` | HTTP proxy URL (e.g., `http://localhost:7890`) | None |
| `--schedule <cron>` | Cron expression for daemon | `"30 0,4-23 * * *"` |

**Cron Schedule Examples:**
- `"0 * * * *"` - Every hour
- `"*/15 * * * *"` - Every 15 minutes  
- `"30 9-17 * * *"` - Business hours (9 AM-5 PM)
- `"0 9 * * 1-5"` - Weekdays at 9 AM

## Commands

```bash
# Manual check/activate
./cckeeper

# Force new block
./cckeeper -f

# Run daemon mode
./cckeeper -d

# Custom schedule (every 2 hours)
./cckeeper -d --schedule "0 */2 * * *"

# Daemon management
ps aux | grep cckeeper        # Check status
pkill -f cckeeper            # Stop daemon
tail -f ~/logs/cckeeper.log  # View logs
```

## Troubleshooting

**"claude command not found"**
- Install [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) first
- Or specify full path: `--claude-command "/path/to/claude"`

**"cron-parser module not found"**
- Run `npm install` in the cckeeper directory

**Daemon issues**
```bash
# Check if running
ps aux | grep cckeeper

# View logs
tail -f ~/logs/cckeeper.log

# Test manually
./cckeeper --log-level verbose
```

## License

[MIT License](LICENSE)