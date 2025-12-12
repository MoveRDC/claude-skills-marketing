# Snowflake Core Tables Reference

Comprehensive documentation for key analytics tables used in RDC marketing and consumer analytics.

## Table Overview

| Table | Database.Schema | Grain | Purpose | ~Daily Volume |
|-------|-----------------|-------|---------|---------------|
| `clickstream_detail` | RDC_ANALYTICS.CLICKSTREAM | Event (hit) | All user interactions on site/app | ~200M rows |
| `marketing_conversion_detail` | RDC_ANALYTICS.REVENUE | Lead | Lead-level conversion data with revenue | ~50K rows |
| `sem_summary` | RDC_MARKETING.AGG_REPORTING | Campaign × Day | Google/Bing SEM campaign metrics | ~300 rows |
| `app_summary` | RDC_MARKETING.AGG_REPORTING | Campaign × Day | Mobile app install campaigns | ~130 rows |
| `psocial_summary` | RDC_MARKETING.AGG_REPORTING | Ad Set × Day | Paid social (Meta, TikTok) metrics | ~200 rows |

---

## 1. CLICKSTREAM_DETAIL

**Location:** `RDC_ANALYTICS.CLICKSTREAM.CLICKSTREAM_DETAIL`

**Purpose:** Event-level tracking of all user interactions across web, mobile web, and native apps. This is the foundational user behavior table.

**Grain:** One row per hit/event (pageview or click action)

**Key Identity Fields:**
| Column | Description |
|--------|-------------|
| `ADJUSTED_UU_ID` | Normalized unique user identifier (primary user key) |
| `RDC_VISITOR_ID` | Web visitor ID |
| `CLIENT_MAPI_VISITOR_ID` | Mobile API visitor ID |
| `VISIT_ID` | Session identifier |
| `MESSAGE_ID` | Unique event identifier (primary key) |
| `MEMBER_ID` | Logged-in user identifier (when available) |
| `GOOGLE_CLICK_ID` | GCLID for paid search attribution |

**Critical Date/Time Fields:**
| Column | Description |
|--------|-------------|
| `EVENT_DATE_MST` | Event date in Mountain Time (use this for daily aggregations) |
| `DATETIME_MST` | Full timestamp in Mountain Time |
| `BATCH_DATETIME` | Data loading timestamp (for incremental queries) |

**Platform & Device Fields:**
| Column | Values | Description |
|--------|--------|-------------|
| `EXPERIENCE_TYPE` | `web`, `mobile web`, `mobile apps`, `others` | High-level platform |
| `PLATFORM` | `desktop`, `mobile_web`, `ios`, `android`, `unknown` | Specific platform |
| `DEVICE_TYPE` | `desktop`, `mobile_phone`, `tablet`, `other` | Device category |
| `SITE_SECTION` | `core-ios`, `core-android`, `homes`, etc. | App or site area |

**Product Vertical Fields (CRITICAL for business segmentation):**
| Column | Values | Description |
|--------|--------|-------------|
| `PRODUCT_VERTICAL` | `for_sale`, `for_rent`, `not_for_sale_ldp`, `owner_seller`, `sub_finance`, `realtorpage` | Primary business line |
| `PRODUCT_SUB_VERTICAL` | `offmarket_not_for_sale_ldp`, `recentlysold_not_for_sale_ldp`, `sellermarketplace`, `myhome`, etc. | Detailed segment |
| `PRODUCT_TYPE_VERTICAL` | `home`, `srp`, `ldp`, `myaccount`, `others` | Page category |

**Page & Navigation Fields:**
| Column | Description |
|--------|-------------|
| `PAGE_TYPE` | Specific page type (ldp, srp_list, srp_map, home, etc.) |
| `PAGE_TYPE_GROUP` | Grouped page category |
| `PAGE_NAME_OR_URL` | Page identifier string |
| `CLICK_FROM_PAGE_NAME` | Previous page (for funnel analysis) |
| `CURRENT_PAGE_URL` | Full URL |

**Marketing Attribution Fields:**
| Column | Description |
|--------|-------------|
| `LAST_TOUCH_MARKETING_CHANNEL` | Channel attribution (Paid Search, Organic Search, Direct, etc.) |
| `KPI_CHANNEL_VIEW` | Simplified channel grouping (direct, total paid, organic search, email, etc.) |
| `PAID_VS_ORGANIC` | Binary: `paid`, `organic`, `others`, `unknown` |
| `CID` | Campaign ID from URL parameter |

**Lead & Conversion Fields:**
| Column | Description |
|--------|-------------|
| `EVENT_NAME` | Event type (search, saveditem, signup, notforsalelead, etc.) |
| `ACTION_EVENT` | Derived action (saved listing, saved search, share, registered, etc.) |
| `INQUIRY_LEAD_ID` | Lead GUID when lead is submitted |
| `LEAD_PLACEMENT` | Where on page the lead form appeared |
| `NOT_FOR_SALE_LEADS` | 'y'/'n' flag for NFS leads |

**Search & Filter Fields:**
| Column | Description |
|--------|-------------|
| `SEARCH_BOX` | Search box type used |
| `SEARCH_FILTER_ONE` | Applied filters (semicolon-separated) |
| `N_FILTERS` | Count of filters applied |
| `SEARCH_MIN_PRICE`, `SEARCH_MAX_PRICE` | Price range filters |
| `SEARCH_NUMBER_OF_BEDROOMS`, `SEARCH_NUMBER_OF_BATHROOMS` | Bed/bath filters |

**Property Context Fields:**
| Column | Description |
|--------|-------------|
| `LISTING_ID` | Property listing identifier |
| `MPR_ID` | MPR property ID |
| `PROPERTY_STATUS_HIT` | Listing status (for_sale, for_rent, etc.) |
| `LISTING_PRICE` | Property price |
| `PROPERTY_TYPE` | Property type (single family, condo, etc.) |

**Geo Fields:**
| Column | Description |
|--------|-------------|
| `ZIP` | Property/search ZIP code |
| `CITY`, `STATE` | Property/search location |
| `CONSUMER_IP_DMA` | User's DMA from IP |
| `CONSUMER_IP_ZIP` | User's ZIP from IP |

**Boolean/Flag Fields:**
| Column | Description |
|--------|-------------|
| `IS_PAGEVIEW` | 1 if pageview, 0 if click/action |
| `IS_NEW_CONSTRUCTION` | 1 if new construction page/property |
| `IS_PURE_MARKET` | 1 if ZIP is in active market |

### Common Query Patterns

**Daily pageviews by platform:**
```sql
SELECT 
    event_date_mst,
    experience_type,
    platform,
    COUNT(*) as total_hits,
    SUM(is_pageview) as pageviews
FROM rdc_analytics.clickstream.clickstream_detail
WHERE event_date_mst >= DATEADD('day', -7, CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY 1, 2;
```

**Product vertical traffic:**
```sql
SELECT 
    event_date_mst,
    product_vertical,
    COUNT(DISTINCT adjusted_uu_id) as unique_users,
    COUNT(DISTINCT visit_id) as sessions,
    SUM(is_pageview) as pageviews
FROM rdc_analytics.clickstream.clickstream_detail
WHERE event_date_mst >= DATEADD('day', -7, CURRENT_DATE())
  AND product_vertical IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
```

**Lead submission funnel:**
```sql
SELECT 
    product_vertical,
    COUNT(DISTINCT CASE WHEN page_type_group = 'srp' THEN visit_id END) as srp_sessions,
    COUNT(DISTINCT CASE WHEN page_type_group = 'ldp' THEN visit_id END) as ldp_sessions,
    COUNT(DISTINCT inquiry_lead_id) as leads_submitted
FROM rdc_analytics.clickstream.clickstream_detail
WHERE event_date_mst >= DATEADD('day', -7, CURRENT_DATE())
  AND product_vertical IN ('for_sale', 'for_rent')
GROUP BY 1;
```

---

## 2. MARKETING_CONVERSION_DETAIL

**Location:** `RDC_ANALYTICS.REVENUE.MARKETING_CONVERSION_DETAIL`

**Purpose:** Lead-level conversion data with revenue attribution. This is the source of truth for lead counts and EFR (Estimated Future Revenue).

**Grain:** One row per submitted lead

**Key Identity Fields:**
| Column | Description |
|--------|-------------|
| `SUBMITTED_LEAD_ID` | Unique lead identifier (primary key) |
| `LEAD_ID` | Numeric lead ID |
| `ADJUSTED_UU_ID` | User identifier (joins to clickstream) |
| `GOOGLE_CLICK_ID` | GCLID for paid attribution |
| `INQUIRY_LEAD_ID` | Alternative lead GUID |

**Date Fields:**
| Column | Description |
|--------|-------------|
| `EVENT_DATE` | Lead submission date |
| `SUBMITTED_DATETIME_MST` | Full timestamp |

**Lead Classification Fields:**
| Column | Values | Description |
|--------|--------|-------------|
| `SUBMITTED_LEAD_VERTICAL` | `for_sale`, `for_rent`, `Seller`, `FAR` | Business vertical |
| `SUBMITTED_LEAD_PRODUCT` | `for_sale:connections_plus`, `for_sale:advantage_pro`, `for_rent:unknown`, etc. | Specific product |
| `LISTING_TYPE` | `for_sale`, `for_rent`, `not_for_sale` | Property listing type |

**Revenue Fields (CRITICAL):**
| Column | Description |
|--------|-------------|
| `ESTIMATED_FUTURE_REVENUE` | Total EFR for this lead |
| `TOTAL_BUY_ESTIMATED_FUTURE_REVENUE` | Buy-side EFR |
| `TOTAL_SELL_ESTIMATED_FUTURE_REVENUE` | Sell-side EFR |
| `TOTAL_RENT_ESTIMATED_FUTURE_REVENUE` | Rental EFR |
| `BUY_ESTIMATED_FUTURE_REVENUE_REFERRAL` | Referral-attributed buy EFR |
| `CPLUS_CONTRACT_REVENUE` | Connections Plus revenue |
| `MVIP_REVENUE` | MVIP revenue |
| `ADPRO_REVENUE` | Advantage Pro revenue |
| `VETERANS_REVENUE` | Veterans United revenue |

**Delivery/Product Flags:**
| Column | Description |
|--------|-------------|
| `DELIVERED_TO_CONNECTIONS_PLUS_FLAG` | Lead sent to C+ |
| `DELIVERED_TO_READYCONNECT_CONCIERGE_FLAG` | Lead sent to RCC |
| `DELIVERED_TO_ADVANTAGE_PRO_FLAG` | Lead sent to AdPro |
| `DELIVERED_TO_VETERANS_UNITED_FLAG` | Lead sent to VU |
| `TOTAL_DELIVERIES` | Count of delivery destinations |

**Attribution Fields:**
| Column | Description |
|--------|-------------|
| `LAST_TOUCH_MARKETING_CHANNEL` | Marketing channel attribution |
| `PLATFORM` | Device platform |
| `CID` | Campaign ID |

**Property/Geo Fields:**
| Column | Description |
|--------|-------------|
| `LISTING_ID` | Property listing ID |
| `LEAD_LISTING_PRICE` | Price at lead submission |
| `DMA_CODE`, `DMA_DESCRIPTION` | Designated Market Area |
| `STATE`, `CITY`, `POSTAL_CODE` | Location |
| `MARKET_TYPE_AT_SUBMISSION` | Pure market vs. non-pure |

### Common Query Patterns

**Daily lead volume and EFR by vertical:**
```sql
SELECT 
    event_date,
    submitted_lead_vertical,
    COUNT(*) as leads,
    SUM(estimated_future_revenue) as total_efr,
    SUM(total_buy_estimated_future_revenue) as buy_efr,
    SUM(total_sell_estimated_future_revenue) as sell_efr,
    SUM(total_rent_estimated_future_revenue) as rent_efr
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1, 2;
```

**Lead distribution by product:**
```sql
SELECT 
    submitted_lead_product,
    COUNT(*) as leads,
    SUM(estimated_future_revenue) as efr,
    AVG(lead_listing_price) as avg_price
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -7, CURRENT_DATE())
GROUP BY 1
ORDER BY 2 DESC;
```

**Channel attribution:**
```sql
SELECT 
    last_touch_marketing_channel,
    platform,
    COUNT(*) as leads,
    SUM(estimated_future_revenue) as efr,
    SUM(estimated_future_revenue) / NULLIF(COUNT(*), 0) as efr_per_lead
FROM rdc_analytics.revenue.marketing_conversion_detail
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 3 DESC;
```

---

## 3. SEM_SUMMARY

**Location:** `RDC_MARKETING.AGG_REPORTING.SEM_SUMMARY`

**Purpose:** Aggregated search engine marketing (Google/Bing) performance with spend, leads, and EFR.

**Grain:** Campaign × Day

**Dimension Fields:**
| Column | Description |
|--------|-------------|
| `EVENT_DATE` | Performance date |
| `BRAND` | Brand identifier |
| `PARTNER` | Ad platform (Google, Bing) |
| `TACTIC` | Campaign tactic (performance) |
| `MEDIA_TYPE` | Ad format (search, performance, mixed) |
| `TARGET_VERTICAL` | Target audience (buy, rent, sell, new_construction) |
| `TARGET_PLATFORM`, `TARGET_CUSTOMER`, `TARGET_AUDIENCE` | Targeting dimensions |
| `ACCOUNT_ID`, `ACCOUNT_NAME` | Ad account |
| `CAMPAIGN_ID`, `CAMPAIGN_NAME` | Campaign identifiers |
| `BUDGET_ID` | Budget allocation ID |

**Spend & Engagement Metrics:**
| Column | Description |
|--------|-------------|
| `SPEND` | Daily spend |
| `IMPRESSIONS` | Ad impressions |
| `CLICKS` | Ad clicks |
| `CONVERSIONS` | Platform-reported conversions |

**Lead Metrics:**
| Column | Description |
|--------|-------------|
| `LEADS` | Total attributed leads |
| `BUY_LEADS` | Buy-intent leads |
| `RENT_LEADS` | Rental leads |
| `SELL_LEADS` | Seller leads |
| `RENT_MONETIZED_LEADS`, `RENT_UNMONETIZED_LEADS` | Rental lead breakdown |
| `SALES_BUILDER_LEADS` | New construction leads |

**Revenue Metrics:**
| Column | Description |
|--------|-------------|
| `EFR` | Total Estimated Future Revenue |
| `TOTAL_BUY_EFR`, `TOTAL_SELL_EFR`, `TOTAL_RENT_EFR` | EFR by vertical |
| `EFR_BUY_LEAD_SALE` | Buy lead sale EFR |
| `EFR_VETERANS`, `EFR_ADPRO`, `EFR_SALES_BUILDER` | Product-specific EFR |
| `IEFR` | Incremental EFR |

**Lead Quality:**
| Column | Description |
|--------|-------------|
| `MEDIAN_LEAD_LISTING_PRICE` | Median property price of leads |
| `AVG_LEAD_LISTING_PRICE` | Average property price of leads |
| `ULS` | User-level score |

### Common Query Patterns

**Campaign performance summary:**
```sql
SELECT 
    campaign_name,
    target_vertical,
    SUM(spend) as total_spend,
    SUM(leads) as total_leads,
    SUM(efr) as total_efr,
    SUM(spend) / NULLIF(SUM(leads), 0) as cpl,
    SUM(efr) / NULLIF(SUM(spend), 0) as roas
FROM rdc_marketing.agg_reporting.sem_summary
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
HAVING SUM(spend) > 1000
ORDER BY total_spend DESC;
```

**Weekly trend:**
```sql
SELECT 
    DATE_TRUNC('week', event_date) as week,
    target_vertical,
    SUM(spend) as spend,
    SUM(leads) as leads,
    SUM(efr) as efr
FROM rdc_marketing.agg_reporting.sem_summary
WHERE event_date >= DATEADD('day', -90, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1, 2;
```

---

## 4. APP_SUMMARY

**Location:** `RDC_MARKETING.AGG_REPORTING.APP_SUMMARY`

**Purpose:** Mobile app install campaign performance across networks (AppsFlyer attribution).

**Grain:** Campaign × Day × Platform

**Dimension Fields:**
| Column | Description |
|--------|-------------|
| `DATE` | Performance date |
| `PLATFORM` | iOS or Android |
| `MEDIA_SOURCE` | Attribution network (Google, Meta, Apple Search, etc.) |
| `CAMPAIGN`, `CAMPAIGN_ID` | Campaign identifiers |
| `EFFORT` | Marketing effort classification |
| `CHANNEL` | Channel classification |
| `IS_APP` | App vs. non-app flag |
| `IS_RENTAL` | Rental app flag |

**Spend & Install Metrics:**
| Column | Description |
|--------|-------------|
| `SPEND` | Daily spend |
| `IMPRESSIONS`, `CLICKS` | Engagement |
| `INSTALLS` | Raw install count |
| `SKAN_INSTALLS_EXEC_OVERLAP` | SKAdNetwork installs |
| `NON_SKAN_INSTALLS` | Non-SKAN installs |
| `SSOT_INSTALLS` | Single Source of Truth installs |
| `SKAN_MULTIPLIER` | SKAN adjustment factor |

**Lead Metrics (Cohort vs Snapshot):**
| Column | Description |
|--------|-------------|
| `SNAPSHOT_LEADS_FOR_SALE`, `SNAPSHOT_LEADS_RENTALS`, `SNAPSHOT_LEADS_SELLER` | Point-in-time leads |
| `COHORT_LEADS_FOR_SALE`, `COHORT_LEADS_RENTAL`, `COHORT_LEADS_SELLER` | Cohort-attributed leads |

**EFR Metrics:**
| Column | Description |
|--------|-------------|
| `SNAPSHOT_EFR_FOR_SALE`, `SNAPSHOT_EFR_RENTAL`, `SNAPSHOT_EFR_SELLER` | Snapshot EFR |
| `COHORT_EFR_FOR_SALE`, `COHORT_EFR_RENTAL`, `COHORT_EFR_SELLER` | Cohort EFR |
| `SNAPSHOT_IEFR_FOR_SALE` | Incremental EFR |

**Legacy Lead Fields:**
| Column | Description |
|--------|-------------|
| `ADVANTAGELEADS`, `COBROKELEADS` | Product-specific leads |
| `FORSALEADVANTAGEPHONELEADS`, `FORSALECOBROKEPHONELEADS` | Phone leads |
| `RENTALBASICLEADS`, `RENTALSHOWCASELEADS` | Rental leads |

### Common Query Patterns

**Media source performance:**
```sql
SELECT 
    media_source,
    platform,
    SUM(spend) as spend,
    SUM(ssot_installs) as installs,
    SUM(cohort_leads_for_sale + cohort_leads_rental) as leads,
    SUM(spend) / NULLIF(SUM(ssot_installs), 0) as cpi,
    SUM(cohort_efr_for_sale + cohort_efr_rental) as efr
FROM rdc_marketing.agg_reporting.app_summary
WHERE date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
HAVING SUM(spend) > 100
ORDER BY spend DESC;
```

---

## 5. PSOCIAL_SUMMARY

**Location:** `RDC_MARKETING.AGG_REPORTING.PSOCIAL_SUMMARY`

**Purpose:** Paid social campaign performance (Meta, TikTok, etc.).

**Grain:** Ad Set × Day

**Dimension Fields:**
| Column | Description |
|--------|-------------|
| `EVENT_DATE` | Performance date |
| `CHANNEL` | Platform (Meta, TikTok) |
| `PARTNER`, `TACTIC`, `MEDIA_TYPE` | Campaign classification |
| `TARGET_VERTICAL` | Target audience (buy, rent, sell) |
| `ACCOUNT_ID`, `ACCOUNT_NAME` | Ad account |
| `CAMPAIGN_ID`, `CAMPAIGN_NAME` | Campaign |
| `ADSET_ID`, `ADSET_NAME` | Ad set |
| `AD_ID`, `AD_NAME` | Individual ad |

**Metrics:** (Same structure as SEM_SUMMARY)
- `SPEND`, `IMPRESSIONS`, `CLICKS`, `LINK_CLICKS`
- `LEADS`, `BUY_LEADS`, `RENT_LEADS`, `SELL_LEADS`
- `EFR`, `TOTAL_BUY_EFR`, `TOTAL_SELL_EFR`, `TOTAL_RENT_EFR`

### Common Query Patterns

**Channel performance:**
```sql
SELECT 
    channel,
    target_vertical,
    SUM(spend) as spend,
    SUM(link_clicks) as link_clicks,
    SUM(leads) as leads,
    SUM(efr) as efr,
    SUM(spend) / NULLIF(SUM(leads), 0) as cpl
FROM rdc_marketing.agg_reporting.psocial_summary
WHERE event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY spend DESC;
```

---

## Common Join Patterns

### Clickstream to Lead Attribution
```sql
-- Match clickstream sessions to leads
SELECT 
    c.visit_id,
    c.adjusted_uu_id,
    c.last_touch_marketing_channel,
    c.platform,
    m.submitted_lead_id,
    m.estimated_future_revenue
FROM rdc_analytics.clickstream.clickstream_detail c
INNER JOIN rdc_analytics.revenue.marketing_conversion_detail m
    ON c.inquiry_lead_id = m.submitted_lead_id
WHERE c.event_date_mst >= DATEADD('day', -7, CURRENT_DATE())
  AND c.inquiry_lead_id IS NOT NULL;
```

### SEM to Lead Attribution (via GCLID)
```sql
-- Match SEM spend to leads via Google Click ID
SELECT 
    s.event_date,
    s.campaign_name,
    s.spend,
    COUNT(DISTINCT m.submitted_lead_id) as attributed_leads,
    SUM(m.estimated_future_revenue) as attributed_efr
FROM rdc_marketing.agg_reporting.sem_summary s
LEFT JOIN rdc_analytics.revenue.marketing_conversion_detail m
    ON s.event_date = m.event_date
    AND m.google_click_id IS NOT NULL
    AND m.last_touch_marketing_channel = 'Paid Search'
WHERE s.event_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY 1, 3 DESC;
```

---

## Best Practices

1. **Always filter on date first** - These tables are large; date filters reduce scan volume dramatically
2. **Use appropriate date column:**
   - Clickstream: `event_date_mst`
   - Conversions: `event_date`
   - Marketing: `event_date` or `date`
3. **ADJUSTED_UU_ID is the canonical user ID** - Use for cross-table user analysis
4. **EFR is probabilistic revenue** - Not actual revenue; use for relative comparisons
5. **Snapshot vs. Cohort metrics in app_summary:**
   - Snapshot = point-in-time measurement
   - Cohort = attributed to install date (preferred for LTV analysis)
