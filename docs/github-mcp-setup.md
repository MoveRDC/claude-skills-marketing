# GitHub MCP Server Setup Guide

This guide covers setting up the GitHub MCP (Model Context Protocol) server for Claude Desktop, enabling Claude to interact directly with GitHub repositories.

## What This Enables

With the GitHub MCP server, Claude can:
- Search repositories and code
- Read file contents from repos
- Create branches and commits
- Create and manage pull requests
- Create and manage issues
- Push multiple files in a single commit

## Prerequisites

### 1. Node.js

The GitHub MCP server runs via `npx`, which requires Node.js.

**Check if installed:**
```bash
node --version  # Should show v18+ 
npx --version   # Should show 8+
```

**Install if needed:**
- macOS: `brew install node`
- Windows: Download from https://nodejs.org/

### 2. Claude Desktop

Download from https://claude.ai/download if not already installed.

### 3. GitHub Account

You need a GitHub account with access to the repositories you want Claude to work with.

## Setup Steps

### Step 1: Create a Fine-Grained Personal Access Token

1. Go to: https://github.com/settings/personal-access-tokens/new

2. **Configure the token:**

   | Setting | Value |
   |---------|-------|
   | **Token name** | `Claude GitHub Access` (or your preference) |
   | **Expiration** | 90 days (or custom - remember to renew!) |
   | **Resource owner** | Select **MoveRDC** (or your organization) |
   | **Repository access** | Choose specific repos or "All repositories" |

3. **Set Permissions** (Repository permissions):

   | Permission | Level | Required For |
   |------------|-------|--------------|
   | **Contents** | Read and write | Reading/writing files |
   | **Metadata** | Read-only | Auto-selected |
   | **Pull requests** | Read and write | Creating PRs |
   | **Issues** | Read and write | Managing issues (optional) |

4. Click **Generate token**

5. **Copy the token immediately** - you won't be able to see it again!

### Step 2: Locate Your Claude Desktop Config File

**macOS:**
```bash
~/Library/Application Support/Claude/claude_desktop_config.json
```

To navigate there:
```bash
cd ~/Library/"Application Support"/Claude/
```

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

### Step 3: Edit the Config File

Open the config file in a text editor:

**macOS:**
```bash
nano ~/Library/"Application Support"/Claude/claude_desktop_config.json
```

**Windows:**
```
notepad %APPDATA%\Claude\claude_desktop_config.json
```

### Step 4: Add GitHub MCP Server Configuration

If you have an **empty config** or **no existing MCP servers**, use:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_TOKEN_HERE"
      }
    }
  }
}
```

If you have **existing MCP servers** (like Snowflake), add GitHub to them:

```json
{
  "mcpServers": {
    "snowflake": {
      "command": "/Users/yourname/snowflake-mcp/venv/bin/python",
      "args": ["/Users/yourname/snowflake-mcp/server.py"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_TOKEN_HERE"
      }
    }
  }
}
```

**Important:** Replace `YOUR_TOKEN_HERE` with your actual token.

### Step 5: Save and Restart Claude Desktop

1. Save the config file
   - In nano: `Ctrl+O`, then `Enter`, then `Ctrl+X`
2. **Completely quit Claude Desktop** (not just close the window)
   - macOS: `Cmd+Q` or right-click dock icon → Quit
   - Windows: Right-click system tray → Exit
3. Reopen Claude Desktop

### Step 6: Verify It Works

Ask Claude:
```
"Search for repositories in the MoveRDC organization"
```

or

```
"Show me the contents of the claude-skills-marketing repository"
```

Claude should return results from GitHub.

## Troubleshooting

### "Tool not available" or GitHub commands don't work

**Check:**
1. Config file syntax is valid JSON (no trailing commas, proper quotes)
2. Token is correctly pasted (no extra spaces)
3. Claude Desktop was fully restarted

**Verify config:**
```bash
cat ~/Library/"Application Support"/Claude/claude_desktop_config.json
```

### "Authentication failed" or 401 errors

**Check:**
1. Token hasn't expired
2. Token has correct permissions
3. Token has access to the repository/organization

**Fix:** Generate a new token with proper permissions

### "Repository not found" or 404 errors

**Check:**
1. Repository name is correct
2. Token has access to that specific repository
3. If using fine-grained token, the repo is in the allowed list

### Node.js errors

**Check:**
```bash
node --version
npx --version
```

If not installed or outdated, install/update Node.js.

## Security Best Practices

### Token Security

- **Never share your token** in chat, email, or public channels
- **Never commit tokens** to repositories
- **Rotate tokens regularly** (every 90 days recommended)
- **Use fine-grained tokens** with minimum necessary permissions
- **Revoke immediately** if compromised: https://github.com/settings/tokens

### Repository Access

- Grant access to **specific repositories** rather than "All repositories" when possible
- Review token permissions periodically
- Remove tokens you no longer use

## Example Workflows

Once set up, you can ask Claude to:

### Code Review
```
"Look at PR #123 in the claude-skills-marketing repo and review the changes"
```

### Create Documentation
```
"Create a new markdown file in the docs folder explaining our data pipeline"
```

### Search Code
```
"Find all files in our repo that reference ROAS"
```

### Create Issues
```
"Create an issue in claude-skills-marketing to track adding a new metric"
```

### Create PRs
```
"Create a branch, update the README with our new team member, and open a PR"
```

## Token Renewal Reminder

Fine-grained tokens expire. Set a calendar reminder to renew before expiration:

1. Go to: https://github.com/settings/tokens
2. Find your Claude token
3. Click to regenerate or create a new one
4. Update your `claude_desktop_config.json`
5. Restart Claude Desktop

---

**Questions?** Contact the Marketing Analytics team or open an issue in this repository.

**Last Updated:** December 2025
