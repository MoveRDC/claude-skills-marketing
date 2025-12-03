# Update Workflow

How the team collaborates on skill updates and maintenance.

## Overview

This workflow ensures skills stay current while maintaining quality. It balances open contribution with centralized quality control.

## Roles

### Skill Maintainer (Currently: Mikael)
- Reviews and approves changes
- Repackages skills after updates
- Manages releases and versioning
- Announces updates to team

### Contributors (All Team Members)
- Suggest improvements
- Report issues
- Share best practices
- Test new versions

### Reviewers (Optional)
- Senior team members who review major changes
- Ensure accuracy of business logic
- Validate data quality rules

## Update Cycle

### Regular Updates (Monthly)

**Week 1: Collection**
- Maintainer reviews open GitHub issues
- Collects Slack suggestions
- Identifies recurring questions/patterns
- Creates update proposal

**Week 2: Implementation**
- Maintainer updates skill files
- Increments version number
- Updates CHANGELOG
- Repackages skill

**Week 3: Testing**
- Maintainer tests with example queries
- Optional: Share beta with 1-2 team members
- Verify no breaking changes
- Confirm all references work

**Week 4: Release**
- Push to GitHub
- Announce in #marketing-analytics
- Update team documentation
- Support any installation issues

### Ad-Hoc Updates (As Needed)

For urgent fixes or high-value additions:
- Maintainer implements immediately
- Releases as patch version
- Announces via Slack
- Documents in CHANGELOG

## Contribution Methods

### Method 1: GitHub Issue (Recommended)

**When to use:** Any suggestion, bug report, or enhancement

**Process:**
1. Open new issue in repository
2. Use appropriate template (if available)
3. Provide details and examples
4. Tag maintainer if urgent
5. Maintainer reviews and incorporates
6. Issue closed when released

**Example Issues:**

**New Table:**
```
Title: Add AGENT_ENGAGEMENT table to schema docs

Labels: enhancement, database

We now track agent interactions with leads. This should be added to the
snowflake_schema.md reference file.

Table: RDC_ANALYTICS.AGENT_ENGAGEMENT
Key fields: ENGAGEMENT_ID, LEAD_ID, AGENT_ID, ENGAGEMENT_TYPE, ENGAGEMENT_TIMESTAMP
Common use: Measuring lead response times

Example query:
[Include working SQL]
```

**Correction:**
```
Title: Fix CPL calculation in business_logic.md

Labels: bug, documentation

The CPL formula shows SUM(spend) / COUNT(*) but should use COUNT(DISTINCT lead_id)
to avoid counting duplicate leads.

Location: business_logic.md, line 23
Correction: SUM(spend) / NULLIF(COUNT(DISTINCT lead_id), 0)
```

**Enhancement:**
```
Title: Add geographic expansion analysis pattern

Labels: enhancement, workflow

As we focus more on market expansion, we should add a common analysis pattern
for identifying high-potential untapped markets.

Suggested content:
[Describe the workflow]
```

### Method 2: Slack Suggestion

**When to use:** Quick suggestions, informal discussion

**Process:**
1. Post in #marketing-analytics
2. Use tag: `[SKILL UPDATE]`
3. Describe the suggestion
4. Maintainer creates GitHub issue to track
5. Discussion happens in Slack or GitHub

**Example Slack Message:**
```
[SKILL UPDATE] We should add the new CAC (Customer Acquisition Cost) metric
to our skill. It's different from CPL and includes full funnel costs. 
@mikael can you add this?
```

### Method 3: Direct Edit (Maintainers Only)

**When to use:** You are the maintainer or have write access

**Process:**

1. **Clone repository**
   ```bash
   git clone https://github.com/MoveRDC/claude-skills-marketing.git
   cd claude-skills-marketing
   ```

2. **Create feature branch**
   ```bash
   git checkout -b add-cac-metric
   ```

3. **Make changes**
   - Edit appropriate files in `skills/rdc-marketing-analytics/`
   - Follow style guidelines in CONTRIBUTING.md
   - Test your changes

4. **Commit changes**
   ```bash
   git add skills/rdc-marketing-analytics/references/business_logic.md
   git commit -m "Add CAC (Customer Acquisition Cost) metric definition"
   ```

5. **Repackage skill**
   ```bash
   # Ask Claude to repackage, or use script if available
   ```

6. **Update version**
   - Increment version number in filename
   - Update CHANGELOG.md
   ```bash
   git add dist/rdc-marketing-analytics-v1.2.skill
   git add CHANGELOG.md
   git commit -m "Release v1.2: Add CAC metric"
   ```

7. **Push and create PR (if not maintainer)**
   ```bash
   git push origin add-cac-metric
   # Create PR on GitHub
   ```

8. **Or push directly (if maintainer)**
   ```bash
   git push origin main
   ```

## Repackaging Skills

After making changes to skill source files, the skill must be repackaged.

### Using Claude

**Simple method:**
```
"Claude, I've updated the files in skills/rdc-marketing-analytics/. 
Please repackage the skill as version 1.2"
```

Claude will:
1. Read the updated source files
2. Validate the structure
3. Create new .skill file in dist/
4. Name it with new version number

### Using Packaging Script (If Available)

```bash
cd claude-skills-marketing
python scripts/package_skill.py skills/rdc-marketing-analytics dist/
```

### Manual Packaging

The .skill file is just a zip file with a different extension:

```bash
cd skills/rdc-marketing-analytics
zip -r ../../dist/rdc-marketing-analytics-v1.2.skill .
```

## Version Numbering

Follow semantic versioning: `vMAJOR.MINOR.PATCH`

### When to Increment

**MAJOR (v2.0)**
- Complete restructuring
- Breaking changes to skill format
- Major philosophy shift

**MINOR (v1.2)**
- New tables or data sources
- New analysis patterns
- Significant additions to documentation
- New features or capabilities

**PATCH (v1.1.1)**
- Bug fixes
- Clarifications
- Typo corrections
- Small improvements

### Naming Convention

Files: `rdc-marketing-analytics-vMAJOR.MINOR.PATCH.skill`

Examples:
- `rdc-marketing-analytics-v1.1.skill`
- `rdc-marketing-analytics-v1.2.skill`
- `rdc-marketing-analytics-v1.2.1.skill`

## Release Process

### 1. Pre-Release Checklist

- [ ] All changes committed and pushed
- [ ] CHANGELOG.md updated with changes
- [ ] Version number incremented
- [ ] Skill repackaged
- [ ] New .skill file in dist/ folder
- [ ] Tested with example queries
- [ ] No sensitive data in files

### 2. Create Release

```bash
git tag v1.2
git push origin v1.2
```

Optional: Create GitHub release with notes

### 3. Announce Update

**Slack Message Template:**
```
📢 New Skill Release: RDC Marketing Analytics v1.2

What's new:
✨ Added CAC (Customer Acquisition Cost) metric definitions
✨ New AGENT_ENGAGEMENT table documentation
🐛 Fixed CPL calculation formula
📚 Expanded geographic market analysis patterns

📥 Download: [GitHub Link]
📖 Full changelog: [Link to CHANGELOG.md]

Please reinstall to get the latest updates!
Questions? Reply here or ping @mikael
```

### 4. Support Period

**First 2-3 days after release:**
- Monitor Slack for questions
- Address installation issues quickly
- Be available for clarifications
- Fix critical bugs immediately (patch release)

## Change Types and Where They Go

### Core Concepts → SKILL.md

**Examples:**
- New campaign types
- Team priority changes
- Workflow updates
- Tool integrations

**Edit:**
```markdown
### Campaign Types
- **DSA (Dynamic Search Ads)** - Existing description
- **Display Remarketing** - NEW: Retargeting campaigns showing ads to previous visitors
```

### Database Changes → references/snowflake_schema.md

**Examples:**
- New tables
- New fields in existing tables
- Changed data structures
- Query pattern updates

**Edit:**
```markdown
#### RDC_ANALYTICS.AGENT_ENGAGEMENT
Agent interaction tracking table (added Q4 2024).

**Key Fields:**
- `ENGAGEMENT_ID` - Unique identifier
...
```

### Business Logic → references/business_logic.md

**Examples:**
- Metric definitions
- Calculation methods
- Business rules
- Quality standards

**Edit:**
```markdown
### Customer Acquisition Cost (CAC)

**Definition:** Total cost to acquire a paying customer, including marketing and sales.

**Calculation:**
```sql
(SUM(marketing_spend) + SUM(sales_costs)) / COUNT(DISTINCT customers) AS cac
```
```

## Quality Control

### Self-Review Checklist

Before submitting changes:

- [ ] **Accurate**: Information is correct and tested
- [ ] **Clear**: Writing is concise and understandable
- [ ] **Complete**: Includes examples where helpful
- [ ] **Consistent**: Matches existing style and formatting
- [ ] **Relevant**: Provides value to multiple team members
- [ ] **Secure**: No credentials, PII, or sensitive data

### Maintainer Review

Maintainer checks:

- [ ] Factual accuracy
- [ ] SQL queries work (spot check)
- [ ] Proper placement (right file, right section)
- [ ] No duplicated information
- [ ] Appropriate level of detail
- [ ] Follows style guidelines

## Testing Updates

### Basic Tests

After updating, test with queries that use the new information:

**Added table:**
```
"What can you tell me about the AGENT_ENGAGEMENT table?"
```

**Added metric:**
```
"How do we calculate CAC and when should we use it vs CPL?"
```

**Updated workflow:**
```
"Walk me through the process for geographic expansion analysis"
```

### Regression Testing

Ensure existing functionality still works:

```
"Show me common analysis patterns for campaign performance"
"What tables are in RDC_ANALYTICS?"
"How do we calculate lead pricing?"
```

## Rollback Process

If a release has critical issues:

### Quick Rollback

1. **Remove problematic version** from dist/
2. **Restore previous version**
3. **Announce rollback** in Slack
4. **Team reinstalls** previous version
5. **Fix issues** before re-releasing

### Proper Fix

1. **Create hotfix branch**
   ```bash
   git checkout -b hotfix-v1.2.1
   ```

2. **Fix the issue**

3. **Repackage as patch** (v1.2.1)

4. **Test thoroughly**

5. **Release and announce**

## Communication Guidelines

### Update Announcements

**Include:**
- Version number
- Key changes (bullets)
- Download link
- Changelog link
- Contact for questions

**Keep:**
- Concise (5-10 lines max)
- Focused on user impact
- Positive and informative
- Clear call-to-action (reinstall)

### Issue Responses

**Be:**
- Prompt (within 1-2 business days)
- Appreciative of contributions
- Clear about timeline
- Transparent about decisions

### Declined Suggestions

**When declining:**
- Explain reasoning clearly
- Suggest alternatives if possible
- Thank contributor
- Keep door open for future

**Example:**
```
Thanks for suggesting this! We're going to hold off on adding this specific 
workflow because it's very specific to one-off analysis. However, the underlying 
query patterns would be great to add to our examples section. Would you be open 
to reformatting as a general-purpose example?
```

## Maintainer Rotation

When transitioning maintainer role:

### Outgoing Maintainer

1. **Document pending items**
2. **Share access credentials** (if any)
3. **Walk through process** with new maintainer
4. **Introduce to team** via Slack
5. **Remain available** for questions (first month)

### Incoming Maintainer

1. **Review all documentation**
2. **Understand contribution workflows**
3. **Meet with outgoing maintainer**
4. **Announce transition** to team
5. **Do first release** with support

### Transition Checklist

- [ ] GitHub write access granted
- [ ] Added to maintainer team
- [ ] Reviewed CONTRIBUTING.md and this doc
- [ ] Understands repackaging process
- [ ] Has context on pending issues
- [ ] Team notified of change
- [ ] Updated README with new maintainer name

## Best Practices

### Do

✅ Keep update cycles consistent
✅ Test before releasing
✅ Document all changes
✅ Respond to contributors promptly
✅ Thank people for contributions
✅ Keep team informed
✅ Version everything

### Don't

❌ Rush releases without testing
❌ Skip documentation updates
❌ Ignore contributor feedback
❌ Make breaking changes without warning
❌ Let issues pile up without response
❌ Forget to announce updates
❌ Mix multiple unrelated changes

## Metrics to Track

Consider tracking:
- Issues opened vs closed
- Time to incorporate suggestions
- Adoption rate (% of team using skill)
- Update frequency
- Contributor activity

Use insights to improve process.

---

**Questions about the workflow?** Open an issue or ask in #marketing-analytics

**Updated**: December 2, 2024
