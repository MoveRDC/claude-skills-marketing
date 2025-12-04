# Snowflake Schema Reference

Comprehensive documentation of key Snowflake tables used in real estate marketing analytics.

## Primary Databases

- **RDC_ANALYTICS** - Analytics and reporting data
- **RDC_MARKETING** - Marketing campaign and performance data

## Key Tables by Function

### Lead & Conversion Data

#### RDC_ANALYTICS.LEADS
Primary table for lead information.

**Key Fields:**
- `LEAD_ID` - Unique lead identifier
- `LEAD_TIMESTAMP` - When lead was submitted
- `LEAD_SOURCE` - Attribution source (paid_search, organic_search, direct, referral)
- `CAMPAIGN_NAME` - Marketing campaign associated with lead
- `PROPERTY_ID` - Property listing associated with lead
- `LIST_PRICE` - Price of the property at time of lead
- `STATE` - Property state
- `DMA` - Designated Market Area
- `USER_SESSION_ID` - Session identifier for clickstream joins

**Common Uses:**
- Lead volume and pricing analysis
- Channel attribution
- Geographic distribution
- Campaign performance

**Example Query:**
```sql
SELECT 
    DATE_TRUNC('day', LEAD_TIMESTAMP) AS lead_date,
    LEAD_SOURCE,
    COUNT(*) AS lead_count,
    MEDIAN(LIST_PRICE) AS median_list_price,
    SUM(LIST_PRICE) / COUNT(*) AS mean_list_price
FROM RDC_ANALYTICS.LEADS
WHERE LEAD_TIMESTAMP >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1 DESC, 3 DESC;
```

### Marketing Campaign Data

#### Overview: Data Construction & Methodology

The tables in `RDC_MARKETING.AGG_REPORTING` combine marketing platform data with internal lead tracking to provide comprehensive campaign performance metrics.

**Data Sources & Join Logic:**
1. **Marketing Platform Data** - Sourced from Fivetran connectors (Google Ads, Bing Ads, Facebook Ads, etc.)
   - Contains spend, impressions, clicks, and platform-reported conversions
   - Organized by campaign, ad group/ad set hierarchy

2. **Internal Leads Data** - Our proprietary lead tracking system
   - Contains lead volume, intent classification, and EFR calculations
   - Includes the `Last_Touch_Marketing_Channel_Detail` field with URL parameters

3. **Join Methodology** - Campaign and ad group/ad set IDs are parsed from the **CID URL parameter** found in `Last_Touch_Marketing_Channel_Detail`
   - This enables attribution of internal leads back to specific marketing campaigns and ad groups
   - Allows calculation of true ROAS using EFR (Expected Future Revenue) instead of platform-reported conversions

**Key Insight:** Platform `CONVERSIONS` metrics are useful for optimization but may not align with internal `LEADS`. Always use `LEADS` and `EFR` for performance measurement and ROAS calculations.

---

#### RDC_MARKETING.AGG_REPORTING.SEM_SUMMARY
Campaign-level SEM (Search Engine Marketing) performance aggregation.

**Key Fields:**
- `EVENT_DATE` - Performance date
- `BRAND` - Brand identifier (realtor.com, homefinder, etc.) **Note:** Also indicates campaign tactic - "BRAND" for brand campaigns vs. other values for performance/non-brand campaigns
- `PARTNER` - Search partner (google, bing)
- `TACTIC` - Campaign tactic type
- `CAMPAIGN_ID` - Unique campaign identifier
- `CAMPAIGN_NAME` - Campaign name
- `ACCOUNT_ID` - Ad account identifier
- `ACCOUNT_NAME` - Ad account name
- `SPEND` - Daily spend amount
- `IMPRESSIONS` - Ad impressions
- `CLICKS` - Ad clicks
- `CONVERSIONS` - Conversion events **sourced from the ad platform** (e.g., Google Ads, Bing Ads). Counts conversions based on the conversion action the campaign is optimizing for (may include form submissions, calls, or other platform-defined conversions)
- `LEADS` - Total leads generated (internal tracking, joined via CID parameter parsing)
- `RENT_LEADS` - Rental intent leads
- `BUY_LEADS` - Buy intent leads
- `SELL_LEADS` - Sell intent leads
- `EFR` - Expected Future Revenue (total)
- `TOTAL_BUY_EFR` - EFR from buy leads
- `TOTAL_SELL_EFR` - EFR from sell leads
- `TOTAL_RENT_EFR` - EFR from rental leads
- `MEDIAN_LEAD_LISTING_PRICE` - Median price of properties generating leads
- `AVG_LEAD_LISTING_PRICE` - Average price of properties generating leads

**Important Notes:**
- `CONVERSIONS` vs `LEADS`: CONVERSIONS are platform-reported and may differ from LEADS (our internal tracking). Always use LEADS for EFR calculations and performance analysis.
- `BRAND` field: When value is "BRAND", indicates brand campaigns; other values indicate performance/non-brand campaigns.

**Common Uses:**
- Campaign-level performance analysis
- ROAS calculation (EFR / SPEND)
- Lead volume and quality tracking by campaign
- Budget allocation across campaigns
- Partner performance comparison (Google vs Bing)
- Brand vs. performance campaign comparison

**Example Query:**
```sql
SELECT 
    EVENT_DATE,
    PARTNER,
    CAMPAIGN_NAME,
    BRAND,
    SUM(SPEND) AS total_spend,
    SUM(CLICKS) AS total_clicks,
    SUM(CONVERSIONS) AS platform_conversions,
    SUM(LEADS) AS total_leads,
    SUM(EFR) AS total_efr,
    SUM(EFR) / NULLIF(SUM(SPEND), 0) AS roas,
    SUM(SPEND) / NULLIF(SUM(LEADS), 0) AS cpl
FROM RDC_MARKETING.AGG_REPORTING.SEM_SUMMARY
WHERE EVENT_DATE >= DATEADD('day', -30, CURRENT_DATE())
    AND SPEND > 0
GROUP BY 1, 2, 3, 4
ORDER BY total_spend DESC;
```

---

#### RDC_MARKETING.AGG_REPORTING.SEM_ADGROUP_SUMMARY
Ad group-level SEM performance aggregation (granular campaign data).

**Key Fields:**
- `EVENT_DATE` - Performance date
- `BRAND` - Brand identifier **Note:** Also indicates campaign tactic - "BRAND" for brand campaigns vs. other values for performance/non-brand campaigns
- `PARTNER` - Search partner (google, bing)
- `TACTIC` - Campaign tactic type
- `CAMPAIGN_ID` - Unique campaign identifier
- `CAMPAIGN_NAME` - Campaign name
- `AD_GROUP_ID` - Unique ad group identifier
- `AD_GROUP_NAME` - Ad group name
- `ACCOUNT_NAME` - Ad account name
- `SPEND` - Daily spend amount
- `IMPRESSIONS` - Ad impressions
- `CLICKS` - Ad clicks
- `CONVERSIONS` - Conversion events **sourced from the ad platform** (e.g., Google Ads, Bing Ads). Counts conversions based on the conversion action the campaign is optimizing for (may include form submissions, calls, or other platform-defined conversions)
- `LEADS` - Total leads generated (internal tracking, joined via CID parameter parsing)
- `RENT_LEADS`, `BUY_LEADS`, `SELL_LEADS` - Intent-specific leads
- `EFR` - Expected Future Revenue
- `TOTAL_BUY_EFR`, `TOTAL_SELL_EFR`, `TOTAL_RENT_EFR` - Intent-specific EFR
- `MEDIAN_LEAD_LISTING_PRICE` - Median price of properties generating leads

**Important Notes:**
- `CONVERSIONS` vs `LEADS`: CONVERSIONS are platform-reported and may differ from LEADS (our internal tracking). Always use LEADS for EFR calculations and performance analysis.
- `BRAND` field: When value is "BRAND", indicates brand campaigns; other values indicate performance/non-brand campaigns.

**Common Uses:**
- Ad group optimization and performance analysis
- Identifying underperforming ad groups for budget reallocation
- Granular ROAS and CPL calculation
- A/B testing across ad groups
- Keyword-level insights (via ad group segmentation)
- Brand vs. performance ad group comparison

**Example Query:**
```sql
-- Identify top performing ad groups by ROAS
SELECT 
    CAMPAIGN_NAME,
    AD_GROUP_NAME,
    BRAND,
    SUM(SPEND) AS total_spend,
    SUM(CONVERSIONS) AS platform_conversions,
    SUM(LEADS) AS total_leads,
    SUM(EFR) AS total_efr,
    SUM(EFR) / NULLIF(SUM(SPEND), 0) AS roas,
    SUM(SPEND) / NULLIF(SUM(LEADS), 0) AS cpl
FROM RDC_MARKETING.AGG_REPORTING.SEM_ADGROUP_SUMMARY
WHERE EVENT_DATE >= DATEADD('day', -30, CURRENT_DATE())
    AND SPEND > 100
GROUP BY 1, 2, 3
HAVING SUM(LEADS) > 10
ORDER BY roas DESC
LIMIT 20;
```

---

#### RDC_MARKETING.AGG_REPORTING.PSOCIAL_SUMMARY
Paid social media campaign performance (Facebook, Instagram, etc.).

**Key Fields:**
- `EVENT_DATE` - Performance date
- `CHANNEL` - Channel identifier (psocial)
- `PARTNER` - Social platform (facebook, instagram)
- `CAMPAIGN_ID` - Unique campaign identifier
- `CAMPAIGN_NAME` - Campaign name
- `ADSET_ID` - Unique ad set identifier
- `ADSET_NAME` - Ad set name
- `AD_ID` - Unique ad identifier
- `AD_NAME` - Ad creative name
- `SPEND` - Daily spend amount
- `IMPRESSIONS` - Ad impressions
- `CLICKS` - Total clicks
- `LINK_CLICKS` - Link clicks (more specific than total clicks)
- **Note:** This table does not have a CONVERSIONS column. Use LEADS for conversion tracking.
- `LEADS` - Total leads generated (internal tracking, joined via CID parameter parsing)
- `RENT_LEADS`, `BUY_LEADS`, `SELL_LEADS` - Intent-specific leads
- `EFR` - Expected Future Revenue
- `TOTAL_BUY_EFR`, `TOTAL_SELL_EFR`, `TOTAL_RENT_EFR` - Intent-specific EFR

**Common Uses:**
- Paid social campaign performance analysis
- Creative performance optimization (ad-level analysis)
- Audience targeting effectiveness
- Cross-channel comparison (social vs search)
- Lead generation efficiency for social campaigns

**Example Query:**
```sql
-- Compare campaign performance across social platforms
SELECT 
    PARTNER,
    CAMPAIGN_NAME,
    SUM(SPEND) AS total_spend,
    SUM(LINK_CLICKS) AS total_link_clicks,
    SUM(LEADS) AS total_leads,
    SUM(EFR) AS total_efr,
    SUM(EFR) / NULLIF(SUM(SPEND), 0) AS roas,
    SUM(SPEND) / NULLIF(SUM(LEADS), 0) AS cpl,
    SUM(LEADS) / NULLIF(SUM(LINK_CLICKS), 0) AS link_to_lead_rate
FROM RDC_MARKETING.AGG_REPORTING.PSOCIAL_SUMMARY
WHERE EVENT_DATE >= DATEADD('day', -30, CURRENT_DATE())
    AND SPEND > 0
GROUP BY 1, 2
ORDER BY total_spend DESC;
```

---

#### RDC_MARKETING.AGG_REPORTING.APP_SUMMARY
Mobile app marketing campaign performance across iOS and Android.

**Key Fields:**
- `DATE` - Performance date
- `PLATFORM` - Mobile platform (ios, android)
- `MEDIA_SOURCE` - Attribution source (googleadwords_int, facebook, etc.)
- `CAMPAIGN` - Campaign identifier
- `EFFORT` - Marketing effort/initiative
- `CHANNEL` - Marketing channel
- `SPEND` - Daily spend amount
- `IMPRESSIONS` - Ad impressions
- `CLICKS` - Ad clicks
- **Note:** This table does not have a CONVERSIONS column. Use INSTALLS and lead metrics for conversion tracking.
- `INSTALLS` - App installs (attributed)

**Snapshot Fields (Conversion Date Attribution):**
Conversions attributed to the date when the conversion occurred.
- `SNAPSHOT_EFR_FOR_SALE` - EFR from for-sale leads
- `SNAPSHOT_EFR_RENTAL` - EFR from rental leads
- `SNAPSHOT_EFR_SELLER` - EFR from seller leads
- `SNAPSHOT_LEADS_FOR_SALE` - For-sale leads
- `SNAPSHOT_LEADS_RENTALS` - Rental leads
- `SNAPSHOT_LEADS_SELLER` - Seller leads
- `SNAPSHOT_IEFR_FOR_SALE` - Incrementalized EFR for sale

**Cohort Fields (Install Date Attribution):**
Conversions attributed back to the date of the original app install (install cohort). Use these for understanding the long-term value of users acquired on a specific date.
- `COHORT_EFR_FOR_SALE` - EFR from buy leads (attributed to install date)
- `COHORT_EFR_RENTAL` - EFR from rental leads (attributed to install date)
- `COHORT_EFR_SELLER` - EFR from seller leads (attributed to install date)
- `COHORT_LEADS_FOR_SALE` - For-sale leads (attributed to install date)
- `COHORT_LEADS_RENTAL` - Rental leads (attributed to install date)
- `COHORT_LEADS_SELLER` - Seller leads (attributed to install date)

**Attribution Note:**
- **Snapshot metrics** show performance on the date conversions happened - useful for daily performance tracking
- **Cohort metrics** show performance attributed to the install date - useful for LTV analysis and understanding campaign quality over time

**Other Fields:**
- `ADVANTAGELEADS`, `COBROKELEADS` - Product-specific lead types
- `FISCAL_YEAR`, `MONTH_YEAR` - Time dimensions for reporting
- `AGENCY_FEES` - Agency management fees
- `INCREMENTALITY_MULTIPLIER` - Factor for incremental lift calculation

**Common Uses:**
- Mobile app user acquisition analysis
- Platform comparison (iOS vs Android)
- Install-to-lead conversion tracking
- Mobile campaign ROAS calculation (use Cohort metrics for true LTV ROAS)
- Media source attribution and optimization
- Install cohort performance analysis

**Example Query - Snapshot Attribution:**
```sql
-- Daily performance tracking (conversion date attribution)
SELECT 
    DATE,
    PLATFORM,
    MEDIA_SOURCE,
    SUM(SPEND) AS total_spend,
    SUM(INSTALLS) AS total_installs,
    SUM(SNAPSHOT_LEADS_FOR_SALE + SNAPSHOT_LEADS_RENTALS + SNAPSHOT_LEADS_SELLER) AS total_leads,
    SUM(SNAPSHOT_EFR_FOR_SALE + SNAPSHOT_EFR_RENTAL + SNAPSHOT_EFR_SELLER) AS total_efr,
    SUM(SNAPSHOT_EFR_FOR_SALE + SNAPSHOT_EFR_RENTAL + SNAPSHOT_EFR_SELLER) / NULLIF(SUM(SPEND), 0) AS snapshot_roas
FROM RDC_MARKETING.AGG_REPORTING.APP_SUMMARY
WHERE DATE >= DATEADD('day', -30, CURRENT_DATE())
    AND SPEND > 0
GROUP BY 1, 2, 3
ORDER BY DATE DESC, total_spend DESC;
```

**Example Query - Cohort Attribution:**
```sql
-- Install cohort LTV analysis (install date attribution)
SELECT 
    DATE AS install_date,
    PLATFORM,
    MEDIA_SOURCE,
    SUM(SPEND) AS total_spend,
    SUM(INSTALLS) AS total_installs,
    SUM(COHORT_LEADS_FOR_SALE + COHORT_LEADS_RENTAL + COHORT_LEADS_SELLER) AS cohort_leads,
    SUM(COHORT_EFR_FOR_SALE + COHORT_EFR_RENTAL + COHORT_EFR_SELLER) AS cohort_efr,
    SUM(COHORT_EFR_FOR_SALE + COHORT_EFR_RENTAL + COHORT_EFR_SELLER) / NULLIF(SUM(SPEND), 0) AS cohort_roas,
    SUM(COHORT_EFR_FOR_SALE + COHORT_EFR_RENTAL + COHORT_EFR_SELLER) / NULLIF(SUM(INSTALLS), 0) AS ltv_per_install
FROM RDC_MARKETING.AGG_REPORTING.APP_SUMMARY
WHERE DATE >= DATEADD('day', -90, CURRENT_DATE())
    AND SPEND > 0
GROUP BY 1, 2, 3
ORDER BY install_date DESC;
```

### Clickstream & Session Data

#### RDC_ANALYTICS.CLICKSTREAM
User behavior and session tracking.

**Key Fields:**
- `SESSION_ID` - Unique session identifier
- `USER_ID` - User identifier (if authenticated)
- `TIMESTAMP` - Event timestamp
- `PAGE_TYPE` - Type of page (SRP, PDP, etc.)
- `EVENT_TYPE` - User action (pageview, click, form_submit)
- `PROPERTY_ID` - Property viewed/interacted with
- `REFERRER_SOURCE` - Traffic source

**Page Types:**
- `SRP` - Search Results Page
- `PDP` - Property Detail Page
- `LEAD_FORM` - Lead submission page
- `HOMEPAGE` - Homepage

**Common Uses:**
- User journey analysis
- Conversion funnel tracking
- Drop-off identification
- Session attribution

**Example Query:**
```sql
WITH session_stages AS (
    SELECT 
        SESSION_ID,
        MIN(CASE WHEN PAGE_TYPE = 'SRP' THEN TIMESTAMP END) AS srp_time,
        MIN(CASE WHEN PAGE_TYPE = 'PDP' THEN TIMESTAMP END) AS pdp_time,
        MIN(CASE WHEN PAGE_TYPE = 'LEAD_FORM' THEN TIMESTAMP END) AS lead_time
    FROM RDC_ANALYTICS.CLICKSTREAM
    WHERE TIMESTAMP >= DATEADD('day', -7, CURRENT_DATE())
    GROUP BY SESSION_ID
)
SELECT 
    COUNT(*) AS total_sessions,
    COUNT(pdp_time) AS reached_pdp,
    COUNT(lead_time) AS submitted_lead,
    COUNT(lead_time)::FLOAT / NULLIF(COUNT(*), 0) AS conversion_rate
FROM session_stages
WHERE srp_time IS NOT NULL;
```

### Listing Inventory Data

#### RDC_ANALYTICS.PROPERTY_LISTINGS
Current and historical property listings.

**Key Fields:**
- `PROPERTY_ID` - Unique property identifier
- `LIST_PRICE` - Current listing price
- `STATE` - Property state
- `DMA` - Designated Market Area
- `LISTING_STATUS` - Active, sold, pending, etc.
- `LISTING_DATE` - When listing went live
- `PROPERTY_TYPE` - Single family, condo, land, etc.

**Common Uses:**
- Market inventory analysis
- Geographic distribution
- Price segment analysis
- Market alignment studies

**Example Query:**
```sql
SELECT 
    STATE,
    DMA,
    COUNT(*) AS active_listings,
    MEDIAN(LIST_PRICE) AS median_price,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY LIST_PRICE) AS p25_price,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY LIST_PRICE) AS p75_price
FROM RDC_ANALYTICS.PROPERTY_LISTINGS
WHERE LISTING_STATUS = 'Active'
GROUP BY 1, 2
ORDER BY active_listings DESC;
```

## Common Table Joins

### Lead to Campaign Performance
```sql
SELECT 
    l.LEAD_SOURCE,
    l.CAMPAIGN_NAME,
    COUNT(DISTINCT l.LEAD_ID) AS lead_count,
    SUM(s.SPEND) AS total_spend,
    SUM(s.EFR) AS total_efr,
    SUM(s.EFR) / NULLIF(SUM(s.SPEND), 0) AS roas
FROM RDC_ANALYTICS.LEADS l
LEFT JOIN RDC_MARKETING.AGG_REPORTING.SEM_SUMMARY s
    ON l.CAMPAIGN_NAME = s.CAMPAIGN_NAME
    AND DATE(l.LEAD_TIMESTAMP) = s.EVENT_DATE
WHERE l.LEAD_TIMESTAMP >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2;
```

### Lead to Listing (Property Context)
```sql
SELECT 
    l.STATE,
    l.DMA,
    COUNT(DISTINCT l.LEAD_ID) AS lead_count,
    MEDIAN(p.LIST_PRICE) AS median_listing_price,
    MEDIAN(l.LIST_PRICE) AS median_lead_price
FROM RDC_ANALYTICS.LEADS l
LEFT JOIN RDC_ANALYTICS.PROPERTY_LISTINGS p
    ON l.PROPERTY_ID = p.PROPERTY_ID
WHERE l.LEAD_TIMESTAMP >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2;
```

### Clickstream to Lead (User Journey)
```sql
SELECT 
    c.SESSION_ID,
    MIN(c.TIMESTAMP) AS session_start,
    MAX(c.TIMESTAMP) AS session_end,
    COUNT(DISTINCT CASE WHEN c.PAGE_TYPE = 'PDP' THEN c.PROPERTY_ID END) AS properties_viewed,
    MAX(CASE WHEN l.LEAD_ID IS NOT NULL THEN 1 ELSE 0 END) AS converted
FROM RDC_ANALYTICS.CLICKSTREAM c
LEFT JOIN RDC_ANALYTICS.LEADS l
    ON c.SESSION_ID = l.USER_SESSION_ID
WHERE c.TIMESTAMP >= DATEADD('day', -7, CURRENT_DATE())
GROUP BY 1;
```

## Query Best Practices

1. **Always specify fully-qualified table names**: `RDC_MARKETING.AGG_REPORTING.TABLE_NAME`
2. **Use date filters early** to reduce data volume
3. **Handle NULL values** with NULLIF when dividing
4. **Use CTEs** for complex multi-step queries
5. **Aggregate appropriately** - consider using MEDIAN for skewed distributions
6. **Test queries** on small date ranges before scaling up

## Data Refresh Schedules

- **LEADS** - Real-time (< 5 minute lag)
- **AGG_REPORTING tables** - Daily (refreshed at 2 AM PT)
- **CLICKSTREAM** - Near real-time (< 15 minute lag)
- **PROPERTY_LISTINGS** - Hourly

## Schema Updates

When new tables or fields are added:
1. Document them in this file
2. Include example queries
3. Note any special considerations
4. Update the skill package
