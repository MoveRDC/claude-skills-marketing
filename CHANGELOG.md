# Changelog

All notable changes to the RDC Marketing Analytics skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1] - 2024-12-02

### Added - Initial Release

#### Core Skill (SKILL.md)
- Key concepts and terminology
  - Campaign types: DSA, Performance Max, Buy Intent, Brand
  - Lead metrics: Lead Price, Lead Quality, Volume-Weighted Performance, Zero-Lead Markets
  - Geographic hierarchy: DMA, State-Level Analysis, Market Alignment
  - Channel attribution: Paid Search, Organic Search, Direct, Referral
- Team goals and priorities
  - SEM Campaign Optimization
  - Lead Generation Analysis
  - Channel Performance
  - Cross-Functional Collaboration
- Common analysis patterns
  - Campaign Performance Analysis
  - Geographic Market Analysis
  - Channel Attribution
  - Clickstream Analysis
- Best practices for queries, data quality, reporting, and collaboration
- Tool integrations: Snowflake, Google Ads, Jira, Slack

#### Database Schema (references/snowflake_schema.md)
- RDC_ANALYTICS database documentation
  - LEADS table (lead information and attribution)
  - CLICKSTREAM table (user behavior and session tracking)
  - PROPERTY_LISTINGS table (listing inventory)
- RDC_MARKETING database documentation
  - GOOGLE_ADS_PERFORMANCE table (campaign metrics)
- Common table joins and relationships
- Query best practices and optimization techniques
- Data refresh schedules

#### Business Logic (references/business_logic.md)
- Core metric definitions
  - Lead Price (median, mean, volume-weighted)
  - Cost Per Lead (CPL)
  - Lead Quality metrics
  - Conversion Rate calculations
- Campaign classification rules
- Underperforming campaign criteria
- Geographic market rules (DMA prioritization, zero-lead analysis)
- Data quality rules and anomaly detection
- Aggregation best practices (MEDIAN vs AVG, date ranges)
- Attribution rules (last-touch, multi-touch considerations)
- Reporting standards (significant figures, change calculations, benchmarks)

### Repository Structure
- Created skills/ directory for skill source files
- Created dist/ directory for compiled .skill files
- Created docs/ directory for team documentation
- Added README.md with installation and usage guide
- Added CONTRIBUTING.md with contribution guidelines
- Added this CHANGELOG.md

### Notes
- Initial skill based on team's current Snowflake environment (RDC_ANALYTICS, RDC_MARKETING schemas)
- Focused on most commonly used tables and analysis patterns
- Designed for easy updates as team knowledge grows

---

## Version Template for Future Updates

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features, tables, or capabilities

### Changed
- Updates to existing documentation or logic

### Deprecated
- Features being phased out

### Removed
- Removed features or deprecated content

### Fixed
- Bug fixes or corrections

### Security
- Security-related changes
```

---

## Upcoming Changes (Planned)

Track potential future updates here:

- [ ] Add RDC_ANALYTICS.AGENT_ENGAGEMENT table (when available)
- [ ] Expand clickstream analysis patterns
- [ ] Add multi-touch attribution examples
- [ ] Include CAC (Customer Acquisition Cost) metrics
- [ ] Document A/B testing analysis workflows

---

**Maintainer**: Mikael  
**Last Updated**: December 2, 2024
