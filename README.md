# Claude Block Keeper

🤖 **Automatically keep Claude Code billing blocks active**

## What it does

Claude Code bills in 5-hour blocks. This tool runs every hour and:
1. **Checks** if you have an active billing block
2. **Activates** a new block if none exists (uses ~5 tokens)
3. **Prevents** billing gaps and maximizes your token usage

## Installation

### Step 1: Download
```bash
# Download the script
curl -O https://raw.githubusercontent.com/user/claude-keeper/main/claude-keeper
chmod +x claude-keeper
```

### Step 2: Test
```bash
# Test the script
./claude-keeper --help
./claude-keeper
```

### Step 3: Schedule (choose your platform)

#### **Windows**
1. Open Task Scheduler (`Win+R` → `taskschd.msc`)
2. Create Basic Task
3. **Name**: Claude Block Keeper
4. **Trigger**: Daily, repeat every 1 hour
5. **Action**: Start program
   - **Program**: `node`
   - **Arguments**: `C:\full\path\to\claude-keeper`

#### **macOS/Linux**
```bash
# Get the full paths first
which node
realpath claude-keeper

# Add to crontab
crontab -e

# Add this line (replace with your actual paths):
30 * * * * /usr/bin/node /full/path/to/claude-keeper >/dev/null 2>&1
```

## Configuration (Optional)

Create `config.json` next to the script:

```json
{
  "sessionDuration": 18000000,
  "claudeCommand": "claude",
  "activationCommand": "1+1",
  "logLevel": "info",
  "proxy": null
}
```

| Option | Description | Default |
|--------|-------------|---------|
| `sessionDuration` | Block duration in milliseconds | `18000000` (5 hours) |
| `claudeCommand` | Claude CLI command or full path | `"claude"` |
| `activationCommand` | Command to activate block | `"1+1"` |
| `logLevel` | Logging level: `silent`, `info`, `verbose` | `"info"` |
| `proxy` | Proxy URL for Claude CLI | `null` |

## Usage

```bash
# Normal operation (check and activate if needed)
./claude-keeper

# Force activate new block
./claude-keeper --force

# Show help
./claude-keeper --help
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

### **Cron not working**
```bash
# 1. Use full paths (no ~/ or relative paths)
which node          # Use this full path
realpath claude-keeper  # Use this full path

# 2. Test manually first
/usr/bin/node /full/path/to/claude-keeper

# 3. Check cron logs (macOS)
log show --predicate 'process == "cron"' --last 1h
```

### **Windows Task not working**
- Use full paths in Task Scheduler (no relative paths)
- Test in Command Prompt first: `node C:\full\path\to\claude-keeper`
- Ensure Node.js is in system PATH

### **Permission issues (macOS)**
1. **System Preferences** → **Security & Privacy** → **Privacy**
2. **Full Disk Access** → Add `cron` and your terminal app

### **Proxy not working**
- Verify proxy URL format: `http://host:port` or `https://host:port`
- Test proxy manually: `HTTP_PROXY=your-proxy-url claude --help`
- Use verbose logging to see if proxy is being used: `"logLevel": "verbose"`
- Check if proxy requires authentication: `http://username:password@host:port`

## How it works

- 🚀 **Simple**: Single file, ~200 lines of code
- ⚡ **Efficient**: Uses only ~5 tokens per activation
- 🔒 **Reliable**: No environment dependencies
- 🌍 **Cross-platform**: Windows, macOS, Linux
- 📖 **Transparent**: Manual setup, you control everything

## Project Structure

```
claude-keeper/
├── README.md              # This file
├── LICENSE                # MIT license
├── claude-keeper          # Main executable (~200 lines)
├── package.json           # NPM metadata
├── config.example.json    # Configuration example
└── .gitignore            # Git ignore rules
```

## Why manual setup?

**Manual setup is better than automated complexity:**

✅ **Transparent** - You know exactly what's happening  
✅ **Reliable** - Fewer failure points and dependencies  
✅ **Customizable** - Set your own schedule and paths  
✅ **Debuggable** - Easy to test and troubleshoot  

❌ **Automated** - Complex, fragile, platform-specific  

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