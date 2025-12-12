# sell_spend View - Annotated Definition

## Overview

The `sell_spend` view aggregates marketing spend across multiple advertising platforms for seller-focused campaigns. It joins campaign taxonomy to raw platform data and normalizes output fields.

**Location**: `rdc_marketing.seller.sell_spend`  
**Grain**: date + channel + partner + campaign + adgroup  
**Refresh**: Daily

## Source Tables

| Table | Schema | Purpose |
|-------|--------|---------|
| `taxonomy_hist` | `rdc_marketing.team_digital_marketing` | Campaign classification and targeting metadata |
| `ad_group` | `fivetran_martech.raw_google` | Google Ads ad group performance |
| `campaign` | `fivetran_martech.raw_google_campaign` | Google PMAX campaign performance |
| `ad_group_impression_performance_daily_report` | `fivetran_martech.raw_bing` | Bing Ads performance |
| `facebook_all` | `fivetran_martech.raw_facebook` | Meta/Facebook spend |
| `adobe_all` | `rdc_marketing.agg_adobe` | Adobe DSP programmatic |
| `test_gcm_360` | `fivetran_martech.gcm_360` | NewsCorp/GCM display |

## Taxonomy CTE

The taxonomy CTE filters and enriches campaign metadata for seller campaigns:

```sql
SELECT
  partner, channel, account_id, campaign_id, tactic, media_type,
  -- Marketing brand classification
  CASE WHEN account_id IN ('4680216157', '2783507') THEN 'UPNEST'
       ELSE 'REALTOR_COM' END AS marketing_brand,
  -- Seller product classification  
  CASE WHEN account_id IN ('1306500412', '40641080') OR target_customer = 'b2b' THEN 'LTK'
       WHEN account_id IN ('4680216157', '2783507', '2160430690', '149500636', '7422312111172492') 
            THEN 'RealChoice Selling'
       ELSE 'Seller - General' END AS seller_product,
  target_customer, target_platform, target_audience
FROM rdc_marketing.team_digital_marketing.taxonomy_hist
WHERE target_vertical = 'sell' OR account_id IN ('1306500412')
```

### Key Account IDs

| Account ID | Platform | Classification |
|------------|----------|----------------|
| 4680216157 | Google | UPNEST brand |
| 2783507 | Bing | UPNEST brand |
| 1306500412 | Google | LTK (b2b) |
| 40641080 | Facebook | LTK (b2b) |
| 2160430690 | Google | RealChoice Selling |
| 149500636 | Bing | RealChoice Selling |
| 7422312111172492 | Facebook | RealChoice Selling |

## Platform-Specific Logic

### Google Ads (google_spend CTE)

Joins `raw_google.ad_group` to taxonomy and campaign/adgroup history:

```sql
-- Special handling for demand_gen campaigns
CASE WHEN target_customer = 'b2b' AND LOWER(campaign_name) LIKE '%demand_gen%'
     THEN 'display_social_advertising'
     ELSE taxonomy.channel END AS channel
```

**Exclusions**: B2B campaigns unless they're LTK campaigns in account 1306500412

### PMAX (pmax_spend CTE)

Performance Max campaigns from `raw_google_campaign.campaign`:
- Identified by: `name ILIKE '%pmax%'`
- Sets `adgroup_id = 'PMAX'` and `adgroup_name = 'PMAX'` (no ad group granularity)

### Bing Ads (bing_spend CTE)

From `raw_bing.ad_group_impression_performance_daily_report`:
- Joined to campaign/adgroup history for names
- Limited to accounts: 2783507, 149500636

### Facebook/Meta (facebook_spend CTE)

From `raw_facebook.facebook_all`:
- Account 7422312111172492: All campaigns
- Account 40641080: Only LTK campaigns (`campaign_name ILIKE '%ltk%'`)
- Uses COALESCE for taxonomy fields (some campaigns may not be in taxonomy)

### Adobe DSP (adobe_spend CTE)

From `rdc_marketing.agg_adobe.adobe_all`:

Channel classification from naming conventions:
```sql
CASE 
  WHEN campaign/package/placement/ad_name LIKE '%_TVE_%' THEN 'programmatic-tve'
  WHEN ... LIKE '%_CTV_%' THEN 'programmatic-ctv'
  WHEN ... LIKE '%_OLV_%' THEN 'programmatic-olv'
  ELSE 'programmatic-display'
END AS channel
```

### NewsCorp (newscorp_spend CTE)

From `fivetran_martech.gcm_360.test_gcm_360`:
- Hardcoded campaign_ids: 30249495, 30249465, 30249483, 29270761, 29270758, 29347715
- Filtered to `LOWER(creative) ILIKE '%seller%'`
- Fixed values: channel = 'display/social ads', partner = 'newscorp', target_customer = 'b2c'

## Output Schema

| Field | Type | Description |
|-------|------|-------------|
| `calendar_date` | DATE | Performance date |
| `channel` | STRING | Marketing channel |
| `partner` | STRING | Ad platform (google, bing, facebook, adobe, newscorp) |
| `target_customer` | STRING | 'b2c' or 'b2b' |
| `account_id` | STRING | Platform account ID |
| `marketing_brand` | STRING | 'UPNEST' or 'REALTOR_COM' |
| `seller_product` | STRING | 'LTK', 'RealChoice Selling', or 'Seller - General' |
| `campaign` | STRING | Campaign ID |
| `campaign_name` | STRING | Campaign name |
| `adgroup_id` | STRING | Ad group ID (or 'PMAX') |
| `adgroup_name` | STRING | Ad group name |
| `impressions` | INT | Total impressions |
| `clicks` | INT | Total clicks |
| `spend` | FLOAT | Total spend (USD) |

## Common Filters

```sql
-- Standard B2C paid search filter
WHERE channel = 'paid search'
  AND target_customer = 'b2c'
  AND calendar_date >= DATEADD('day', -30, CURRENT_DATE())

-- UPNEST brand only
WHERE marketing_brand = 'UPNEST'

-- Specific product
WHERE seller_product = 'RealChoice Selling'
```

## Notes

1. **Google cost**: Stored as micros in source, converted to dollars (`cost_micros / 1000000`)
2. **PMAX granularity**: No ad group level data available
3. **Facebook account rounding**: Account IDs may need rounding for joins
4. **Taxonomy gaps**: Some Facebook campaigns use COALESCE for fallback values
