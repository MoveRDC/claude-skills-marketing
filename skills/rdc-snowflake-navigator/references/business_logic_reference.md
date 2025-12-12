# Marketing Analytics Business Logic Reference

This document captures the critical business rules, attribution logic, and calculation methods used across RDC marketing analytics tables.

---

## 1. Incrementality Multipliers (IEFR)

IEFR (Incremental Estimated Future Revenue) applies channel-specific multipliers to account for incrementality - i.e., what portion of attributed revenue would have occurred anyway without the marketing spend.

### SEM (sem_summary)
```sql
IEFR = EFR * multiplier

-- Multiplier logic:
CASE 
  WHEN target_customer = 'b2c' 
   AND target_vertical = 'buy' 
   AND target_platform = 'web'
  THEN 0.70
  ELSE 1.00
END
```

| Condition | Multiplier |
|-----------|------------|
| B2C + Buy + Web | 0.70 |
| All other | 1.00 |

### App Install (app_summary)
```sql
IEFR = snapshot_efr_for_sale * skan_multiplier * incrementality_multiplier
```

| Channel | Platform | Multiplier |
|---------|----------|------------|
| Apple Search Ads | iOS | 0.46 |
| Google | iOS | 0.46 |
| Google | Android | 0.56 |
| Other Media | Any | 0.70 |
| Default | - | 1.00 |

### Paid Social (psocial_summary)
```sql
IEFR = EFR * multiplier
```

**Criteo (Display):**
| Condition | Multiplier |
|-----------|------------|
| B2C + Buy + Web | 0.65 |
| All other | 1.00 |

**Facebook (PSocial):**
| Campaign Pattern | Multiplier |
|-----------------|------------|
| Veterans, Brand campaigns | 0.70 |
| Retargeting, ASC, Florida | 0.55 |
| Prospecting | 1.00 |
| Default | 1.00 |

---

## 2. Lead Attribution Logic

### SEM Attribution
Leads are attributed via `last_touch_marketing_channel_detail` parsing:

**Tracking Code Patterns:**
- Pre-Oct 2021: `sem_google_<keyword>` or `sem_bing_<keyword>`
- Oct 2021 - Present: `sem_<campaign_id>_<ad_group_id>_<keyword_id>`
- During tracking issues (Oct 2021 - Jan 2022): `sem___<values>`

**Campaign ID Extraction:**
```sql
-- Multiple fallback patterns due to tracking code evolution
CASE
  -- Bing campaigns (check against known Bing campaign list)
  WHEN IS_INTEGER(SPLIT_PART(detail, '_', 4)) 
   AND SPLIT_PART(detail, '_', 3) IN (SELECT campaign_id FROM bing_campaigns)
  THEN SPLIT_PART(detail, '_', 3)
  
  -- Standard pattern: sem_<campaign_id>_<ad_group_id>
  WHEN IS_INTEGER(SPLIT_PART(detail, '_', 3))
  THEN SPLIT_PART(detail, '_', 2)
  
  -- Fallback
  ELSE SPLIT_PART(detail, '_', 2)
END AS campaign_id
```

**Partner Detection:**
```sql
CASE
  WHEN LOWER(last_touch_marketing_channel_detail) LIKE 'sem_google%' THEN 'google'
  WHEN LOWER(last_touch_marketing_channel_detail) LIKE '%bing%' THEN 'bing'
  ELSE NULL
END AS partner
```

**Exclusions (not SEM web):**
- `%android%`, `%ios%` - App campaigns
- `%facebook%` - Social
- `%app install%`, `%appinstall%` - App install
- `%Apple Search Ads%`, `%apple%` - ASA
- `sem_app_%` - App-specific SEM

### App Attribution (AppsFlyer)
Attribution via AppsFlyer SDK with SKAN reconciliation for iOS.

**SKAN (SKAdNetwork) Handling:**
```sql
-- Single Source of Truth installs
ssot_installs = skan_installs_exec_overlap + non_skan_installs

-- SKAN multiplier for iOS
skan_multiplier = CASE
  WHEN ssot_installs IS NULL THEN 1
  WHEN non_skan_installs > 0 
   AND media_source != 'googleadwords_int'
   AND platform = 'ios'
  THEN ssot_installs / non_skan_installs
  ELSE 1
END
```

**is_app Flag:**
```sql
CASE
  WHEN media_source NOT IN ('Facebook Ads', 'googleadwords_int') THEN 1
  WHEN media_source = 'googleadwords_int' 
   AND platform = 'android' 
   AND campaign LIKE 'sem_app%' THEN 1
  WHEN media_source = 'googleadwords_int' 
   AND platform = 'ios' 
   AND campaign LIKE 'sem_%' THEN 1
  WHEN media_source = 'Facebook Ads' 
   AND campaign LIKE '%app%' THEN 1
  ELSE 0
END AS is_app
```

### Paid Social Attribution
**Facebook Ad ID Extraction:**
```sql
-- Extract 13-18 digit ad ID from tracking code
fb_ad_id = CAST(
  REVERSE(
    REGEXP_SUBSTR(
      REVERSE(
        COALESCE(
          REGEXP_SUBSTR(detail, 'cid=([^&]+)', 1, 1, 'e', 1),
          detail
        )
      ),
      '\\d{13,18}'
    )
  ) AS BIGINT
)
```

**Criteo Adset Extraction:**
```sql
-- Pattern: dsp_xxx_xxx_<adset_id>_...
criteo_adset = REGEXP_SUBSTR(detail, '[a-z]{3}_\\d+_\\d+_(\\d+)_', 1, 1, 'e', 1)
```

**Tracking Code Patterns:**
- `psc_%` - Paid social
- `dsp_%` - Display/DSP (Criteo)
- `rmc_%` - RMC campaigns

---

## 3. Taxonomy Dimensions

Campaign taxonomy is managed in `rdc_marketing.team_digital_marketing.taxonomy_hist`.

**Key Dimensions:**
| Field | Values | Description |
|-------|--------|-------------|
| `channel` | paid search, psocial, display | Marketing channel |
| `partner` | google, bing, facebook, criteo | Ad platform |
| `tactic` | performance | Campaign strategy |
| `media_type` | search, performance, mixed | Ad format |
| `target_platform` | web, app | Destination platform |
| `target_customer` | b2c, b2b | Customer segment |
| `target_audience` | varies | Audience targeting |
| `target_vertical` | buy, rent, sell, new_construction | Business line |

**Taxonomy Join Logic:**
```sql
-- SEM: Join on account_id
ON CAST(spend.account_id AS VARCHAR) = CAST(taxonomy.account_id AS VARCHAR)
   AND event_date BETWEEN taxonomy.start_date AND taxonomy.end_date

-- PSocial Facebook: Join on campaign_id
ON CAST(spend.campaign_id AS VARCHAR) = CAST(taxonomy.campaign_id AS VARCHAR)
   AND event_date BETWEEN taxonomy.start_date AND taxonomy.end_date

-- PSocial Criteo: Join on adset_id to ad_group_id
ON CAST(spend.adset_id AS VARCHAR) = CAST(taxonomy.ad_group_id AS VARCHAR)
   AND event_date BETWEEN taxonomy.start_date AND taxonomy.end_date
```

---

## 4. Lead Metrics Definitions

### Lead Verticals
From `marketing_conversion_detail_v2.submitted_lead_vertical`:

| Vertical | Description |
|----------|-------------|
| `for_sale` | Buy-intent leads |
| `for_rent` | Rental leads |
| `Seller` | Sell-intent leads |
| `FAR` | Find a Realtor leads |

### Lead Products
From `submitted_lead_product`:

| Product | Description |
|---------|-------------|
| `for_sale:connections_plus` | C+ agent matched leads |
| `for_sale:advantage_pro` | AdPro leads |
| `for_sale:basic` | Basic (free) leads |
| `for_rent:unknown` | Rental leads (unclassified) |
| `not_for_sale:unknown` | Off-market property leads |

### Sell Lead Definition
```sql
sell_leads = CASE 
  WHEN submitted_lead_vertical = 'Seller' THEN 1
  WHEN DELIVERED_TO_UPNEST_FLAG = 1 THEN 1
  WHEN DELIVERED_TO_SELLER_PARTNER_FLAG = 1 THEN 1
  ELSE 0
END
```

### Rent Monetization
```sql
rent_monetized_leads = CASE WHEN is_rent_monetized_lead_flag = '1' THEN 1 ELSE 0 END
rent_unmonetized_leads = CASE WHEN is_rent_monetized_lead_flag = '0' THEN 1 ELSE 0 END
```

---

## 5. EFR (Estimated Future Revenue) Components

### Revenue Sources
| Field | Description |
|-------|-------------|
| `estimated_future_revenue` | Total EFR |
| `total_buy_estimated_future_revenue` | Buy vertical EFR |
| `total_sell_estimated_future_revenue` | Sell vertical EFR |
| `total_rent_estimated_future_revenue` | Rental EFR |
| `buy_estimated_future_revenue_referral` | Buy referral EFR |
| `sell_estimated_future_revenue_referral` | Sell referral EFR |
| `sell_realchoice_estimated_future_revenue` | RealChoice sell EFR |
| `cplus_contract_revenue` | Connections Plus contract revenue |
| `veterans_revenue` | Veterans United revenue |
| `adpro_revenue` | Advantage Pro revenue |
| `sales_builder_revenue` | New construction sales builder revenue |

### EFR Source Tables
| Component | Source Table |
|-----------|--------------|
| Referral Buy/Sell | `rdc_analytics.revenue.referral_revenue` |
| Connections Plus | `rdc_analytics.revenue.lead_sales_revenue` |
| MVIP | `rdc_analytics.revenue.mvip_revenue` |
| Advantage Pro | Calculated from C+ zip averages |
| Veterans United | Fixed rate schedule (see below) |
| Sales Builder | `rdc_analytics.revenue.nc_sales_builder_revenue` |
| Rentals | `rdc_analytics.revenue.rentals_revenue` |
| UpNest/RealChoice | `rdc_analytics.revenue.realchoice_revenue` |

### Veterans United Rate Schedule
| Date Range | Market Type | Price Range | Value |
|------------|-------------|-------------|-------|
| Pre-March 2022 | Any | Any | $93 |
| Mar 2022 - Mar 2023 | Choice | $75K-$100K | $65 |
| Mar 2022 - Mar 2023 | Choice | $100K-$500K | $100 |
| Mar 2022 - Mar 2023 | Pure | $75K-$500K | $120 |
| Post-March 2023 | Any | $75K-$125K | $25 |
| Post-March 2023 | Any | $125K-$200K | $55 |
| Post-March 2023 | Any | $200K-$500K | $97 |
| Post-March 2023 | Any | $500K-$600K | $105 |
| Post-March 2023 | Any | $600K-$700K | $125 |

**Exclusion:** New York state leads excluded from VU revenue.

### Referral EFR Methodology
Referral EFR uses a **7-day rolling average** of 29-day predicted close revenue, **lagged by 30 days**:
```sql
-- Window: rows 36-30 days before inquiry date
-- This ensures predictions have matured before being used

buy_efr_referral = SUM(buyer_29_day_predicted_close_rev) 
  OVER (ROWS BETWEEN 36 PRECEDING AND 30 PRECEDING)
  / COUNT(leads) OVER (same window)
```

### App EFR (Snapshot vs Cohort)
| Metric Type | Description | Use Case |
|-------------|-------------|----------|
| `snapshot_efr_*` | EFR measured on event date | Daily reporting |
| `cohort_efr_*` | EFR attributed to install date | LTV analysis |

---

## 6. Platform/Channel Classification

### SEM Brand Flag
```sql
brand = CASE
  WHEN campaign_name LIKE '%realtor%' THEN 'yes'
  WHEN campaign_name IS NULL THEN 'unknown'
  ELSE 'no'
END
```

### PSocial Channel Mapping
```sql
channel = CASE
  WHEN partner = 'facebook' THEN 'psocial'
  WHEN partner = 'criteo' THEN 'display'
END
```

### App Media Source Normalization
```sql
media_source = CASE
  WHEN media_source = 'restricted' THEN 'Facebook Ads'
  WHEN LOWER(media_source) LIKE '%pinsight%' THEN 'pinsight_int'
  WHEN LOWER(media_source) LIKE '%af_app_in%' THEN 'af_app_invites'
  WHEN LOWER(media_source) LIKE '%feedmob%' THEN 'feedmob_int'
  ELSE media_source
END
```

---

## 7. Date/Time Conventions

| Table | Date Field | Timezone |
|-------|------------|----------|
| clickstream_detail | `event_date_mst` | Mountain Time |
| marketing_conversion_detail | `event_date` | UTC (date only) |
| sem_summary | `event_date` | UTC |
| app_summary | `date` | UTC |
| psocial_summary | `event_date` | UTC |

### Fiscal Year
```sql
fiscal_year = CASE
  WHEN MONTH(date) > 6 THEN YEAR(date) + 1  -- Jul-Dec = next FY
  ELSE YEAR(date)                            -- Jan-Jun = current FY
END
```

### Week Start (App Summary)
```sql
-- Sunday-based weeks
week_start = CASE
  WHEN DAYOFWEEK(date) = 7 THEN date
  ELSE DATEADD(DAY, -1, DATE_TRUNC('WEEK', date))
END
```

---

## 8. Data Quality Filters

### SEM Exclusions
```sql
WHERE
  channel = 'paid search'
  AND target_customer = 'b2c'
  AND target_platform = 'web'
  -- Excludes B2B, app campaigns
```

### PSocial Exclusions
```sql
WHERE
  COALESCE(lead_ads_flag, 0) = 0  -- Exclude Facebook Lead Ads
  AND event_date <= DATEADD(DAY, -1, CURRENT_DATE)  -- T-1 data
```

### App Exclusions
```sql
WHERE
  date <= DATEADD(DAY, -1, CURRENT_DATE)  -- T-2 for SKAN
  AND date >= '2021-06-01'  -- Data available from this date
```

---

## 9. Historical Data Considerations

### SEM Tracking Code Changes
| Period | Pattern | Notes |
|--------|---------|-------|
| Pre-Oct 2021 | `sem_google_<keyword>` | Partner in code |
| Oct 2021 - Jan 2022 | `sem___<values>` | Tracking issues |
| Jan 2022+ | `sem_<campaign>_<adgroup>_<keyword>` | Campaign ID included |

### App Data Sources
| Period | Source |
|--------|--------|
| Pre-Jun 2021 | `stg_rdc_marketing.app.app_data_before_2021_06_01` |
| Jun 2021+ | `rdc_marketing.agg_appsflyer.*` |

### PSocial Facebook Tracking Fix
In 2024, Facebook tracking broke and only campaign_id was recorded instead of full CID. Special handling via hardcoded campaign_id list in view.

---

## 10. Key Performance Metrics

### Efficiency Metrics
```sql
-- Cost Per Lead
CPL = spend / NULLIF(leads, 0)

-- Return on Ad Spend
ROAS = efr / NULLIF(spend, 0)

-- Incremental ROAS
iROAS = iefr / NULLIF(spend, 0)

-- Cost Per Install (App)
CPI = spend / NULLIF(ssot_installs, 0)
```

### Lead Quality Indicators
```sql
-- Median lead listing price (indicates market tier)
median_lead_listing_price

-- Average lead listing price
avg_lead_listing_price

-- Unique Lead Submitters
uls = COUNT(DISTINCT adjusted_uu_id)
```
