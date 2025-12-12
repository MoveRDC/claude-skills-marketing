# Business Glossary Skill

A comprehensive reference guide for marketing and business terminology used at realtor.com.

## What This Skill Provides

This skill gives Claude instant access to 80+ marketing terms, metrics, and concepts including:

- **KPIs & Metrics**: ROAS, EFR, CPL, RPL, LSR, conversion rates, and more
- **Campaign Types**: DSA, PMax, Brand, Buy Intent, VBB strategies
- **Business Concepts**: Two-sided marketplace, seasonal trends, market dynamics
- **Geographic Terms**: DMA tiers, market alignment, zero-lead markets
- **Product Terms**: RCC, Homefinder, Pricing Workstream
- **Analytical Terms**: Attribution models, date ranges, data quality standards

## Why Use This Skill?

### For Marketing Analysts
- Ensures Claude uses consistent metric definitions in analyses
- Provides correct formulas for KPI calculations
- Explains business context behind metrics

### For Stakeholder Communication
- Clarifies jargon and acronyms
- Provides context for non-technical audiences
- Standardizes terminology across teams

### For Cross-Functional Collaboration
- Bridges gaps between marketing, product, and analytics teams
- Ensures shared understanding of business concepts
- Facilitates clearer communication

## Installation

1. Download this `SKILL.md` file
2. Create a directory in your skills folder: `~/.config/claude/skills/business-glossary/`
3. Place `SKILL.md` in that directory
4. Restart Claude Desktop

## Usage Examples

### Example 1: Clarifying Metrics
**You**: "What's the difference between CPL and RPL?"

**Claude**: *[References glossary]* CPL (Cost Per Lead) measures acquisition efficiency - how much you spend to get a lead. Formula: CPL = Spend / Leads. RPL (Revenue Per Lead) measures lead value - expected revenue per lead. Formula: RPL = EFR / Leads. Together they determine ROAS.

### Example 2: Consistent Calculations
**You**: "Calculate ROAS for this campaign"

**Claude**: *[Uses glossary formula]* ROAS = EFR / Spend. Per the glossary, always calculate ROAS using EFR before using other revenue columns...

### Example 3: Explaining Business Context
**You**: "Why is our lead quality lower in paid search?"

**Claude**: *[References glossary business rule]* According to the glossary's data quality rules, paid search consistently delivers leads with 30-37% lower median list prices than other channels. This is expected behavior factored into channel strategy...

### Example 4: Campaign Analysis
**You**: "Is this campaign underperforming?"

**Claude**: *[Applies glossary criteria]* Based on the glossary's underperforming campaign criteria, I'll check if it meets any of these conditions:
1. High CPL: >1.5x channel median
2. Low Volume: <10 leads in 30 days with >$1K spend
3. Declining Trend: 30% YoY/QoQ decline
4. Quality Issues: Median lead price <0.5x channel median...

## What Makes This Different?

### Traditional Approach (Without Skill)
- You explain metrics every time
- Risk of inconsistent definitions
- Claude might use generic formulas that don't match your business
- No business context in responses

### With Business Glossary Skill
- Claude knows your exact metric definitions
- Consistent terminology across all analyses
- Business rules and context automatically applied
- Formulas match your data warehouse calculations

## Sharing With Your Team

This skill is designed to be shared across marketing teams. Benefits of team adoption:

1. **Consistency**: Everyone gets the same metric definitions
2. **Onboarding**: New team members learn terminology faster
3. **Documentation**: Living reference that stays up-to-date
4. **Collaboration**: Shared language reduces miscommunication

### How to Share
1. Export this skill as a `.zip` or share the `SKILL.md` file
2. Team members install via skills-librarian or manual installation
3. Everyone references the same source of truth
4. Updates propagate when skill is updated

## Maintenance

This glossary should be updated when:
- New metrics or KPIs are introduced
- Business rules change
- Campaign strategies evolve
- Common terminology questions arise
- Cross-team confusion is identified

**Update Process**:
1. Edit the `SKILL.md` file
2. Add new terms in the appropriate section
3. Include definition, formula (if applicable), and usage context
4. Redistribute updated version to team

## Tips for Best Results

1. **Reference Explicitly**: When you want Claude to use specific definitions, mention the glossary: "Using the glossary definitions, calculate ROAS..."

2. **Combine with Other Skills**: This glossary works great alongside the `real-estate-marketing-analytics` skill for data analysis

3. **Update Regularly**: As your business evolves, keep the glossary current

4. **Be Specific**: If a term has multiple meanings (like "lead price" can mean cost OR property value), the glossary clarifies which is being discussed

## Questions or Issues?

If you find:
- Missing terms that should be included
- Incorrect or outdated definitions
- Ambiguous terminology
- Opportunities to improve

Update the glossary and share with your team!

## Version History

- **v1.0** (December 2024): Initial release combining GEM role, PM Co-Pilot, and marketing analytics skill terminology

---

**Related Skills**:
- `real-estate-marketing-analytics`: For Snowflake queries and analysis workflows
- `skills-librarian`: For managing and discovering skills
- `seller-analytics`: For seller vertical-specific terminology
