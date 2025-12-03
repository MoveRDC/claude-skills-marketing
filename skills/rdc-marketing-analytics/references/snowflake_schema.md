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

#### RDC_MARKETING.GOOGLE_ADS_PERFORMANCE
Google Ads campaign performance metrics.

**Key Fields:**
- `DATE` - Performance date
- `CAMPAIGN_NAME` - Campaign identifier
- `AD_GROUP_NAME` - Ad group within campaign
- `CAMPAIGN_TYPE` - Type (Search, Display, Performance Max, etc.)
- `SPEND` - Daily spend amount
- `IMPRESSIONS` - Ad impressions
- `CLICKS` - Ad clicks
- `CONVERSIONS` - Conversion events (may differ from leads)

**Common Uses:**
- SEM spend analysis
- Campaign efficiency metrics
- Ad group performance
- Budget allocation decisions

**Example Query:**
```sql
SELECT 
    CAMPAIGN_NAME,
    AD_GROUP_NAME,
    SUM(SPEND) AS total_spend,
    SUM(CLICKS) AS total_clicks,
    SUM(CONVERSIONS) AS total_conversions,
    SUM(SPEND) / NULLIF(SUM(CONVERSIONS), 0) AS cost_per_conversion
FROM RDC_MARKETING.GOOGLE_ADS_PERFORMANCE
WHERE DATE >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
HAVING SUM(SPEND) > 1000
ORDER BY total_spend DESC;
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
    SUM(g.SPEND) AS total_spend,
    SUM(g.SPEND) / NULLIF(COUNT(DISTINCT l.LEAD_ID), 0) AS cost_per_lead
FROM RDC_ANALYTICS.LEADS l
LEFT JOIN RDC_MARKETING.GOOGLE_ADS_PERFORMANCE g
    ON l.CAMPAIGN_NAME = g.CAMPAIGN_NAME
    AND DATE(l.LEAD_TIMESTAMP) = g.DATE
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

1. **Always specify fully-qualified table names**: `RDC_ANALYTICS.SCHEMA.TABLE`
2. **Use date filters early** to reduce data volume
3. **Handle NULL values** with NULLIF when dividing
4. **Use CTEs** for complex multi-step queries
5. **Aggregate appropriately** - consider using MEDIAN for skewed distributions
6. **Test queries** on small date ranges before scaling up

## Data Refresh Schedules

- **LEADS** - Real-time (< 5 minute lag)
- **GOOGLE_ADS_PERFORMANCE** - Daily (refreshed at 2 AM PT)
- **CLICKSTREAM** - Near real-time (< 15 minute lag)
- **PROPERTY_LISTINGS** - Hourly

## Schema Updates

When new tables or fields are added:
1. Document them in this file
2. Include example queries
3. Note any special considerations
4. Update the skill package
