# Claude Block Keeper

🤖 **Automatically keep Claude Code billing blocks active**

## What it does

Claude Code bills in 5-hour blocks. This tool runs on schedule and:
1. **Checks** if you have an active billing block
2. **Activates** a new block if none exists (uses ~5 tokens)
3. **Prevents** billing gaps and maximizes your token usage
4. **Runs intelligently** using cron-style scheduling (default: 30 minutes past midnight, 4am-11pm)

## Installation

### Step 1: Download
```bash
# Download the scripts
curl -O https://raw.githubusercontent.com/user/claude-keeper/main/claude-keeper
curl -O https://raw.githubusercontent.com/user/claude-keeper/main/claude-keeper-daemon.sh
chmod +x claude-keeper claude-keeper-daemon.sh
```

### Step 2: Test
```bash
# Test the script
./claude-keeper --help
./claude-keeper
```

### Step 3: Start the Daemon

#### **macOS/Linux (Recommended)**
```bash
# Start the daemon in background
nohup ./claude-keeper-daemon.sh &

# Check if it's running
ps aux | grep claude-keeper-daemon

# View logs
tail -f claude-keeper.log
```

#### **Windows**
```bash
# Run the daemon (keep terminal open)
.\claude-keeper-daemon.sh

# Or create a scheduled task to run the daemon at startup
```

#### **Auto-start on Login (Optional)**
Add to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):
```bash
# Auto-start Claude Keeper daemon if not running
if ! pgrep -f claude-keeper-daemon >/dev/null; then
    cd /path/to/claude-keeper && nohup ./claude-keeper-daemon.sh &
fi
```

## Configuration (Optional)

Create `config.json` next to the script:

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

| Option | Description | Default |
|--------|-------------|---------|
| `sessionDuration` | Block duration in milliseconds | `18000000` (5 hours) |
| `claudeCommand` | Claude CLI command or full path | `"claude"` |
| `activationCommand` | Command to activate block | `"1+1"` |
| `logLevel` | Logging level: `silent`, `info`, `verbose` | `"info"` |
| `proxy` | Proxy URL for Claude CLI | `null` |
| `forceMode` | Always activate without checking | `false` |
| `schedule` | Cron expression for when to run | `"30 0,4-23 * * *"` |

### Schedule Examples
- `"30 0,4-23 * * *"` - At 30 minutes past midnight, 4am-11pm (default)
- `"0 */2 * * *"` - Every 2 hours
- `"0 9-17 * * 1-5"` - Every hour, 9am-5pm, Monday-Friday
- `"*/30 * * * *"` - Every 30 minutes

## Usage

```bash
# Manual operation (check and activate if needed)
./claude-keeper

# Force activate new block
./claude-keeper --force

# Show current blocks
./claude-keeper --blocks

# Show help
./claude-keeper --help

# Daemon management
nohup ./claude-keeper-daemon.sh &  # Start daemon
pkill -f claude-keeper-daemon      # Stop daemon
ps aux | grep claude-keeper-daemon  # Check status
tail -f claude-keeper.log          # View logs
```

## Proxy Support

If you're behind a corporate firewall or need to use a proxy, set the `proxy` option in your config.json:

```json
{
  "proxy": "http://proxy.company.com:8080"
}
```

**Supported proxy formats:**
- `http://proxy.company.com:8080`
- `http://username:password@proxy.company.com:8080`  
- `https://proxy.company.com:8080`

When configured, the script automatically sets `HTTP_PROXY` and `HTTPS_PROXY` environment variables for the Claude CLI command.

## Troubleshooting

### **"claude command not found"**
- Install [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) first
- Or set full path in config: `"claudeCommand": "/full/path/to/claude"`

### **Daemon not starting**
```bash
# 1. Test claude-keeper manually first
./claude-keeper

# 2. Check if daemon is running
ps aux | grep claude-keeper-daemon

# 3. Check daemon logs
tail -f claude-keeper.log

# 4. Start daemon with explicit output
./claude-keeper-daemon.sh  # Run in foreground to see errors
```

### **Authentication issues (macOS)**
- The daemon runs in your user context with full keychain access
- If prompted for keychain access, click "Always Allow"
- Ensure you're logged in when starting the daemon

### **Schedule not working**
- Check your cron expression syntax: `"schedule": "minute hour day month weekday"`
- Test with a simple schedule: `"*/5 * * * *"` (every 5 minutes)
- View daemon logs to see calculated next run times: `tail -f claude-keeper.log`

### **Proxy not working**
- Verify proxy URL format: `http://host:port` or `https://host:port`
- Test proxy manually: `HTTP_PROXY=your-proxy-url claude --help`
- Use verbose logging to see if proxy is being used: `"logLevel": "verbose"`
- Check if proxy requires authentication: `http://username:password@host:port`

## How it works

- 🚀 **Simple**: Two scripts, intelligent scheduling
- ⚡ **Efficient**: Uses only ~5 tokens per activation
- 🔒 **Reliable**: Runs in user context with full keychain access
- 🌍 **Cross-platform**: Windows, macOS, Linux
- 📖 **Transparent**: Manual setup, you control everything
- ⏰ **Smart**: Cron-style scheduling with automatic sleep calculations

## Project Structure

```
claude-keeper/
├── README.md                    # This file
├── README.zh.md                 # Chinese documentation
├── LICENSE                      # MIT license
├── claude-keeper                # Main logic (~200 lines)
├── claude-keeper-daemon.sh      # Smart daemon with cron scheduling
├── config.json                  # Configuration file
└── .gitignore                  # Git ignore rules
```

## Why this approach?

**Smart daemon design beats complex installation:**

✅ **No system dependencies** - Runs in your user context  
✅ **No keychain issues** - Full access to authentication  
✅ **No cron complexity** - Built-in intelligent scheduling  
✅ **Easy debugging** - Clear logs and simple process management  
✅ **Customizable schedule** - Use any cron expression  

❌ **System scheduling** - Complex permissions and environment setup  

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

**Keep it simple!** This project follows the KISS principle.

## License

[MIT License](LICENSE) - feel free to use and modify.

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/user/claude-keeper/issues)
- 💡 **Feature requests**: [GitHub Discussions](https://github.com/user/claude-keeper/discussions)
- 📖 **Documentation**: This README

---

**⚡ Built with KISS principle: Maximum simplicity, zero overengineering.**