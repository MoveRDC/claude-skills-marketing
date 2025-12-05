# Common Data Quality Pitfalls

Real examples of data quality issues and how to catch them, based on actual analysis errors.

**This document contains 12 real pitfalls from actual work:**
1. Unbalanced Pre/Post Periods
2. Future Dates in Queries  
3. Day-of-Week Imbalance
4. Lead Count Mismatches
5. Average vs Sum Confusion
6. Silent Null Exclusions
7. Wrong Percentage Change Formula
8. Denominators with Zeros
9. Property Type Mix Confusion
10. Median vs Mean for Skewed Data
11. Missing Vertical Filter
12. Expecting Median Contributions to Sum to 100%

## Date Range Errors

### Pitfall 1: Unbalanced Pre/Post Periods

**What Happened:**
```
Analysis claimed: "POST leads are lower than PRE"
  PRE: Oct 5 - Nov 1 (28 days) = 102,085 leads
  POST: Nov 2 - Nov 22 (21 days) = 85,953 leads
```

**The Error:** Comparing 28 days to 21 days without normalizing

**Correct Approach:**
```python
# Normalize to daily rate
PRE_daily = 102_085 / 28 = 3,646 leads/day
POST_daily = 85_953 / 21 = 4,093 leads/day

# POST is actually +12.3% higher on a daily basis!
```

**Lesson:** Always normalize metrics to same time unit (daily, weekly) when periods differ.

---

### Pitfall 2: Future Dates in Queries

**What Happened:**
```sql
-- Analyst's query
WHERE event_date >= '2025-11-01'
  AND current_date = '2025-10-30'  -- But we're still in October!
```

**The Error:** Query includes future dates that don't exist yet

**How to Catch:**
```sql
-- Add validation check
SELECT 
    MIN(event_date) as earliest,
    MAX(event_date) as latest,
    CURRENT_DATE() as today,
    CASE 
        WHEN MAX(event_date) > CURRENT_DATE() THEN 'ERROR: Future dates detected'
        ELSE 'OK'
    END as validation
FROM your_table;
```

**Lesson:** Always validate date ranges are within available data before running analysis.

---

### Pitfall 3: Day-of-Week Imbalance

**What Happened:**
```
POST period: 18 days = 2.57 weeks
  Mon: 3, Tue: 3, Wed: 3, Thu: 2, Fri: 2, Sat: 2, Sun: 3
```

**The Error:** Unequal distribution of weekdays skews averages

**Impact on Metrics:**
- If Mondays have 50% higher spend than Fridays
- Having 3 Mondays vs 2 Fridays = artificial +2.8% boost in average spend

**Fix:**
```python
# Check balance
def check_dow_balance(df, date_col):
    dow_counts = df[date_col].dt.day_name().value_counts()
    if dow_counts.std() > 0.5:
        return f"⚠️ Unbalanced: {dow_counts.to_dict()}"
    return "✓ Balanced"
```

**Lesson:** For metrics with strong day-of-week patterns, always use X*7 day periods.

---

## Cross-Source Reconciliation Errors

### Pitfall 4: Lead Count Mismatches

**What Happened:**
```
Homefinder buyer leads since 11/1:
  Inquiry table: 647 leads
  Lead table: 427 leads (-34%)
  Revenue table: 362 leads (-44%)
```

**The Error:** Analyst assumed all tables should show same count

**Root Cause:**
- Inquiry → Lead: Quality filtering removes 39%
- Lead → Revenue: Only RCC-delivered leads included

**Correct Approach:**
```sql
-- Trace individual records through pipeline
WITH inquiry_base AS (
    SELECT id as inquiry_id, 'inquiry' as stage
    FROM lead_inquiry WHERE source LIKE '%homefinder%'
),
lead_conversions AS (
    SELECT i.inquiry_id, 'lead' as stage
    FROM inquiry_base i
    JOIN lead l ON l.primary_inquiry_id = i.inquiry_id
),
revenue_conversions AS (
    SELECT l.inquiry_id, 'revenue' as stage
    FROM lead_conversions l
    JOIN referral_revenue r ON r.primary_lead_id = l.lead_id
)
-- Calculate conversion rates at each stage
SELECT 
    COUNT(DISTINCT inquiry_base.inquiry_id) as inquiries,
    COUNT(DISTINCT lead_conversions.inquiry_id) as leads,
    COUNT(DISTINCT revenue_conversions.inquiry_id) as revenue_leads,
    ROUND(100.0 * COUNT(DISTINCT leads) / COUNT(DISTINCT inquiries), 1) as inquiry_to_lead_pct,
    ROUND(100.0 * COUNT(DISTINCT revenue_leads) / COUNT(DISTINCT leads), 1) as lead_to_revenue_pct
FROM inquiry_base
LEFT JOIN lead_conversions USING (inquiry_id)
LEFT JOIN revenue_conversions USING (inquiry_id);
```

**Lesson:** Document expected conversion/attrition rates between data sources.

---

### Pitfall 5: Average vs Sum Confusion

**What Happened:**
```
MCD table shows avg EFR = $12.48
Custom query shows avg EFR = $25+
```

**Root Cause:**
- MCD has 143K records but only 62K unique inquiries
- Multiple records per inquiry, many with $0 EFR
- $0 records dilute the average

**Fix:**
```sql
-- WRONG: Average across all records
SELECT AVG(efr) FROM mcd_table;  -- Includes duplicate records

-- RIGHT: Average at inquiry level
SELECT AVG(efr) 
FROM (
    SELECT inquiry_id, MAX(efr) as efr
    FROM mcd_table
    GROUP BY inquiry_id
);
```

**Lesson:** Always clarify grain of analysis - per-record vs per-entity.

---

## Null Value Errors

### Pitfall 6: Silent Null Exclusions

**What Happened:**
```
Price buckets don't sum to 100%:
  <$220K: 72.3%
  ≥$220K: 21.8%
  Missing: 5.9% (NOT SHOWN)
```

**The Error:** NULL prices excluded without documentation or user awareness

**Impact:** Analysis conclusions may be incomplete if NULL segment behaves differently

**Better Approach - Inform the User:**
```sql
-- GOOD: Explicitly handle and report NULLs
SELECT 
    CASE 
        WHEN price < 220000 THEN '<$220K'
        WHEN price >= 220000 THEN '≥$220K'
        WHEN price IS NULL THEN 'Unknown'
        ELSE 'Error'
    END as price_segment,
    COUNT(*) as leads,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) as pct
FROM leads
GROUP BY 1;

-- With informational note:
-- ℹ️ Data Quality Note: 5.9% of records have NULL price values
--    These are included as "Unknown" category
--    Median/average calculations exclude NULLs per SQL standard
```

**Response Pattern:**
```
ℹ️ Data Quality Note:
   - LEAD_LISTING_PRICE has 5.9% null values (1,234 of 20,890 records)
   - NULL values included as "Unknown" segment in breakdown
   - Median and average calculations automatically exclude NULLs
   - Analysis proceeds with 94.1% of records having price data
```

**Why Inform, Not Block:**
- User can decide if 5.9% null is acceptable
- Analysis can proceed with explicit handling
- User understands data completeness
- No unnecessary delays waiting for "perfect" data

**Lesson:** Explicitly handle NULL values and inform the user about data completeness, but allow analysis to proceed.

---

## Calculation Errors

### Pitfall 7: Wrong Percentage Change Formula

**What Happened:**
```
Analyst calculated:
  Growth = (POST/PRE - 1) * 100  -- For EACH group separately
  DiD = Test_growth% - Control_growth%
```

**The Error:** This gives 1.3% DiD effect

**Correct Formula:**
```python
# Standard DiD: Absolute differences first
Control_change = POST_control - PRE_control  # Absolute
Test_change = POST_test - PRE_test           # Absolute
DiD = Test_change - Control_change           # Absolute

# Then convert to %
DiD_pct = DiD / PRE_control * 100            # Use Control baseline
```

**This gives 1.5% DiD effect (different result!)**

**Lesson:** DiD uses absolute differences first, then percentage. Not vice versa.

---

### Pitfall 8: Denominators with Zeros

**What Happened:**
```sql
SELECT 
    campaign,
    SUM(revenue) / SUM(spend) as ROAS  -- Division by zero possible!
FROM campaigns
GROUP BY campaign;
```

**The Error:** Some campaigns have $0 spend, causing NULL or infinity

**Fix:**
```sql
SELECT 
    campaign,
    SUM(revenue) / NULLIF(SUM(spend), 0) as ROAS,
    CASE 
        WHEN SUM(spend) = 0 THEN 'No spend'
        ELSE 'OK'
    END as data_quality_flag
FROM campaigns
GROUP BY campaign;
```

**Lesson:** Always use NULLIF when dividing, especially for aggregated metrics.

---

## Aggregation Errors

### Pitfall 9: Property Type Mix Confusion

**What Happened:**
```
Initial analysis: "Land leads grew 26.48% → 25.82%"
Corrected analysis: "Land actually grew 25.82% → 26.48%"
```

**The Error:** PRE/POST labels swapped in query results

**How to Catch:**
```sql
-- Add explicit validation
SELECT 
    period,
    property_type,
    pct_of_total,
    -- Sanity check: POST should be later date
    MIN(event_date) as earliest_date,
    MAX(event_date) as latest_date
FROM analysis_results
GROUP BY period, property_type, pct_of_total
ORDER BY period, property_type;
```

**Lesson:** Include date ranges in output to validate period labels are correct.

---

### Pitfall 10: Median vs Mean for Skewed Data

**What Happened:**
```
Paid Search leads:
  Mean listing price: $284K
  Median listing price: $147K
  
Huge difference! (93% higher mean)
```

**The Problem:** Using mean for highly skewed price distributions

**When Skewness Matters:**
```python
# Check skewness
skewness = stats.skew(prices)
if skewness > 1.0:
    print("⚠️ Highly skewed - use MEDIAN")
    metric = prices.median()
else:
    print("✓ Normal distribution - mean OK")
    metric = prices.mean()
```

**Lesson:** For price data, ALWAYS use median unless you have a specific reason to use mean.

---

### Pitfall 11: Missing Vertical Filter

**What Happened:**
```
User: "Show me for sale lead counts for October"

Query:
SELECT COUNT(*) as leads
FROM submitted_lead_detail
WHERE event_date >= '2025-10-01'
  AND event_date < '2025-11-01';

Result: 125,840 leads
```

**The Error:** Query has NO vertical filter - includes for_sale, for_rent, AND seller leads

**Actual Breakdown:**
```sql
SELECT 
    submitted_lead_vertical,
    COUNT(*) as leads
FROM submitted_lead_detail
WHERE event_date >= '2025-10-01'
  AND event_date < '2025-11-01'
GROUP BY submitted_lead_vertical;

Results:
  for_sale: 89,420 leads (71%)
  for_rent: 31,285 leads (25%)  
  seller: 5,135 leads (4%)
  Total: 125,840 leads
```

**Impact:** User expected 89K for_sale leads, got 125K (all verticals)

**Correct Query:**
```sql
SELECT COUNT(*) as leads
FROM submitted_lead_detail
WHERE event_date >= '2025-10-01'
  AND event_date < '2025-11-01'
  AND submitted_lead_vertical = 'for_sale';  -- ✓ Filter added

Result: 89,420 leads (correct!)
```

**Why This Matters:**

**Metric Skewing:**
- for_sale median price: $290K
- for_rent median price: $1,800/month
- Mixing them = meaningless averages

**Business Logic:**
- Different teams own different verticals
- Performance metrics calculated differently
- Revenue models are distinct

**How to Catch:**
```python
# Validation check
def validate_vertical_filter(query, user_request):
    vertical_mentions = {
        'for_sale': ['for sale', 'buy', 'buyer', 'purchase'],
        'for_rent': ['rent', 'rental', 'lease'],
        'seller': ['seller', 'listing']
    }
    
    mentioned = None
    for vertical, keywords in vertical_mentions.items():
        if any(k in user_request.lower() for k in keywords):
            mentioned = vertical
            break
    
    if mentioned and mentioned not in query.lower():
        return f"⚠️ User mentioned {mentioned} but query has no vertical filter"
    
    return "✓ OK"
```

**Response Pattern:**
```
"I notice there's no vertical filter in this query. You mentioned 'for sale leads' - 
should this be filtered to submitted_lead_vertical = 'for_sale', or include all verticals?"
```

**Lesson:** When user mentions lead type, ALWAYS verify appropriate vertical filter is present.

---

## Validation Checklist Template

**Before Publishing Analysis:**

### Query Validation
- [ ] Date ranges match documented analysis period
- [ ] No future dates included
- [ ] All aggregations have proper GROUP BY
- [ ] Division operations use NULLIF
- [ ] NULL values explicitly handled
- [ ] Vertical filter present when user mentions lead type (for_sale/for_rent/seller)

### Data Consistency  
- [ ] Summary totals = sum of detail rows
- [ ] Percentages sum to 100%
- [ ] Median/average consistent across sections
- [ ] Same date ranges used throughout

### Period Balance (for experiments)
- [ ] Pre and post periods are comparable lengths
- [ ] Day-of-week distribution is balanced (X*7 days)
- [ ] Parallel trends assumption validated

### Cross-Source Reconciliation
- [ ] Lead counts match across related tables
- [ ] Document expected conversion rates
- [ ] Explain any discrepancies > 10%

### Statistical Validation
- [ ] Anomalies flagged and investigated
- [ ] Confidence intervals calculated
- [ ] Sensitivity analysis performed
- [ ] Results robust to period changes

---

## Recovery Patterns

**When You Find an Error:**

1. **Document the Issue**
   - What was wrong
   - How it was discovered  
   - What the correct approach is

2. **Re-run with Corrections**
   - Update all affected queries
   - Validate consistency across sections
   - Check if conclusions change

3. **Impact Assessment**
   - Which sections need updates
   - How much do numbers change
   - Do recommendations still hold

4. **Prevention**
   - Add to validation checklist
   - Create reusable validation query
   - Document in this file for future reference

---

### Pitfall 12: Expecting Median Contributions to Sum to 100%

**What Happened:**
```
Median listing price dropped 4.76%

Contribution analysis:
- Paid Search: -2.1% × 65% = -1.37pp
- SEO: -3.8% × 28% = -1.06pp
- Direct: -8.9% × 7% = -0.62pp
Sum: -3.05pp

Gap: 4.76pp - 3.05pp = 1.71pp (36% unexplained)
```

**The Misunderstanding:** Analyst expected contributions to sum to 100% like they would for mean

**Why This is Actually CORRECT:**

Median is a **non-additive metric**:
- Depends on ordering of all values, not weighted averages
- Changing one segment affects where the "middle" value falls globally
- Interaction effects between segments exist
- Composition shifts matter

**Math Explanation:**
```
For MEAN (additive):
Total Mean = (Seg1_Mean × Vol1% + Seg2_Mean × Vol2% + ...)
Contributions DO sum to 100% ✓

For MEDIAN (non-additive):
Total Median ≠ (Seg1_Median × Vol1% + Seg2_Median × Vol2% + ...)
Contributions DON'T sum to 100% - and that's OK! ✓
```

**What the Gap Represents:**
- **Interaction effects:** Segments don't change in isolation
- **Composition effects:** How volume shifted between segments
- **Ordering effects:** Which properties entered/exited the median range

**Correct Interpretation:**
```
ℹ️ Median Contribution Analysis (Approximate):

All three segments pushed median DOWN:
  1. Paid Search: Largest impact (high volume + decline)
  2. SEO: Moderate impact  
  3. Direct: Smallest impact (low volume despite large % drop)

Gap of 1.7pp represents interaction between segments.

This is directional analysis, not exact attribution.
```

**How to Handle:**

```python
# Detect if analyzing non-additive metric
if metric_type in ['median', 'percentile', 'mode']:
    note = f"""
    ℹ️ Contribution Analysis Note ({metric_type.upper()}):
       Gap is expected and represents interaction effects.
       Use contributions to understand directional impact, not exact attribution.
       Analysis proceeds - this is mathematically correct.
    """
else:  # mean, sum, count
    if gap > 5%:
        warning = f"⚠️ Contributions should sum closer to 100% for {metric_type}"
```

**When to Use What:**

| Goal | Use Mean | Use Median |
|------|----------|------------|
| Exact contribution attribution | ✓ Yes | ✗ No |
| Directional impact analysis | ✓ Yes | ✓ Yes |
| Handling skewed data | ✗ Poor | ✓ Good |
| Dollar impact (revenue) | ✓ Yes | ✗ No |
| Typical value impact | ✗ Poor | ✓ Yes |

**Lesson:** For non-additive metrics (median, percentiles), contributions are directional guides, not exact decompositions. Gap is mathematically expected - don't flag as error!

