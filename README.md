# Claude Skills - Marketing Analytics

Claude AI skill packages for the RDC Marketing Analytics team. This repository contains custom skills that extend Claude's capabilities with domain-specific knowledge about our marketing data, processes, and best practices.

## 📦 Available Skills

### RDC Marketing Analytics v1.1
Specialized knowledge for real estate marketing analytics, including SEM campaign optimization, lead generation analysis, and channel performance insights.

**[Download Latest Version](dist/rdc-marketing-analytics-v1.1.skill)** ⬅️ Install this file in Claude

**What it includes:**
- SEM campaign types and terminology (DSA, Performance Max, Buy Intent)
- Snowflake database schemas (RDC_ANALYTICS, RDC_MARKETING)
- Lead metrics and calculation methods
- Geographic market analysis frameworks
- Common analysis patterns and best practices

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
"Analyze our Google Buy Intent campaigns from last month"
"Show me which DMAs have zero leads despite having inventory"
"Compare lead pricing across paid search vs. organic channels"
"What tables do you know about in RDC_ANALYTICS?"
```

## 📚 Documentation

- **[Installation Guide](docs/installation-guide.md)** - Detailed setup instructions
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

**Current Version: v1.1** (December 2024)
- Initial release with core marketing analytics knowledge
- Snowflake schema documentation (LEADS, GOOGLE_ADS_PERFORMANCE, CLICKSTREAM, PROPERTY_LISTINGS)
- Business logic and metric definitions
- Common analysis patterns

## 👥 Team

**Skill Maintainer**: Mikael (Marketing Analytics)

**Contributors**: Marketing Analytics Team

## 📁 Repository Structure

```
claude-skills-marketing/
├── README.md                          # This file
├── CONTRIBUTING.md                    # Contribution guidelines
├── CHANGELOG.md                       # Version history
├── skills/                            # Skill source files
│   └── rdc-marketing-analytics/
│       ├── SKILL.md                   # Core skill documentation
│       └── references/                # Reference documentation
│           ├── snowflake_schema.md    # Database schemas
│           └── business_logic.md      # Metrics and rules
├── dist/                              # Compiled .skill files (install these)
│   └── rdc-marketing-analytics-v1.1.skill
└── docs/                              # Team documentation
    ├── installation-guide.md
    └── update-workflow.md
```

## 🔒 Security

This repository contains internal business logic and database schemas. Access is restricted to MoveRDC organization members.

**Do not include**:
- API keys or credentials
- PII or sensitive customer data
- Actual query results with real data

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

**Installation problems?**
- Verify you're using the latest .skill file from `dist/`
- Try reinstalling
- Check Claude Desktop/claude.ai skills settings

## 📈 Roadmap

Future enhancements:
- Additional skills for specific analysis types
- Integration with more data sources
- Expanded best practices library
- Automated skill updates from data dictionary

---

**Last Updated**: December 2024  
**Repository**: MoveRDC/claude-skills-marketing  
**License**: Internal Use Only
