#!/bin/bash
#
# MCP Server Setup Script for Claude Desktop
# Sets up GitHub MCP server (and optionally Snowflake)
#
# Usage: ./setup-mcp-servers.sh
#

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       MCP Server Setup for Claude Desktop                  ║"
echo "║       Marketing Analytics Team                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
    CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
    OS="macOS"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    CONFIG_DIR="$APPDATA/Claude"
    CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
    OS="Windows"
else
    echo "❌ Unsupported operating system: $OSTYPE"
    exit 1
fi

echo "📍 Detected OS: $OS"
echo "📁 Config location: $CONFIG_FILE"
echo ""

# ============================================
# PREREQUISITES CHECK
# ============================================

echo "🔍 Checking prerequisites..."
echo ""

# Check Node.js (required for GitHub MCP)
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js installed: $NODE_VERSION"
else
    echo "❌ Node.js not found"
    echo "   Install with: brew install node (macOS) or download from https://nodejs.org"
    exit 1
fi

# Check npx
if command -v npx &> /dev/null; then
    NPX_VERSION=$(npx --version)
    echo "✅ npx installed: $NPX_VERSION"
else
    echo "❌ npx not found (should come with Node.js)"
    exit 1
fi

# Check curl (for GitHub API validation)
if command -v curl &> /dev/null; then
    echo "✅ curl installed"
else
    echo "⚠️  curl not found (token validation will be skipped)"
fi

# Check Python (for Snowflake MCP)
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python installed: $PYTHON_VERSION"
else
    echo "⚠️  Python 3 not found (optional, needed for Snowflake MCP)"
fi

echo ""

# ============================================
# CONFIG DIRECTORY SETUP
# ============================================

echo "📂 Setting up config directory..."

if [ ! -d "$CONFIG_DIR" ]; then
    echo "   Creating directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

echo "✅ Config directory ready"
echo ""

# ============================================
# GITHUB TOKEN SETUP
# ============================================

echo "🔐 GitHub Personal Access Token Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You need a fine-grained personal access token from GitHub."
echo ""
echo "To create one:"
echo "  1. Go to: https://github.com/settings/personal-access-tokens/new"
echo "  2. Token name: Claude GitHub Access"
echo "  3. Expiration: 90 days (recommended)"
echo "  4. Resource owner: MoveRDC"
echo "  5. Repository access: Select repos or 'All repositories'"
echo "  6. Permissions:"
echo "     - Contents: Read and write"
echo "     - Metadata: Read-only (auto-selected)"
echo "     - Pull requests: Read and write"
echo "     - Issues: Read and write (optional)"
echo ""
read -p "Do you have a GitHub token ready? (y/n): " HAS_TOKEN

if [[ "$HAS_TOKEN" != "y" && "$HAS_TOKEN" != "Y" ]]; then
    echo ""
    echo "Please create a token first, then run this script again."
    echo "Opening GitHub token page..."
    if [[ "$OS" == "macOS" ]]; then
        open "https://github.com/settings/personal-access-tokens/new"
    fi
    exit 0
fi

echo ""
read -sp "Paste your GitHub token (input hidden): " GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ No token provided"
    exit 1
fi

# ============================================
# TOKEN VALIDATION
# ============================================

echo ""
echo "🔍 Validating GitHub token..."

# Check token format
if [[ "$GITHUB_TOKEN" == ghp_* ]] || [[ "$GITHUB_TOKEN" == github_pat_* ]]; then
    echo "✅ Token format looks correct"
else
    echo "⚠️  Token format is unusual (expected ghp_* or github_pat_*)"
    echo "   This may still work if it's a valid token."
    read -p "   Continue anyway? (y/n): " CONTINUE_ANYWAY
    if [[ "$CONTINUE_ANYWAY" != "y" && "$CONTINUE_ANYWAY" != "Y" ]]; then
        exit 1
    fi
fi

# Test token against GitHub API
if command -v curl &> /dev/null; then
    echo "   Testing token against GitHub API..."
    
    HTTP_STATUS=$(curl -s -o /tmp/github_response.json -w "%{http_code}" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/user")
    
    if [ "$HTTP_STATUS" == "200" ]; then
        GITHUB_USER=$(cat /tmp/github_response.json | grep -o '"login":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "✅ Token is valid! Authenticated as: $GITHUB_USER"
        rm -f /tmp/github_response.json
    elif [ "$HTTP_STATUS" == "401" ]; then
        echo "❌ Token is invalid or expired (HTTP 401)"
        echo "   Please generate a new token and try again."
        rm -f /tmp/github_response.json
        exit 1
    elif [ "$HTTP_STATUS" == "403" ]; then
        echo "❌ Token lacks required permissions (HTTP 403)"
        echo "   Please check the token has the correct scopes."
        rm -f /tmp/github_response.json
        exit 1
    else
        echo "⚠️  Could not verify token (HTTP $HTTP_STATUS)"
        echo "   Continuing anyway - the token may still work."
        rm -f /tmp/github_response.json
    fi
    
    # Test access to MoveRDC organization
    echo "   Checking access to MoveRDC organization..."
    
    ORG_STATUS=$(curl -s -o /tmp/github_org.json -w "%{http_code}" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/orgs/MoveRDC")
    
    if [ "$ORG_STATUS" == "200" ]; then
        echo "✅ Access to MoveRDC organization confirmed"
        rm -f /tmp/github_org.json
    else
        echo "⚠️  Could not verify MoveRDC access (HTTP $ORG_STATUS)"
        echo "   Make sure the token's resource owner is set to MoveRDC"
        rm -f /tmp/github_org.json
    fi
else
    echo "⚠️  Skipping API validation (curl not available)"
fi

echo ""

# ============================================
# PRE-DOWNLOAD GITHUB MCP PACKAGE
# ============================================

echo "📦 Pre-downloading GitHub MCP package..."
echo "   This may take a moment on first run..."

# Run npx to cache the package (suppress output unless there's an error)
if npx -y @modelcontextprotocol/server-github --help > /dev/null 2>&1; then
    echo "✅ GitHub MCP package is ready"
else
    # The package might not have a --help flag, so check if it downloaded
    if npm list -g @modelcontextprotocol/server-github > /dev/null 2>&1 || \
       [ -d "$HOME/.npm/_npx" ]; then
        echo "✅ GitHub MCP package cached"
    else
        echo "⚠️  Could not verify package download"
        echo "   Claude Desktop will download it on first use."
    fi
fi

echo ""

# ============================================
# CONFIG FILE GENERATION
# ============================================

echo "📝 Generating config file..."
echo ""

# Check if config file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "⚠️  Existing config file found!"
    echo ""
    cat "$CONFIG_FILE"
    echo ""
    read -p "Overwrite with new config? (y/n): " OVERWRITE
    if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "Y" ]]; then
        echo ""
        echo "To manually add GitHub MCP, add this to your mcpServers:"
        echo ""
        echo '    "github": {'
        echo '      "command": "npx",'
        echo '      "args": ["-y", "@modelcontextprotocol/server-github"],'
        echo '      "env": {'
        echo '        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_TOKEN_HERE"'
        echo '      }'
        echo '    }'
        echo ""
        exit 0
    fi
    # Backup existing config
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"
    echo "📦 Backed up existing config"
fi

# Ask about additional MCP servers
echo ""
echo "Which MCP servers do you want to configure?"
echo ""

read -p "Include Snowflake MCP? (y/n): " INCLUDE_SNOWFLAKE

# Build config
echo ""
echo "Building configuration..."

CONFIG='{\n  "mcpServers": {\n'

# GitHub (always included)
CONFIG+='    "github": {\n'
CONFIG+='      "command": "npx",\n'
CONFIG+='      "args": ["-y", "@modelcontextprotocol/server-github"],\n'
CONFIG+='      "env": {\n'
CONFIG+="        \"GITHUB_PERSONAL_ACCESS_TOKEN\": \"$GITHUB_TOKEN\"\n"
CONFIG+='      }\n'
CONFIG+='    }'

# Snowflake
if [[ "$INCLUDE_SNOWFLAKE" == "y" || "$INCLUDE_SNOWFLAKE" == "Y" ]]; then
    echo ""
    read -p "Enter path to Snowflake MCP python (e.g., /Users/you/snowflake-mcp/venv/bin/python): " SNOWFLAKE_PYTHON
    read -p "Enter path to Snowflake MCP server.py (e.g., /Users/you/snowflake-mcp/server.py): " SNOWFLAKE_SCRIPT
    
    # Validate paths exist
    if [ ! -f "$SNOWFLAKE_PYTHON" ]; then
        echo "⚠️  Warning: Python path does not exist: $SNOWFLAKE_PYTHON"
    fi
    if [ ! -f "$SNOWFLAKE_SCRIPT" ]; then
        echo "⚠️  Warning: Server script does not exist: $SNOWFLAKE_SCRIPT"
    fi
    
    CONFIG+=',\n'
    CONFIG+='    "snowflake": {\n'
    CONFIG+="      \"command\": \"$SNOWFLAKE_PYTHON\",\n"
    CONFIG+="      \"args\": [\"$SNOWFLAKE_SCRIPT\"]\n"
    CONFIG+='    }'
fi

CONFIG+='\n  }\n}'

# Write config file
echo -e "$CONFIG" > "$CONFIG_FILE"

echo ""
echo "✅ Config file written to: $CONFIG_FILE"
echo ""

# ============================================
# VERIFICATION
# ============================================

echo "📋 Config file contents:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$CONFIG_FILE"
echo ""

# Validate JSON
if command -v python3 &> /dev/null; then
    if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
        echo "✅ JSON is valid"
    else
        echo "❌ JSON validation failed!"
        exit 1
    fi
fi

# ============================================
# NEXT STEPS
# ============================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                     SETUP COMPLETE                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Next Steps:"
echo ""
echo "  1. RESTART Claude Desktop completely"
echo "     - macOS: Cmd+Q to quit, then reopen"
echo "     - Windows: Right-click tray icon → Exit, then reopen"
echo ""
echo "  2. TEST the connection by asking Claude:"
echo "     \"Search for repositories in the MoveRDC organization\""
echo ""
echo "  3. If it doesn't work:"
echo "     - Make sure Claude Desktop fully restarted"
echo "     - Check the token has correct permissions"
echo "     - Review docs/github-mcp-setup.md for troubleshooting"
echo ""
echo "📚 Documentation:"
echo "   - GitHub MCP: docs/github-mcp-setup.md"
echo "   - Complete Guide: docs/mcp-setup-guide.md"
echo ""
echo "🔐 Security Reminder:"
echo "   - Never share your tokens"
echo "   - Rotate tokens every 90 days"
echo "   - Revoke tokens at: https://github.com/settings/tokens"
echo ""
