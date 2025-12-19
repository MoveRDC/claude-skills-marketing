# Lead to Property to Client Delivery Paths

This document defines the established data paths for connecting leads to property attributes and client delivery destinations in RDC's Snowflake data warehouse.

**Established:** December 2025 (MOPS-928 Analysis)
**Primary Table:** `RDC_ANALYTICS.REVENUE.MARKETING_CONVERSION_DETAIL`

---

## Overview

The marketing_conversion_detail table contains lead-level data with property attributes and delivery flags. This document defines the standard join paths and field mappings for:

1. **Lead → Property Type** (listing classification)
2. **Lead → Client Delivery Flags** (where leads are routed - flag-based)
3. **Lead → Geographic Market** (RCC market mapping)
4. **Price Bucket Segmentation** (standardized price tiers)
5. **Lead → Client Fulfillment** (SFDC asset-level allocation tracking)

---

## 1. Lead to Property Type

### Listing Type Classification

The `listing_type` field in marketing_conversion_detail identifies the property type associated with each lead.

**Field:** `listing_type`
**Location:** `RDC_ANALYTICS.REVENUE.MARKETING_CONVERSION_DETAIL`

#### Low-Value Listing Types

For analysis of low-value leads by property type:

| Listing Type | Description | Typical RPL |
|-------------|-------------|-------------|
| `land` | Vacant land/lots | ~$42 |
| `farms/ranches` | Farm properties | ~$40 |
| `mobile home` | Mobile/manufactured | ~$35 |

#### Land/Lot Lead Filter

For land-specific analysis (excludes mobile homes):

```sql
LOWER(listing_type) IN ('land', 'farms/ranches')
```

For all low-value property types:

```sql
LOWER(listing_type) IN ('land', 'farms/ranches', 'mobile home')
```

**Note:** Case-insensitive matching recommended as values may have mixed case.

### Property Price

**Field:** `lead_listing_price`
**Type:** NUMBER
**Description:** Listing price of the property at time of lead submission

**Caveats:**
- Can be NULL for some leads
- High skewness - use MEDIAN for representative values
- Mean is ~3x median due to high-value outliers

---

## 2. Lead to Client Delivery Flags

### Delivery Type Hierarchy

Leads are routed to various client products. When a lead qualifies for multiple products, use this priority hierarchy:

```
Priority 1: Connections Plus (highest value)
Priority 2: MVIP (includes MVIP Package)
Priority 3: RCC (Non-MVIP)
Priority 4: No Premium Delivery
```

**Source:** wbs2512_pcv_optimization test definition

### Delivery Flag Fields

| Field | Type | Product |
|-------|------|---------|
| `delivered_to_connections_plus_flag` | BOOLEAN | Connections Plus |
| `delivered_to_mvip_flag` | BOOLEAN | MVIP |
| `delivered_to_mvip_package_flag` | BOOLEAN | MVIP Package |
| `delivered_to_readyconnect_concierge_flag` | BOOLEAN | ReadyConnect Concierge |
| `delivered_to_advantage_pro_flag` | BOOLEAN | Advantage Pro |
| `delivered_to_veterans_united_flag` | BOOLEAN | Veterans United |
| `delivered_to_find_a_realtor_flag` | BOOLEAN | Find a Realtor |
| `delivered_to_seller_partner_flag` | BOOLEAN | Seller Partner |
| `delivered_to_upnest_flag` | BOOLEAN | UpNest |
| `delivered_to_rental_flag` | BOOLEAN | Rentals |
| `delivered_to_new_construction_sales_builder_flag` | BOOLEAN | NC Sales Builder |
| `delivered_to_basic_free_flag` | BOOLEAN | Basic Free |
| `delivered_to_local_expert_flag` | BOOLEAN | Local Expert |
| `delivered_to_market_reach_flag` | BOOLEAN | Market Reach |

### Standard Delivery Type Classification

Use this CASE statement for mutually exclusive delivery type assignment:

```sql
CASE 
    WHEN delivered_to_connections_plus_flag = 1 THEN 'Connections Plus'
    WHEN delivered_to_mvip_flag = 1 OR delivered_to_mvip_package_flag = 1 THEN 'MVIP'
    WHEN delivered_to_readyconnect_concierge_flag = 1 THEN 'RCC (Non-MVIP)'
    ELSE 'No Premium Delivery'
END as delivery_type
```

---

## 3. Lead to Geographic Market (RCC)

### RCC Market Mapping

The RCC market mapping connects leads to ReadyConnect Concierge market definitions via postal code.

**Coverage:** ~39% of leads (use State/DMA for complete coverage)

### Source Tables

| Table | Location | Purpose |
|-------|----------|---------|
| lead_zone_zipcode | `fivetran_referral.pg_public.lead_zone_zipcode` | Zip to zone mapping |
| lead_zone | `fivetran_referral.pg_public.lead_zone` | Zone to market mapping |
| market | `fivetran_referral.pg_public.market` | Market definitions |

### Join Path

```
postal_code → lead_zone_zipcode.zipcode → lead_zone.zone_id → market.id
```

### Standard Join Pattern

```sql
WITH zip_market_map AS (
    SELECT DISTINCT
        lzz.zipcode,
        lz.market_id,
        m.name as market_name,
        m.is_premium_market,
        m.price_category
    FROM fivetran_referral.pg_public.lead_zone_zipcode lzz
    JOIN fivetran_referral.pg_public.lead_zone lz ON lzz.zone_id = lz.id
    JOIN fivetran_referral.pg_public.market m ON lz.market_id = m.id
    WHERE m.is_active = true
)
SELECT 
    mcd.*,
    zmm.market_name,
    zmm.market_id
FROM rdc_analytics.revenue.marketing_conversion_detail mcd
LEFT JOIN zip_market_map zmm ON mcd.postal_code = zmm.zipcode
WHERE mcd.event_date >= DATEADD('day', -180, CURRENT_DATE())
```

**Recommendation:** Use `state` or `dma_description` fields from marketing_conversion_detail for complete geographic coverage (99.9%). Reserve RCC market mapping for RCC-specific inventory analysis only.

---

## 4. Price Bucket Segmentation

### Standard Price Bucket Definition

Use this standardized price bucket classification for lead segmentation:

```sql
CASE 
    WHEN lead_listing_price < 100000 THEN '< $100K'
    WHEN lead_listing_price >= 100000 AND lead_listing_price < 200000 THEN '$100K-$200K'
    WHEN lead_listing_price >= 200000 AND lead_listing_price < 300000 THEN '$200K-$300K'
    WHEN lead_listing_price >= 300000 AND lead_listing_price < 400000 THEN '$300K-$400K'
    WHEN lead_listing_price >= 400000 AND lead_listing_price < 500000 THEN '$400K-$500K'
    WHEN lead_listing_price >= 500000 AND lead_listing_price < 750000 THEN '$500K-$750K'
    WHEN lead_listing_price >= 750000 AND lead_listing_price < 1000000 THEN '$750K-$1M'
    WHEN lead_listing_price >= 1000000 THEN '$1M+'
    ELSE 'Unknown'
END as price_bucket
```

**Source:** wbs2512_pcv_optimization test definition

### Price Bucket Ordering

For proper sorting in reports, use this ORDER BY pattern:

```sql
ORDER BY 
    CASE price_bucket
        WHEN '< $100K' THEN 1
        WHEN '$100K-$200K' THEN 2
        WHEN '$200K-$300K' THEN 3
        WHEN '$300K-$400K' THEN 4
        WHEN '$400K-$500K' THEN 5
        WHEN '$500K-$750K' THEN 6
        WHEN '$750K-$1M' THEN 7
        WHEN '$1M+' THEN 8
        ELSE 9
    END
```

### Price Bucket Distribution (Land Leads)

**Data as of:** December 2025 (180-day lookback)
**Note:** Values are point-in-time and will shift with market conditions.

| Price Bucket | Land Leads | % of Land | Land RPL |
|-------------|------------|-----------|----------|
| < $100K | 144,463 | **74.9%** | $36.83 |
| $100K-$200K | 27,446 | 14.2% | $54.19 |
| $200K-$300K | 8,605 | 4.5% | $66.83 |
| $300K-$400K | 4,034 | 2.1% | $67.73 |
| $400K-$500K | 1,953 | 1.0% | $75.42 |
| $500K-$750K | 2,451 | 1.3% | $76.37 |
| $750K-$1M | 1,301 | 0.7% | $74.27 |
| $1M+ | 2,213 | 1.1% | $82.85 |

---

## 5. Lead to Client Fulfillment (SFDC Assets)

This section documents the join path from consumer leads to specific client fulfillment allocations via Salesforce asset records. Use this when analyzing how marketing-driven leads are delivered to specific clients/accounts.

### Conceptual Model

```
Consumer Lead (submitted_lead_id)
    ↓
Lead Inquiry (rdc_inquiry_guid)
    ↓
Lead Inquiry Allocation (parent_asset_id, fulfill_to_asset_id, allocation_type)
    ↓
SFDC Asset (Parent → Fulfill To hierarchy)
    ↓
SFDC Account (Client/Agent)
```

### Source Tables

| Table | Location | Purpose |
|-------|----------|---------|
| lead_inquiry | `fivetran_referral.pg_public.lead_inquiry` | Lead-level detail with `rdc_inquiry_guid` |
| lead_inquiry_allocation | `fivetran_referral.pg_public.lead_inquiry_allocation` | Lead-to-asset allocation records |
| dim_asset_current | `rdc_entsys.sfdc.dim_asset_current` | SFDC asset definitions (contracts) |
| dim_account_current | `rdc_entsys.account.dim_account_current` | Client/account information |

### Key Join Fields

| Field | Table | Description |
|-------|-------|-------------|
| `rdc_inquiry_guid` | lead_inquiry | Links to `submitted_lead_id` in lead tables |
| `lead_inquiry_id` | lead_inquiry_allocation | FK to lead_inquiry.id |
| `parent_asset_id` | lead_inquiry_allocation | Market-level contract asset |
| `fulfill_to_asset_id` | lead_inquiry_allocation | Zip-level fulfillment asset |
| `allocation_type` | lead_inquiry_allocation | `paid` or `followup` |

### Asset Hierarchy

SFDC assets follow a Parent → Fulfill To hierarchy:

| Asset Type | Description | Example |
|------------|-------------|---------|
| **Parent** | Market-level contract | "MVIP Unity DENVER#1" |
| **Fulfill To** | Zip-code level allocation | "MVIP Unity DENVER#1-80202" |

### Key Asset Fields

| Field | Description |
|-------|-------------|
| `id` | Asset ID (links to allocation tables) |
| `parent_asset` | Parent asset ID for Fulfill To assets |
| `accountid` | SFDC Account ID (client) |
| `product2id` | Product identifier |
| `status` | Active, In Active, Expired |
| `market` | Zip code (for Fulfill To assets) |
| `sov` | Share of Voice (%) |
| `min_fuls` / `max_fuls` | Fulfillment bounds |
| `annual_contract_value` | Contract value |
| `start_date` / `end_date` | Contract period |

### Allocation Types

| Type | Description |
|------|-------------|
| `paid` | Monetized lead delivery |
| `followup` | Non-monetized follow-up |

### Major Products by Asset Volume

| Product ID | Product Name | Active Assets |
|------------|--------------|---------------|
| `01t3a000004dsNMAAY` | RCC Concierge | ~72,000 |
| `01tj0000000XyWGAA0` | Connections Plus | ~64,000 |
| `01tj0000003mtmMAAQ` | Realsuite Respond | ~20,000 |
| `01tf1000004YS33AAG` | Realsuite Connect | ~20,000 |
| `01t5f000006sGgOAAU` | MVIP Unity | ~2,500 |

### Standard Join Pattern: Lead to Client

```sql
WITH client_assets AS (
    SELECT
        a.parent_asset,
        a.id as fulfill_asset_id,
        a.name as asset_name,
        a.accountid,
        ac.name as account_name,
        a.status,
        a.market as zip,
        a.sov::int as share_of_voice,
        a.min_fuls::int as min_fulfillments,
        a.max_fuls::int as max_fulfillments,
        a.start_date::date as start_date,
        a.end_date::date as end_date
    FROM rdc_entsys.sfdc.dim_asset_current a
    LEFT JOIN rdc_entsys.account.dim_account_current ac ON a.accountid = ac.id
    WHERE a.isdeleted != true
      AND a.asset_type = 'Fulfill To'
      AND a.status = 'Active'
      -- Filter by product if needed:
      -- AND a.product2id = '01t5f000006sGgOAAU'  -- MVIP Unity
),

lead_allocations AS (
    SELECT DISTINCT
        li.rdc_inquiry_guid as submitted_lead_id,
        lia.parent_asset_id,
        lia.fulfill_to_asset_id,
        lia.allocation_type,
        lia.created_at as allocation_date
    FROM fivetran_referral.pg_public.lead_inquiry_allocation lia
    JOIN fivetran_referral.pg_public.lead_inquiry li ON li.id = lia.lead_inquiry_id
    WHERE lia.deleted_at IS NULL
      -- Filter by specific parent assets if needed:
      -- AND lia.parent_asset_id IN ('02iKa000005MyGmIAK', ...)
)

SELECT 
    lead.submitted_lead_id,
    lead.lead_submitted_date,
    lead.property_postal_code,
    alloc.allocation_type,
    alloc.parent_asset_id,
    ca.account_name as client_name,
    ca.asset_name
FROM rdc_analytics.leads.submitted_lead_detail lead
LEFT JOIN lead_allocations alloc ON lead.submitted_lead_id = alloc.submitted_lead_id
LEFT JOIN client_assets ca ON lead.property_postal_code = ca.zip
WHERE lead.lead_submitted_date >= DATEADD('day', -90, CURRENT_DATE())
  AND lead.lead_vertical LIKE '%for_sale%'
```

---

## 6. Combined Analysis Patterns

### Lowest-Value Segment Identification

To identify the lowest-value lead segments, combine delivery type and price bucket:

```sql
SELECT 
    CASE 
        WHEN delivered_to_connections_plus_flag = 1 THEN 'Connections Plus'
        WHEN delivered_to_mvip_flag = 1 OR delivered_to_mvip_package_flag = 1 THEN 'MVIP'
        WHEN delivered_to_readyconnect_concierge_flag = 1 THEN 'RCC (Non-MVIP)'
        ELSE 'No Premium Delivery'
    END as delivery_type,
    
    CASE 
        WHEN lead_listing_price < 100000 THEN '< $100K'
        WHEN lead_listing_price >= 100000 AND lead_listing_price < 200000 THEN '$100K-$200K'
        WHEN lead_listing_price >= 200000 AND lead_listing_price < 300000 THEN '$200K-$300K'
        WHEN lead_listing_price >= 300000 AND lead_listing_price < 400000 THEN '$300K-$400K'
        WHEN lead_listing_price >= 400000 AND lead_listing_price < 500000 THEN '$400K-$500K'
        WHEN lead_listing_price >= 500000 AND lead_listing_price < 750000 THEN '$500K-$750K'
        WHEN lead_listing_price >= 750000 AND lead_listing_price < 1000000 THEN '$750K-$1M'
        WHEN lead_listing_price >= 1000000 THEN '$1M+'
        ELSE 'Unknown'
    END as price_bucket,
    
    COUNT(DISTINCT submitted_lead_id) as lead_count,
    ROUND(SUM(estimated_future_revenue) / NULLIF(COUNT(DISTINCT submitted_lead_id), 0), 2) as rpl

FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -180, CURRENT_DATE())
  AND last_touch_marketing_channel = 'paid search'
  AND submitted_lead_vertical = 'for_sale'
  AND LOWER(listing_type) IN ('land', 'farms/ranches')
GROUP BY 1, 2
ORDER BY 
    CASE delivery_type
        WHEN 'Connections Plus' THEN 1
        WHEN 'MVIP' THEN 2
        WHEN 'RCC (Non-MVIP)' THEN 3
        ELSE 4
    END,
    CASE price_bucket
        WHEN '< $100K' THEN 1
        WHEN '$100K-$200K' THEN 2
        WHEN '$200K-$300K' THEN 3
        WHEN '$300K-$400K' THEN 4
        WHEN '$400K-$500K' THEN 5
        WHEN '$500K-$750K' THEN 6
        WHEN '$750K-$1M' THEN 7
        WHEN '$1M+' THEN 8
        ELSE 9
    END;
```

### Marketing Channel to Client Fulfillment Analysis

To analyze how specific marketing campaigns drive leads to specific clients:

```sql
WITH lead_data AS (
    SELECT 
        lead.submitted_lead_id,
        lead.lead_submitted_date,
        lead.property_postal_code,
        lead.last_touch_marketing_channel,
        lead.last_touch_marketing_channel_detail,
        rev.estimated_future_revenue,
        rev.list_price_current
    FROM rdc_analytics.leads.submitted_lead_detail lead
    LEFT JOIN rdc_analytics.revenue.marketing_conversion_detail_v2 rev 
        ON lead.submitted_lead_id = rev.submitted_lead_id
    WHERE lead.lead_submitted_date >= DATEADD('day', -90, CURRENT_DATE())
      AND lead.lead_vertical LIKE '%for_sale%'
),

allocations AS (
    SELECT DISTINCT
        li.rdc_inquiry_guid as submitted_lead_id,
        lia.parent_asset_id,
        lia.allocation_type
    FROM fivetran_referral.pg_public.lead_inquiry_allocation lia
    JOIN fivetran_referral.pg_public.lead_inquiry li ON li.id = lia.lead_inquiry_id
    WHERE lia.deleted_at IS NULL
)

SELECT 
    ld.last_touch_marketing_channel,
    a.allocation_type,
    COUNT(DISTINCT ld.submitted_lead_id) as lead_count,
    ROUND(SUM(ld.estimated_future_revenue), 2) as total_efr,
    ROUND(AVG(ld.estimated_future_revenue), 2) as avg_efr
FROM lead_data ld
LEFT JOIN allocations a ON ld.submitted_lead_id = a.submitted_lead_id
GROUP BY 1, 2
ORDER BY 1, 2;
```

---

## 7. Data Quality Notes

### Aggregation Grain

The marketing_conversion_detail table is at the `submitted_lead_id` grain with no duplicates. Each row represents one unique lead.

**Validation:**
```sql
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT submitted_lead_id) as unique_leads
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -180, CURRENT_DATE());
-- Result: Records = Unique Leads (1:1 ratio)
```

### Lead Allocation Coverage

Not all leads have allocation records. The lead_inquiry_allocation table only contains leads that were routed through the allocation system.

```sql
-- Check allocation coverage
SELECT 
    COUNT(DISTINCT lead.submitted_lead_id) as total_leads,
    COUNT(DISTINCT alloc.submitted_lead_id) as allocated_leads,
    ROUND(100.0 * COUNT(DISTINCT alloc.submitted_lead_id) / 
          NULLIF(COUNT(DISTINCT lead.submitted_lead_id), 0), 2) as coverage_pct
FROM rdc_analytics.leads.submitted_lead_detail lead
LEFT JOIN (
    SELECT DISTINCT li.rdc_inquiry_guid as submitted_lead_id
    FROM fivetran_referral.pg_public.lead_inquiry_allocation lia
    JOIN fivetran_referral.pg_public.lead_inquiry li ON li.id = lia.lead_inquiry_id
    WHERE lia.deleted_at IS NULL
) alloc ON lead.submitted_lead_id = alloc.submitted_lead_id
WHERE lead.lead_submitted_date >= DATEADD('day', -30, CURRENT_DATE());
```

---

## 8. Related Documentation

- **[marketing_conversion_detail_annotated.md](marketing_conversion_detail_annotated.md)** - Full schema and EFR calculation methodology
- **[business_logic_reference.md](business_logic_reference.md)** - Incrementality and attribution rules
- **[snowflake_core_tables.md](snowflake_core_tables.md)** - Complete table schema documentation

---
