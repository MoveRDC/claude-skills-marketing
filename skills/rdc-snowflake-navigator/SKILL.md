---
name: rdc-snowflake-navigator
description: Comprehensive guide to RDC's Snowflake data warehouse for marketing and consumer analytics. Use when querying clickstream data, lead attribution, marketing spend analysis, campaign performance, or revenue metrics. Triggers include queries about EFR, leads, spend, campaigns, clickstream, user journeys, SEM, app installs, paid social, or any Snowflake table exploration.
---

# RDC Snowflake Navigator Skill

This skill provides comprehensive knowledge of RDC's Snowflake data warehouse, including table schemas, business logic, attribution rules, and query patterns for marketing and consumer analytics.

## Quick Reference

### Core Tables

| Table | Location | Grain | Primary Use |
|-------|----------|-------|-------------|
| **clickstream_detail** | `RDC_ANALYTICS.CLICKSTREAM` | Event (hit) | User behavior, journeys, conversions |
| **marketing_conversion_detail** | `RDC_ANALYTICS.REVENUE` | Lead | Lead attribution, EFR, delivery flags |
| **sem_summary** | `RDC_MARKETING.AGG_REPORTING` | Campaign × Day | SEM spend, leads, EFR |
| **app_summary** | `RDC_MARKETING.AGG_REPORTING` | Campaign × Day | App install campaigns |
| **psocial_summary** | `RDC_MARKETING.AGG_REPORTING` | Ad Set × Day | Facebook, Criteo spend |

### Key Identity Fields
- **User ID**: `adjusted_uu_id` (canonical across tables)
- **Session ID**: `visit_id` (clickstream)
- **Lead ID**: `submitted_lead_id` or `inquiry_lead_id`
- **GCLID**: `google_click_id` (paid search attribution)

### Key Date Fields
- Clickstream: `event_date_mst` (Mountain Time)
- All others: `event_date` or `date` (UTC)

## Workflow

When a query involves these tables:

1. **Identify the question type:**
   - User behavior → clickstream_detail
   - Lead/revenue metrics → marketing_conversion_detail
   - Campaign performance → sem_summary, app_summary, psocial_summary

2. **Load relevant reference docs:**
   - Schema details → [references/snowflake_core_tables.md](references/snowflake_core_tables.md)
   - Business rules → [references/business_logic_reference.md](references/business_logic_reference.md)
   - Clickstream specifics → [references/clickstream_view_annotated.md](references/clickstream_view_annotated.md)

3. **Apply correct filters:**
   - Always filter on date first (these are large tables)
   - Use appropriate date field for each table
   - Apply business-specific exclusions as documented

4. **Use proper metrics:**
   - EFR for revenue attribution
   - IEFR for incrementality-adjusted revenue
   - Snapshot vs Cohort for app metrics

## Critical Business Logic

### Incrementality Multipliers (IEFR)
Different channels have different incrementality adjustments:

| Channel | Condition | Multiplier |
|---------|-----------|------------|
| SEM | B2C + Buy + Web | 0.70 |
| App - Apple Search | iOS | 0.46 |
| App - Google | iOS | 0.46 |
| App - Google | Android | 0.56 |
| App - Other Media | Any | 0.70 |
| PSocial - Criteo | B2C + Buy + Web | 0.65 |
| PSocial - FB Veterans/Brand | - | 0.70 |
| PSocial - FB Retargeting | - | 0.55 |

### Product Verticals (Clickstream)
```
for_sale       → Buy intent pages
for_rent       → Rental pages  
not_for_sale_ldp → Off-market/recently sold
owner_seller   → Seller marketplace, My Home
sub_finance    → Mortgage/finance pages
realtorpage    → Agent pages
```

### Lead Verticals (Conversions)
```
for_sale → Buy leads
for_rent → Rental leads
Seller   → Sell leads (or DELIVERED_TO_UPNEST/SELLER_PARTNER flags)
FAR      → Find a Realtor leads
```

### EFR Components
Total EFR is calculated from multiple revenue sources:

| Component | Source | Description |
|-----------|--------|-------------|
| `buy_efr_referral` | RCC referral model | 7-day rolling avg by price tier |
| `sell_efr_referral` | RCC referral model | 7-day rolling avg by price tier |
| `cplus_contract_revenue` | lead_sales_revenue | Connections Plus contracts |
| `mvip_revenue` | mvip_revenue | MVIP contracts |
| `adpro_revenue` | Zip code avg from C+ | Advantage Pro |
| `veterans_revenue` | Fixed rate schedule | Veterans United |
| `sales_builder_revenue` | nc_sales_builder_revenue | New Construction |
| `sell_realchoice_efr` | realchoice_revenue | UpNest sell |
| `rent_efr` | rentals_revenue | Rental leads |

### RPL Categories (Listing Price Tiers)
```
G: $0-$62K       E: $115K-$152.5K    C: $212.9K-$380K    A: $800K-$30M
F: $62K-$115K    D: $152.5K-$212.9K  B: $380K-$800K      High: >$30M (excluded)
```

## Common Query Patterns

### Daily Traffic by Platform
```sql
SELECT 
    event_date_mst,
    experience_type,
    platform,
    COUNT(DISTINCT adjusted_uu_id) as users,
    COUNT(DISTINCT visit_id) as sessions,
    SUM(is_pageview) as pageviews
FROM rdc_analytics.clickstream.clickstream_detail
WHERE event_date_mst >= DATEADD('day', -7, CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC;
```

### Lead Volume by Channel
```sql
SELECT 
    event_date,
    last_touch_marketing_channel,
    submitted_lead_vertical,
    COUNT(*) as leads,
    SUM(estimated_future_revenue) as efr,
    MEDIAN(lead_listing_price) as median_price
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC;
```

### SEM Campaign Performance
```sql
SELECT 
    campaign_name,
    target_vertical,
    SUM(spend) as spend,
    SUM(leads) as leads,
    SUM(efr) as efr,
    SUM(iefr) as iefr,
    SUM(spend) / NULLIF(SUM(leads), 0) as cpl,
    SUM(iefr) / NULLIF(SUM(spend), 0) as iroas
FROM rdc_marketing.agg_reporting.sem_summary
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
HAVING SUM(spend) > 1000
ORDER BY spend DESC;
```

### App Install Efficiency
```sql
SELECT 
    media_source,
    platform,
    SUM(spend) as spend,
    SUM(ssot_installs) as installs,
    SUM(cohort_efr_for_sale) as cohort_efr,
    SUM(snapshot_iefr_for_sale) as iefr,
    SUM(spend) / NULLIF(SUM(ssot_installs), 0) as cpi
FROM rdc_marketing.agg_reporting.app_summary
WHERE date >= DATEADD('day', -30, CURRENT_DATE())
  AND is_app = 1
GROUP BY 1, 2
HAVING SUM(spend) > 100
ORDER BY spend DESC;
```

### User Journey to Lead
```sql
WITH lead_sessions AS (
    SELECT DISTINCT visit_id, inquiry_lead_id
    FROM rdc_analytics.clickstream.clickstream_detail
    WHERE event_date_mst >= DATEADD('day', -7, CURRENT_DATE())
      AND inquiry_lead_id IS NOT NULL
)
SELECT 
    c.product_vertical,
    c.page_type_group,
    COUNT(DISTINCT c.visit_id) as sessions,
    COUNT(DISTINCT l.inquiry_lead_id) as leads,
    COUNT(DISTINCT l.inquiry_lead_id)::FLOAT / NULLIF(COUNT(DISTINCT c.visit_id), 0) as conversion_rate
FROM rdc_analytics.clickstream.clickstream_detail c
LEFT JOIN lead_sessions l ON c.visit_id = l.visit_id
WHERE c.event_date_mst >= DATEADD('day', -7, CURRENT_DATE())
  AND c.product_vertical IN ('for_sale', 'for_rent')
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
```

## Data Caveats

### Historical Data Considerations
- **SEM tracking codes** changed multiple times (pre-Oct 2021, Oct-Jan 2022 issues, Jan 2022+)
- **App data** before June 2021 comes from separate historical table
- **PSocial FB tracking** broke in 2024 (special handling in view)

### SKAN Privacy (iOS)
- iOS 14.5+ requires SKAdNetwork for attribution
- `ssot_installs` = SKAN + non-SKAN combined
- `skan_multiplier` adjusts for attribution gaps

### Snapshot vs Cohort (App)
- **Snapshot**: Measured on event date (use for daily reporting)
- **Cohort**: Attributed to install date (use for LTV analysis)

## Reference Documents

- **[snowflake_core_tables.md](references/snowflake_core_tables.md)** - Complete schema documentation for all tables
- **[business_logic_reference.md](references/business_logic_reference.md)** - Incrementality, attribution rules, metric definitions
- **[clickstream_view_annotated.md](references/clickstream_view_annotated.md)** - Detailed clickstream field derivation logic
- **[marketing_conversion_detail_annotated.md](references/marketing_conversion_detail_annotated.md)** - EFR calculation methodology and revenue sources

## Tips for Effective Queries

1. **Always filter on date first** - These tables have billions of rows
2. **Use `adjusted_uu_id`** for cross-table user joins
3. **Check data freshness** - Some tables are T-1 or T-2
4. **Use IEFR for incrementality** - Raw EFR overstates impact
5. **Prefer MEDIAN over AVG** for price metrics (skewed distributions)
6. **Use CTEs** for complex multi-step queries
7. **Handle NULLs** with NULLIF when dividing
