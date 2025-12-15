# Spend View Definition - Annotated

This document provides an annotated version of the `RDC_MARKETING.AGG_REPORTING.SPEND` view, explaining the logic behind data consolidation from multiple marketing channels.

## Overview

The spend view is a unified aggregation of marketing spend data across all paid channels. It consolidates data from platform-specific source tables and enriches each record with taxonomy fields for consistent reporting and budget attribution.

**Location:** `RDC_MARKETING.AGG_REPORTING.SPEND`

**Grain:** Partner × Account × Day (with taxonomy dimensions)

**Primary Use:** Cross-channel spend reporting, budget tracking, ROAS calculations, media mix analysis

---

## Output Schema

| Field | Type | Description |
|-------|------|-------------|
| `event_date` | DATE | Date of spend activity |
| `channel` | VARCHAR | Marketing channel (e.g., 'sem', 'psocial', 'brand') |
| `tactic` | VARCHAR | Specific tactic within channel |
| `partner` | VARCHAR | Ad platform/partner (e.g., 'google', 'facebook', 'adobe') |
| `media_type` | VARCHAR | Media format (e.g., 'search', 'display', 'linear video', 'streaming video') |
| `budget_id` | VARCHAR | Internal budget code for finance attribution |
| `budget_name` | VARCHAR | Human-readable budget category |
| `target_customer` | VARCHAR | Customer segment: 'b2c' or 'b2b' |
| `target_platform` | VARCHAR | Target platform: 'web', 'app', or specific platforms |
| `target_audience` | VARCHAR | Audience targeting: 'new', 'retargeting', 'both' |
| `target_vertical` | VARCHAR | Business vertical: 'buy', 'rent', 'sell' |
| `account_id` | VARCHAR | Platform-specific account identifier |
| `account_name` | VARCHAR | Human-readable account name |
| `impressions` | NUMBER | Ad impressions served |
| `clicks` | NUMBER | Ad clicks recorded |
| `spend` | NUMBER | Spend amount in USD |

---

## Source Tables and CTEs

The view is constructed from multiple CTEs that pull from different source systems, then UNIONed together.

### Source Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FINAL (UNION ALL)                           │
├─────────────────────────────────────────────────────────────────────┤
│  f_google_spend        ← rdc_marketing.agg_google.google_all        │
│  f_google_b2b_spend    ← rdc_marketing.agg_google.google_all        │
│  f_facebook_spend      ← rdc_marketing.agg_facebook.facebook_all    │
│  f_bing_spend          ← rdc_marketing.agg_bing.bing_all            │
│  f_linkedin_spend      ← rdc_marketing.agg_linkedin.linkedin_all    │
│  f_oceanmedia_spend    ← rdc_marketing.agg_oceanmedia.*             │
│  f_adobe_spend         ← rdc_marketing.agg_adobe.adobe_all          │
│  app_summary_spend     ← rdc_marketing.agg_reporting.app_summary    │
│  criteo_spend          ← fivetran_martech.criteo.*                  │
│  taboola_spend         ← fivetran_martech.raw_taboola.*             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## CTE Details

### 1. taxonomy_hist (Enrichment Table)

Provides taxonomy mapping for campaign-level classification.

**Source:** `rdc_marketing.team_digital_marketing.taxonomy_hist`

```sql
SELECT DISTINCT
    start_date,
    mapping_id,
    account_id,
    campaign_id,        -- Normalized via TRY_CAST for consistent joining
    ad_group_id,
    channel,
    tactic,
    partner,
    media_type,
    budget_id,
    budget_name,
    target_customer,
    target_platform,
    target_audience,
    target_vertical
FROM rdc_marketing.team_digital_marketing.taxonomy_hist
WHERE start_date >= '2021-06-01' 
  AND campaign_id IS NOT NULL
```

**Key Logic:**
- Campaign IDs are normalized using `TRY_CAST` to handle mixed numeric/string formats
- Historical taxonomy allows point-in-time attribution

---

### 2. app_partner_data (App Spend Preprocessing)

Preprocesses app install campaign spend before taxonomy enrichment.

**Source:** `rdc_marketing.agg_reporting.app_summary`

**Partner Normalization:**
```sql
CASE
  WHEN channel IN ('AppleSearchAds', 'Apple Search Ads') THEN 'Apple Search Ads'
  WHEN channel = 'Google' THEN 'Google'
  WHEN channel = 'Facebook Ads' THEN 'Facebook'
  ELSE 'Other'
END AS partner
```

**Spend Adjustments:**
```sql
SUM(
  CASE
    WHEN channel = 'essence' THEN agency_fees           -- Use agency fees for Essence
    WHEN media_source = 'bytedanceglobal_int' 
         AND date >= '2024-01-01' THEN 0                -- Zero out TikTok post-2024
    ELSE spend
  END
) AS spend_
```

**Filtering Logic:**
- Requires `spend <> 0` and `date >= '2021-01-01'`
- Includes records where `is_app = 1` OR specific media sources (Apple Search Ads, TikTok, Aura, FeedMob, etc.)
- Excludes Facebook Ads and Google channel records (handled separately)

---

### 3. app_summary_spend

Enriches preprocessed app data with taxonomy.

**Default Values (when taxonomy missing):**
```sql
COALESCE(t.budget_id, '722000') AS budget_id,
COALESCE(t.budget_name, 'mobile') AS budget_name,
COALESCE(t.target_customer, 'b2c') AS target_customer,
'app' AS target_platform,                              -- Always 'app' for this CTE
COALESCE(t.target_audience, 'new') AS target_audience,
COALESCE(t.target_vertical, 'buy') AS target_vertical
```

---

### 4. f_google_spend (B2C Google)

**Source:** `rdc_marketing.agg_google.google_all`

**Key Logic:**
- Excludes accounts already captured in `app_summary_spend` via LEFT JOIN anti-pattern
- Filters to `target_customer = 'b2c'` only

```sql
FROM rdc_marketing.agg_google.google_all AS a
LEFT JOIN app_summary_spend AS b
    ON CAST(a.account_id AS VARCHAR) = CAST(b.account_id AS VARCHAR)
WHERE b.account_id IS NULL      -- Exclude app accounts
  AND a.target_customer = 'b2c'
```

---

### 5. f_google_b2b_spend (B2B Google)

**Source:** `rdc_marketing.agg_google.google_all`

**Key Logic:**
- Separate CTE for B2B to avoid app account exclusion logic
- No anti-join against app_summary_spend

```sql
WHERE a.target_customer = 'b2b'
```

---

### 6. f_facebook_spend

**Source:** `rdc_marketing.agg_facebook.facebook_all`

**Key Logic:**
- Excludes accounts in app_summary_spend (same anti-join pattern as Google B2C)

---

### 7. f_bing_spend

**Source:** `rdc_marketing.agg_bing.bing_all`

**Key Logic:**
- Excludes accounts in app_summary_spend

---

### 8. f_linkedin_spend

**Source:** `rdc_marketing.agg_linkedin.linkedin_all`

**Key Logic:**
- Excludes accounts in app_summary_spend

---

### 9. criteo_spend

**Source:** `fivetran_martech.criteo.adset_statistics_report`

**Key Logic:**
- Joins to taxonomy via `ad_group_id` (not campaign_id)
- Fixed account configuration:
  - `account_name = 'Realtor.com US'`

```sql
LEFT JOIN taxonomy_hist AS t
    ON TO_CHAR(ROUND(TRY_CAST(a.adset_id AS BIGINT))) 
     = TO_CHAR(ROUND(TRY_CAST(t.ad_group_id AS BIGINT)))
```

---

### 10. taboola_spend

**Source:** `fivetran_martech.raw_taboola.campaign_site_day_report`

**Key Logic:**
- Fixed account configuration:
  - `account_id = 1007327`
  - `account_name = 'Realtor.com - SC'`
- Joins to taxonomy via campaign_id

---

### 11. f_oceanmedia_spend (Linear TV + TVE)

**Sources:**
- `rdc_marketing.agg_oceanmedia.oceanmedia_all` (actuals)
- `rdc_marketing.agg_oceanmedia.oceanmedia_pacing` (pacing)
- `rdc_marketing.agg_oceanmedia.oceanmedia_actuals` (TVE actuals)

**Spend Calculation Logic:**

The view implements a fallback mechanism for recent dates where actuals may not be available:

```sql
CASE
  WHEN (CURRENT_DATE - t1.event_date <= 7)
       AND (t1.spend = 0 OR t1.spend IS NULL)
  THEN (t3.spend + t2.spend)    -- Use pacing + TVE pacing
  ELSE (t1.spend + t2.spend)    -- Use actuals + TVE actuals
END AS spend
```

**Fixed Taxonomy:**
```sql
'brand' AS channel,
'brand' AS tactic,
'oceanmedia' AS partner,
'linear video' AS media_type,
'750000' AS budget_id,
'brand_tv' AS budget_name,
'b2c' AS target_customer,
'web' AS target_platform,
'both' AS target_audience,
'buy' AS target_vertical
```

**Note:** No impressions or clicks data for linear TV.

---

### 12. f_adobe_spend (Streaming Video / CTV)

**Source:** `rdc_marketing.agg_adobe.adobe_all`

**Taxonomy Join:**
```sql
LEFT JOIN rdc_marketing.team_digital_marketing.taxonomy_hist AS t2
    ON CAST(t1.campaign_id AS VARCHAR) = t2.campaign_id
    AND t1._event_date BETWEEN t2.start_date AND t2.end_date
    AND t2.partner ILIKE 'adobe%'
```

**Default Values:**
```sql
COALESCE(t2.channel, 'brand') AS channel,
COALESCE(t2.tactic, 'brand') AS tactic,
COALESCE(t2.partner, 'adobe') AS partner,
COALESCE(t2.media_type, 'streaming video') AS media_type,
COALESCE(t2.budget_id, '750001') AS budget_id,
COALESCE(t2.budget_name, 'brand_digital') AS budget_name
```

**Exclusions:**
```sql
WHERE NOT LOWER(t1.campaign_name) LIKE '%rentals%'
  AND NOT LOWER(t1.campaign_name) LIKE '%renters%'
  AND NOT LOWER(t1.campaign_name) LIKE '%sellers%'
```

---

## Key Business Logic

### Account ID Anti-Join Pattern

Several CTEs use an anti-join pattern to prevent double-counting spend from accounts that also appear in app_summary_spend:

```sql
FROM source_table AS a
LEFT JOIN app_summary_spend AS b
    ON CAST(a.account_id AS VARCHAR) = CAST(b.account_id AS VARCHAR)
WHERE b.account_id IS NULL
```

This ensures:
- App install campaigns are attributed only once (via app_summary_spend)
- Platform aggregates (Google, Facebook, Bing, LinkedIn) exclude app accounts

### Campaign ID Normalization

Consistent handling of campaign IDs across all sources:

```sql
CASE
  WHEN NOT TRY_CAST(campaign_id AS BIGINT) IS NULL
  THEN TO_CHAR(ROUND(TRY_CAST(campaign_id AS BIGINT)))
  ELSE TO_CHAR(campaign_id)
END AS campaign_id
```

This handles mixed numeric and string campaign IDs for reliable taxonomy joins.

---

## Data Caveats

### Historical Considerations

| Issue | Impact | Mitigation |
|-------|--------|------------|
| TikTok spend zeroed post-2024 | `bytedanceglobal_int` shows $0 after 2024-01-01 | Intentional exclusion |
| Linear TV has no impression data | OceanMedia records have NULL impressions/clicks | Use spend only for TV |
| Recent TV actuals use pacing | Last 7 days may use pacing data | Caveat in reporting |
| Taxonomy coverage varies | Some campaigns lack taxonomy mapping | Check NULL taxonomy fields |

### Budget ID Reference

| Budget ID | Budget Name | Channel |
|-----------|-------------|--------|
| 722000 | mobile | App campaigns |
| 750000 | brand_tv | Linear TV |
| 750001 | brand_digital | Streaming video (Adobe) |

---

## Common Query Patterns

### Total Spend by Channel (Last 30 Days)
```sql
SELECT 
    channel,
    partner,
    SUM(spend) AS total_spend,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(spend) / NULLIF(SUM(clicks), 0) AS cpc
FROM rdc_marketing.agg_reporting.spend
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY total_spend DESC;
```

### Spend by Budget for Finance Reconciliation
```sql
SELECT 
    budget_id,
    budget_name,
    target_customer,
    SUM(spend) AS total_spend
FROM rdc_marketing.agg_reporting.spend
WHERE event_date >= DATE_TRUNC('month', CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY total_spend DESC;
```

### Daily Spend Trend by Vertical
```sql
SELECT 
    event_date,
    target_vertical,
    SUM(spend) AS daily_spend
FROM rdc_marketing.agg_reporting.spend
WHERE event_date >= DATEADD('day', -90, CURRENT_DATE())
  AND target_customer = 'b2c'
GROUP BY 1, 2
ORDER BY 1, 2;
```

### Cross-Channel Media Mix
```sql
SELECT 
    media_type,
    SUM(spend) AS spend,
    SUM(impressions) AS impressions,
    SUM(spend) / NULLIF(SUM(impressions), 0) * 1000 AS cpm
FROM rdc_marketing.agg_reporting.spend
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
  AND impressions > 0
GROUP BY 1
ORDER BY spend DESC;
```

### B2C vs B2B Spend Comparison
```sql
SELECT 
    target_customer,
    channel,
    SUM(spend) AS total_spend,
    COUNT(DISTINCT event_date) AS days_active
FROM rdc_marketing.agg_reporting.spend
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1, total_spend DESC;
```

---

## Joining with Other Tables

### Join to Marketing Conversion Detail (for ROAS)
```sql
WITH daily_spend AS (
    SELECT 
        event_date,
        channel,
        target_vertical,
        SUM(spend) AS spend
    FROM rdc_marketing.agg_reporting.spend
    WHERE target_customer = 'b2c'
    GROUP BY 1, 2, 3
),
daily_revenue AS (
    SELECT 
        event_date,
        last_touch_marketing_channel AS channel,
        submitted_lead_vertical AS target_vertical,
        SUM(estimated_future_revenue) AS efr
    FROM rdc_analytics.revenue.marketing_conversion_detail
    GROUP BY 1, 2, 3
)
SELECT 
    s.event_date,
    s.channel,
    s.target_vertical,
    s.spend,
    r.efr,
    r.efr / NULLIF(s.spend, 0) AS roas
FROM daily_spend s
LEFT JOIN daily_revenue r
    ON s.event_date = r.event_date
    AND s.channel = r.channel
    AND s.target_vertical = r.target_vertical
WHERE s.event_date >= DATEADD('day', -30, CURRENT_DATE())
ORDER BY s.event_date, s.spend DESC;
```

**Note:** Channel mapping between spend and conversion detail may require additional logic depending on your reporting taxonomy alignment.