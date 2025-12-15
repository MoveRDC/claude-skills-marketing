# Claude Skills - Marketing Analytics

Claude AI skill packages for the RDC Marketing Analytics team. This repository contains custom skills that extend Claude's capabilities with domain-specific knowledge about our marketing data, processes, and best practices.

## 📦 Available Skills

### RDC Marketing Analytics v1.3
Specialized knowledge for real estate marketing analytics, including SEM campaign optimization, lead generation analysis, and channel performance insights.

**[Download Latest Version](dist/rdc-marketing-analytics-v1.3.skill)** ⬅️ Install this file in Claude

**What it includes:**
- Business context (two-sided marketplace model, platforms, external factors)
- Key metrics and formulas (EFR, ROAS, RPL, CPL, LSR, and more)
- SEM campaign types and terminology (DSA, Performance Max, VBB, Buy Intent)
- Snowflake database schemas (RDC_ANALYTICS, RDC_MARKETING)
- Lead metrics and quality calculations
- Geographic market analysis frameworks
- Common analysis patterns and best practices

### Data Quality Validation v1.0
Systematic data validation, error detection, cross-source reconciliation, and query correctness checking for analytical work.

**[Download Latest Version](dist/data-quality-validation-v1.0.skill)** ⬅️ Install this file in Claude

**What it includes:**
- 9 validation categories (query correctness, data consistency, cross-source reconciliation, null values, date balance, anomalies, vertical filters, metric calculation, aggregation grain)
- 12 real-world pitfalls with examples and solutions
- Metric calculation guidance (median vs mean, rate normalization)
- Aggregation grain validation (per-record vs per-entity detection)
- Contribution analysis for non-additive metrics (understanding expected gaps)
- 100% informational approach - validates without blocking analysis
- Decision frameworks for metric selection and data quality trade-offs

**Triggers:** "validate this query", "check for errors", "why don't these numbers match", "should I use median or mean", "why don't contributions sum to 100%", "reconcile these metrics", "verify data quality"

### RDC Snowflake Navigator v1.1
Comprehensive guide to RDC's Snowflake data warehouse for marketing and consumer analytics.

**[Download Latest Version](dist/rdc-snowflake-navigator-v1.1.skill)** ⬅️ Install this file in Claude

**What it includes:**
- Core table schemas (clickstream, marketing conversions, SEM, app, paid social)
- Incrementality multipliers and IEFR calculations
- Lead attribution logic and EFR components
- Query patterns and best practices

## 🚀 Quick Start

### Installation

1. **Download the skill**: Click the download link above or navigate to the `dist/` folder
2. **Install in Claude**:
   - **Claude Desktop**: Settings → Skills → Install (or drag & drop)
   - **claude.ai**: Skills menu → Upload skill file
3. **Verify**: Ask Claude "What skills do you have?" to confirm installation

### First Use

Try these example queries:
```
"What is our North Star metric and how do we calculate ROAS?"
"Analyze our Google Buy Intent campaigns from last month"
"Show me which DMAs have zero leads despite having inventory"
"What external factors affect our lead volume?"
"Validate this query for potential issues"
"Why don't these contribution percentages add up to 100%?"
```

## 🔧 MCP Server Setup

To give Claude direct access to your tools (GitHub, Snowflake, Google Ads), set up MCP servers:

### Quick Setup (Recommended)

Run the interactive setup script:
```bash
git clone https://github.com/MoveRDC/claude-skills-marketing.git
cd claude-skills-marketing
chmod +x scripts/setup-mcp-servers.sh
./scripts/setup-mcp-servers.sh
```

### Manual Setup

See the detailed guides:
- **[Complete MCP Setup Guide](docs/mcp-setup-guide.md)** - All MCP servers (Snowflake, GitHub, Google Ads)
- **[GitHub MCP Setup](docs/github-mcp-setup.md)** - GitHub integration setup

### Example Config

Your `claude_desktop_config.json` should look like:
```json
{
  "mcpServers": {
    "snowflake": {
      "command": "/path/to/snowflake-mcp/venv/bin/python",
      "args": ["/path/to/snowflake-mcp/server.py"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_TOKEN_HERE"
      }
    },
    "googleAds": {
      "command": "/path/to/mcp-google-ads/.venv/bin/python",
      "args": ["/path/to/mcp-google-ads/google_ads_server.py"]
    }
  }
}
```

## 📚 Documentation

- **[Installation Guide](docs/installation-guide.md)** - Detailed skill setup instructions
- **[MCP Setup Guide](docs/mcp-setup-guide.md)** - Complete MCP server configuration
- **[GitHub MCP Setup](docs/github-mcp-setup.md)** - GitHub integration setup
- **[Update Workflow](docs/update-workflow.md)** - How to contribute and update skills
- **[CHANGELOG](CHANGELOG.md)** - Version history and updates

## 🤝 Contributing

We welcome contributions from the marketing analytics team! See **[CONTRIBUTING.md](CONTRIBUTING.md)** for:
- How to suggest improvements
- Adding new tables or metrics
- Updating business logic
- Proposing new skills

### Quick Contribution Workflow

1. **Discover something new** (table, metric, best practice)
2. **Document it** in a GitHub issue or Slack
3. **Skill maintainer** incorporates the change
4. **New version** is released and team is notified
5. **Everyone reinstalls** the updated skill

## 🔄 Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

**Current Version: v1.5** (December 2025)
- Removed deprecated skills-librarian skill
- Repository cleanup and maintenance

**Previous: v1.4** (December 2025)
- Added data-quality-validation skill

## 👥 Team

**Skill Maintainer**: Marketing Analytics Team

**Contributors**: Marketing Analytics Team

## 📁 Repository Structure

```
claude-skills-marketing/
├── README.md                          # This file
├── CONTRIBUTING.md                    # Contribution guidelines
├── CHANGELOG.md                       # Version history
├── skills/                            # Skill source files
│   ├── data-quality-validation/       # Data quality & validation
│   │   ├── SKILL.md                   # Core validation skill
│   │   └── references/                # Validation references
│   │       ├── validation_framework.md # Technical framework
│   │       └── common_pitfalls.md     # Real-world examples
│   ├── rdc-marketing-analytics/
│   │   ├── SKILL.md                   # Core skill documentation
│   │   └── references/                # Reference documentation
│   │       ├── snowflake_schema.md    # Database schemas
│   │       ├── business_logic.md      # Metrics and rules
│   │       └── glossary.md            # Terms and acronyms
│   ├── rdc-snowflake-navigator/       # Snowflake navigation
│   │   ├── SKILL.md                   # Navigator skill
│   │   └── references/                # Schema references
│   ├── business-glossary/             # Business terminology
│   │   └── SKILL.md                   # Glossary skill
│   ├── seller-analytics/              # Seller vertical analytics
│   │   └── SKILL.md                   # Seller skill
│   └── taxonomy-updater/              # Campaign taxonomy
│       └── SKILL.md                   # Taxonomy skill
├── dist/                              # Compiled .skill files (install these)
│   ├── data-quality-validation-v1.0.skill
│   └── rdc-marketing-analytics-v1.3.skill
├── docs/                              # Team documentation
│   ├── installation-guide.md          # Skill installation
│   ├── mcp-setup-guide.md             # Complete MCP setup
│   ├── github-mcp-setup.md            # GitHub MCP setup
│   └── update-workflow.md             # Contribution workflow
└── scripts/                           # Setup scripts
    └── setup-mcp-servers.sh           # Interactive MCP setup
```

## 🔒 Security

This repository contains internal business logic and database schemas. Access is restricted to MoveRDC organization members.

**Do not include**:
- API keys or credentials
- PII or sensitive customer data
- Actual query results with real data

**Token Security**:
- Never share tokens in chat or email
- Rotate tokens every 90 days
- Use fine-grained tokens with minimum permissions

## 💡 Tips

- **Keep skills installed**: Reinstall after each update to get the latest knowledge
- **Suggest improvements**: Found something unclear? Open an issue!
- **Share learnings**: If you develop a useful analysis pattern, add it to the skill
- **Ask Claude**: "What's in our marketing analytics skill?" to see what it knows

## 🆘 Support

**Questions about the skill?**
- Open a GitHub issue
- Ask in #marketing-analytics Slack channel
- Contact the skill maintainer

**MCP Setup problems?**
- Check the troubleshooting section in [mcp-setup-guide.md](docs/mcp-setup-guide.md)
- Verify prerequisites (Node.js, Python)
- Ensure Claude Desktop fully restarted after config changes

## 📈 Roadmap

Future enhancements:
- Additional skills for specific analysis types
- Integration with more data sources
- Expanded best practices library
- Automated skill updates from data dictionary

---

**Last Updated**: December 2025  
**Repository**: MoveRDC/claude-skills-marketing  
**License**: Internal Use Only
