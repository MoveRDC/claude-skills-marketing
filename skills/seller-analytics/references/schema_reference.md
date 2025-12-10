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
| `partner` | STRING | Ad platform partner ('google', 'bing', 'facebook') |
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
| `actualizedrev` | FLOAT | Realized/actualized revenue (populated after transaction closes, 6+ month lag) |
| `estimated_home_value` | FLOAT | Estimated value of the property associated with the lead |

**Join Notes**:
- Join to attribution: `request_id + transaction_type`
- For EFR, prefer v2 from `seller_lead_efr_paid_search` when available
- EFR is adjusted by GQ/LQ coefficient: GQ = 147% of baseline, LQ = 75%

**Home Value Analysis**:
```sql
-- Home value distribution
SELECT
    CASE 
        WHEN estimated_home_value < 150000 THEN 'Under $150K'
        WHEN estimated_home_value < 300000 THEN '$150K-$300K'
        WHEN estimated_home_value < 500000 THEN '$300K-$500K'
        WHEN estimated_home_value < 750000 THEN '$500K-$750K'
        WHEN estimated_home_value >= 750000 THEN '$750K+'
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
| `awarded_30d` | BOOLEAN | Listing agreement signed within 30 days |
| `rejected` | BOOLEAN | Lead was rejected |
| `is_fake_or_fraud` | BOOLEAN | Flagged as fake/fraudulent |

**Downstream Quality Metrics**:
```sql
-- UCA 14d (Unconfirmed Award within 14 days)
COUNT(DISTINCT CASE 
    WHEN DATEDIFF('day', d.created_date, d.matchdate) <= 14 
    THEN d.request_id 
END) AS uca_14d

-- Awarded 30d
COUNT(DISTINCT CASE WHEN d.awarded_30d = TRUE THEN d.request_id END) AS awarded_30d
```

---

## rdc_analytics.ons.sell_lead_quality

Lead quality scoring. **IMPORTANT: Only contains scores for sell leads. Buy leads will not have records in this table.**

**Grain**: request_id + transaction_type

| Field | Type | Description |
|-------|------|-------------|
| `request_id` | STRING | Unique lead identifier |
| `transaction_type` | STRING | Always 'sell' (buy leads not scored) |
| `quality_level` | STRING | Quality tier ('GQ' or 'LQ') |

**Quality Level Values**:
- `'GQ'` - Good Quality
- `'LQ'` - Low Quality

**V0 Qualification Criteria (for GQ):**
- Property is residential (not land)
- Property is not a mobile home  
- Estimated home value ≥ $150K
- Lead submitter matches property in CoreLogic data (deed or mortgage records)
- Lead passes S4 validation checks (email, phone, spam filtering)

**Performance Impact:**
- GQ leads: ~147% of baseline 180-day sold rate
- LQ leads: ~75% of baseline 180-day sold rate

**Usage Notes:**
- When joining, buy leads will have NULL quality_level
- Filter to `transaction_type = 'sell'` for accurate GQ rate calculations
- This is the QLC (Qualified Lead Conversion) signal used for paid media optimization

```sql
-- Correct GQ rate calculation (sell leads only)
SELECT
    COUNT(DISTINCT CASE WHEN q.quality_level = 'GQ' THEN a.request_id END) AS gq_leads,
    COUNT(DISTINCT a.request_id) AS total_sell_leads,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN q.quality_level = 'GQ' THEN a.request_id END) 
          / NULLIF(COUNT(DISTINCT a.request_id), 0), 1) AS gq_rate
FROM rdc_marketing.seller.sell_attribution AS a
LEFT JOIN rdc_analytics.ons.sell_lead_quality AS q 
    ON a.request_id = q.request_id 
    AND a.transaction_type = q.transaction_type
WHERE a.transaction_type = 'sell';  -- Must filter to sell for GQ analysis
```

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

**Note**: Only contains records for paid search leads. Other channels (Facebook, display) use EFR v1 only.

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
                         │        ├──LEFT JOIN──► seller_lead_efr_paid_search (paid search only)
                         │        │
                         │        ├──LEFT JOIN──► sell_lead_quality (sell leads only)
                         │        │
                         │        └──LEFT JOIN──► sell_downfunnel
```

## Join Key Reference

| From Table | To Table | Join Keys | Notes |
|------------|----------|-----------|-------|
| sell_spend | leads_subquery | `campaign = campaign_id` AND `adgroup_id = adgroup_id` AND `calendar_date = lead_date` | Use COALESCE for adgroup nulls |
| sell_attribution | sell_revenue_est | `request_id` AND `transaction_type` | |
| sell_attribution | seller_lead_efr_paid_search | `request_id` AND `transaction_type` | Paid search leads only |
| sell_attribution | sell_lead_quality | `request_id` AND `transaction_type` | Sell leads only (buy = NULL) |
| sell_attribution | sell_downfunnel | `request_id` AND `transaction_type` | |

## Field Naming Conventions

| sell_spend | sell_attribution | Notes |
|------------|------------------|-------|
| `calendar_date` | `lead_date` | Same meaning, different names |
| `campaign` | `campaign_id` | ID field naming varies |
| `adgroup_id` | `adgroup_id` | Same name |

## Quality Metrics by Lead Type

| Metric | Buy Leads | Sell Leads |
|--------|-----------|------------|
| GQ/LQ Score | ❌ Not available | ✅ Available |
| UCA 14d | ✅ Available | ✅ Available |
| Awarded 30d | ✅ Available | ✅ Available |
| Actualized Revenue | ✅ Available | ✅ Available |
| EFR v2 (paid search) | ✅ Available | ✅ Available |
