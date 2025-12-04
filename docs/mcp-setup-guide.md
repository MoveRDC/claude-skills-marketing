# Complete MCP Server Setup Guide

This guide covers setting up all MCP (Model Context Protocol) servers for Claude Desktop, enabling Claude to interact with your tools and data sources.

## Overview

MCP servers extend Claude's capabilities by connecting it to external tools. This guide covers:

| MCP Server | Purpose | Prerequisites |
|------------|---------|---------------|
| **Snowflake** | Query data warehouse | Python 3.12+, Snowflake account |
| **GitHub** | Manage repositories, PRs, issues | Node.js 18+, GitHub account |

## Quick Start: Complete Config

If you're setting up everything at once, here's a complete `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "snowflake": {
      "command": "/Users/YOURNAME/snowflake-mcp/venv/bin/python",
      "args": ["/Users/YOURNAME/snowflake-mcp/server.py"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_TOKEN_HERE"
      }
    }
  }
}
```

**Replace:**
- `YOURNAME` with your macOS username
- `YOUR_GITHUB_TOKEN_HERE` with your GitHub personal access token

---

## Part 1: Snowflake MCP Server

### Prerequisites

- Python 3.12+ installed
- Snowflake account credentials
- Access to RDC_ANALYTICS database

### Step 1: Check Python Version

```bash
python3 --version  # Should be 3.12+
```

If you need to upgrade:
```bash
brew install python@3.12
```

### Step 2: Create Project Directory

```bash
mkdir -p ~/snowflake-mcp
cd ~/snowflake-mcp
```

### Step 3: Create Virtual Environment

```bash
python3.12 -m venv venv
source venv/bin/activate
```

### Step 4: Install Dependencies

```bash
pip install snowflake-connector-python mcp
```

### Step 5: Create Server Script

Create `~/snowflake-mcp/server.py` with your Snowflake MCP server code.

### Step 6: Configure Credentials

Set up your Snowflake credentials (account, user, password, warehouse, database, schema).

### Step 7: Test the Server

```bash
cd ~/snowflake-mcp
source venv/bin/activate
python server.py
```

Should start without errors.

---

## Part 2: GitHub MCP Server

### Prerequisites

- Node.js 18+ installed
- GitHub account with repository access

### Step 1: Check Node.js

```bash
node --version  # Should be v18+
npx --version   # Should be 8+
```

If not installed:
```bash
brew install node
```

### Step 2: Create GitHub Personal Access Token

1. Go to: https://github.com/settings/personal-access-tokens/new

2. **Configure:**
   | Setting | Value |
   |---------|-------|
   | Token name | `Claude GitHub Access` |
   | Expiration | 90 days |
   | Resource owner | **MoveRDC** |
   | Repository access | Select specific repos or "All repositories" |

3. **Permissions (Repository):**
   | Permission | Level |
   |------------|-------|
   | Contents | Read and write |
   | Metadata | Read-only |
   | Pull requests | Read and write |
   | Issues | Read and write |

4. Generate and **copy the token immediately**

### Step 3: Add to Config

The GitHub MCP server doesn't need a separate installation - it runs via `npx`:

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_YOUR_TOKEN_HERE"
  }
}
```

---

## Config File Location

**macOS:**
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

Navigate there:
```bash
cd ~/Library/"Application Support"/Claude/
```

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

---

## Editing the Config

### macOS

```bash
# Using nano
nano ~/Library/"Application Support"/Claude/claude_desktop_config.json

# Or open in VS Code
code ~/Library/"Application Support"/Claude/claude_desktop_config.json

# Or open in default editor
open ~/Library/"Application Support"/Claude/claude_desktop_config.json
```

### Saving in nano

1. `Ctrl+O` - Write out (save)
2. `Enter` - Confirm filename
3. `Ctrl+X` - Exit

---

## Restarting Claude Desktop

After any config change, you must **completely restart** Claude Desktop:

**macOS:**
1. `Cmd+Q` to quit (or right-click dock icon → Quit)
2. Reopen Claude Desktop

**Windows:**
1. Right-click system tray icon → Exit
2. Reopen Claude Desktop

**Note:** Just closing the window is NOT enough - you must fully quit the application.

---

## Verification Commands

After restarting Claude Desktop, verify each server:

### Snowflake
```
"Run a simple Snowflake query: SELECT CURRENT_DATE()"
```

### GitHub
```
"Search for repositories in the MoveRDC organization"
```

---

## Troubleshooting

### Config File Issues

**Symptom:** Claude doesn't recognize any MCP servers

**Check:**
```bash
# Verify file exists and is valid JSON
cat ~/Library/"Application Support"/Claude/claude_desktop_config.json | python -m json.tool
```

**Common JSON errors:**
- Trailing commas after last item in objects/arrays
- Missing quotes around strings
- Unescaped backslashes in Windows paths

### Snowflake Issues

**Symptom:** Snowflake queries fail

**Check:**
1. Python path is correct: `ls /Users/YOURNAME/snowflake-mcp/venv/bin/python`
2. Virtual environment has dependencies: 
   ```bash
   source ~/snowflake-mcp/venv/bin/activate
   pip list | grep snowflake
   ```
3. Credentials are configured correctly

### GitHub Issues

**Symptom:** GitHub commands fail or return auth errors

**Check:**
1. Token hasn't expired
2. Token has correct permissions
3. Token has access to the organization/repos

**Fix:** Regenerate token at https://github.com/settings/tokens

---

## Adding New MCP Servers

To add a new MCP server:

1. Install/configure the server (varies by server)
2. Add entry to `mcpServers` in config:
   ```json
   "newServer": {
     "command": "path/to/executable",
     "args": ["arg1", "arg2"],
     "env": {
       "ENV_VAR": "value"
     }
   }
   ```
3. Restart Claude Desktop
4. Test with a simple command

---

## Security Notes

### Token Storage

The config file stores tokens in plain text. Protect it:
- Don't commit to version control
- Don't share screenshots of the file
- Use fine-grained tokens with minimum permissions

### Token Rotation

Set reminders to rotate tokens before expiration:
- GitHub: Typically 90 days

### Revoking Access

If a token is compromised:
- **GitHub:** https://github.com/settings/tokens → Delete token

---

## Reference: Full Example Config

```json
{
  "mcpServers": {
    "snowflake": {
      "command": "/Users/gbecker/snowflake-mcp/venv/bin/python",
      "args": [
        "/Users/gbecker/snowflake-mcp/server.py"
      ]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      }
    }
  }
}
```

---

**Questions?** Open an issue in this repository or contact the Marketing Analytics team.

**Last Updated:** December 2025
