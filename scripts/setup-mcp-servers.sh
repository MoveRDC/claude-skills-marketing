#!/bin/bash
#
# MCP Server Setup & Update Script for Claude Desktop
# Sets up and updates MCP servers based on team recommendations
#
# Usage: 
#   ./setup-mcp-servers.sh          # Interactive setup/update
#   ./setup-mcp-servers.sh --check  # Check for updates only
#   ./setup-mcp-servers.sh --force  # Force update all servers
#

set -e

# ============================================
# CONFIGURATION
# ============================================

REPO_RAW_URL="https://raw.githubusercontent.com/MoveRDC/claude-skills-marketing/main"
RECOMMENDED_CONFIG_URL="$REPO_RAW_URL/config/recommended-mcp-servers.json"
SCRIPT_VERSION="2.0.0"

# ============================================
# PARSE ARGUMENTS
# ============================================

CHECK_ONLY=false
FORCE_UPDATE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        --help|-h)
            echo "MCP Server Setup & Update Script"
            echo ""
            echo "Usage: ./setup-mcp-servers.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --check    Check for updates without making changes"
            echo "  --force    Force update all managed servers"
            echo "  --help     Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ============================================
# HEADER
# ============================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       MCP Server Setup & Update for Claude Desktop         ║"
echo "║       Marketing Analytics Team                             ║"
echo "║       Script Version: $SCRIPT_VERSION                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================
# DETECT OS & SET PATHS
# ============================================

if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
    CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
    LOCAL_STATE_FILE="$CONFIG_DIR/.mcp-setup-state.json"
    OS="macOS"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    CONFIG_DIR="$APPDATA/Claude"
    CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
    LOCAL_STATE_FILE="$CONFIG_DIR/.mcp-setup-state.json"
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

# Check required tools
MISSING_PREREQS=false

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js installed: $NODE_VERSION"
else
    echo "❌ Node.js not found"
    echo "   Install with: brew install node (macOS) or download from https://nodejs.org"
    MISSING_PREREQS=true
fi

if command -v npx &> /dev/null; then
    NPX_VERSION=$(npx --version)
    echo "✅ npx installed: $NPX_VERSION"
else
    echo "❌ npx not found (should come with Node.js)"
    MISSING_PREREQS=true
fi

if command -v curl &> /dev/null; then
    echo "✅ curl installed"
else
    echo "❌ curl not found (required for updates)"
    MISSING_PREREQS=true
fi

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python installed: $PYTHON_VERSION"
else
    echo "⚠️  Python 3 not found (optional, needed for Snowflake MCP)"
fi

if [ "$MISSING_PREREQS" = true ]; then
    echo ""
    echo "❌ Missing required prerequisites. Please install them and try again."
    exit 1
fi

echo ""

# ============================================
# ENSURE CONFIG DIRECTORY EXISTS
# ============================================

if [ ! -d "$CONFIG_DIR" ]; then
    echo "📂 Creating config directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

# ============================================
# FETCH RECOMMENDED CONFIGURATION
# ============================================

echo "📡 Fetching recommended MCP server configuration..."

RECOMMENDED_CONFIG=$(curl -s "$RECOMMENDED_CONFIG_URL" 2>/dev/null)

if [ -z "$RECOMMENDED_CONFIG" ]; then
    echo "❌ Could not fetch recommended configuration from repository"
    echo "   URL: $RECOMMENDED_CONFIG_URL"
    echo "   Check your internet connection and try again."
    exit 1
fi

# Parse version from recommended config
RECOMMENDED_VERSION=$(echo "$RECOMMENDED_CONFIG" | python3 -c "import sys, json; print(json.load(sys.stdin).get('version', 'unknown'))" 2>/dev/null || echo "unknown")
LAST_UPDATED=$(echo "$RECOMMENDED_CONFIG" | python3 -c "import sys, json; print(json.load(sys.stdin).get('lastUpdated', 'unknown'))" 2>/dev/null || echo "unknown")

echo "✅ Fetched recommended config (version: $RECOMMENDED_VERSION, updated: $LAST_UPDATED)"
echo ""

# ============================================
# CHECK CURRENT STATE
# ============================================

CURRENT_VERSION="none"
NEEDS_UPDATE=false

if [ -f "$LOCAL_STATE_FILE" ]; then
    CURRENT_VERSION=$(python3 -c "import sys, json; print(json.load(open('$LOCAL_STATE_FILE')).get('version', 'none'))" 2>/dev/null || echo "none")
fi

if [ "$CURRENT_VERSION" != "$RECOMMENDED_VERSION" ]; then
    NEEDS_UPDATE=true
    echo "📦 Update available!"
    echo "   Current version: $CURRENT_VERSION"
    echo "   Latest version:  $RECOMMENDED_VERSION"
else
    echo "✅ You have the latest configuration (version: $CURRENT_VERSION)"
fi

echo ""

# ============================================
# CHECK-ONLY MODE
# ============================================

if [ "$CHECK_ONLY" = true ]; then
    if [ "$NEEDS_UPDATE" = true ]; then
        echo "Run without --check to apply updates."
        exit 0
    else
        echo "No updates needed."
        exit 0
    fi
fi

# ============================================
# LOAD EXISTING CONFIG (IF ANY)
# ============================================

EXISTING_SERVERS="{}"
EXISTING_GITHUB_TOKEN=""
EXISTING_SNOWFLAKE_PYTHON=""
EXISTING_SNOWFLAKE_SCRIPT=""

if [ -f "$CONFIG_FILE" ]; then
    echo "📂 Loading existing configuration..."
    
    # Extract existing mcpServers
    EXISTING_SERVERS=$(python3 -c "
import sys, json
try:
    config = json.load(open('$CONFIG_FILE'))
    print(json.dumps(config.get('mcpServers', {})))
except:
    print('{}')
" 2>/dev/null || echo "{}")
    
    # Extract existing GitHub token if present
    EXISTING_GITHUB_TOKEN=$(python3 -c "
import sys, json
try:
    config = json.load(open('$CONFIG_FILE'))
    github = config.get('mcpServers', {}).get('github', {})
    env = github.get('env', {})
    print(env.get('GITHUB_PERSONAL_ACCESS_TOKEN', ''))
except:
    print('')
" 2>/dev/null || echo "")
    
    # Extract existing Snowflake config if present
    EXISTING_SNOWFLAKE_PYTHON=$(python3 -c "
import sys, json
try:
    config = json.load(open('$CONFIG_FILE'))
    sf = config.get('mcpServers', {}).get('snowflake', {})
    print(sf.get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")
    
    EXISTING_SNOWFLAKE_SCRIPT=$(python3 -c "
import sys, json
try:
    config = json.load(open('$CONFIG_FILE'))
    sf = config.get('mcpServers', {}).get('snowflake', {})
    args = sf.get('args', [])
    print(args[0] if args else '')
except:
    print('')
" 2>/dev/null || echo "")
    
    if [ -n "$EXISTING_GITHUB_TOKEN" ]; then
        echo "   Found existing GitHub token"
    fi
    if [ -n "$EXISTING_SNOWFLAKE_PYTHON" ]; then
        echo "   Found existing Snowflake configuration"
    fi
    echo ""
fi

# ============================================
# GITHUB TOKEN SETUP
# ============================================

GITHUB_TOKEN="$EXISTING_GITHUB_TOKEN"

if [ -z "$GITHUB_TOKEN" ] || [ "$FORCE_UPDATE" = true ]; then
    echo "🔐 GitHub Personal Access Token Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ -n "$EXISTING_GITHUB_TOKEN" ]; then
        echo ""
        echo "You have an existing GitHub token configured."
        read -p "Do you want to replace it? (y/n): " REPLACE_TOKEN
        if [[ "$REPLACE_TOKEN" != "y" && "$REPLACE_TOKEN" != "Y" ]]; then
            GITHUB_TOKEN="$EXISTING_GITHUB_TOKEN"
            echo "✅ Keeping existing token"
        else
            GITHUB_TOKEN=""
        fi
    fi
    
    if [ -z "$GITHUB_TOKEN" ]; then
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
    fi
fi

# ============================================
# VALIDATE GITHUB TOKEN
# ============================================

echo ""
echo "🔍 Validating GitHub token..."

# Check token format
if [[ "$GITHUB_TOKEN" == ghp_* ]] || [[ "$GITHUB_TOKEN" == github_pat_* ]]; then
    echo "✅ Token format looks correct"
else
    echo "⚠️  Token format is unusual (expected ghp_* or github_pat_*)"
fi

# Test token against GitHub API
echo "   Testing token against GitHub API..."

HTTP_STATUS=$(curl -s -o /tmp/github_response.json -w "%{http_code}" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/user")

if [ "$HTTP_STATUS" == "200" ]; then
    GITHUB_USER=$(cat /tmp/github_response.json | python3 -c "import sys, json; print(json.load(sys.stdin).get('login', 'unknown'))" 2>/dev/null || echo "unknown")
    echo "✅ Token is valid! Authenticated as: $GITHUB_USER"
    rm -f /tmp/github_response.json
elif [ "$HTTP_STATUS" == "401" ]; then
    echo "❌ Token is invalid or expired (HTTP 401)"
    echo "   Please generate a new token and try again."
    rm -f /tmp/github_response.json
    exit 1
elif [ "$HTTP_STATUS" == "403" ]; then
    echo "❌ Token lacks required permissions (HTTP 403)"
    rm -f /tmp/github_response.json
    exit 1
else
    echo "⚠️  Could not verify token (HTTP $HTTP_STATUS)"
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
else
    echo "⚠️  Could not verify MoveRDC access (HTTP $ORG_STATUS)"
fi
rm -f /tmp/github_org.json

echo ""

# ============================================
# SNOWFLAKE SETUP (OPTIONAL)
# ============================================

SNOWFLAKE_PYTHON="$EXISTING_SNOWFLAKE_PYTHON"
SNOWFLAKE_SCRIPT="$EXISTING_SNOWFLAKE_SCRIPT"
INCLUDE_SNOWFLAKE=false

if [ -n "$EXISTING_SNOWFLAKE_PYTHON" ]; then
    INCLUDE_SNOWFLAKE=true
    echo "📊 Snowflake MCP Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Existing Python path: $EXISTING_SNOWFLAKE_PYTHON"
    echo "   Existing script path: $EXISTING_SNOWFLAKE_SCRIPT"
    read -p "Keep existing Snowflake configuration? (y/n): " KEEP_SNOWFLAKE
    if [[ "$KEEP_SNOWFLAKE" != "y" && "$KEEP_SNOWFLAKE" != "Y" ]]; then
        read -p "Remove Snowflake MCP entirely? (y/n): " REMOVE_SNOWFLAKE
        if [[ "$REMOVE_SNOWFLAKE" == "y" || "$REMOVE_SNOWFLAKE" == "Y" ]]; then
            INCLUDE_SNOWFLAKE=false
            SNOWFLAKE_PYTHON=""
            SNOWFLAKE_SCRIPT=""
        else
            read -p "Enter new path to Snowflake MCP python: " SNOWFLAKE_PYTHON
            read -p "Enter new path to Snowflake MCP server.py: " SNOWFLAKE_SCRIPT
        fi
    fi
    echo ""
else
    read -p "Include Snowflake MCP? (y/n): " SETUP_SNOWFLAKE
    if [[ "$SETUP_SNOWFLAKE" == "y" || "$SETUP_SNOWFLAKE" == "Y" ]]; then
        INCLUDE_SNOWFLAKE=true
        read -p "Enter path to Snowflake MCP python (e.g., /Users/you/snowflake-mcp/venv/bin/python): " SNOWFLAKE_PYTHON
        read -p "Enter path to Snowflake MCP server.py (e.g., /Users/you/snowflake-mcp/server.py): " SNOWFLAKE_SCRIPT
        
        # Validate paths
        if [ ! -f "$SNOWFLAKE_PYTHON" ]; then
            echo "⚠️  Warning: Python path does not exist: $SNOWFLAKE_PYTHON"
        fi
        if [ ! -f "$SNOWFLAKE_SCRIPT" ]; then
            echo "⚠️  Warning: Server script does not exist: $SNOWFLAKE_SCRIPT"
        fi
    fi
    echo ""
fi

# ============================================
# PRE-DOWNLOAD GITHUB MCP PACKAGE
# ============================================

echo "📦 Ensuring GitHub MCP package is cached..."

if npx -y @modelcontextprotocol/server-github --help > /dev/null 2>&1; then
    echo "✅ GitHub MCP package is ready"
else
    if [ -d "$HOME/.npm/_npx" ]; then
        echo "✅ GitHub MCP package cached"
    else
        echo "⚠️  Package will download on first use"
    fi
fi

echo ""

# ============================================
# BUILD AND WRITE CONFIG
# ============================================

echo "📝 Building configuration..."

# Backup existing config
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "📦 Backed up existing config to: $BACKUP_FILE"
fi

# Build config using Python for proper JSON handling
python3 << EOF
import json

config = {
    "mcpServers": {
        "github": {
            "command": "npx",
            "args": ["-y", "@modelcontextprotocol/server-github"],
            "env": {
                "GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_TOKEN"
            }
        }
    }
}

# Add Snowflake if configured
if "$INCLUDE_SNOWFLAKE" == "true" and "$SNOWFLAKE_PYTHON" and "$SNOWFLAKE_SCRIPT":
    config["mcpServers"]["snowflake"] = {
        "command": "$SNOWFLAKE_PYTHON",
        "args": ["$SNOWFLAKE_SCRIPT"]
    }

with open("$CONFIG_FILE", "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")

print("✅ Config file written")
EOF

# Save state file for version tracking
python3 << EOF
import json
from datetime import datetime

state = {
    "version": "$RECOMMENDED_VERSION",
    "lastUpdated": datetime.now().isoformat(),
    "scriptVersion": "$SCRIPT_VERSION"
}

with open("$LOCAL_STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
    f.write("\n")
EOF

echo ""

# ============================================
# VERIFICATION
# ============================================

echo "📋 Config file contents:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$CONFIG_FILE"
echo ""

# Validate JSON
if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "✅ JSON is valid"
else
    echo "❌ JSON validation failed!"
    exit 1
fi

# ============================================
# COMPLETION
# ============================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                     SETUP COMPLETE                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Configuration Summary:"
echo "   • Version: $RECOMMENDED_VERSION"
echo "   • GitHub MCP: ✅ Configured"
if [ "$INCLUDE_SNOWFLAKE" = true ]; then
    echo "   • Snowflake MCP: ✅ Configured"
else
    echo "   • Snowflake MCP: ⏭️  Skipped"
fi
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
echo "🔄 To check for updates later, run:"
echo "   ./setup-mcp-servers.sh --check"
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
