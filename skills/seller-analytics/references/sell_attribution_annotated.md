# sell_attribution View - Annotated Definition

## Overview

The `sell_attribution` view maps UpNest leads to their attributed marketing campaigns by parsing tracking codes from landing URLs and Google tracking fields.

**Location**: `rdc_marketing.seller.sell_attribution`  
**Grain**: request_id + transaction_type  
**Refresh**: Daily

## Source Tables

| Table | Schema | Purpose |
|-------|--------|---------|
| `qrequest` | `fivetran_martech.upnest_maria_realtor` | Sell request leads |
| `brequest` | `fivetran_martech.upnest_maria_realtor` | Buy request leads |
| `taxonomy_hist` | `rdc_marketing.team_digital_marketing` | PMAX campaign detection |
| `campaign` | `fivetran_martech.raw_google_campaign` | PMAX campaign names |

## Attribution Logic

### Primary Method: CID Parsing

The view extracts campaign attribution from the `cid` parameter in landing URLs:

```sql
-- Extract cid from landing_url query string
SELECT 
  REPLACE(lu_cid.value, 'cid=', '') AS cid,
  -- Parse underscore-delimited components
  SPLIT(cid, '_')[0] AS channel_prefix,
  SPLIT(cid, '_')[1] AS account_id,
  SPLIT(cid, '_')[2] AS campaign_id,
  SPLIT(cid, '_')[3] AS adgroup_id,
  SPLIT(cid, '_')[4] AS ad_id
FROM request, LATERAL FLATTEN(input => SPLIT(landing_url_params, '&')) AS lu_cid
WHERE lu_cid.value LIKE 'cid=%'
```

### CID Format

Standard format: `{channel_prefix}_{account_id}_{campaign_id}_{adgroup_id}_{ad_id}`

Example: `fb_7422312111172492_123456_789012_345678`

### SEM Special Handling

For SEM campaigns (channel_prefix = 'sem'), field positions shift left:

| Position | Standard Channels | SEM Channels |
|----------|-------------------|--------------|
| [1] | account_id | campaign_id |
| [2] | campaign_id | adgroup_id |
| [3] | adgroup_id | ad_id |
| [4] | ad_id | (unused) |

```sql
CASE WHEN channel_prefix = 'sem' THEN NULL ELSE account_id END AS account_id,
CASE WHEN channel_prefix = 'sem' THEN account_id ELSE campaign_id END AS campaign_id,
CASE WHEN channel_prefix = 'sem' THEN campaign_id ELSE adgroup_id END AS adgroup_id,
CASE WHEN channel_prefix = 'sem' THEN adgroup_id ELSE ad_id END AS ad_id
```

**Rationale**: SEM tracking codes don't include account_id since it's implied.

### Fallback Method: Google Tracking Field

If CID is missing, the view parses the `googletracking` field for campaign/adgroup tags:

```sql
-- Extract [campaign] tag
SELECT REPLACE(TRIM(gt_campaign.Value), '[campaign] ', '') AS campaign
FROM request, LATERAL FLATTEN(input => SPLIT(googletracking, ',')) AS gt_campaign
WHERE TRIM(gt_campaign.Value) LIKE '[campaign]%'

-- Extract [adgroup] tag  
SELECT REPLACE(TRIM(gt_adgroup.Value), '[adgroup] ', '') AS adgroup
FROM request, LATERAL FLATTEN(input => SPLIT(googletracking, ',')) AS gt_adgroup
WHERE TRIM(gt_adgroup.Value) LIKE '[adgroup]%'
```

### PMAX Detection

Performance Max campaigns are detected by joining to taxonomy and checking campaign names:

```sql
SELECT CAST(c.id AS VARCHAR) AS campaign, 'PMAX' AS adgroup_id
FROM taxonomy_hist t
JOIN raw_google_campaign.campaign c
  ON t.account_id = CAST(c.customer_id AS VARCHAR)
  AND c.name ILIKE '%pmax%'
  AND (t.target_vertical = 'sell' OR t.account_id IN ('1306500412'))
```

When a lead's campaign matches the PMAX list, `adgroup_id` is overridden to 'PMAX'.

### Attribution Priority

Final attribution uses COALESCE to prefer CID over Google tracking:

```sql
COALESCE(cid_data.campaign_id, google_tracking.campaign) AS campaign_id,
COALESCE(pmax.adgroup_id, cid_data.adgroup_id, google_tracking.adgroup) AS adgroup_id
```

## Output Schema

| Field | Type | Description |
|-------|------|-------------|
| `request_id` | STRING | Unique lead identifier |
| `lead_date` | DATE | Date lead was created |
| `transaction_type` | STRING | 'buy' or 'sell' |
| `cid` | STRING | Full CID tracking code (if present) |
| `channel_prefix` | STRING | Channel identifier from CID |
| `account_id` | STRING | Platform account ID (NULL for SEM) |
| `campaign_id` | STRING | Attributed campaign ID |
| `adgroup_id` | STRING | Attributed ad group ID (or 'PMAX') |
| `ad_id` | STRING | Attributed ad ID |

## Join Patterns

### Join to sell_spend

```sql
FROM sell_attribution a
JOIN sell_spend s
  ON s.campaign = a.campaign_id
  AND COALESCE(s.adgroup_id, '') = COALESCE(a.adgroup_id, '')
  AND s.calendar_date = a.lead_date
```

**Important**: Use COALESCE for adgroup_id to handle NULLs.

### Join to sell_revenue_est

```sql
FROM sell_attribution a
JOIN sell_revenue_est r
  ON r.request_id = a.request_id
  AND r.transaction_type = a.transaction_type
```

## Known Issues

1. **CID parsing edge cases**: Some legacy CIDs may have different formats or delimiters
2. **Missing attribution**: Leads without CID or googletracking will have NULL campaign attribution
3. **SEM field shift**: Easy to forget when debugging - always check channel_prefix
4. **PMAX override**: PMAX campaigns lose ad group granularity by design

## Example Queries

### Check attribution coverage
```sql
SELECT 
  DATE_TRUNC('week', lead_date) AS week,
  COUNT(*) AS total_leads,
  COUNT(campaign_id) AS attributed_leads,
  ROUND(100.0 * COUNT(campaign_id) / COUNT(*), 1) AS attribution_rate
FROM rdc_marketing.seller.sell_attribution
WHERE lead_date >= DATEADD('day', -90, CURRENT_DATE())
GROUP BY 1
ORDER BY 1 DESC;
```

### Debug CID parsing
```sql
SELECT 
  request_id,
  cid,
  channel_prefix,
  account_id,
  campaign_id,
  adgroup_id
FROM rdc_marketing.seller.sell_attribution
WHERE lead_date = CURRENT_DATE() - 1
  AND cid IS NOT NULL
LIMIT 100;
```
