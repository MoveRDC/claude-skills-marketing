# Amplitude Experimentation Guide

This document provides guidance on experiment analysis in Amplitude, including setup, analysis patterns, and interpretation of results.

## Overview

Amplitude Experiment is the experimentation platform that allows teams to:
- Test hypotheses with A/B tests
- Measure impact on user behavior
- Make data-driven decisions on feature rollouts

## Key Concepts

### Assignment vs Exposure Events

| Event Type | When Triggered | Use Case |
|------------|----------------|----------|
| **Assignment** | When user is assigned to variant (evaluation time) | Monitoring, debugging, server-side experiments |
| **Exposure** | When user actually sees the variant | Client-side experiments, accurate analysis |

**Critical**: Use **exposure events** for experiment analysis, not assignment events. A user can be assigned to a variant without ever seeing it.

### Local vs Remote Evaluation

| Evaluation Type | Where | Latency | Capabilities |
|-----------------|-------|---------|--------------|
| **Local** | In SDK | Fast | Basic targeting |
| **Remote** | Amplitude servers | Higher | User enrichment, cohort targeting, geo |

RDC currently uses **local evaluation** for most experiments.

---

## Experiment Analysis Workflow

### 1. Find the Experiment

Use the `search` tool to find experiments:
```
entityTypes: ["EXPERIMENT"]
query: "experiment name or key"
```

### 2. Get Experiment Details

Use `get_experiments` with the experiment ID to retrieve:
- State (running, completed, etc.)
- Variants
- Primary/secondary metrics
- Decision status

### 3. Query Experiment Results

Use `query_experiment` for statistical analysis:
```javascript
// Basic experiment query
{
  "id": "123456",  // Experiment ID
  // metricIds: omit for primary metric only
}
```

### 4. Segment Analysis (Optional)

Add groupBy for segment breakdown:
```javascript
{
  "id": "123456",
  "groupBy": [{
    "type": "user",
    "value": "platform",
    "group_type": "User"
  }]
}
```

---

## Interpreting Results

### Dashboard vs Experiment UI

| View | Shows | Good For | Limitations |
|------|-------|----------|-------------|
| **Dashboard/Chart** | Raw metrics (CTR, pageviews, leads) | Spot-checking, early monitoring | No statistical significance |
| **Experiment UI** | Statistical analysis (lift, p-value, CI) | Final decisions | Only includes exposed users |

**Important**: Raw dashboard metrics can be misleading. Always check statistical significance before making decisions.

### Statistical Metrics

| Metric | Meaning | Decision Threshold |
|--------|---------|-------------------|
| **Lift** | % change vs control | Positive = better |
| **P-Value** | Probability result is due to chance | < 0.05 = significant |
| **Confidence Interval** | Range of expected uplift | If crosses 0 = not significant |

### Reading Confidence Intervals

```
[-------|-------]     ← Crosses 0: NOT significant
         0

        [---|---]     ← Entirely above 0: POSITIVE significant
         0

[---|---]             ← Entirely below 0: NEGATIVE significant
         0
```

### Warning Symbols

**Orange Triangle (⚠️)**: Stats assumptions not met
- Extreme skew in data
- Low event frequency
- Uneven exposure distribution

---

## Segmenting by Experiment in Queries

### Method 1: User Property Segment

```javascript
{
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 14 Days",
    "events": [{"event_type": "pageview", "filters": [], "group_by": []}],
    "metric": "uniques",
    "segments": [
      {
        "name": "Control",
        "conditions": [{
          "type": "property",
          "group_type": "User",
          "prop_type": "user",
          "prop": "gp:[Experiment] experiment-key",
          "op": "is",
          "values": ["control"]
        }]
      },
      {
        "name": "Treatment",
        "conditions": [{
          "type": "property",
          "group_type": "User",
          "prop_type": "user",
          "prop": "gp:[Experiment] experiment-key",
          "op": "is",
          "values": ["treatment"]
        }]
      }
    ]
  }
}
```

### Method 2: Using Exposure Event Filter

More accurate method - only includes users who were actually exposed:

```javascript
{
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 14 Days",
    "events": [{
      "event_type": "pageview",
      "filters": [{
        "group_type": "User",
        "subprop_key": "[Experiment] Variant",
        "subprop_op": "is",
        "subprop_type": "user",
        "subprop_value": ["control", "treatment"]
      }],
      "group_by": []
    }],
    "metric": "uniques",
    "groupBy": [{"type": "user", "value": "[Experiment] Variant"}]
  }
}
```

---

## Snowflake Validation

To validate experiment metrics in Snowflake (aligned with Amplitude):

```sql
WITH experiment_group AS (
  SELECT
    COALESCE(edw_visitor_id, client_visitor_id) AS adjusted_uu_id,
    CASE
      WHEN UPPER(ab_test_id_exposure) LIKE '%EXPERIMENT_KEY:C%'  THEN 'control'
      WHEN UPPER(ab_test_id_exposure) LIKE '%EXPERIMENT_KEY:V1%' THEN 'treatment'
    END AS variation,
    MIN(event_date_utc) AS first_date_utc,
    MIN(client_sdk_timestamp) AS first_datetime
  FROM STG_RDC_CORE.CLICKSTREAM.STG_CLICKSTREAM_PRODUCT_EVENT
  WHERE event_date_utc BETWEEN '2025-01-01' AND '2025-01-31'
    AND LOWER(event_name) = 'expexposure'
    AND UPPER(ab_test_id_exposure) LIKE '%EXPERIMENT_KEY%'
  GROUP BY 1, 2
)
SELECT variation, COUNT(DISTINCT adjusted_uu_id) as users
FROM experiment_group
GROUP BY 1;
```

**Note**: As of July 2025, exposure events are sourced from `STG_RDC_CORE.CLICKSTREAM.STG_CLICKSTREAM_PRODUCT_EVENT`, not the main clickstream table.

---

## Common Experiment Metrics

### Lead Submission Rate (LSR)

```javascript
{
  "type": "funnels",
  "app": "670280",
  "params": {
    "range": "Last 14 Days",
    "events": [
      {"event_type": "_active", "filters": [], "group_by": []},
      {"event_type": "RDC Lead Submission", "filters": [], "group_by": []}
    ],
    "countGroup": "User",
    "conversionWindow": {"value": 7, "unit": "day"},
    "segments": [
      {
        "name": "Control",
        "conditions": [{
          "type": "property",
          "group_type": "User",
          "prop_type": "user",
          "prop": "gp:[Experiment] experiment-key",
          "op": "is",
          "values": ["control"]
        }]
      },
      {
        "name": "Treatment",
        "conditions": [{
          "type": "property",
          "group_type": "User",
          "prop_type": "user",
          "prop": "gp:[Experiment] experiment-key",
          "op": "is",
          "values": ["treatment"]
        }]
      }
    ]
  }
}
```

### Pageviews per User

```javascript
{
  "type": "eventsSegmentation",
  "params": {
    "events": [{"event_type": "pageview", "filters": [], "group_by": []}],
    "metric": "average",
    // ... segments by experiment variant
  }
}
```

### Click-Through Rate

```javascript
{
  "type": "funnels",
  "params": {
    "events": [
      {"event_type": "listingimpression", "filters": [], "group_by": []},
      {"event_type": "listingclick", "filters": [], "group_by": []}
    ],
    // ... segments by experiment variant
  }
}
```

---

## Session Replay for Experiments

Use `get_session_replays` to watch user behavior by variant:

```javascript
{
  "projectId": "675822",  // Real Time SDK - Prod
  "segmentFilters": [{
    "conditions": [{
      "type": "property",
      "group_type": "User",
      "prop_type": "user",
      "prop": "gp:[Experiment] experiment-key",
      "op": "is",
      "values": ["treatment"]
    }]
  }],
  "limit": 10
}
```

---

## Decision Framework

### When to End an Experiment

**Ideal**: Reach statistical significance
- Result is reliable
- Can confidently ship or kill

**Acceptable to end without stat sig**:
- No meaningful impact after sufficient time (2-4 weeks)
- Effect size too small to matter
- Need to free traffic for other tests
- Business priority changed

### Why Some Metrics Never Reach Significance

| Metric Type | Likelihood | Reason |
|-------------|------------|--------|
| CTR, Pageviews | High | Large sample, frequent events |
| LSR | Low | Rare events, high variance |
| Revenue | Medium | Depends on volume |

**Minimum Detectable Effect (MDE)**: If real effect < MDE, may never reach significance even with large samples.

---

## Best Practices

1. **Use exposure events for analysis** - Not assignment events

2. **Check for SRM** - Sample Ratio Mismatch indicates data quality issues

3. **Don't peek and decide** - Wait for significance or planned duration

4. **Consider practical significance** - A 0.1% lift may be significant but not meaningful

5. **Combine Dashboard + Experiment UI** - Use both for complete picture

6. **Document decisions** - Record why you shipped/killed each variant

7. **Allow for learning period** - First few days may have novelty effects

---

## Reference Links

- [Amplitude Experiment Docs](https://amplitude.com/docs/experiment)
- [How to Interpret Amplitude Metrics](https://moveinc.atlassian.net/wiki/spaces/DSA/pages/117893201921)
- [Validate Experiment Metrics in Snowflake](https://moveinc.atlassian.net/wiki/spaces/DSA/pages/117855553142)
- [Guide to Exposure Events](https://moveinc.atlassian.net/wiki/spaces/EXPO/pages/117609234582)
- [Quick Start Guide to Web Experimentation](https://moveinc.atlassian.net/wiki/spaces/EXPO/pages/117488615523)
