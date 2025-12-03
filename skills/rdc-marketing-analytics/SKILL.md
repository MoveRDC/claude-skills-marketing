---
name: real-estate-marketing-analytics
description: Specialized knowledge for real estate marketing analytics, including SEM campaign optimization, lead generation analysis, marketing channel performance, and geographic market insights. Use when working with real estate marketing data, Snowflake databases (RDC_ANALYTICS, RDC_MARKETING schemas), analyzing paid search campaigns, lead pricing trends, conversion funnels, or cross-channel attribution. Triggers include queries about Google Ads performance, lead quality analysis, market-level metrics, campaign budget optimization, or any real estate marketing KPIs.
---

# Real Estate Marketing Analytics Skill

This skill provides domain expertise for real estate marketing analytics, focusing on SEM optimization, lead generation, channel performance analysis, and data-driven decision making.

## Core Workflow

When a marketing analytics task is requested:

1. **Understand the business question** - Identify the key metric or insight needed
2. **Review relevant references** - Load appropriate schema and business logic files
3. **Query Snowflake** - Use the snowflake tool with proper database/schema context
4. **Analyze results** - Apply marketing analytics best practices and domain knowledge
5. **Provide actionable insights** - Frame findings in business context with recommendations

## Key Concepts & Terminology

### Campaign Types
- **DSA (Dynamic Search Ads)** - Google ad type that auto-generates ads based on website content
- **Performance Max (PMax)** - Google's automated campaign type across all inventory
- **Buy Intent Campaigns** - Targeting users with high purchase intent signals
- **Brand Campaigns** - Campaigns targeting branded search terms

### Lead Metrics
- **Lead Price** - Cost to acquire a lead (can be median or mean)
- **Lead Quality** - Assessed via downstream conversion rates and engagement
- **Volume-Weighted Performance** - Metrics adjusted for campaign spend/volume
- **Zero-Lead Markets** - Geographic areas with no lead generation despite listings

### Geographic Hierarchy
- **DMA (Designated Market Area)** - TV market regions used for geographic analysis
- **State-Level Analysis** - Broader geographic segmentation
- **Market Alignment** - Comparing lead acquisition patterns with listing inventory

### Channel Attribution
- **Paid Search** - Google Ads, Bing Ads, etc.
- **Organic Search** - Unpaid search traffic
- **Direct** - Direct URL entry or bookmarked traffic
- **Referral** - Traffic from other websites

## Database Resources

For detailed schema information, table relationships, and query patterns:

- **See [references/snowflake_schema.md](references/snowflake_schema.md)** - Comprehensive database schema documentation
  - When to load: Any query involving Snowflake tables, joins, or data exploration
  - Contains: Table structures, key relationships, common query patterns

- **See [references/business_logic.md](references/business_logic.md)** - Business rules and metric definitions
  - When to load: Calculating KPIs, understanding metric definitions, applying business rules
  - Contains: Metric formulas, data quality rules, aggregation methods

## Team Goals & Priorities

### Current Focus Areas

1. **SEM Campaign Optimization**
   - Identify underperforming ad groups for budget reallocation
   - Analyze spend efficiency across campaign types
   - Track lead quality trends by campaign

2. **Lead Generation Analysis**
   - Monitor lead pricing trends across channels
   - Analyze geographic distribution vs. inventory
   - Identify zero-lead markets and opportunities

3. **Channel Performance**
   - Compare paid vs. organic search effectiveness
   - Track lead quality by acquisition channel
   - Measure volume-weighted campaign performance

4. **Cross-Functional Collaboration**
   - Share insights via Slack with revenue teams
   - Track action items in Jira (MOPS project)
   - Coordinate with product on conversion optimization

## Common Analysis Patterns

### Campaign Performance Analysis
```
Goal: Identify underperforming campaigns/ad groups
Approach:
1. Pull spend and lead volume data
2. Calculate cost per lead by segment
3. Compare against benchmarks
4. Identify reallocation opportunities
```

### Geographic Market Analysis
```
Goal: Align marketing spend with market opportunity
Approach:
1. Analyze lead volume by DMA/state
2. Compare with listing inventory
3. Identify misalignment (over/under-invested markets)
4. Calculate market-specific lead prices
```

### Channel Attribution
```
Goal: Understand channel effectiveness
Approach:
1. Track leads by acquisition channel
2. Calculate median lead prices by channel
3. Analyze quality indicators (price segments)
4. Compare volume vs. quality trade-offs
```

### Clickstream Analysis
```
Goal: Track user journey from discovery to lead
Approach:
1. Query clickstream data (RDC_ANALYTICS.CLICKSTREAM)
2. Track sessions from SRP to lead submission
3. Identify drop-off points
4. Calculate conversion rates by step
```

## Tools & Integrations

- **Snowflake** - Primary data warehouse (use snowflake MCP tool)
- **Google Ads** - Campaign management (bulk upload sheets for changes)
- **Jira** - Project tracking (MOPS project)
- **Slack** - Team communication and reporting

## Best Practices

### Query Optimization
- Always specify database and schema: `RDC_ANALYTICS.SCHEMA_NAME`
- Use CTEs for complex multi-step queries
- Filter early to reduce data volume
- Use appropriate aggregation levels

### Data Quality
- Check for null values in key fields
- Validate date ranges before analysis
- Cross-reference metrics across tables when possible
- Flag anomalies in the data

### Reporting
- Lead with the business insight, not the data
- Provide context (comparisons, trends, benchmarks)
- Include actionable recommendations
- Visualize when appropriate (Mermaid charts)

### Collaboration
- Document assumptions and methodology
- Share reproducible queries
- Tag relevant team members in findings
- Track follow-up actions in Jira

## Updating This Skill

This skill should evolve as new insights emerge. Update when:

- **New tables or schemas** are added to Snowflake
- **Business logic changes** (metric definitions, calculation methods)
- **Team priorities shift** (new focus areas or KPIs)
- **Best practices emerge** from successful analyses
- **Common patterns** are identified through repeated work

To update: Modify SKILL.md, add new reference files, or update existing documentation. Repackage the skill after changes.
