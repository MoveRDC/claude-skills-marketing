# Lead Analysis Patterns in Amplitude

This document provides workflows and query patterns for analyzing lead data in Amplitude.

## Overview

Lead data in Amplitude comes from two primary sources:
1. **Realtor - Leads 2.0 (678364)** - Dedicated lead project with `RDC Lead Submission` event
2. **Leads + Clickstream 2.0 (670280)** - Combined view for cross-project analysis

### Why Separate Lead Data?

Just because a user submits a lead form on the app or website does not automatically make them an "RDC lead." Lead data includes:
- Online submissions via realtor.com
- Third-party lead providers
- Integrations with other platforms
- Manual/offline leads
- Phone-originated leads

The separate lead project ensures lead data is available as a Snowflake source and not limited by app/website activity.

---

## Core Lead Metrics

### Lead Count by Vertical

**Query Pattern:**
```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
  "name": "Lead Count by Vertical",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "RDC Lead Submission",
      "filters": [],
      "group_by": [{"type": "event", "value": "lead_vertical"}]
    }],
    "metric": "totals",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Lead Count by Marketing Channel

```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
  "name": "Leads by Marketing Channel",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "RDC Lead Submission",
      "filters": [],
      "group_by": [{"type": "event", "value": "last_touch_marketing_channel"}]
    }],
    "metric": "totals",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### EFR (Estimated Future Revenue) Analysis

```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
  "name": "Average EFR by Vertical",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "RDC Lead Submission",
      "filters": [],
      "group_by": [{"type": "event", "value": "estimated_future_revenue"}]
    }],
    "metric": "value_avg",
    "countGroup": "User",
    "interval": 1,
    "groupBy": [{"type": "event", "value": "lead_vertical"}],
    "segments": [{"conditions": []}]
  }
}
```

---

## Lead Delivery Analysis

### Leads by Delivery Type

Filter leads by specific delivery flags:

```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
  "name": "Connections Plus Leads",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "RDC Lead Submission",
      "filters": [{
        "group_type": "User",
        "subprop_key": "delivered_to_connections_plus_flag",
        "subprop_op": "is",
        "subprop_type": "event",
        "subprop_value": ["1"]
      }],
      "group_by": []
    }],
    "metric": "totals",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Multi-Delivery Breakdown

Compare delivery types:

```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
  "name": "Lead Delivery Breakdown",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {
        "event_type": "RDC Lead Submission",
        "filters": [{"subprop_key": "delivered_to_connections_plus_flag", "subprop_op": "is", "subprop_type": "event", "subprop_value": ["1"], "group_type": "User"}],
        "group_by": []
      },
      {
        "event_type": "RDC Lead Submission",
        "filters": [{"subprop_key": "delivered_to_mvip_flag", "subprop_op": "is", "subprop_type": "event", "subprop_value": ["1"], "group_type": "User"}],
        "group_by": []
      },
      {
        "event_type": "RDC Lead Submission",
        "filters": [{"subprop_key": "delivered_to_upnest_flag", "subprop_op": "is", "subprop_type": "event", "subprop_value": ["1"], "group_type": "User"}],
        "group_by": []
      }
    ],
    "metric": "totals",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

---

## Cross-Portfolio Analysis

### Lead Submission Rate (LSR) by Page

Using `Leads + Clickstream 2.0` for cross-project analysis:

```javascript
{
  "type": "funnels",
  "app": "670280",
  "name": "LSR by Entry Page",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {
        "event_type": "pageview",
        "filters": [],
        "group_by": [{"type": "event", "value": "visit_start_pagename"}]
      },
      {
        "event_type": "RDC Lead Submission",
        "filters": [],
        "group_by": []
      }
    ],
    "countGroup": "User",
    "conversionWindow": {"value": 30, "unit": "day"},
    "segments": [{"conditions": []}]
  }
}
```

### Verified Leads Analysis

Segment users who submitted leads and analyze their behavior:

```javascript
{
  "type": "eventsSegmentation",
  "app": "670280",
  "name": "Verified Lead User Behavior",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "pageview",
      "filters": [],
      "group_by": [{"type": "event", "value": "visit_start_pagename"}]
    }],
    "metric": "uniques",
    "countGroup": "User",
    "interval": 1,
    "segments": [{
      "name": "Users who submitted leads",
      "conditions": [{
        "type": "property",
        "group_type": "User",
        "prop_type": "user",
        "prop": "gp:lead_converted",
        "op": "is",
        "values": ["true"]
      }]
    }]
  }
}
```

---

## Lead Funnel Analysis

### Full Journey Funnel

```javascript
{
  "type": "funnels",
  "app": "670280",
  "name": "Search to Lead Funnel",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {"event_type": "search", "filters": [], "group_by": []},
      {"event_type": "listingclick", "filters": [], "group_by": []},
      {"event_type": "pageview", "filters": [{"subprop_key": "page_type", "subprop_op": "is", "subprop_type": "event", "subprop_value": ["ldp"], "group_type": "User"}], "group_by": []},
      {"event_type": "RDC Lead Submission", "filters": [], "group_by": []}
    ],
    "countGroup": "User",
    "conversionWindow": {"value": 7, "unit": "day"},
    "order": "this_order",
    "segments": [{"conditions": []}]
  }
}
```

### Funnel by Vertical

```javascript
{
  "type": "funnels",
  "app": "670280",
  "name": "Lead Funnel by Vertical",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {"event_type": "search", "filters": [], "group_by": []},
      {"event_type": "listingclick", "filters": [], "group_by": []},
      {"event_type": "RDC Lead Submission", "filters": [], "group_by": []}
    ],
    "countGroup": "User",
    "conversionWindow": {"value": 7, "unit": "day"},
    "groupBy": [{"type": "event", "value": "lead_vertical"}],
    "segments": [{"conditions": []}]
  }
}
```

---

## Lead Form Analysis

### Lead Form Abandonment

```javascript
{
  "type": "eventsSegmentation",
  "app": "670280",
  "name": "Lead Form Abandonment Rate",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {"event_type": "leadformabandon", "filters": [], "group_by": []},
      {"event_type": "RDC Lead Submission", "filters": [], "group_by": []}
    ],
    "formulas": ["TOTALS(A) / (TOTALS(A) + TOTALS(B))"],
    "metric": "formula",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Lead by Form Placement

```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
  "name": "Leads by Form Placement",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "RDC Lead Submission",
      "filters": [],
      "group_by": [{"type": "event", "value": "lead_placement"}]
    }],
    "metric": "totals",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

---

## Geographic Analysis

### Leads by State

```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
  "name": "Leads by State",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "RDC Lead Submission",
      "filters": [],
      "group_by": [{"type": "event", "value": "lead_state"}]
    }],
    "metric": "totals",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}],
    "groupByLimit": 50
  }
}
```

### Leads by City with EFR

```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
  "name": "Top Cities by Lead Volume and EFR",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "RDC Lead Submission",
      "filters": [],
      "group_by": [
        {"type": "event", "value": "lead_city"},
        {"type": "event", "value": "lead_state"}
      ]
    }],
    "metric": "totals",
    "countGroup": "User",
    "interval": -1,
    "segments": [{"conditions": []}],
    "groupByLimit": 100
  }
}
```

---

## Platform Analysis

### Leads by Platform

```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
  "name": "Leads by Platform",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "RDC Lead Submission",
      "filters": [],
      "group_by": [{"type": "event", "value": "platform"}]
    }],
    "metric": "totals",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Mobile vs Web LSR Comparison

```javascript
{
  "type": "funnels",
  "app": "670280",
  "name": "LSR by Platform",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {"event_type": "_active", "filters": [], "group_by": []},
      {"event_type": "RDC Lead Submission", "filters": [], "group_by": []}
    ],
    "countGroup": "User",
    "conversionWindow": {"value": 30, "unit": "day"},
    "segments": [
      {
        "name": "Web Users",
        "conditions": [{
          "type": "property",
          "group_type": "User",
          "prop_type": "user",
          "prop": "platform",
          "op": "is",
          "values": ["web"]
        }]
      },
      {
        "name": "iOS Users",
        "conditions": [{
          "type": "property",
          "group_type": "User",
          "prop_type": "user",
          "prop": "platform",
          "op": "is",
          "values": ["ios"]
        }]
      },
      {
        "name": "Android Users",
        "conditions": [{
          "type": "property",
          "group_type": "User",
          "prop_type": "user",
          "prop": "platform",
          "op": "is",
          "values": ["android"]
        }]
      }
    ]
  }
}
```

---

## Key Reference Charts

The following charts are referenced in Confluence documentation:

| Chart | URL | Purpose |
|-------|-----|---------|
| Lead Count Demo | https://app.amplitude.com/analytics/realtor/chart/5b6a2u1b | Basic lead counting |
| EFR Analysis | https://app.amplitude.com/analytics/realtor/chart/l2avfe0m | Revenue per lead |
| Verified Leads | https://app.amplitude.com/analytics/realtor/chart/bkpkhw1m | Lead + behavior cross-analysis |
| LSR by Vertical | https://app.amplitude.com/analytics/realtor/chart/ged9mnvp | Conversion rate by vertical |
| Demo Dashboard | https://app.amplitude.com/analytics/realtor/dashboard/iu8wst1x | Lead data overview |

---

## Best Practices

1. **Use Realtor - Leads 2.0 for pure lead metrics** - This is the source of truth for lead counts and attributes

2. **Use Leads + Clickstream 2.0 for cross-journey analysis** - When you need to combine lead data with user behavior

3. **Always filter by `lead_vertical`** - Different verticals have very different characteristics

4. **Be aware of EFR timing** - EFR is calculated with ~30 day lag; recent leads will have lower/missing EFR

5. **Consider delivery flags for revenue attribution** - Not all leads generate equal revenue; delivery type matters

6. **Use `last_touch_marketing_channel` for attribution** - This is the standard attribution model for marketing analysis
