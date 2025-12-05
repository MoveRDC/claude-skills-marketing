# Data Quality Validation Framework

Systematic validation patterns for catching data quality issues, query errors, and inconsistencies.

## Core Validation Categories

### 1. Query Correctness Validation

**Common Errors to Catch:**

**Date Range Errors:**
```sql
-- WRONG: Using future dates or wrong cutoff
WHERE event_date >= '2025-11-01'  -- But current date is Oct 2025

-- RIGHT: Verify date ranges match analysis period
WHERE event_date BETWEEN '2025-10-05' AND '2025-11-01'  -- Explicitly bounded
```

**Aggregation Errors:**
```sql
-- WRONG: Mixing different time periods
-- PRE: 4 weeks, POST: 3 weeks (unbalanced comparison)

-- RIGHT: Use consistent periods
-- PRE: 28 days (4 weeks), POST: 28 days (4 weeks)
```

**Missing GROUP BY:**
```sql
-- WRONG: Aggregating without proper grouping
SELECT period, COUNT(*) FROM data;  -- Missing GROUP BY period

-- RIGHT: Explicit grouping
SELECT period, COUNT(*) FROM data GROUP BY period;
```

**Validation Checklist:**
- [ ] Date ranges match documented analysis periods
- [ ] Pre/post periods are balanced (same # weeks)
- [ ] Aggregation levels are consistent across queries
- [ ] All calculated fields have proper formulas
- [ ] No hardcoded values that should be parameters

---

### 2. Data Consistency Validation

**Cross-Section Validation:**

Compare metrics across different sections of an analysis to ensure alignment.

```python
def validate_cross_section_consistency(data_dict):
    """
    Validate that totals in summary match detailed breakdowns
    
    Args:
        data_dict: Dict with 'summary' and 'detail' dataframes
    
    Returns:
        List of inconsistencies found
    """
    issues = []
    
    # Check if detail sums to summary
    summary_total = data_dict['summary']['leads'].sum()
    detail_total = data_dict['detail']['leads'].sum()
    
    if not np.isclose(summary_total, detail_total, rtol=0.01):
        issues.append(f"Summary total ({summary_total:,}) != Detail total ({detail_total:,})")
    
    # Check percentage calculations
    pct_sum = data_dict['detail']['pct_of_total'].sum()
    if not np.isclose(pct_sum, 100.0, atol=0.5):
        issues.append(f"Percentages sum to {pct_sum:.1f}% instead of 100%")
    
    return issues
```

**Common Inconsistencies:**
- Summary totals don't match detail sums
- Percentages don't sum to 100%
- Median/average in one section contradicts another
- Date ranges differ across sections

**Validation Pattern:**
```
1. Extract key metrics from each section
2. Calculate expected relationships (e.g., sum of parts = total)
3. Flag deviations > 1% threshold
4. Investigate root cause (usually query or filter mismatch)
```

---

### 3. Cross-Source Reconciliation

**Pattern: Comparing Same Metric Across Tables**

When the same business metric exists in multiple tables, validate consistency:

**Example: Lead Counts Across Tables**
```sql
-- Table 1: Upstream inquiry table
SELECT COUNT(*) as inquiry_count
FROM fivetran_referral.pg_public.lead_inquiry
WHERE source LIKE '%homefinder%' AND created_at >= '2025-11-01';
-- Result: 647

-- Table 2: Leads table  
SELECT COUNT(*) as lead_count
FROM fivetran_referral.pg_public.lead  
WHERE PRIMARY_INQUIRY_SOURCE LIKE '%homefinder%' AND created_at >= '2025-11-01';
-- Result: 427

-- Table 3: Revenue table
SELECT COUNT(*) as revenue_count
FROM RDC_ANALYTICS.REVENUE.REFERRAL_REVENUE
WHERE FIRST_INQUIRY_PARENT_SOURCE_NAME = 'Homefinder' 
  AND first_inquiry_created_at >= '2025-11-01';
-- Result: 362
```

**Reconciliation Analysis:**
```
INQUIRY (647) → LEAD (427) → REVENUE (362)
Conversion: 66% inquiry-to-lead, 85% lead-to-revenue, 56% overall
```

**Questions to Ask:**
1. What business logic filters each stage?
2. Are the filters documented?
3. Which table is "source of truth" for your use case?
4. Can you trace individual records across tables?

**Validation Checklist:**
- [ ] Identify all tables containing similar metrics
- [ ] Document the expected relationship (should be equal, subset, etc.)
- [ ] Calculate conversion/attrition rates between stages
- [ ] Flag unexpected drops (>20% usually indicates data issue)
- [ ] Verify join keys match across tables

---

#### 2.1 Contribution Analysis for Non-Additive Metrics

**Special validation for decomposing changes in median, percentiles, and ratios**

**The Problem:**

When decomposing non-additive metrics, contributions won't sum to 100%:

```python
# Example: Median price drop analysis
site_median_change = -4.76%

segment_contributions = {
    'Paid Search': -2.1% * 0.65 = -1.37pp,
    'SEO': -3.8% * 0.28 = -1.06pp,
    'Direct': -8.9% * 0.07 = -0.62pp
}

sum_contributions = -3.05pp
actual_change = -4.76pp
gap = 1.71pp (36% of total change)
```

**Why This Happens:**

Median depends on the **ordering** of all values, not weighted averages:
- Changing one segment affects where the "middle" value falls
- Interaction effects between segments
- Composition shifts (% in each segment)

**Validation Logic:**

```python
def validate_contribution_analysis(contributions, total_change, metric_type):
    """
    Validate contribution analysis - inform but don't block
    
    Args:
        contributions: List of segment contributions
        total_change: Actual total change
        metric_type: 'median', 'mean', 'sum', etc.
    
    Returns:
        Informational message about gap
    """
    sum_contributions = sum(contributions)
    gap = total_change - sum_contributions
    gap_pct = abs(gap / total_change * 100) if total_change != 0 else 0
    
    # Classify metric type
    non_additive = ['median', 'percentile', 'p25', 'p50', 'p75', 'p90', 
                    'mode', 'max', 'min', 'ratio', 'roas', 'geometric_mean']
    
    additive = ['mean', 'average', 'avg', 'sum', 'count', 'total']
    
    metric_lower = metric_type.lower()
    
    # Determine if non-additive
    is_non_additive = any(m in metric_lower for m in non_additive)
    is_additive = any(m in metric_lower for m in additive)
    
    if is_non_additive:
        return {
            'type': 'informational',
            'status': 'expected_gap',
            'message': f"""
ℹ️ Contribution Analysis Note ({metric_type.upper()} decomposition):
   - Sum of segment contributions: {sum_contributions:.2f}pp
   - Actual total change: {total_change:.2f}pp
   - Gap: {gap:.2f}pp ({gap_pct:.0f}% of total)
   
This gap is EXPECTED and CORRECT for {metric_type} analysis.
   
Why {metric_type} contributions don't sum exactly:
   • {metric_type.title()} is a non-additive metric
   • Cannot be decomposed as simple weighted sums
   • Gap represents interaction and composition effects
   • Ordering of values matters, not just segment averages
   
What this means:
   • Contributions show directional impact (which pushed it up/down)
   • Magnitudes are approximate attributions
   • All segments with negative contributions pushed metric down
   • Segment with largest |contribution| had biggest directional impact
   
This is mathematically correct. Analysis proceeds.
            """
        }
    
    elif is_additive and gap_pct < 5:
        return {
            'type': 'informational',
            'status': 'ok',
            'message': f"""
✓ Contribution Analysis Validated ({metric_type.upper()}):
   - Sum of contributions: {sum_contributions:.2f}
   - Actual total: {total_change:.2f}
   - Gap: {gap:.2f} ({gap_pct:.1f}% - within tolerance)
   
For {metric_type}, contributions appropriately sum to total.
            """
        }
    
    elif is_additive and gap_pct >= 5:
        return {
            'type': 'informational',
            'status': 'check_needed',
            'message': f"""
ℹ️ Contribution Analysis Note ({metric_type.upper()}):
   - Sum of contributions: {sum_contributions:.2f}
   - Actual total: {total_change:.2f}
   - Gap: {gap:.2f} ({gap_pct:.1f}%)
   
For {metric_type} (additive metric), contributions should sum closer to total.
   
Possible causes:
   • Missing segments not included in breakdown
   • Different time periods for segments vs total
   • Rounding in intermediate calculations
   • Check if all categories are represented
   
Recommendation: Verify all segments included and time periods match.
Analysis proceeds but breakdown may be incomplete.
            """
        }
    
    else:
        # Unknown metric type - be cautious
        return {
            'type': 'informational',
            'status': 'unknown_metric',
            'message': f"""
ℹ️ Contribution Analysis Note:
   - Sum of contributions: {sum_contributions:.2f}
   - Actual total: {total_change:.2f}
   - Gap: {gap:.2f} ({gap_pct:.1f}%)
   - Metric type: {metric_type}
   
Gap analysis depends on whether {metric_type} is additive.
Analysis proceeds - verify if gap is expected for this metric.
            """
        }
```

**SQL Pattern for Gap Analysis:**

```sql
-- Calculate contributions and gap for median decomposition
WITH segment_changes AS (
    SELECT 
        segment,
        MEDIAN(price) as median_price,
        COUNT(*) as volume,
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as volume_pct
    FROM leads
    GROUP BY segment
),
total_change AS (
    SELECT 
        pre.overall_median as pre_median,
        post.overall_median as post_median,
        (post.overall_median - pre.overall_median) / pre.overall_median * 100 as pct_change
    FROM pre_period_summary pre
    CROSS JOIN post_period_summary post
),
contribution_calc AS (
    SELECT 
        segment,
        median_price,
        volume_pct,
        -- Approximate contribution (directional)
        (median_pct_change * volume_pct / 100) as contribution_pp
    FROM segment_changes
)
SELECT 
    *,
    SUM(contribution_pp) OVER () as sum_contributions,
    (SELECT pct_change FROM total_change) as actual_change,
    (SELECT pct_change FROM total_change) - SUM(contribution_pp) OVER () as gap
FROM contribution_calc;

-- Add informational note:
-- "Gap is expected for MEDIAN decomposition - represents interaction effects"
```


### 4. Null/Missing Value Detection

**Purpose: Inform, Not Block**

Check for null values in critical fields and inform the user so they're aware. The analysis should proceed, but the user should understand data completeness.

**Critical Field Validation:**

```sql
-- Template for checking nulls in critical fields
SELECT 
    'FIELD_NAME' as field,
    COUNT(*) as total_records,
    SUM(CASE WHEN FIELD_NAME IS NULL THEN 1 ELSE 0 END) as null_count,
    ROUND(100.0 * SUM(CASE WHEN FIELD_NAME IS NULL) / COUNT(*), 1) as null_pct,
    MIN(FIELD_NAME) as min_value,
    MAX(FIELD_NAME) as max_value
FROM table_name
WHERE date_field >= 'start_date';
```

**Reporting Thresholds (Informational):**

| Field Type | Note to User When | Message Type |
|------------|-------------------|--------------|
| Primary Keys | >0% null | ℹ️ Data Quality Note |
| Foreign Keys | >5% null | ℹ️ Potential Join Issue |
| Price/Revenue | >10% null | ℹ️ May Impact Averages |
| Optional attributes | >50% null | ℹ️ Limited Data Available |

**Response Templates:**

**For moderate null percentages:**
```
ℹ️ Data Quality Note: 
   - LEAD_LISTING_PRICE has 8.3% null values (847 of 10,234 records)
   - This may slightly affect median/average calculations
   - Analysis will proceed with available data
```

**For high null percentages:**
```
ℹ️ Data Quality Note:
   - CAMPAIGN_NAME has 23% null values (2,340 of 10,234 records)
   - Consider if "Unknown Campaign" category should be created
   - Excluding nulls may skew results toward known campaigns
   - Analysis will proceed but results may not be fully representative
```

**For critical ID fields:**
```
ℹ️ Data Quality Note:
   - PRIMARY_KEY has 0.1% null values (12 records)
   - These records may cause issues in joins or grouping
   - Consider excluding these records or investigating source
   - Analysis will proceed with available data
```

**Missing Date Detection:**
```sql
-- Check for gaps in daily data
WITH date_spine AS (
    SELECT DATE_TRUNC('day', DATEADD(day, seq4(), 'start_date')) as expected_date
    FROM TABLE(GENERATOR(ROWCOUNT => 90))  -- 90 days
),
actual_dates AS (
    SELECT DISTINCT event_date FROM your_table
)
SELECT expected_date
FROM date_spine
WHERE expected_date NOT IN (SELECT event_date FROM actual_dates);
```

**If missing dates found:**
```
ℹ️ Data Quality Note:
   - 3 dates missing from expected range: [2025-10-15, 2025-10-22, 2025-10-29]
   - This may indicate data collection gaps or weekday/weekend patterns
   - Averages and totals may be slightly affected
   - Analysis will proceed with available dates
```

**Key Principle:**

**Don't stop the analysis, but inform the user:**
- What percentage of data is null
- Which fields are affected
- How this might impact results
- That analysis is proceeding with available data

**Let the user decide** if null levels are acceptable or if they need to address data quality issues.

---

### 5. Date Range & Period Validation

**Balanced Period Validation for Experiments:**

Critical for A/B tests with day-of-week patterns:

```python
def validate_balanced_periods(df, date_col, period_col):
    """
    Validate that pre/post periods have balanced weeks (X*7 days)
    
    Args:
        df: DataFrame with dates and period labels
        date_col: Column name with dates
        period_col: Column name with 'pre'/'post' labels
    
    Returns:
        Dict with validation results
    """
    results = {}
    
    for period in df[period_col].unique():
        period_df = df[df[period_col] == period]
        
        # Count total days
        n_days = len(period_df)
        n_weeks = n_days / 7
        is_balanced = (n_days % 7 == 0)
        
        # Count each day of week
        dow_counts = period_df[date_col].dt.day_name().value_counts()
        
        results[period] = {
            'n_days': n_days,
            'n_weeks': n_weeks,
            'is_balanced': is_balanced,
            'dow_counts': dow_counts.to_dict(),
            'issue': None if is_balanced else f"Period has {n_days} days ({n_weeks:.1f} weeks), not balanced"
        }
    
    return results
```

**Example Validation Output:**
```
PRE Period: 28 days (4.0 weeks) ✓ BALANCED
  Mon: 4, Tue: 4, Wed: 4, Thu: 4, Fri: 4, Sat: 4, Sun: 4

POST Period: 23 days (3.3 weeks) ✗ UNBALANCED  
  Mon: 4, Tue: 4, Wed: 3, Thu: 3, Fri: 3, Sat: 3, Sun: 3
  ⚠️ Issue: Weekday bias - 4 Mondays/Tuesdays but only 3 of other days
```

**Fix Strategy:**
```
Option 1: Extend to 28 days (4 weeks)
Option 2: Truncate to 21 days (3 weeks)  
Option 3: Use normalized daily averages (less ideal)
```

---

### 6. Anomaly Detection

**Statistical Outlier Detection:**

```python
from scipy import stats
import numpy as np

def detect_statistical_anomalies(series, threshold=3, window=None):
    """
    Detect anomalies using z-score method
    
    Args:
        series: Pandas Series to analyze
        threshold: Z-score threshold (default 3 = 99.7th percentile)
        window: Rolling window size for dynamic thresholding (optional)
    
    Returns:
        DataFrame with anomalies flagged
    """
    if window:
        # Rolling z-score for time series
        rolling_mean = series.rolling(window).mean()
        rolling_std = series.rolling(window).std()
        z_scores = (series - rolling_mean) / rolling_std
    else:
        # Global z-score
        z_scores = np.abs(stats.zscore(series.dropna()))
    
    anomalies = pd.DataFrame({
        'value': series,
        'z_score': z_scores,
        'is_anomaly': np.abs(z_scores) > threshold,
        'severity': pd.cut(np.abs(z_scores), 
                          bins=[0, 2, 3, 4, float('inf')],
                          labels=['normal', 'mild', 'moderate', 'severe'])
    })
    
    return anomalies
```

**Common Anomaly Patterns:**

**Spend Anomalies:**
- Daily spend > 3σ from 30-day mean
- Sudden drop to $0 (tracking issue)
- Spike > 2x typical (budget overspend)

**Lead Volume Anomalies:**
- Day-over-day change > 50%
- Week-over-week change > 30%
- Sustained zero leads in active markets

**Performance Anomalies:**
- ROAS suddenly doubles (tracking delay)
- Conversion rate drops below 50% of baseline
- CPL increases > 100% without spend change

**Validation Query Template:**
```sql
WITH daily_metrics AS (
    SELECT 
        event_date,
        SUM(spend) as daily_spend,
        COUNT(leads) as daily_leads
    FROM your_table
    GROUP BY event_date
),
stats AS (
    SELECT 
        AVG(daily_spend) as mean_spend,
        STDDEV(daily_spend) as std_spend
    FROM daily_metrics
)
SELECT 
    dm.*,
    s.mean_spend,
    s.std_spend,
    (dm.daily_spend - s.mean_spend) / s.std_spend as z_score,
    CASE 
        WHEN ABS((dm.daily_spend - s.mean_spend) / s.std_spend) > 3 
        THEN 'ANOMALY'
        ELSE 'NORMAL'
    END as flag
FROM daily_metrics dm
CROSS JOIN stats s
WHERE z_score > 3 OR z_score < -3;
```

---

### 7. Vertical Filter Validation

**Critical for Real Estate Lead Analysis:**

Real estate data typically has multiple verticals (for_sale, for_rent, seller). When users mention specific lead types, always verify the appropriate vertical filter is applied.

**Trigger Phrases:**

| User Says | Should Check For |
|-----------|------------------|
| "for sale leads" or "buy leads" | `vertical = 'for_sale'` or `submitted_lead_vertical = 'for_sale'` |
| "rental leads" or "for rent" | `vertical = 'for_rent'` |
| "seller leads" | `vertical = 'seller'` or seller-specific filters |
| "buyer leads" | Usually `for_sale` vertical |

**Common Column Names:**
- `vertical`
- `submitted_lead_vertical`
- `lead_vertical`
- `LEAD_VERTICAL`
- `SUBMITTED_LEAD_VERTICAL`

**Validation Process:**

```python
def check_vertical_filter(query_text, user_request):
    """
    Validate that queries have appropriate vertical filters
    when user mentions specific lead types
    """
    # Extract mentioned lead types
    lead_type_mentions = {
        'for_sale': ['for sale', 'buy leads', 'buyer leads', 'purchase'],
        'for_rent': ['for rent', 'rental', 'rent leads'],
        'seller': ['seller', 'listing leads']
    }
    
    mentioned_verticals = []
    for vertical, keywords in lead_type_mentions.items():
        if any(keyword in user_request.lower() for keyword in keywords):
            mentioned_verticals.append(vertical)
    
    if not mentioned_verticals:
        return None  # No vertical mentioned, skip check
    
    # Check if query has vertical filter
    has_vertical_filter = any([
        'vertical' in query_text.lower(),
        'submitted_lead_vertical' in query_text.lower(),
        'lead_vertical' in query_text.lower()
    ])
    
    if not has_vertical_filter:
        return {
            'issue': 'missing_vertical_filter',
            'mentioned': mentioned_verticals,
            'action': 'confirm_with_user'
        }
    
    # Verify correct vertical in filter
    for vertical in mentioned_verticals:
        if f"'{vertical}'" not in query_text.lower():
            return {
                'issue': 'wrong_vertical',
                'expected': vertical,
                'action': 'ask_user_to_verify'
            }
    
    return {'status': 'valid'}
```

**Example Validations:**

**✓ CORRECT: User mentions for_sale, filter present**
```
User: "Get me for sale lead counts"

Query:
SELECT COUNT(*) as leads
FROM submitted_lead_detail
WHERE event_date >= '2025-10-01'
  AND submitted_lead_vertical = 'for_sale';  -- ✓ Filter matches request
```

**✗ INCORRECT: User mentions for_sale, no filter**
```
User: "Analyze buy lead performance"

Query:
SELECT COUNT(*) as leads
FROM submitted_lead_detail
WHERE event_date >= '2025-10-01';  -- ❌ No vertical filter!

Action: Ask user "Should this be limited to for_sale leads only?"
```

**✗ INCORRECT: Filter doesn't match mention**
```
User: "Show me rental lead trends"

Query:
SELECT COUNT(*) as leads
FROM leads
WHERE date >= '2025-10-01'
  AND vertical = 'for_sale';  -- ❌ User said rental, query has for_sale

Action: "You mentioned rental leads, but query filters to for_sale. Should this be for_rent instead?"
```

**⚠️ AMBIGUOUS: Multiple verticals possible**
```
User: "Get total lead counts"

Query:
SELECT COUNT(*) as leads
FROM leads
WHERE date >= '2025-10-01';  -- No vertical filter

Action: "Should this include all verticals (for_sale, for_rent, seller) or just specific ones?"
```

**Response Templates:**

**When vertical filter is missing:**
```
I notice there's no vertical filter in this query. You mentioned [for sale/rental/seller] leads - 
should this be filtered to [vertical = 'for_sale'/for_rent/seller], or should it include all verticals?
```

**When vertical filter doesn't match:**
```
The query filters to vertical = '[X]', but you mentioned [Y] leads. 
Should the filter be changed to vertical = '[Y]'?
```

**When confirming all verticals:**
```
This query doesn't filter by vertical, so it will include for_sale, for_rent, and seller leads. 
Is that what you intended?
```

**Why This Matters:**

**Performance Differences:**
- for_sale median price: ~$300K
- for_rent median price: ~$2K/month
- Mixing them skews all price-based metrics

**Volume Differences:**
- for_sale typically 60-70% of volume
- for_rent typically 25-35% of volume
- Missing filter = including unintended data

**Business Logic:**
- Different teams own different verticals
- Metrics calculated differently (sale price vs monthly rent)
- Conversion rates vary significantly

**Common Tables with Vertical Columns:**
```sql
-- Submitted Lead Detail
SELECT * FROM rdc_analytics.leads.submitted_lead_detail
WHERE submitted_lead_vertical = 'for_sale';

-- Marketing Conversion Detail
SELECT * FROM rdc_analytics.revenue.marketing_conversion_detail_v2
WHERE submitted_lead_vertical = 'for_sale';

-- Lead Inquiry (uses category instead)
SELECT * FROM fivetran_referral.pg_public.lead_inquiry
WHERE inquiry_client_category = 'buyer';  -- for_sale equivalent
```

**Edge Cases:**

**Multi-vertical Analysis:**
```sql
-- OK: Explicitly comparing verticals
SELECT 
    vertical,
    COUNT(*) as leads
FROM leads
GROUP BY vertical;
```

**Buyer = for_sale:**
```
User says: "buyer leads"
Equivalent to: vertical = 'for_sale'
```

**Seller can mean two things:**
```
1. Seller vertical (people listing properties)
2. Sellers in for_sale vertical (buyers purchasing from sellers)

Always clarify with user!
```

---

## Validation Workflow

**Standard Process:**

1. **Before Analysis:**
   - [ ] Validate date ranges match analysis definition
   - [ ] Check for null/missing values in critical fields
   - [ ] Verify balanced periods for experiments
   - [ ] Test parallel trends for causal analyses

2. **During Analysis:**
   - [ ] Cross-check totals against detail sums
   - [ ] Flag anomalies in key metrics
   - [ ] Validate percentages sum to 100%
   - [ ] Compare results to expected ranges

3. **After Analysis:**
   - [ ] Reconcile metrics across different tables/sources
   - [ ] Document any data quality issues found
   - [ ] Flag queries that need correction
   - [ ] Create summary of validation findings

---

## Common Validation Mistakes

**❌ Don't Do:**
1. Skip validation when results "look right"
2. Assume totals are correct without checking sums
3. Ignore small percentage discrepancies (<1%)
4. Compare unbalanced time periods
5. Trust single data source without cross-validation

**✅ Do:**
1. Always validate critical fields for nulls
2. Check cross-section consistency in every analysis
3. Document expected vs actual results
4. Investigate even small anomalies (they often indicate bigger issues)
5. Build validation into your standard workflow

---

### 8. Metric Calculation Validation

**Purpose: Ensure appropriate metric selection for data distribution**

When users calculate averages, rates, or percentages, validate that the metric choice matches the data characteristics.

**Skewness Detection & Median vs Mean:**

```python
from scipy import stats
import numpy as np

def validate_metric_choice(data, metric_type='mean'):
    """
    Recommend median vs mean based on distribution
    
    Args:
        data: Array of values (e.g., prices, revenues)
        metric_type: What user is calculating ('mean' or 'median')
    
    Returns:
        Dict with recommendation and reasoning
    """
    # Calculate skewness
    skewness = stats.skew(data)
    
    # Calculate both metrics
    mean_val = np.mean(data)
    median_val = np.median(data)
    
    # Check for outliers
    q1 = np.percentile(data, 25)
    q3 = np.percentile(data, 75)
    iqr = q3 - q1
    outliers = data[(data < q1 - 1.5*iqr) | (data > q3 + 1.5*iqr)]
    outlier_pct = len(outliers) / len(data) * 100
    
    # Determine if skewed
    is_skewed = abs(skewness) > 1.0
    has_outliers = outlier_pct > 5
    
    if is_skewed and metric_type == 'mean':
        return {
            'issue': 'inappropriate_metric',
            'skewness': skewness,
            'mean': mean_val,
            'median': median_val,
            'outlier_pct': outlier_pct,
            'recommendation': f"""
ℹ️ Metric Selection Note:
   - Skewness: {skewness:.2f} (|skew| > 1.0 = highly skewed)
   - Mean: ${mean_val:,.0f}
   - Median: ${median_val:,.0f}
   - Difference: {abs(mean_val - median_val) / median_val * 100:.1f}%
   - {outlier_pct:.1f}% of values are outliers

Recommendation: Consider using MEDIAN instead of MEAN
   - Skewed distributions: Median represents "typical" value better
   - Mean is heavily influenced by extreme values
   - For price data, almost always use median
   
Analysis proceeds with current metric.
            """
        }
    
    return {
        'status': 'ok',
        'skewness': skewness,
        'message': f'✓ Metric choice appropriate (skewness: {skewness:.2f})'
    }
```

**Rate Normalization Validation:**

```python
def validate_rate_comparison(numerator_1, denominator_1, time_unit_1,
                            numerator_2, denominator_2, time_unit_2):
    """
    Validate that rates are compared at same time scale
    
    Example:
        PRE: 102,085 leads / 28 days
        POST: 85,953 leads / 21 days
        → Need to normalize to same unit
    """
    # Detect if different time scales
    if denominator_1 != denominator_2:
        # Calculate daily rates
        rate_1_daily = numerator_1 / denominator_1
        rate_2_daily = numerator_2 / denominator_2
        
        return {
            'issue': 'unnormalized_rates',
            'rate_1': f"{numerator_1:,} / {denominator_1} {time_unit_1}",
            'rate_2': f"{numerator_2:,} / {denominator_2} {time_unit_2}",
            'rate_1_daily': rate_1_daily,
            'rate_2_daily': rate_2_daily,
            'pct_change': (rate_2_daily - rate_1_daily) / rate_1_daily * 100,
            'recommendation': f"""
ℹ️ Rate Comparison Note:
   - Period 1: {numerator_1:,} over {denominator_1} {time_unit_1}
   - Period 2: {numerator_2:,} over {denominator_2} {time_unit_2}
   
Without normalization: Period 2 appears lower ({numerator_2:,} < {numerator_1:,})
   
Normalized (per day):
   - Period 1: {rate_1_daily:,.1f} per day
   - Period 2: {rate_2_daily:,.1f} per day
   - Change: {(rate_2_daily - rate_1_daily) / rate_1_daily * 100:+.1f}%
   
Recommendation: Always normalize to same time unit before comparing.
Analysis proceeds - user can decide to normalize.
            """
        }
    
    return {'status': 'ok', 'message': '✓ Rates at same time scale'}
```

**SQL Pattern for Skewness Check:**

```sql
-- Quick skewness check in Snowflake
WITH stats AS (
    SELECT 
        AVG(price) as mean_price,
        MEDIAN(price) as median_price,
        STDDEV(price) as std_price,
        COUNT(*) as n
    FROM leads
),
skewness_calc AS (
    SELECT 
        s.mean_price,
        s.median_price,
        s.std_price,
        -- Simplified skewness check
        CASE 
            WHEN ABS(s.mean_price - s.median_price) / s.std_price > 0.5 
            THEN 'SKEWED - Use Median'
            ELSE 'NORMAL - Mean OK'
        END as distribution_type,
        (s.mean_price - s.median_price) / s.median_price * 100 as pct_diff
    FROM stats s
)
SELECT 
    mean_price,
    median_price,
    pct_diff,
    distribution_type
FROM skewness_calc;
```

---

### 9. Aggregation Grain Validation

**Purpose: Ensure metrics aggregate at the correct entity level**

When tables have multiple records per entity, validate that aggregations happen at the intended grain.

**Duplicate Record Detection:**

```python
def validate_aggregation_grain(df, entity_id_col, metric_col):
    """
    Check if multiple records per entity affect metrics
    
    Args:
        df: DataFrame with data
        entity_id_col: Column identifying unique entities (e.g., 'inquiry_id')
        metric_col: Column being aggregated (e.g., 'efr')
    
    Returns:
        Dict with grain analysis and recommendation
    """
    total_records = len(df)
    unique_entities = df[entity_id_col].nunique()
    duplication_ratio = total_records / unique_entities
    
    # Calculate metric both ways
    per_record_metric = df[metric_col].mean()
    per_entity_metric = df.groupby(entity_id_col)[metric_col].max().mean()
    
    pct_difference = abs(per_record_metric - per_entity_metric) / per_entity_metric * 100
    
    if duplication_ratio > 1.2 and pct_difference > 10:
        return {
            'issue': 'aggregation_grain_mismatch',
            'total_records': total_records,
            'unique_entities': unique_entities,
            'duplication_ratio': duplication_ratio,
            'per_record_metric': per_record_metric,
            'per_entity_metric': per_entity_metric,
            'pct_difference': pct_difference,
            'recommendation': f"""
ℹ️ Aggregation Grain Note:
   - Total records: {total_records:,}
   - Unique entities: {unique_entities:,}
   - Duplication ratio: {duplication_ratio:.1f}x
   
Metric calculated two ways:
   - Per-record average: ${per_record_metric:,.2f}
   - Per-entity average: ${per_entity_metric:,.2f}
   - Difference: {pct_difference:.1f}%
   
Problem: Multiple records per {entity_id_col} are affecting the average
   
Recommendation: Consider aggregating to entity level first:
   SELECT {entity_id_col}, MAX({metric_col}) as {metric_col}
   FROM table
   GROUP BY {entity_id_col}
   Then calculate average on that result
   
Analysis proceeds - user can decide if regrouping needed.
            """
        }
    
    return {
        'status': 'ok',
        'duplication_ratio': duplication_ratio,
        'message': f'✓ Aggregation grain appropriate ({duplication_ratio:.1f}x duplication)'
    }
```

**SQL Pattern for Grain Check:**

```sql
-- Check for duplicate records affecting metrics
WITH record_counts AS (
    SELECT 
        COUNT(*) as total_records,
        COUNT(DISTINCT inquiry_id) as unique_inquiries,
        COUNT(*) / NULLIF(COUNT(DISTINCT inquiry_id), 0) as duplication_ratio
    FROM your_table
),
metric_comparison AS (
    SELECT 
        -- Per-record calculation (may be WRONG if duplicates)
        AVG(efr) as per_record_avg,
        
        -- Per-entity calculation (CORRECT)
        (SELECT AVG(max_efr) 
         FROM (
             SELECT inquiry_id, MAX(efr) as max_efr
             FROM your_table
             GROUP BY inquiry_id
         )) as per_entity_avg
    FROM your_table
)
SELECT 
    rc.total_records,
    rc.unique_inquiries,
    rc.duplication_ratio,
    mc.per_record_avg,
    mc.per_entity_avg,
    ABS(mc.per_record_avg - mc.per_entity_avg) / mc.per_entity_avg * 100 as pct_difference,
    CASE 
        WHEN rc.duplication_ratio > 1.2 
         AND ABS(mc.per_record_avg - mc.per_entity_avg) / mc.per_entity_avg > 0.1
        THEN 'ℹ️ GRAIN ISSUE: Multiple records per entity affecting metrics'
        ELSE '✓ OK'
    END as validation_status
FROM record_counts rc
CROSS JOIN metric_comparison mc;
```

**Correct Aggregation Patterns:**

```sql
-- Pattern 1: Group to entity level first
WITH entity_level AS (
    SELECT 
        inquiry_id,
        MAX(efr) as efr,  -- Or SUM/MIN depending on logic
        MAX(created_at) as created_at
    FROM multi_record_table
    GROUP BY inquiry_id
)
SELECT 
    AVG(efr) as avg_efr,
    MEDIAN(efr) as median_efr
FROM entity_level;

-- Pattern 2: Use DISTINCT when appropriate
SELECT 
    campaign,
    COUNT(DISTINCT inquiry_id) as unique_inquiries,  -- Not COUNT(*)
    SUM(DISTINCT efr) as total_efr  -- If EFR same for all records
FROM multi_record_table
GROUP BY campaign;

-- Pattern 3: Use window functions with QUALIFY
SELECT *
FROM multi_record_table
QUALIFY ROW_NUMBER() OVER (PARTITION BY inquiry_id ORDER BY created_at DESC) = 1;
```

