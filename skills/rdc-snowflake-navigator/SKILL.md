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
| **spend** | `RDC_MARKETING.AGG_REPORTING` | Partner × Account × Day | Cross-channel spend consolidation, budget tracking |
| **sem_summary** | `RDC_MARKETING.AGG_REPORTING` | Campaign × Day | SEM spend, leads, EFR |
| **app_summary** | `RDC_MARKETING.AGG_REPORTING` | Campaign × Day | App install campaigns |
| **psocial_summary** | `RDC_MARKETING.AGG_REPORTING` | Ad Set × Day | Facebook, Criteo spend |

### Key Identity Fields
- **User ID**: `adjusted_uu_id` (canonical across tables)
- **Visit ID**: `visit_id` (clickstream)
- **Lead ID**: `submitted_lead_id` or `inquiry_lead_id`
- **GCLID**: `google_click_id` (paid search attribution)

### Key Date Fields
- Clickstream: `event_date_mst` (Mountain Time)

## Workflow

When a query involves these tables:

1. **Identify the question type:**
   - User behavior → clickstream_detail
   - Lead/revenue metrics → marketing_conversion_detail
   - Campaign performance → sem_summary, app_summary, psocial_summary
   - Cross-channel spend analysis → spend

2. **Load relevant reference docs:**
   - Schema details → [references/snowflake_core_tables.md](references/snowflake_core_tables.md)
   - Business rules → [references/business_logic_reference.md](references/business_logic_reference.md)
   - Clickstream specifics → [references/clickstream_view_annotated.md](references/clickstream_view_annotated.md)
   - EFR calculations → [references/marketing_conversion_detail_annotated.md](references/marketing_conversion_detail_annotated.md)
   - Spend consolidation → [references/spend_view_annotated.md](references/spend_view_annotated.md)
   - Lead/property/delivery paths → [references/lead_property_delivery_paths.md](references/lead_property_delivery_paths.md)

3. **Apply correct filters:**
   - Always filter on date first (these are large tables)
   - Use the appropriate date field for each table
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

### Product Verticals (Clickstream) - Field name: product_vertical
```
for_sale       → Buy intent pages
for_rent       → Rental pages  
not_for_sale_ldp → Off-market/recently sold
owner_seller   → Seller marketplace, My Home
sub_finance    → Mortgage/finance pages
realtorpage    → Agent pages
```

### Lead Verticals (Conversions) - Field name: target_vertical
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

### Delivery Type Hierarchy
When classifying leads by client delivery product, use this mutually exclusive priority:

```sql
CASE 
    WHEN delivered_to_connections_plus_flag = 1 THEN 'Connections Plus'
    WHEN delivered_to_mvip_flag = 1 OR delivered_to_mvip_package_flag = 1 THEN 'MVIP'
    WHEN delivered_to_readyconnect_concierge_flag = 1 THEN 'RCC (Non-MVIP)'
    ELSE 'No Premium Delivery'
END as delivery_type
```

**Source:** wbs2512_pcv_optimization test definition

### Listing Type Classification
For property type segmentation, key low-value categories:
```
land           → Vacant land/lots (RPL ~$42)
farms/ranches  → Farm properties (RPL ~$40)
mobile home    → Mobile/manufactured (RPL ~$35)
```
Use: `LOWER(listing_type) IN ('land', 'farms/ranches')` for lot/land analysis.

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

### Cross-Channel Spend Summary
```sql
SELECT 
    channel,
    partner,
    target_vertical,
    SUM(spend) AS spend,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks
FROM rdc_marketing.agg_reporting.spend
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
  AND target_customer = 'b2c'
GROUP BY 1, 2, 3
HAVING SUM(spend) > 1000
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

### RCC Market Mapping Coverage
The zip-to-RCC-market mapping only covers ~39% of leads. Join path:
```
postal_code → lead_zone_zipcode.zipcode → lead_zone.zone_id → market.id
```
**Tables:** `fivetran_referral.pg_public.{lead_zone_zipcode, lead_zone, market}`

**Recommendation:** Use `state` or `dma_description` fields from marketing_conversion_detail for complete geographic coverage (99.9%). Reserve RCC market mapping for RCC-specific inventory analysis only.

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

### Spend Table Considerations
- **Linear TV** (OceanMedia) has no impression/click data
- **Recent TV data** (last 7 days) may use pacing instead of actuals
- **TikTok spend** (`bytedanceglobal_int`) is zeroed after 2024-01-01
- **App accounts** are excluded from platform aggregates (Google, Facebook, Bing, LinkedIn) to prevent double-counting

### EFR Calculation Notes
- **EFR is lagged 30 days** - Recent leads have no referral EFR (rolling avg uses days 30-36 back)
- **High price tier ($30M+)** gets $0 referral EFR (intentional exclusion)
- **NY excluded from Veterans United** per VU agreement
- **Seller EFR capped at $25K** to prevent outlier skew

## Reference Documents

- **[snowflake_core_tables.md](references/snowflake_core_tables.md)** - Complete schema documentation for all tables
- **[business_logic_reference.md](references/business_logic_reference.md)** - Incrementality, attribution rules, metric definitions
- **[clickstream_view_annotated.md](references/clickstream_view_annotated.md)** - Detailed clickstream field derivation logic
- **[marketing_conversion_detail_annotated.md](references/marketing_conversion_detail_annotated.md)** - EFR calculation methodology and revenue sources
- **[spend_view_annotated.md](references/spend_view_annotated.md)** - Unified spend aggregation across all marketing channels
- **[lead_property_delivery_paths.md](references/lead_property_delivery_paths.md)** - Lead to property type, client delivery, and geographic market mapping paths

## Tips for Effective Queries

1. **Always filter on date first** - These tables have billions of rows
2. **Use `adjusted_uu_id`** for cross-table user joins
3. **Check data freshness** - Some tables are T-1 or T-2
4. **Use IEFR for incrementality** - Raw EFR overstates impact
5. **Prefer MEDIAN over AVG** for price metrics (skewed distributions)
6. **Use CTEs** for complex multi-step queries
7. **Handle NULLs** with NULLIF when dividing
