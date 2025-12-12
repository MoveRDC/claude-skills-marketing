# sell_revenue_est View - Annotated Definition

## Overview

The `sell_revenue_est` view calculates Expected Future Revenue (EFR) for UpNest leads based on estimated home values, historical conversion rates, and geographic model data.

**Location**: `rdc_marketing.seller.sell_revenue_est`  
**Grain**: request_id + transaction_type  
**Refresh**: Daily

## Source Tables

| Table | Schema | Purpose |
|-------|--------|---------|
| `qrequest` | `fivetran_martech.upnest_maria_realtor` | Sell request lead data |
| `brequest` | `fivetran_martech.upnest_maria_realtor` | Buy request lead data |
| `property` | `fivetran_martech.upnest_maria_realtor` | Property zip codes |
| `zipcode` | `fivetran_martech.upnest_maria_realtor` | City/state avg listing prices |
| `gtmrevenuetracker` | `fivetran_martech.upnest_maria_realtor` | Manual GTM revenue overrides |
| `historical_home_value_ratio` | `rdc_analytics.revenue` | Sell-side HV→revenue model |
| `buy_historical_home_value_ratio` | `rdc_analytics.revenue` | Buy-side HV→revenue model |

## EFR Calculation Overview

```
EFR = Estimated Home Value × Home Value Rate (hv_rate)
```

Where:
- **Estimated Home Value**: Best available property value estimate
- **Home Value Rate**: Historical conversion rate from home value to revenue (varies by geography and agent availability)

## Sell Lead EFR Calculation

### Step 1: Estimated Home Value

Priority cascade for sell leads:

```sql
CASE 
  WHEN recentprice > 0 THEN recentprice
  WHEN zestimate > 0 THEN zestimate
  WHEN highrange > 0 AND lowrange > 0 THEN (highrange + lowrange) / 2
  WHEN lowrange = 0 OR lowrange IS NULL THEN highrange / 2
  WHEN highrange = 0 OR highrange IS NULL THEN lowrange
END AS estimated_home_value
```

**Data quality correction**: Values > $5M are divided by 10 (suspected data entry errors):
```sql
CASE WHEN estimated_home_value > 5000000 
     THEN estimated_home_value / 10 
     ELSE estimated_home_value END
```

### Step 2: Snapshot Date Selection

Model data is snapshotted bi-monthly (1st and 15th). Lead is matched to appropriate snapshot:

```sql
CASE 
  WHEN lead_date >= max_snapshot_date THEN max_snapshot_date
  WHEN DAY(created_on) < 15 THEN DATE_FROM_PARTS(YEAR, MONTH, 1)
  ELSE DATE_FROM_PARTS(YEAR, MONTH, 15)
END AS snapshot_date
```

### Step 3: Home Value Rate (hv_rate)

Rate varies based on agent availability at lead creation:

```sql
CASE 
  WHEN green_agents_at_create_time = 0 
       THEN zest_to_sold_revenue_w_0_green_agents
  ELSE zest_to_sold_revenue_w_green_agents
END AS hv_rate
```

**Rationale**: Leads with no available agents at creation have lower expected conversion.

### Step 4: EFR Calculation

```sql
expectedrev = estimated_home_value × hv_rate
```

## Buy Lead EFR Calculation

### Step 1: Estimated Home Value

```sql
avg_range = COALESCE(
  (lowrange + highrange) / 2,
  city_avg_listing_price,
  national_avg_listing_price
)
```

Falls back through geographic averages if lead doesn't provide price range.

### Step 2: Home Value Rate

Uses buy-specific model tables with city/state rollups:
```sql
-- Try city-level first
LEFT JOIN buy_city_hist_value_ratio ON city + state + processing_date
-- Fall back to state-level
LEFT JOIN buy_state_hist_value_ratio ON state + processing_date
```

### Step 3: Agent Availability Adjustment

```sql
CASE 
  WHEN green_agents_at_create_time IS NULL 
       THEN revenue_percent_no_agents
  ELSE revenue_percent
END AS hv_rate
```

## Actualized Revenue

For closed transactions, actual revenue is calculated:

### Sell Actualized
```sql
soldprice × commission × referralfee AS actualizedrev
```

Only calculated when:
- `soldflipdate` is not null
- `status = 10`
- `solddate < GETDATE() - 1`

### Buy Actualized
```sql
COALESCE(collectedamount, soldprice × commission × referralfee) AS actualizedrev
```

### Commission/Referral Normalization

Raw data may be stored as percentages or basis points. Normalized to decimals:

```sql
-- Commission: cap at 3.5%, convert to decimal
commission = CASE 
  WHEN finalcomm > 3.5 THEN 0.03 
  WHEN finalcomm IS NULL THEN 0 
  ELSE finalcomm / 100 
END

-- Referral fee: cap at 30%, convert to decimal
referralfee = CASE 
  WHEN referralfee > 30 THEN 0.30 
  WHEN referralfee IS NULL THEN 0 
  ELSE referralfee / 100 
END
```

## GTM Override

The `gtmrevenuetracker` table can override calculated values with manual entries:

```sql
COALESCE(g.prop_val_estimate, estimated_home_value) AS estimated_home_value
COALESCE(g.multiplier, hv_rate) AS hv_rate
COALESCE(g.gtm_expected_revenue, expectedrev) AS expectedrev
```

**Use case**: Manual revenue tracking for special deals or corrections.

## Lead Exclusions

Standard filters applied to both sell and buy leads:

```sql
WHERE sample = FALSE                    -- Exclude test leads
  AND status NOT IN (0, 5)              -- Exclude drafts and duplicates
  AND _fivetran_deleted = FALSE         -- Exclude deleted records
  AND assignedAdmin <> 1466             -- Exclude fake/fraud admin
```

## Output Schema

| Field | Type | Description |
|-------|------|-------------|
| `lead_created_date` | DATE | Lead creation date |
| `request_id` | STRING | Unique lead identifier |
| `transaction_type` | STRING | 'buy' or 'sell' |
| `estimated_home_value` | FLOAT | Best estimate of property value |
| `hv_rate` | FLOAT | Home value to revenue conversion rate |
| `rep_efr` | FLOAT | EFR v1 (calculated expected revenue) |
| `expectedrev` | FLOAT | Expected revenue (may include GTM override) |
| `actualizedrev` | FLOAT | Actual collected/closed revenue |

## EFR v1 vs v2

This view produces **EFR v1** (`rep_efr`). For paid search leads, prefer **EFR v2** from `seller_lead_efr_paid_search`:

```sql
COALESCE(v2.rep_efr_v2, v1.rep_efr) AS efr
```

## Model Tables

### historical_home_value_ratio (Sell)

| Field | Description |
|-------|-------------|
| `processing_date` | Model snapshot date (1st/15th) |
| `zip` | ZIP code |
| `zest_to_sold_revenue_w_green_agents` | Rate with available agents |
| `zest_to_sold_revenue_w_0_green_agents` | Rate with no agents |

### buy_historical_home_value_ratio (Buy)

| Field | Description |
|-------|-------------|
| `processing_date` | Model snapshot date |
| `city`, `state` | Geography |
| `revenue_percent` | Rate with agents |
| `revenue_percent_no_agents` | Rate without agents |
| `ga_closerate` | Close rate with agents |
| `zero_ga_closerate` | Close rate without agents |
| `avg_commission_rate` | Average commission |

## Example Queries

### EFR Distribution by Transaction Type
```sql
SELECT 
  transaction_type,
  COUNT(*) AS leads,
  AVG(rep_efr) AS avg_efr,
  MEDIAN(rep_efr) AS median_efr,
  SUM(rep_efr) AS total_efr
FROM rdc_marketing.seller.sell_revenue_est
WHERE lead_created_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1;
```

### Actualized vs Expected Comparison
```sql
SELECT 
  DATE_TRUNC('month', lead_created_date) AS month,
  SUM(rep_efr) AS expected,
  SUM(actualizedrev) AS actualized,
  ROUND(100.0 * SUM(actualizedrev) / NULLIF(SUM(rep_efr), 0), 1) AS realization_rate
FROM rdc_marketing.seller.sell_revenue_est
WHERE lead_created_date >= DATEADD('month', -12, CURRENT_DATE())
  AND actualizedrev > 0
GROUP BY 1
ORDER BY 1;
```
