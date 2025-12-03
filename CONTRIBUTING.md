# Contributing to Marketing Claude Skills

Thank you for helping improve our team's Claude skills! This guide explains how to contribute updates, improvements, and new knowledge.

## 🎯 What to Contribute

### High-Value Contributions

**New Data Sources**
- Tables added to Snowflake
- New fields in existing tables
- Additional data sources or integrations

**Business Logic Updates**
- Metric definition changes
- New KPI calculations
- Updated business rules or thresholds

**Best Practices**
- Effective query patterns you've discovered
- Analysis approaches that worked well
- Data quality insights

**Team Knowledge**
- Changed priorities or focus areas
- New workflows or processes
- Tool integrations

### Not Suitable for Skills

- One-off analysis results
- Temporary project work
- Personal notes or drafts
- Confidential strategy details

## 📝 How to Contribute

### Option 1: GitHub Issue (Easiest)

1. **Open an issue** using the "Skill Update" template
2. **Describe what needs to be added/changed**
3. **Provide examples** if applicable
4. **Skill maintainer** will incorporate and release new version

**Example Issue:**
```
Title: Add RDC_ANALYTICS.AGENT_ENGAGEMENT table

Description:
We now have a table tracking agent interactions with leads.

Table: RDC_ANALYTICS.AGENT_ENGAGEMENT
Key fields:
- ENGAGEMENT_ID (unique identifier)
- LEAD_ID (foreign key to LEADS)
- AGENT_ID 
- ENGAGEMENT_TYPE (email, call, text)
- ENGAGEMENT_TIMESTAMP
- RESPONSE_TIME (minutes)

Common use: Measuring lead response times and agent performance

Example query:
SELECT 
    AGENT_ID,
    AVG(RESPONSE_TIME) AS avg_response_minutes,
    COUNT(*) AS total_engagements
FROM RDC_ANALYTICS.AGENT_ENGAGEMENT
WHERE ENGAGEMENT_TIMESTAMP >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY AGENT_ID;
```

### Option 2: Direct Edit (For Maintainers)

1. **Clone the repository**
   ```bash
   git clone https://github.com/MoveRDC/claude-skills-marketing.git
   cd claude-skills-marketing
   ```

2. **Create a branch**
   ```bash
   git checkout -b add-agent-engagement-table
   ```

3. **Edit the appropriate file**
   - Core concepts/workflows: `skills/rdc-marketing-analytics/SKILL.md`
   - Database info: `skills/rdc-marketing-analytics/references/snowflake_schema.md`
   - Metrics/rules: `skills/rdc-marketing-analytics/references/business_logic.md`

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add AGENT_ENGAGEMENT table documentation"
   ```

5. **Ask Claude to repackage** (or use packaging script)
   ```
   "Claude, repackage the rdc-marketing-analytics skill with these updates"
   ```

6. **Update version number** in filename: `rdc-marketing-analytics-v1.2.skill`

7. **Update CHANGELOG.md** with your changes

8. **Push and create pull request**
   ```bash
   git push origin add-agent-engagement-table
   ```

9. **Request review** from skill maintainer

### Option 3: Slack Suggestion

1. **Post in #marketing-analytics** with `[SKILL UPDATE]` tag
2. **Describe the change** and why it's valuable
3. **Maintainer** will track and incorporate in next release

## 📋 Contribution Guidelines

### Writing Style

**Be concise** - Skills share context window with everything else
- ✅ "DSA campaigns auto-generate ads from website content"
- ❌ "Dynamic Search Ads are a type of campaign available in Google Ads that automatically generates advertisements based on the content found on your website, which can be very helpful for..."

**Be specific** - Include examples and concrete details
- ✅ Show example queries with realistic table/field names
- ❌ Vague descriptions like "query the database for information"

**Be practical** - Focus on what Claude needs to know
- ✅ "Always specify database and schema: RDC_ANALYTICS.SCHEMA_NAME"
- ❌ Background on why databases exist or general SQL tutorials

### File Organization

**SKILL.md** - Core knowledge (~5-10KB)
- Key concepts and terminology
- Team goals and priorities
- Common workflows
- When to use reference files

**references/snowflake_schema.md** - Database details
- Table structures
- Field definitions
- Common joins
- Example queries

**references/business_logic.md** - Calculations and rules
- Metric definitions
- Business rules
- Data quality standards
- Reporting conventions

### Quality Standards

✅ **Include examples** - Show don't just tell
✅ **Test queries** - Verify SQL actually works
✅ **Update related sections** - Keep documentation consistent
✅ **Check formatting** - Use proper markdown
✅ **Update changelog** - Document what changed and why

## 🔄 Update Workflow

### Regular Update Cycle

**Monthly Review** (1st week of month)
1. Maintainer reviews open issues and Slack suggestions
2. Consolidates updates into new skill version
3. Updates CHANGELOG
4. Releases new version
5. Announces in Slack with change summary

### Emergency Updates

For urgent changes (broken queries, wrong information):
1. Open issue with `[URGENT]` tag
2. Maintainer prioritizes and releases patch version
3. Team notified immediately

## 🏷️ Version Numbering

We use semantic versioning: `vMAJOR.MINOR.PATCH`

**MAJOR** (v2.0) - Significant restructuring or breaking changes
**MINOR** (v1.2) - New features, tables, or substantial additions
**PATCH** (v1.1.1) - Bug fixes, clarifications, minor updates

## ✅ Checklist for Skill Updates

Before requesting a skill update, verify:

- [ ] Information is accurate and tested
- [ ] Examples include real table/field names from our environment
- [ ] Documentation is clear and concise
- [ ] Related sections are updated (if needed)
- [ ] Change provides value to multiple team members
- [ ] No sensitive data or credentials included

## 🎨 Template Examples

### Adding a New Table

```markdown
#### RDC_ANALYTICS.TABLE_NAME
Brief description of what this table contains.

**Key Fields:**
- `FIELD_1` - Description
- `FIELD_2` - Description

**Common Uses:**
- Use case 1
- Use case 2

**Example Query:**
```sql
SELECT ...
FROM RDC_ANALYTICS.TABLE_NAME
WHERE ...;
```
```

### Adding a New Metric

```markdown
### Metric Name

**Definition:** Clear explanation of what this measures.

**Calculation:**
```sql
SUM(field_a) / NULLIF(COUNT(field_b), 0) AS metric_name
```

**Use when:** When to use this metric vs alternatives
**Related metrics:** Other relevant metrics
```

### Adding a Best Practice

```markdown
### Practice Name

**What:** Brief description
**Why:** Explanation of benefit
**How:** 
```sql
-- Example implementation
```
**When to use:** Specific scenarios
```

## 🤝 Recognition

Contributors will be acknowledged in:
- CHANGELOG entries
- README contributors section
- Skill metadata (for major contributions)

## 📞 Questions?

- **General questions**: #marketing-analytics Slack channel
- **Technical issues**: Open a GitHub issue
- **Skill maintainer**: @mikael on Slack

## 🚀 Thank You!

Your contributions help the entire team work more effectively with Claude. Every improvement, no matter how small, makes a difference!
