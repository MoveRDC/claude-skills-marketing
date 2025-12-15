# Changelog

All notable changes to the Marketing Analytics Claude Skills will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [v1.5] - 2025-12-15

### Removed

**Deprecated: skills-librarian**
- Removed skills-librarian skill from repository
- Functionality has been replaced by native Claude memory and past chats features
- Users should use Claude's built-in conversation search for skill discovery

### Maintenance
- Repository cleanup and dist file reorganization
- Updated documentation to remove librarian references

## [v1.4] - 2025-12-04

### Added

**New Skill: data-quality-validation**
- Systematic data validation framework for analytical work
- 9 validation categories: query correctness, data consistency, cross-source reconciliation, null values, date balance, anomalies, vertical filters, metric calculation, aggregation grain
- 12 real-world pitfalls with detailed examples and solutions
- Metric calculation validation (median vs mean, rate normalization)
- Aggregation grain validation (per-record vs per-entity detection)
- Contribution analysis validation for non-additive metrics
- Informational validation approach - never blocks analysis
- Decision frameworks for metric selection and data quality trade-offs
- Technical validation framework with SQL and Python examples
- Common pitfalls reference with actual scenarios from marketing analytics work

**Philosophy: Inform, Don't Block**
- All validations are informational
- Analysis always proceeds
- Users decide whether to fix or continue
- Supports informed decision-making without creating bottlenecks

## [v1.2] - 2025-12-03

### Added

**New Reference File: glossary.md**
- Comprehensive glossary of acronyms and terminology
- Two-sided marketplace business model documentation
- Platform definitions (Realtor.com, Homefinder, New-Com, Moving.com)
- Complete metric reference tables (EFR, ROAS, RPL, CPL, CPC, LSR)
- Campaign types and bidding strategies (VBB, BAU, Dual Serving)
- Products and programs (RCC, CPI)
- External factors documentation (seasonal, macroeconomic, competitive)
- Company context (vision, mission, values)

**Updated business_logic.md**
- Added EFR (Expected Future Revenue) as North Star metric
- Added ROAS calculation with interpretation guidelines
- Added RPL (Revenue Per Lead) metric
- Added CPC (Cost Per Click) metric
- Added LSR (Lead Submission Rate) metric
- Added Good Quality Ratio formula
- Added Sell Leads Ratio formula
- Added Spend definition with aliases
- Added VBB campaign type detection
- Added ROAS to underperforming campaign criteria
- Enhanced example queries with EFR and ROAS

**Updated SKILL.md**
- Added Business Context section with company overview
- Added Two-Sided Marketplace Model explanation
- Added Platforms & Properties documentation
- Added External Factors Affecting Performance section
- Added Key Metrics quick reference table
- Added VBB, BAU, RCC, Dual Serving to terminology
- Added reference to new glossary.md file
- Enhanced Team Goals with ROAS and quality metrics focus

### Changed
- Reorganized business_logic.md to lead with revenue metrics (EFR, ROAS)
- Updated analysis patterns to emphasize EFR and ROAS
- Enhanced best practices to always calculate ROAS using EFR

## [v1.1] - 2024-12-01

### Added
- Initial release with core marketing analytics knowledge
- Snowflake schema documentation (LEADS, GOOGLE_ADS_PERFORMANCE, CLICKSTREAM, PROPERTY_LISTINGS)
- Business logic and metric definitions (CPL, conversion rates, lead quality)
- Common analysis patterns
- Team goals and priorities
- Query best practices

---

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| v1.5 | 2025-12-15 | Removed skills-librarian (deprecated), repository cleanup |
| v1.4 | 2025-12-04 | Added data-quality-validation skill for systematic validation |
| v1.2 | 2025-12-03 | Added EFR, ROAS, business context, glossary, platform definitions |
| v1.1 | 2024-12-01 | Initial release with core analytics knowledge |
