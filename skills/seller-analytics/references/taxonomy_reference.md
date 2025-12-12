# taxonomy_hist Table Reference

## Overview

The `taxonomy_hist` table is the central campaign classification and metadata repository for all digital marketing campaigns. It provides standardized dimensions for joining raw platform data to business classifications.

**Location**: `rdc_marketing.team_digital_marketing.taxonomy_hist`  
**Maintained by**: Digital Marketing team  
**Update frequency**: Manual updates via taxonomy updater tool  
**Related skill**: [taxonomy-updater](https://github.com/MoveRDC/claude-skills-marketing/tree/main/skills/taxonomy-updater) - for generating new taxonomy entries

## Purpose

- Maps platform account/campaign IDs to business dimensions
- Enables cross-platform analysis with consistent classification
- Provides targeting metadata (vertical, customer segment, audience)
- Resolves mixed-vertical accounts to proper budget attribution

## Schema

| Field | Type | Description | Allowed Values |
|-------|------|-------------|----------------|
| `partner` | STRING | Ad platform | google, bing, facebook, adobe, apple, tiktok, criteo, reddit, linkedin, snapchat, nextdoor, taboola, x, and others |
| `channel` | STRING | Marketing channel | paid search, display/social ads, digital brand, misc sources, trade_publications, news_corp, direct_mail |
| `account_id` | STRING | Platform account ID | - |
| `campaign_id` | STRING | Platform campaign ID | - |
| `tactic` | STRING | Marketing tactic | performance, brand, brand_partnership |
| `media_type` | STRING | Media format | search, mixed, video, display_video, display_static, display_banner, preload, olv_video, streaming_video, and others |
| `target_vertical` | STRING | Business vertical | buy, sell, rent, mortgage, new_construction, mixed |
| `target_customer` | STRING | Customer segment | b2c, b2b |
| `target_platform` | STRING | Target platform/device | web, app |
| `target_audience` | STRING | Audience targeting | new, existing, both |
| `budget_name` | STRING | Budget category | sem, seller, rentals, brand_digital, social, mobile, retargeting_display, and others |
| `budget_id` | STRING | Budget code | 721000 (sem), 245 (seller), 210 (rentals), 750001 (brand_digital), etc. |
| `start_date` | DATE | Campaign start date | - |
| `end_date` | DATE | Campaign end date (NULL if active) | - |
| `mapping_id` | STRING | Unique mapping key | Format: `_{account_id}_{campaign_id}_` |

## Key Account Classifications

### Seller Vertical Accounts

| Account ID | Partner | Brand | Product |
|------------|---------|-------|---------|
| 4680216157 | Google | UPNEST | RealChoice Selling |
| 2783507 | Bing | UPNEST | RealChoice Selling |
| 1306500412 | Google | REALTOR_COM | LTK (B2B) |
| 40641080 | Facebook | REALTOR_COM | LTK (B2B) |
| 2160430690 | Google | REALTOR_COM | RealChoice Selling |
| 149500636 | Bing | REALTOR_COM | RealChoice Selling |
| 7422312111172492 | Facebook | REALTOR_COM | RealChoice Selling |

### Derived Fields in Views

Views often derive additional classifications from taxonomy_hist:

```sql
-- Marketing brand classification
CASE WHEN account_id IN ('4680216157', '2783507') 
     THEN 'UPNEST'
     ELSE 'REALTOR_COM' 
END AS marketing_brand

-- Seller product classification  
CASE 
  WHEN account_id IN ('1306500412', '40641080') OR target_customer = 'b2b' 
       THEN 'LTK'
  WHEN account_id IN ('4680216157', '2783507', '2160430690', '149500636', '7422312111172492') 
       THEN 'RealChoice Selling'
  ELSE 'Seller - General' 
END AS seller_product
```

## Filtering Patterns

### Seller Vertical
```sql
WHERE target_vertical = 'sell' 
   OR account_id IN ('1306500412')  -- LTK account (B2B but seller-related)
```

### B2C Only
```sql
WHERE target_customer = 'b2c'
```

### Specific Partner
```sql
WHERE partner = 'google'
```

## Join Patterns

### Join to Google Ads
```sql
FROM fivetran_martech.raw_google.ad_group ag
JOIN taxonomy_hist t
  ON t.partner = 'google'
  AND t.account_id = CAST(ag.customer_id AS VARCHAR)
```

### Join to Facebook
```sql
FROM fivetran_martech.raw_facebook.facebook_all f
LEFT JOIN taxonomy_hist t
  ON t.partner = 'facebook'
  AND t.account_id = CAST(ROUND(f.account_id, 0) AS VARCHAR)
  AND t.campaign_id = CAST(ROUND(f.campaign_id, 0) AS VARCHAR)
```

**Note**: Facebook IDs may need rounding due to precision issues.

### Join to Bing
```sql
FROM fivetran_martech.raw_bing.ad_group_impression_performance_daily_report b
JOIN taxonomy_hist t
  ON t.partner = 'bing'
  AND t.account_id = CAST(b.account_id AS VARCHAR)
```

## Channel Values

Common `channel` values:
- `'paid search'` - SEM campaigns
- `'display/social ads'` - Display and social campaigns
- `'display_social_advertising'` - Alternate naming
- `'programmatic-display'` - Programmatic display
- `'programmatic-ctv'` - Connected TV
- `'programmatic-olv'` - Online video
- `'programmatic-tve'` - TV Everywhere

## Usage Notes

1. **Not all campaigns are in taxonomy**: Some views use COALESCE for fallback values
2. **Account ID as string**: Always cast numeric IDs to VARCHAR for joins
3. **Campaign-level joins**: Some platforms require campaign_id in addition to account_id
4. **Historical data**: Table contains historical records; filter by date if needed
5. **Seller filter special case**: LTK account 1306500412 is B2B but included in seller analysis

## Related Views

Views that consume taxonomy_hist:
- `rdc_marketing.seller.sell_spend` - Seller campaign spend
- `rdc_marketing.agg_reporting.sem_summary` - SEM aggregations
- `rdc_marketing.agg_reporting.psocial_summary` - Paid social aggregations

## Mixed-Vertical Account Detection

Some accounts contain campaigns across multiple verticals. Use this query to detect:

```sql
SELECT 
    CASE 
        WHEN LOWER(NAME) LIKE '%_buy_%' OR LOWER(NAME) LIKE '%for sale%' THEN 'buy'
        WHEN LOWER(NAME) LIKE '%rental%' THEN 'rent'
        WHEN LOWER(NAME) LIKE '%newcon%' THEN 'new_construction'
        WHEN LOWER(NAME) LIKE '%sell%' THEN 'sell'
        ELSE 'unknown'
    END as inferred_vertical,
    COUNT(DISTINCT ID) as campaign_count
FROM fivetran_martech.raw_google_campaign.campaign
WHERE CUSTOMER_ID = <account_id>
  AND DATE >= DATEADD(month, -3, CURRENT_DATE)
GROUP BY 1;
```

If multiple verticals exist, campaign-level taxonomy entries are required.

## Common Budget Mappings

| budget_name | budget_id | Use for |
|-------------|-----------|---------|
| sem | 721000 | Paid search campaigns |
| seller | 245 | Seller vertical campaigns |
| rentals | 210 | Rentals vertical campaigns |
| brand_digital | 750001 | Brand awareness campaigns |
| retargeting_display | 720001 | Retargeting campaigns |
| social | 761100 | Social media campaigns |
| mobile | 722000 | Mobile app campaigns |

## Media Type Selection Guide

| Campaign Type | media_type |
|---------------|------------|
| PMax campaigns | mixed |
| Search/DSA campaigns | search |
| Display (static) | display_static |
| Display (video) | display_video |
| Video campaigns | video |
| App preload | preload |

## Maintenance

The taxonomy_hist table is updated via:
1. Manual entries by Digital Marketing team
2. Taxonomy updater tool (for bulk CSV updates)

New campaigns should be added when:
- Launching new ad accounts
- Creating campaigns in new verticals
- Adding new targeting dimensions
- Account has mixed verticals requiring campaign-level attribution
