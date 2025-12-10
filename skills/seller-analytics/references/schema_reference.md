# Seller Schema Reference

Detailed field-level documentation for seller analytics tables.

## rdc_marketing.seller.sell_spend

Campaign spend and performance metrics.

**Grain**: date + campaign + adgroup

| Field | Type | Description |
|-------|------|-------------|
| `calendar_date` | DATE | Performance date |
| `campaign` | STRING | Campaign ID |
| `campaign_name` | STRING | Human-readable campaign name |
| `adgroup_id` | STRING | Ad group ID (can be NULL) |
| `adgroup_name` | STRING | Ad group name |
| `channel` | STRING | Marketing channel ('paid search', etc.) |
| `target_customer` | STRING | Customer segment ('b2c', 'b2b') |
| `partner` | STRING | Ad platform partner ('google', 'bing') |
| `marketing_brand` | STRING | Brand identifier |
| `spend` | FLOAT | Daily spend amount (USD) |
| `impressions` | INT | Ad impressions |
| `clicks` | INT | Ad clicks |

**Standard Filters**:
```sql
WHERE channel = 'paid search'
  AND target_customer = 'b2c'
```

---

## rdc_marketing.seller.sell_attribution

Lead-to-campaign attribution mapping.

**Grain**: request_id + transaction_type

| Field | Type | Description |
|-------|------|-------------|
| `request_id` | STRING | Unique lead identifier |
| `transaction_type` | STRING | 'buy' or 'sell' |
| `lead_date` | DATE | Date lead was submitted |
| `campaign_id` | STRING | Attributed campaign ID |
| `adgroup_id` | STRING | Attributed ad group ID (can be NULL) |

**Join Notes**:
- Primary key: `request_id + transaction_type`
- Join to spend: `campaign_id = campaign` AND `adgroup_id = adgroup_id` AND `lead_date = calendar_date`
- Use `COALESCE(adgroup_id, '')` to handle nulls in joins

---

## rdc_marketing.seller.sell_revenue_est

Revenue, EFR (Expected Future Revenue), and property value estimates per lead.

**Grain**: request_id + transaction_type

| Field | Type | Description |
|-------|------|-------------|
| `request_id` | STRING | Unique lead identifier |
| `transaction_type` | STRING | 'buy' or 'sell' |
| `rep_efr` | FLOAT | EFR v1 - original calculation |
| `actualizedrev` | FLOAT | Realized/actualized revenue |
| `estimated_home_value` | FLOAT | Estimated value of the property associated with the lead |

**Join Notes**:
- Join to attribution: `request_id + transaction_type`
- For EFR, prefer v2 from `seller_lead_efr_paid_search` when available

**Home Value Analysis**:
```sql
-- Home value distribution
SELECT
    CASE 
        WHEN estimated_home_value < 100000 THEN 'Under $100K'
        WHEN estimated_home_value < 250000 THEN '$100K-$250K'
        WHEN estimated_home_value < 500000 THEN '$250K-$500K'
        WHEN estimated_home_value < 750000 THEN '$500K-$750K'
        WHEN estimated_home_value < 1000000 THEN '$750K-$1M'
        WHEN estimated_home_value >= 1000000 THEN '$1M+'
        ELSE 'Unknown'
    END AS home_value_bucket,
    COUNT(DISTINCT request_id) AS lead_count
FROM rdc_marketing.seller.sell_revenue_est
GROUP BY 1;
```

---

## rdc_marketing.seller.sell_downfunnel

Downstream conversion and matching events.

**Grain**: request_id + transaction_type

| Field | Type | Description |
|-------|------|-------------|
| `request_id` | STRING | Unique lead identifier |
| `transaction_type` | STRING | 'buy' or 'sell' |
| `created_date` | DATE | Lead creation date |
| `matchdate` | DATE | Date lead was matched to agent |
| `awarded_30d` | BOOLEAN | Awarded within 30 days |
| `rejected` | BOOLEAN | Lead was rejected |
| `is_fake_or_fraud` | BOOLEAN | Flagged as fake/fraudulent |

**UCA Calculation**:
```sql
COUNT(DISTINCT CASE 
    WHEN DATEDIFF('day', d.created_date, d.matchdate) <= 14 
    THEN d.request_id 
END) AS uca_14d
```

---

## rdc_analytics.ons.sell_lead_quality

Lead quality scoring.

**Grain**: request_id + transaction_type

| Field | Type | Description |
|-------|------|-------------|
| `request_id` | STRING | Unique lead identifier |
| `transaction_type` | STRING | 'buy' or 'sell' |
| `quality_level` | STRING | Quality tier ('GQ' = Good Quality, 'LQ' = Low Quality) |

**Quality Level Values**:
- `'GQ'` - Good Quality (primary success metric)
- `'LQ'` - Low Quality
- NULL/Unknown - Quality not yet determined

---

## rdc_analytics.revenue.seller_lead_efr_paid_search

Updated EFR calculation (v2) specifically for paid search leads.

**Grain**: request_id + transaction_type

| Field | Type | Description |
|-------|------|-------------|
| `request_id` | STRING | Unique lead identifier |
| `transaction_type` | STRING | 'buy' or 'sell' |
| `rep_efr_v2` | FLOAT | EFR v2 - updated calculation |

**Usage**:
```sql
-- Always prefer v2 when available
COALESCE(ra.rep_efr_v2, r.rep_efr) AS efr
```

---

## Entity Relationship Diagram

```
sell_spend (date+campaign+adgroup)
    │
    └──LEFT JOIN──► leads_subquery (aggregated)
                         │
                         ├── sell_attribution (request_id+transaction_type)
                         │        │
                         │        ├──JOIN──► sell_revenue_est
                         │        │
                         │        ├──LEFT JOIN──► seller_lead_efr_paid_search
                         │        │
                         │        ├──LEFT JOIN──► sell_lead_quality
                         │        │
                         │        └──JOIN──► sell_downfunnel
```

## Join Key Reference

| From Table | To Table | Join Keys |
|------------|----------|-----------|
| sell_spend | leads_subquery | `campaign = campaign_id` AND `adgroup_id = adgroup_id` AND `calendar_date = lead_date` |
| sell_attribution | sell_revenue_est | `request_id` AND `transaction_type` |
| sell_attribution | seller_lead_efr_paid_search | `request_id` AND `transaction_type` |
| sell_attribution | sell_lead_quality | `request_id` AND `transaction_type` |
| sell_attribution | sell_downfunnel | `request_id` AND `transaction_type` |

## Field Naming Conventions

| sell_spend | sell_attribution | Notes |
|------------|------------------|-------|
| `calendar_date` | `lead_date` | Same meaning, different names |
| `campaign` | `campaign_id` | ID field naming varies |
| `adgroup_id` | `adgroup_id` | Same name |
