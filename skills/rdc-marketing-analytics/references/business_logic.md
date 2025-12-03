# Business Logic & Metric Definitions

Standard business rules, metric calculations, and data quality guidelines for real estate marketing analytics.

## Core Metrics

### Lead Price

**Definition:** The cost to acquire a single lead.

**Calculation Methods:**

**Median Lead Price (Preferred for skewed distributions):**
```sql
MEDIAN(LIST_PRICE) AS median_lead_price
```
Use when: Distribution is skewed by high-value properties

**Mean Lead Price:**
```sql
AVG(LIST_PRICE) AS mean_lead_price
-- Or equivalently:
SUM(LIST_PRICE) / COUNT(*) AS mean_lead_price
```
Use when: Distribution is relatively normal or when total value matters

**Volume-Weighted Lead Price:**
```sql
SUM(spend * lead_count) / SUM(lead_count) AS weighted_lead_price
```
Use when: Comparing campaigns with very different volumes

### Cost Per Lead (CPL)

**Definition:** Marketing spend divided by number of leads generated.

**Standard Calculation:**
```sql
SUM(spend) / NULLIF(COUNT(DISTINCT lead_id), 0) AS cost_per_lead
```

**By Channel:**
```sql
SELECT 
    lead_source,
    SUM(spend) AS total_spend,
    COUNT(DISTINCT lead_id) AS lead_count,
    SUM(spend) / NULLIF(COUNT(DISTINCT lead_id), 0) AS cpl
FROM leads_with_spend
GROUP BY lead_source;
```

**Important Notes:**
- Always use NULLIF to prevent division by zero
- Attribution can be tricky - ensure spend is properly allocated
- Consider lookback windows for proper attribution

### Lead Quality

**Definition:** Downstream value or conversion likelihood of a lead.

**Proxy Metrics:**

**Price Segment Analysis:**
```sql
CASE 
    WHEN list_price < 200000 THEN 'Under 200K'
    WHEN list_price < 400000 THEN '200K-400K'
    WHEN list_price < 600000 THEN '400K-600K'
    WHEN list_price < 1000000 THEN '600K-1M'
    ELSE '1M+'
END AS price_segment
```

**Engagement Indicators:**
- Multiple property views in session
- Time spent on property detail pages
- Return visits within 7 days
- Contact attempts (phone, email)

**Business Rule:** Paid search consistently delivers leads with 30-37% lower median list prices than other channels. This is expected and factored into channel strategy.

### Conversion Rate

**Definition:** Percentage of users who complete a desired action.

**Session to Lead:**
```sql
COUNT(DISTINCT CASE WHEN converted THEN session_id END)::FLOAT 
/ NULLIF(COUNT(DISTINCT session_id), 0) AS conversion_rate
```

**SRP to PDP:**
```sql
COUNT(DISTINCT CASE WHEN reached_pdp THEN session_id END)::FLOAT 
/ NULLIF(COUNT(DISTINCT session_id), 0) AS srp_to_pdp_rate
```

**PDP to Lead:**
```sql
COUNT(DISTINCT CASE WHEN submitted_lead THEN session_id END)::FLOAT 
/ NULLIF(COUNT(DISTINCT CASE WHEN reached_pdp THEN session_id END), 0) AS pdp_to_lead_rate
```

## Campaign Classification Rules

### Campaign Type Detection

```sql
CASE 
    WHEN LOWER(campaign_name) LIKE '%dsa%' THEN 'DSA'
    WHEN LOWER(campaign_name) LIKE '%pmax%' OR LOWER(campaign_name) LIKE '%performance max%' THEN 'Performance Max'
    WHEN LOWER(campaign_name) LIKE '%brand%' THEN 'Brand'
    WHEN LOWER(campaign_name) LIKE '%buy intent%' THEN 'Buy Intent'
    WHEN LOWER(campaign_name) LIKE '%land%' OR LOWER(campaign_name) LIKE '%lots%' THEN 'Land/Lots'
    ELSE 'Other'
END AS campaign_category
```

### Underperforming Campaign Criteria

A campaign/ad group is considered underperforming if:

1. **High CPL:** Cost per lead > 1.5x channel median
2. **Low volume:** < 10 leads in past 30 days despite significant spend (>$1K)
3. **Declining trend:** 30% YoY or QoQ decline in lead volume
4. **Quality issues:** Median lead price < 0.5x channel median (very low-value properties)

**Example Query:**
```sql
WITH campaign_metrics AS (
    SELECT 
        campaign_name,
        SUM(spend) AS total_spend,
        COUNT(DISTINCT lead_id) AS lead_count,
        SUM(spend) / NULLIF(COUNT(DISTINCT lead_id), 0) AS cpl,
        MEDIAN(list_price) AS median_lead_price
    FROM campaign_performance
    WHERE date >= DATEADD('day', -30, CURRENT_DATE())
    GROUP BY campaign_name
),
channel_benchmarks AS (
    SELECT 
        MEDIAN(cpl) AS median_cpl,
        MEDIAN(median_lead_price) AS median_price
    FROM campaign_metrics
)
SELECT 
    cm.*,
    CASE 
        WHEN cm.cpl > cb.median_cpl * 1.5 THEN 'High CPL'
        WHEN cm.lead_count < 10 AND cm.total_spend > 1000 THEN 'Low Volume'
        WHEN cm.median_lead_price < cb.median_price * 0.5 THEN 'Low Quality'
        ELSE 'Performing'
    END AS performance_flag
FROM campaign_metrics cm
CROSS JOIN channel_benchmarks cb;
```

## Geographic Market Rules

### DMA Prioritization

**Tier 1 Markets (High Priority):**
- Top 20 DMAs by listing inventory
- Markets with > 1000 active listings
- Strategic focus markets

**Tier 2 Markets (Medium Priority):**
- 21-50 DMAs by listing inventory
- Markets with 250-1000 active listings
- Growth opportunity markets

**Tier 3 Markets (Low Priority):**
- 51+ DMAs by listing inventory
- Markets with < 250 active listings
- Maintenance mode markets

### Zero-Lead Market Analysis

**Definition:** Markets with active listings but zero leads in the analysis period.

**Investigation Criteria:**
```sql
SELECT 
    p.dma,
    COUNT(DISTINCT p.property_id) AS active_listings,
    COUNT(DISTINCT l.lead_id) AS lead_count
FROM property_listings p
LEFT JOIN leads l 
    ON p.dma = l.dma 
    AND l.lead_timestamp >= DATEADD('day', -30, CURRENT_DATE())
WHERE p.listing_status = 'Active'
GROUP BY p.dma
HAVING COUNT(DISTINCT l.lead_id) = 0
    AND COUNT(DISTINCT p.property_id) >= 10
ORDER BY active_listings DESC;
```

**Follow-up Actions:**
1. Check if market has marketing coverage
2. Review competitive landscape
3. Assess if targeting parameters exclude market
4. Evaluate market opportunity vs. investment

## Data Quality Rules

### Required Field Validation

**Leads Table:**
- LEAD_ID must not be null
- LEAD_TIMESTAMP must be within reasonable range (not future, not >2 years old)
- LEAD_SOURCE must be one of: paid_search, organic_search, direct, referral, social
- LIST_PRICE should be > 0 (flag if null or 0)

**Campaign Data:**
- DATE must not be null
- SPEND should be >= 0
- CAMPAIGN_NAME must not be null
- Negative clicks or impressions indicate data issues

### Anomaly Detection

**Spend Anomalies:**
```sql
-- Flag days with spend >3 standard deviations from 30-day mean
WITH daily_spend AS (
    SELECT 
        date,
        SUM(spend) AS daily_spend
    FROM google_ads_performance
    WHERE date >= DATEADD('day', -30, CURRENT_DATE())
    GROUP BY date
),
spend_stats AS (
    SELECT 
        AVG(daily_spend) AS mean_spend,
        STDDEV(daily_spend) AS stddev_spend
    FROM daily_spend
)
SELECT 
    ds.date,
    ds.daily_spend,
    ss.mean_spend,
    ss.stddev_spend,
    CASE 
        WHEN ABS(ds.daily_spend - ss.mean_spend) > 3 * ss.stddev_spend 
        THEN 'ANOMALY'
        ELSE 'NORMAL'
    END AS flag
FROM daily_spend ds
CROSS JOIN spend_stats ss
ORDER BY ds.date DESC;
```

**Lead Volume Anomalies:**
- Day-over-day change > 50% requires investigation
- Week-over-week change > 30% should be reviewed
- Sudden drops to zero likely indicate tracking issues

### Null Handling

**Standard Approach:**
```sql
-- Use NULLIF when dividing to prevent errors
metric / NULLIF(denominator, 0)

-- Use COALESCE for default values
COALESCE(optional_field, 'Unknown')

-- Filter out nulls in critical fields
WHERE required_field IS NOT NULL
```

## Aggregation Best Practices

### When to Use MEDIAN vs AVG

**Use MEDIAN when:**
- Data is skewed (list prices, lead prices)
- Outliers exist (luxury properties)
- Representative "typical" value is more important than total

**Use AVG/SUM when:**
- Total value matters (total spend, total revenue)
- Data is normally distributed
- Calculating rates or percentages

### Date Aggregation

**Standard Date Ranges:**
- **L7D:** Last 7 days (DATEADD('day', -7, CURRENT_DATE()))
- **L30D:** Last 30 days (DATEADD('day', -30, CURRENT_DATE()))
- **MTD:** Month to date (DATE_TRUNC('month', CURRENT_DATE()))
- **QTD:** Quarter to date (DATE_TRUNC('quarter', CURRENT_DATE()))
- **YTD:** Year to date (DATE_TRUNC('year', CURRENT_DATE()))

**Comparative Periods:**
```sql
-- Year-over-year comparison
WHERE date BETWEEN DATEADD('year', -1, period_start) 
              AND DATEADD('year', -1, period_end)

-- Quarter-over-quarter comparison  
WHERE date BETWEEN DATEADD('quarter', -1, period_start)
              AND DATEADD('quarter', -1, period_end)
```

## Attribution Rules

### Last-Touch Attribution (Default)

The most recent marketing touchpoint before lead submission gets credit.

```sql
-- Lead source is the last touchpoint
SELECT lead_source FROM leads
```

### Multi-Touch Considerations

For complex attribution:
- First touch: Initial discovery channel
- Last touch: Final conversion channel
- Assisted conversions: Channels in the path

**Note:** Full multi-touch attribution requires clickstream analysis and is more complex. Use last-touch as default unless specifically analyzing assist value.

## Calculation Examples

### Volume-Weighted Campaign Performance

When comparing campaigns of different sizes:

```sql
WITH campaign_data AS (
    SELECT 
        campaign_name,
        SUM(spend) AS total_spend,
        COUNT(DISTINCT lead_id) AS lead_count,
        SUM(spend) / NULLIF(COUNT(DISTINCT lead_id), 0) AS cpl
    FROM campaign_leads
    GROUP BY campaign_name
)
SELECT 
    SUM(total_spend * lead_count) / SUM(lead_count) AS weighted_avg_cpl,
    SUM(total_spend) / SUM(lead_count) AS simple_avg_cpl
FROM campaign_data;
```

The weighted average accounts for campaign volume, preventing small high-CPL campaigns from skewing overall metrics.

## Reporting Standards

### Significant Figures
- Dollar amounts: Round to nearest $1
- Percentages: 1 decimal place (e.g., 12.3%)
- Rates/ratios: 2 decimal places (e.g., 2.47)
- Large numbers: Use K/M notation (e.g., $1.2M, 45K leads)

### Change Calculations
```sql
-- Percentage change
((current_value - prior_value) / NULLIF(prior_value, 0)) * 100 AS pct_change

-- Absolute change
current_value - prior_value AS abs_change
```

### Benchmarks & Targets

**Typical Industry Benchmarks:**
- SRP → PDP conversion: 15-25%
- PDP → Lead conversion: 3-8%
- Overall session → Lead: 0.5-2%

**Note:** These vary significantly by property type, price segment, and market. Always establish baseline from historical data.
