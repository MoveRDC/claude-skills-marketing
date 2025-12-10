---
name: seller-analytics
description: Analyzes seller lead performance, revenue attribution, and marketing campaigns for the Seller vertical (acquired business with separate data architecture). Use when working with seller leads, sell intent, EFR calculations, seller paid search, display/social, or B2C/B2B seller campaigns. Triggers include seller leads, sell_spend, sell_attribution, EFR, GQ leads, UCA, seller revenue, PMAX, DSA, brand campaigns, seller outage analysis, facebook ads, display ads.
---

# Seller Analytics Skill

Domain expertise for the Seller vertical - an acquired business with its own data architecture separate from the core realtor.com platform.

## Why Seller Is Different

The Seller business unit was acquired and maintains separate:
- Database schemas (`rdc_marketing.seller.*`)
- Lead attribution models
- Revenue calculation methods (EFR v1 vs v2)
- Campaign naming conventions

**Do not use generic `RDC_ANALYTICS.LEADS` for seller analysis** - use the seller-specific tables documented here.

## Core Workflow

When a seller analytics task is requested:

1. **Identify the analysis type** - Spend, leads, revenue, or funnel metrics
2. **Start from the right anchor table:**
   - Spend analysis → `sell_spend`
   - Lead analysis → `sell_attribution` 
   - Revenue/EFR → `sell_revenue_est`
   - Quality metrics → `sell_lead_quality`
3. **Apply standard filters** - channel, target_customer, date range
4. **Use campaign classification** - Derive campaign types from naming patterns
5. **Join carefully** - Use `request_id + transaction_type` composite key

## Quick Reference: Where to Start

| Question | Start Here | Join To |
|----------|------------|---------|
| How much did we spend? | `sell_spend` | - |
| How many leads? | `sell_attribution` | `sell_revenue_est` |
| What's the EFR? | `sell_revenue_est` | `seller_lead_efr_paid_search` (for v2) |
| Lead quality breakdown? | `sell_lead_quality` | `sell_attribution` |
| Downstream conversion? | `sell_downfunnel` | `sell_attribution` |
| Spend + Leads combined? | `sell_spend` | LEFT JOIN leads subquery |

## Schema Overview

### Primary Schema: `rdc_marketing.seller`

| Table | Purpose | Grain |
|-------|---------|-------|
| `sell_spend` | Campaign spend data | date + campaign + adgroup |
| `sell_attribution` | Lead-to-campaign attribution | request_id + transaction_type |
| `sell_revenue_est` | Revenue and EFR estimates | request_id + transaction_type |
| `sell_downfunnel` | Downstream conversion events | request_id + transaction_type |

### Supporting Tables

| Table | Schema | Purpose |
|-------|--------|---------|
| `sell_lead_quality` | `rdc_analytics.ons` | Lead quality scoring (GQ flag) |
| `seller_lead_efr_paid_search` | `rdc_analytics.revenue` | EFR v2 for paid search |

## Key Concepts

### Transaction Types
Leads are categorized by intent:
- `'buy'` - Buyer intent leads
- `'sell'` - Seller intent leads

**Always segment or filter by transaction_type** - these are fundamentally different lead types.

### Composite Key Pattern
Most seller tables use a composite key:
```sql
request_id + transaction_type
```
Always join on BOTH fields, not just request_id.

### EFR (Expected Future Revenue)
Two versions exist:
- **EFR v1**: `sell_revenue_est.rep_efr` - Original calculation
- **EFR v2**: `seller_lead_efr_paid_search.rep_efr_v2` - Updated model for paid search

**Best practice**: Use COALESCE to prefer v2:
```sql
COALESCE(ra.rep_efr_v2, r.rep_efr) AS efr
```

### Lead Quality Levels
From `sell_lead_quality.quality_level`:
- `'GQ'` - Good Quality (primary metric)
- Other values indicate lower quality tiers

### UCA (User-to-Agent Connection)
Measures downstream conversion:
```sql
-- UCA within 14 days
COUNT(DISTINCT CASE 
    WHEN DATEDIFF('day', d.created_date, d.matchdate) <= 14 
    THEN d.request_id 
END) AS uca_14d
```

## Campaign Classification

**There is no campaign_type field** - derive from naming conventions:

```sql
CASE 
    WHEN LOWER(campaign_name) LIKE '%pmax%' THEN 'PMAX'
    WHEN LOWER(campaign_name) LIKE '%dsa%' THEN 'DSA'
    WHEN LOWER(campaign_name) LIKE '%brand%' THEN 'Brand'
    WHEN LOWER(campaign_name) LIKE '%longtail%' THEN 'Brand'
    WHEN LOWER(campaign_name) LIKE '%agent%' THEN 'Agent'
    WHEN LOWER(campaign_name) LIKE '%sell%' 
         OR LOWER(campaign_name) LIKE '%fsbo%' THEN 'Sell'
    ELSE 'Others'
END AS campaign_label
```

## Channel & Audience Dimensions

The `sell_spend` table contains multiple marketing channels, audience segments, and ad partners.

### Available Channels

| Channel | Description |
|---------|-------------|
| `'paid search'` | Google/Bing search ads |
| `'display/social ads'` | Facebook display and social advertising |
| `'display_social_advertising'` | Google display network (note: different naming convention) |
| `'digital brand'` | Brand awareness campaigns |

### Target Customer Segments

| Value | Description |
|-------|-------------|
| `'b2c'` | Business-to-consumer (homeowners/sellers) |
| `'b2b'` | Business-to-business (agents/brokers) |

### Ad Partners

| Partner | Channels |
|---------|----------|
| `'google'` | paid search, display_social_advertising, digital brand |
| `'bing'` | paid search |
| `'facebook'` | display/social ads |

### Channel × Target Customer × Partner Matrix

| Channel | Target Customer | Partner |
|---------|-----------------|---------|
| paid search | b2c | google |
| paid search | b2c | bing |
| paid search | b2b | google |
| display/social ads | b2c | facebook |
| display/social ads | b2b | facebook |
| display_social_advertising | b2b | google |
| digital brand | b2b | google |

### Common Filter Patterns

**B2C Paid Search (most common):**
```sql
WHERE channel = 'paid search'
  AND target_customer = 'b2c'
```

**All Paid Search (B2B + B2C):**
```sql
WHERE channel = 'paid search'
```

**Facebook/Social Only:**
```sql
WHERE channel = 'display/social ads'
```

**All B2B Marketing:**
```sql
WHERE target_customer = 'b2b'
```

**Cross-Channel Analysis:**
```sql
SELECT 
    channel,
    target_customer,
    partner,
    SUM(spend) AS spend
FROM rdc_marketing.seller.sell_spend
WHERE calendar_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY spend DESC;
```

## Common Query Patterns

### Pattern 1: Spend + Leads Combined
The canonical join pattern for spend and lead metrics:

```sql
SELECT
    s.calendar_date AS event_date,
    s.campaign_name,
    SUM(s.spend) AS spend,
    SUM(s.clicks) AS clicks,
    SUM(leads.lead_count) AS leads,
    SUM(leads.sell_lead_count) AS sell_intent_leads,
    SUM(leads.efr) AS efr
FROM rdc_marketing.seller.sell_spend AS s
LEFT JOIN (
    -- Leads subquery aggregated to spend grain
    SELECT 
        a.lead_date,
        a.campaign_id,
        COALESCE(a.adgroup_id, '') AS adgroup_id,
        COUNT(DISTINCT r.request_id) AS lead_count,
        COUNT(DISTINCT CASE WHEN r.transaction_type = 'sell' THEN r.request_id END) AS sell_lead_count,
        SUM(COALESCE(ra.rep_efr_v2, r.rep_efr)) AS efr
    FROM rdc_marketing.seller.sell_attribution AS a
    JOIN rdc_marketing.seller.sell_revenue_est AS r 
        ON r.request_id = a.request_id 
        AND r.transaction_type = a.transaction_type
    LEFT JOIN rdc_analytics.revenue.seller_lead_efr_paid_search AS ra 
        ON ra.request_id = a.request_id 
        AND ra.transaction_type = a.transaction_type
    GROUP BY 1, 2, 3
) AS leads 
    ON s.campaign = leads.campaign_id 
    AND s.adgroup_id = leads.adgroup_id  
    AND s.calendar_date = leads.lead_date
WHERE s.channel = 'paid search'
  AND s.target_customer = 'b2c'
  AND s.calendar_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1 DESC;
```

### Pattern 2: Lead Quality Analysis
```sql
SELECT
    DATE_TRUNC('week', a.lead_date) AS week,
    a.transaction_type,
    COUNT(DISTINCT a.request_id) AS total_leads,
    COUNT(DISTINCT CASE WHEN q.quality_level = 'GQ' THEN a.request_id END) AS gq_leads,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN q.quality_level = 'GQ' THEN a.request_id END) 
          / NULLIF(COUNT(DISTINCT a.request_id), 0), 1) AS gq_rate
FROM rdc_marketing.seller.sell_attribution AS a
LEFT JOIN rdc_analytics.ons.sell_lead_quality AS q 
    ON a.request_id = q.request_id 
    AND a.transaction_type = q.transaction_type
WHERE a.lead_date >= DATEADD('day', -90, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1 DESC, 2;
```

### Pattern 3: Campaign Type Performance
```sql
WITH campaign_classified AS (
    SELECT
        s.*,
        CASE 
            WHEN LOWER(campaign_name) LIKE '%pmax%' THEN 'PMAX'
            WHEN LOWER(campaign_name) LIKE '%dsa%' THEN 'DSA'
            WHEN LOWER(campaign_name) LIKE '%brand%' THEN 'Brand'
            WHEN LOWER(campaign_name) LIKE '%longtail%' THEN 'Brand'
            WHEN LOWER(campaign_name) LIKE '%agent%' THEN 'Agent'
            WHEN LOWER(campaign_name) LIKE '%sell%' OR LOWER(campaign_name) LIKE '%fsbo%' THEN 'Sell'
            ELSE 'Others'
        END AS campaign_label
    FROM rdc_marketing.seller.sell_spend AS s
    WHERE channel = 'paid search'
      AND target_customer = 'b2c'
)
SELECT
    campaign_label,
    SUM(spend) AS total_spend,
    SUM(clicks) AS total_clicks,
    SUM(impressions) AS total_impressions,
    ROUND(SUM(spend) / NULLIF(SUM(clicks), 0), 2) AS cpc
FROM campaign_classified
WHERE calendar_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1
ORDER BY total_spend DESC;
```

### Pattern 4: Cross-Channel Performance Comparison
```sql
SELECT
    channel,
    target_customer,
    partner,
    SUM(spend) AS total_spend,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    ROUND(SUM(spend) / NULLIF(SUM(clicks), 0), 2) AS cpc,
    ROUND(100.0 * SUM(clicks) / NULLIF(SUM(impressions), 0), 2) AS ctr
FROM rdc_marketing.seller.sell_spend
WHERE calendar_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY total_spend DESC;
```

## Outage/Incident Analysis Pattern

For analyzing impact of site outages on seller leads:

```sql
-- Compare outage period to baseline
WITH daily_metrics AS (
    SELECT
        s.calendar_date,
        SUM(s.spend) AS spend,
        SUM(s.clicks) AS clicks,
        SUM(leads.lead_count) AS leads,
        -- Flag outage dates
        CASE WHEN s.calendar_date BETWEEN '2024-12-01' AND '2024-12-03' 
             THEN 'outage' ELSE 'normal' END AS period_type
    FROM rdc_marketing.seller.sell_spend AS s
    LEFT JOIN (
        -- leads subquery here
    ) AS leads ON ...
    WHERE s.calendar_date BETWEEN '2024-11-15' AND '2024-12-15'
    GROUP BY 1
)
SELECT
    period_type,
    AVG(leads) AS avg_daily_leads,
    AVG(leads / NULLIF(clicks, 0)) AS avg_conversion_rate
FROM daily_metrics
GROUP BY 1;
```

## Metric Definitions

| Metric | Definition | Calculation |
|--------|------------|-------------|
| Leads | Distinct lead submissions | `COUNT(DISTINCT request_id)` |
| Sell Intent Leads | Leads with sell transaction type | `COUNT(DISTINCT CASE WHEN transaction_type = 'sell' ...)` |
| GQ Leads | Good quality leads | `COUNT(DISTINCT CASE WHEN quality_level = 'GQ' ...)` |
| EFR | Expected Future Revenue | `SUM(COALESCE(rep_efr_v2, rep_efr))` |
| Actualized Revenue | Realized revenue | `SUM(actualizedrev)` |
| UCA 14d | Connections within 14 days | See UCA formula above |
| CPL | Cost per lead | `spend / NULLIF(leads, 0)` |
| Conversion Rate | Clicks to leads | `leads / NULLIF(clicks, 0)` |
| CTR | Click-through rate | `clicks / NULLIF(impressions, 0) * 100` |
| CPC | Cost per click | `spend / NULLIF(clicks, 0)` |

## Data Freshness

| Table | Refresh Frequency |
|-------|-------------------|
| sell_spend | Daily |
| sell_attribution | Daily |
| sell_revenue_est | Daily |
| sell_lead_quality | Daily |
| seller_lead_efr_paid_search | Daily |

**Note**: Most seller data has T-1 latency (yesterday's data available today).

## Common Gotchas

1. **Adgroup ID nulls**: Use `COALESCE(adgroup_id, '')` when joining
2. **Transaction type**: Always include in joins and filters
3. **EFR versions**: Check if v2 exists before using v1
4. **Campaign classification**: Based on naming, not a field
5. **Date alignment**: Spend is `calendar_date`, leads is `lead_date`
6. **Channel naming inconsistency**: Note `display/social ads` vs `display_social_advertising` - different naming for Facebook vs Google display
7. **EFR v2 scope**: `seller_lead_efr_paid_search` only covers paid search leads - other channels use v1 only
