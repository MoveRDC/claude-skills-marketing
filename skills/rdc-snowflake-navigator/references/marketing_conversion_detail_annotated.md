# Marketing Conversion Detail View Definition - Annotated

This document provides an annotated version of the `RDC_ANALYTICS.REVENUE.MARKETING_CONVERSION_DETAIL` view, explaining the EFR calculation methodology and revenue attribution logic.

## Overview

The marketing_conversion_detail view is the primary source for lead-level revenue attribution. It combines submitted and delivered lead data with marketing channel attribution and calculates Estimated Future Revenue (EFR) from multiple revenue sources.

**Location:** `RDC_ANALYTICS.REVENUE.MARKETING_CONVERSION_DETAIL`

**Grain:** Submitted Lead ID

**Primary Use:** Lead attribution, EFR reporting, marketing channel performance, ROAS calculations

---

## Output Schema (Key Fields)

### Lead Identification
| Field | Type | Description |
|-------|------|-------------|
| `event_date` | DATE | Lead submission date |
| `submitted_lead_id` | VARCHAR | Primary lead identifier (RDC inquiry GUID) |
| `adjusted_uu_id` | VARCHAR | Canonical user ID for cross-table joins |
| `inquiry_lead_id` | VARCHAR | Lead ID from consumer mapping |

### Lead Attributes
| Field | Type | Description |
|-------|------|-------------|
| `submitted_lead_vertical` | VARCHAR | Lead vertical: 'for_sale', 'for_rent', 'Seller' |
| `submitted_lead_product` | VARCHAR | Lead product type |
| `lead_listing_price` | NUMBER | Price of associated listing |
| `list_price_current` | NUMBER | Current listing price (from dim_listing_history) |
| `platform` | VARCHAR | Platform where lead was submitted |
| `site_section` | VARCHAR | Site section context |

### Geographic Fields
| Field | Type | Description |
|-------|------|-------------|
| `postal_code` | VARCHAR | Property postal code |
| `city` | VARCHAR | City (from us_zip_mapping) |
| `state` | VARCHAR | State (from us_zip_mapping) |
| `county` | VARCHAR | County (from us_zip_mapping) |
| `dma_code` | VARCHAR | DMA code (from zip_dma_map) |
| `dma_description` | VARCHAR | DMA description |

### Marketing Attribution
| Field | Type | Description |
|-------|------|-------------|
| `last_touch_marketing_channel` | VARCHAR | Last-touch channel attribution |
| `last_touch_marketing_channel_detail` | VARCHAR | Detailed channel info (CID) |
| `cid` | VARCHAR | Campaign ID tracking parameter |
| `google_click_id` | VARCHAR | GCLID for paid search attribution |
| `first_google_click_id_date` | DATE | First date GCLID was seen |

### Delivery Flags
| Field | Type | Description |
|-------|------|-------------|
| `delivered_to_connections_plus_flag` | BOOLEAN | Delivered to Connections Plus |
| `delivered_to_readyconnect_concierge_flag` | BOOLEAN | Delivered to RCC |
| `delivered_to_find_a_realtor_flag` | BOOLEAN | Delivered to FAR |
| `delivered_to_veterans_united_flag` | BOOLEAN | Delivered to Veterans United |
| `delivered_to_advantage_pro_flag` | BOOLEAN | Delivered to Advantage Pro |
| `delivered_to_mvip_flag` | BOOLEAN | Delivered to MVIP |
| `delivered_to_seller_partner_flag` | BOOLEAN | Delivered to Seller Partner |
| `delivered_to_upnest_flag` | BOOLEAN | Delivered to UpNest |
| `delivered_to_rental_flag` | BOOLEAN | Delivered to Rentals |
| `delivered_to_new_construction_sales_builder_flag` | BOOLEAN | Delivered to NC Sales Builder |

### EFR Components
| Field | Type | Description |
|-------|------|-------------|
| `buy_estimated_future_revenue_referral` | NUMBER | Buy-side referral EFR (7-day rolling avg) |
| `sell_estimated_future_revenue_referral` | NUMBER | Sell-side referral EFR (7-day rolling avg) |
| `cplus_contract_revenue` | NUMBER | Connections Plus contract revenue |
| `mvip_revenue` | NUMBER | MVIP contract revenue |
| `adpro_revenue` | NUMBER | Advantage Pro revenue (zip code avg from C+) |
| `veterans_revenue` | NUMBER | Veterans United revenue (fixed rate schedule) |
| `sales_builder_revenue` | NUMBER | New Construction Sales Builder revenue |
| `sell_realchoice_estimated_future_revenue` | NUMBER | UpNest sell-side EFR |
| `rent_estimated_future_revenue_zillow` | NUMBER | Rentals EFR from Zillow |
| `rent_estimated_future_revenue_other_ils` | NUMBER | Rentals EFR from other ILS (post May 2024) |

### Aggregated EFR
| Field | Type | Description |
|-------|------|-------------|
| `estimated_future_revenue` | NUMBER | **Total EFR** (sum of all components) |
| `total_buy_estimated_future_revenue` | NUMBER | Buy-side EFR subtotal |
| `total_sell_estimated_future_revenue` | NUMBER | Sell-side EFR subtotal |
| `total_rent_estimated_future_revenue` | NUMBER | Rent EFR subtotal |

---

## Source Tables

### Primary Sources
```
┌─────────────────────────────────────────────────────────────────────┐
│                       FINAL SELECT                                   │
├─────────────────────────────────────────────────────────────────────┤
│  leads_data              ← submitted_lead_detail_v2 +               │
│                            delivered_lead_detail_v2                  │
│  consumer_mapping_dd     ← consumer_lead_mapping_detail +           │
│                            upnest attribution CTEs                   │
│  efr_buy_referral        ← referral_revenue (buy side)              │
│  efr_sell_referral       ← referral_revenue (sell side)             │
│  lead_sales_revenue      ← C+ contract revenue                      │
│  mvip_revenue            ← MVIP contract revenue                    │
│  rentals_revenue         ← Rental lead revenue                      │
│  realchoice_revenue      ← UpNest revenue                           │
│  nc_sales_builder_revenue← New Construction revenue                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## CTE Details

### 1. leads_data (Core Lead Records)

Joins submitted and delivered lead details to create the base lead record.

**Sources:** 
- `rdc_analytics.leads.submitted_lead_detail_v2`
- `rdc_analytics.leads.delivered_lead_detail_v2`
- `rdc_core.dimension.dim_listing_history` (for current list price)

**Key Logic:**
```sql
SELECT DISTINCT
    a.lead_submitted_date AS event_date,
    a.submitted_lead_id,
    a.adjusted_uu_id,
    ...
    MAX(b.delivered_to_connections_plus_flag) AS delivered_to_connections_plus_flag,
    -- All other delivery flags use MAX() aggregation
FROM submitted_lead_detail_v2 AS a
INNER JOIN delivered_lead_detail_v2 AS b
    ON a.submitted_lead_id = b.submitted_lead_id
LEFT JOIN dim_listing_history AS c  -- Deduplicated to latest
    ON a.listing_id = c.listing_id
GROUP BY ALL
```

**Note:** Delivery flags are aggregated with MAX() because a single submitted lead may have multiple delivery records.

---

### 2. rdc_opcity_map (RCC Lead Mapping)

Maps RDC inquiry GUIDs to OpCity/RCC lead IDs.

**Source:** `rdc_analytics.referral.inquiry_detail` joined to `team_referral.reporting_base.lead_inquiry_base`

```sql
SELECT
    rdc_inquiry_guid,
    FIRST_VALUE(ind.lead_id) IGNORE NULLS OVER (...) AS lead_id,
    FIRST_VALUE(lib.lead_op_id) IGNORE NULLS OVER (...) AS lead_op_id
FROM rdc_analytics.referral.inquiry_detail AS ind
LEFT JOIN team_referral.reporting_base.lead_inquiry_base AS lib
    ON ind.lead_id = lib.lead_id
WHERE rdc_inquiry_guid IS NOT NULL 
  AND inquiry_created_at >= '2020-01-01'
```

---

### 3. UpNest Marketing Attribution CTEs

Four CTEs extract marketing attribution from UpNest lead data:

#### upnest_campaign_data
Extracts campaign name from `googletracking` field:
```sql
REPLACE(TRIM(TO_CHAR(gt_campaign.value)), '[campaign] ', '') AS campaign
```

#### upnest_adgroup_data
Extracts adgroup from `googletracking` field.

#### upnest_cid_data
Parses CID parameters from `landing_url`:
```sql
-- CID format: channel_accountid_campaignid_adgroupid
TO_CHAR(SPLIT(cid, '_')[0]) AS channel_prefix,
TO_CHAR(SPLIT(cid, '_')[1]) AS account_id,
TO_CHAR(SPLIT(cid, '_')[2]) AS campaign_id,
TO_CHAR(SPLIT(cid, '_')[3]) AS adgroup_id
```

#### upnest_cid_final
Maps channel prefix to marketing channel:
```sql
CASE TRUE
  WHEN LEFT(channel_prefix, 3) = 'sem' THEN 'paid search'
  WHEN LEFT(channel_prefix, 3) = 'eml' THEN 'email'
  WHEN LEFT(channel_prefix, 3) = 'aff' THEN 'misc sources'
  WHEN LEFT(channel_prefix, 3) = 'rmc' THEN 'digital brand'
  WHEN LEFT(channel_prefix, 3) = 'psc' THEN 'display/social ads'
  WHEN LEFT(channel_prefix, 3) = 'dsp' THEN 'display/social ads'
  WHEN LEFT(channel_prefix, 4) = 'push' THEN 'notifications'
  WHEN LEFT(channel_prefix, 5) = 'braze' THEN 'notifications'
  WHEN LEFT(channel_prefix, 3) = 'dml' THEN 'direct mail'
  ELSE 'misc sources'
END AS last_touch_marketing_channel
```

---

### 4. consumer_mapping_dd (Consumer Attribution)

Combines standard consumer mapping with UpNest attribution data.

**Sources:**
- `rdc_analytics.consumer_mapping.consumer_lead_mapping_detail`
- `upnest_cid_final` (from above)
- `rdc_analytics.clickstream.clickstream_detail_upnest`

**Key Logic:**
```sql
-- Prioritize UpNest attribution when available
COALESCE(
  CASE WHEN b.last_touch_marketing_channel_detail = '' THEN NULL
       ELSE b.last_touch_marketing_channel END,
  a.last_touch_marketing_channel
) AS last_touch_marketing_channel
```

---

### 5. EFR Buy Referral Calculation

This is a multi-step calculation using a 7-day rolling average by price tier.

#### ref_buy_data
Filters referral_revenue to buy-side transactions:
```sql
WHERE lead_owner_type = 'RCC'           -- Exclude third party
  AND transaction_lead_owner = 'Core'   -- Exclude EM
  AND transaction_type = 'buy'
  AND first_inquiry_created_at >= '2020-10-01'
```

**RPL Category (Price Tier) Logic:**
```sql
CASE
  WHEN lead_listing_price > 0 AND lead_listing_price <= 62000 THEN 'G'
  WHEN lead_listing_price > 62000 AND lead_listing_price <= 115000 THEN 'F'
  WHEN lead_listing_price > 115000 AND lead_listing_price <= 152500 THEN 'E'
  WHEN lead_listing_price > 152500 AND lead_listing_price <= 212900 THEN 'D'
  WHEN lead_listing_price > 212900 AND lead_listing_price <= 380000 THEN 'C'
  WHEN lead_listing_price > 380000 AND lead_listing_price <= 800000 THEN 'B'
  WHEN lead_listing_price > 800000 AND lead_listing_price <= 30000000 THEN 'A'
  WHEN lead_listing_price = 0 OR lead_listing_price IS NULL THEN 'NULL'
  ELSE 'High'
END AS rpl_category
```

**Price Tier Boundaries:**
| Category | Price Range |
|----------|-------------|
| G | $0 - $62,000 |
| F | $62,001 - $115,000 |
| E | $115,001 - $152,500 |
| D | $152,501 - $212,900 |
| C | $212,901 - $380,000 |
| B | $380,001 - $800,000 |
| A | $800,001 - $30,000,000 |
| High | > $30,000,000 |
| NULL | $0 or NULL |

#### lag_metrics_ref_buy
Calculates 7-day rolling window (lagged 30 days):
```sql
SUM(buyer_29_day_predicted_close_rev) OVER (
  PARTITION BY rpl_category
  ORDER BY first_inquiry_created_at
  ROWS BETWEEN 36 PRECEDING AND 30 PRECEDING  -- Days 30-36 back
) AS lag_7_day_moving_revenue
```

**Note:** The window is days 30-36 before the inquiry date, creating a lagged 7-day average.

#### efr_buy_referral
Final calculation:
```sql
lag_7_day_moving_revenue / lag_7_day_moving_lead_count AS buy_estimated_future_revenue_referral
```

---

### 6. EFR Sell Referral Calculation

Mirrors the buy calculation but for sell-side transactions.

**Key Differences:**
- Filters to `transaction_type = 'list'`
- Uses `seller_29_day_predicted_close_rev`
- Caps outliers: `WHEN seller_29_day_predicted_close_rev > 25000 THEN 0`

---

### 7. ad_pro_rpl (Advantage Pro Revenue)

Calculates Advantage Pro EFR using zip code average from Connections Plus.

**Source:** `rdc_analytics.revenue.lead_sales_revenue`

```sql
-- Zip code average C+ RPL per month
SELECT
    DATE_TRUNC('MONTH', event_date) AS lead_month,
    b.postal_code,
    AVG(a.initial_revenue) AS rpl
FROM lead_sales_revenue AS a
LEFT JOIN leads_data AS b ON a.submitted_lead_id = b.submitted_lead_id
WHERE initial_revenue > 0 
  AND delivered_to_connections_plus_flag = 1
GROUP BY 1, 2
```

**Filter:** Only leads with `lead_product_name IN ('advantage_pro', 'showcase')` and `site_section = 'for_sale'`

---

### 8. veterans (Veterans United Revenue)

Fixed rate schedule based on date, market type, and price.

**Rate Schedule:**

| Date Range | Market Type | Price Range | Value |
|------------|-------------|-------------|-------|
| Before 2022-03-01 | Any | Any | $93 |
| 2022-03 to 2023-03 | Choice | $75K-$100K | $65 |
| 2022-03 to 2023-03 | Choice | $100K-$500K | $100 |
| 2022-03 to 2023-03 | Pure | $75K-$500K | $120 |
| 2023-03+ | Any | $75K-$125K | $25 |
| 2023-03+ | Any | $125K-$200K | $55 |
| 2023-03+ | Any | $200K-$500K | $97 |
| 2023-03+ | Any | $500K-$600K | $105 |
| 2023-03+ | Any | $600K-$700K | $125 |

**Exclusion:** `LOWER(lead_state) <> 'ny'` (NY leads excluded per VU agreement)

---

### 9. rent (Rentals Revenue)

**Source:** `rdc_analytics.revenue.rentals_revenue`

**Revenue Split (as of May 2024):**
```sql
CASE WHEN source_abbreviation = 'ZILL' THEN rpl END AS zillow_revenue,
CASE WHEN lead_submitted_date >= '2024-05' 
      AND source_abbreviation <> 'ZILL' THEN rpl END AS other_ILS_revenue
```

---

## Final EFR Calculation

The total EFR is the sum of all components:

```sql
SUM(
  COALESCE(g.buy_estimated_future_revenue_referral, 0) +
  COALESCE(s.seller_estimated_future_revenue_referral, 0) +
  COALESCE(d.contract_revenue, 0) +           -- C+ contract
  COALESCE(f.contract_revenue, 0) +           -- MVIP contract
  COALESCE(ad_pro_rpl.revenue, 0) +           -- Advantage Pro
  COALESCE(veterans.value, 0) +               -- Veterans United
  COALESCE(upnest.sell_realchoice_efr, 0) +   -- UpNest sell
  COALESCE(sb.lead_value, 0) +                -- Sales Builder
  COALESCE(r.rpl, 0)                          -- Rentals
) AS estimated_future_revenue
```

### EFR Component Subtotals

**Buy EFR:**
```sql
buy_estimated_future_revenue_referral + cplus_contract_revenue + 
mvip_revenue + adpro_revenue + veterans_revenue + sales_builder_revenue
```

**Sell EFR:**
```sql
sell_estimated_future_revenue_referral + sell_realchoice_estimated_future_revenue
```

**Rent EFR:**
```sql
total_rent_estimated_future_revenue  -- (Zillow + Other ILS)
```

---

## Key Business Logic

### Lead Matching Pattern

All joins to the base leads_data use case-insensitive matching:
```sql
ON LOWER(a.submitted_lead_id) = LOWER(b.submitted_lead_id)
```

### Data Freshness

The view excludes the current date:
```sql
WHERE TO_DATE(a.event_date) >= '2020-01-01' 
  AND a.event_date < CURRENT_DATE
```

### GCLID Attribution

GCLID timing comes from both:
1. `consumer_mapping.consumer_mapping_detail` (standard path)
2. `rdc_marketing.dimension.dim_gclids` (Segment path)

---

## Data Caveats

| Issue | Impact | Notes |
|-------|--------|-------|
| EFR is lagged 30 days | Recent leads have no referral EFR | Rolling avg uses days 30-36 back |
| High price tier gets $0 EFR | Leads > $30M have no referral EFR | Intentional exclusion |
| NY excluded from Veterans | NY leads get $0 VU revenue | Per VU agreement |
| Rental ILS split post May 2024 | Pre-2024-05 has no ILS breakdown | `other_ILS_revenue` is NULL before |
| Seller EFR capped at $25K | Outliers zeroed out | Prevents skew from anomalies |

---

## Common Query Patterns

### Daily Lead Volume and EFR by Channel
```sql
SELECT 
    event_date,
    last_touch_marketing_channel,
    submitted_lead_vertical,
    COUNT(DISTINCT submitted_lead_id) AS leads,
    SUM(estimated_future_revenue) AS efr,
    SUM(estimated_future_revenue) / NULLIF(COUNT(DISTINCT submitted_lead_id), 0) AS rpl
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC;
```

### EFR Components Breakdown
```sql
SELECT 
    event_date,
    SUM(buy_estimated_future_revenue_referral) AS buy_referral,
    SUM(sell_estimated_future_revenue_referral) AS sell_referral,
    SUM(cplus_contract_revenue) AS cplus,
    SUM(mvip_revenue) AS mvip,
    SUM(adpro_revenue) AS adpro,
    SUM(veterans_revenue) AS veterans,
    SUM(sales_builder_revenue) AS sales_builder,
    SUM(sell_realchoice_estimated_future_revenue) AS upnest,
    SUM(total_rent_estimated_future_revenue) AS rent,
    SUM(estimated_future_revenue) AS total_efr
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1
ORDER BY 1;
```

### Paid Search Performance with GCLID
```sql
SELECT 
    event_date,
    COUNT(DISTINCT submitted_lead_id) AS leads,
    COUNT(DISTINCT CASE WHEN google_click_id IS NOT NULL 
                        THEN submitted_lead_id END) AS leads_with_gclid,
    SUM(estimated_future_revenue) AS efr
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
  AND last_touch_marketing_channel = 'paid search'
GROUP BY 1
ORDER BY 1;
```

### Lead Delivery Analysis
```sql
SELECT 
    event_date,
    SUM(CASE WHEN delivered_to_connections_plus_flag THEN 1 ELSE 0 END) AS cplus_leads,
    SUM(CASE WHEN delivered_to_mvip_flag THEN 1 ELSE 0 END) AS mvip_leads,
    SUM(CASE WHEN delivered_to_veterans_united_flag THEN 1 ELSE 0 END) AS vu_leads,
    SUM(CASE WHEN delivered_to_upnest_flag THEN 1 ELSE 0 END) AS upnest_leads,
    SUM(CASE WHEN delivered_to_rental_flag THEN 1 ELSE 0 END) AS rental_leads
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1
ORDER BY 1;
```

### RPL by Price Tier
```sql
SELECT 
    rpl_category,
    COUNT(DISTINCT submitted_lead_id) AS leads,
    SUM(buy_estimated_future_revenue_referral) AS buy_efr,
    SUM(buy_estimated_future_revenue_referral) / NULLIF(COUNT(DISTINCT submitted_lead_id), 0) AS buy_rpl
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
  AND submitted_lead_vertical = 'for_sale'
  AND rpl_category IS NOT NULL
GROUP BY 1
ORDER BY 
    CASE rpl_category 
        WHEN 'A' THEN 1 WHEN 'B' THEN 2 WHEN 'C' THEN 3 
        WHEN 'D' THEN 4 WHEN 'E' THEN 5 WHEN 'F' THEN 6 
        WHEN 'G' THEN 7 ELSE 8 
    END;
```

---

## Joining with Other Tables

### Join to Spend for ROAS
```sql
WITH daily_efr AS (
    SELECT 
        event_date,
        last_touch_marketing_channel AS channel,
        SUM(estimated_future_revenue) AS efr
    FROM rdc_analytics.revenue.marketing_conversion_detail
    GROUP BY 1, 2
),
daily_spend AS (
    SELECT 
        event_date,
        channel,
        SUM(spend) AS spend
    FROM rdc_marketing.agg_reporting.spend
    WHERE target_customer = 'b2c'
    GROUP BY 1, 2
)
SELECT 
    s.event_date,
    s.channel,
    s.spend,
    e.efr,
    e.efr / NULLIF(s.spend, 0) AS roas
FROM daily_spend s
LEFT JOIN daily_efr e
    ON s.event_date = e.event_date
    AND s.channel = e.channel
WHERE s.event_date >= DATEADD('day', -30, CURRENT_DATE())
ORDER BY s.event_date, s.spend DESC;
```

**Note:** Channel mapping between spend and conversion detail may require normalization. The spend table uses taxonomy-based channels while marketing_conversion_detail uses last-touch marketing channels.