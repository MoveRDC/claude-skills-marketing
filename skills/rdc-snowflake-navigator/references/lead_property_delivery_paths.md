# Lead to Property to Client Delivery Paths

This document defines the established data paths for connecting leads to property attributes and client delivery destinations in RDC's Snowflake data warehouse.

**Established:** December 2025 (MOPS-928 Analysis)
**Primary Table:** `RDC_ANALYTICS.REVENUE.MARKETING_CONVERSION_DETAIL`

---

## Overview

The marketing_conversion_detail table contains lead-level data with property attributes and delivery flags. This document defines the standard join paths and field mappings for:

1. **Lead → Property Type** (listing classification)
2. **Lead → Client Delivery** (where leads are routed)
3. **Lead → Geographic Market** (RCC market mapping)
4. **Price Bucket Segmentation** (standardized price tiers)

---

## 1. Lead to Property Type

### Listing Type Classification

The `listing_type` field in marketing_conversion_detail identifies the property type associated with each lead.

**Field:** `listing_type`
**Location:** `RDC_ANALYTICS.REVENUE.MARKETING_CONVERSION_DETAIL`

#### Land/Lot Lead Definition

For analysis of low-value lot/land leads, use:

```sql
LOWER(listing_type) IN ('land', 'farms/ranches')
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

## 2. Lead to Client Delivery

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

### Source Tables

| Table | Location | Purpose |
|-------|----------|---------|
| lead_zone_zipcode | `fivetran_referral.pg_public.lead_zone_zipcode` | Zip to zone mapping |
| lead_zone | `fivetran_referral.pg_public.lead_zone` | Zone to market mapping |
| market | `fivetran_referral.pg_public.market` | Market definitions |

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

## 5. Combined Analysis Patterns

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
        -- ... (full price bucket logic)
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
ORDER BY delivery_type, price_bucket;
```

---

## 6. Data Quality Notes

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

---

## 7. Related Documentation

- **[marketing_conversion_detail_annotated.md](marketing_conversion_detail_annotated.md)** - Full schema and EFR calculation methodology
- **[business_logic_reference.md](business_logic_reference.md)** - Incrementality and attribution rules
- **[snowflake_core_tables.md](snowflake_core_tables.md)** - Complete table schema documentation

---
