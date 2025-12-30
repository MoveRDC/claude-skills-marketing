# Amplitude Query Patterns

Detailed query templates for common analysis scenarios.

## Events Segmentation Patterns

### Daily Active Users (DAU)
```python
{
  "name": "Daily Active Users",
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [{"event_type": "_active", "filters": [], "group_by": []}],
    "metric": "uniques",
    "countGroup": "User",
    "groupBy": [],
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### New Users
```python
{
  "name": "New Users Daily",
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [{"event_type": "_new", "filters": [], "group_by": []}],
    "metric": "uniques",
    "countGroup": "User",
    "groupBy": [],
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Event Count by Platform
```python
{
  "name": "Pageviews by Platform",
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [{"event_type": "pageview", "filters": [], "group_by": []}],
    "metric": "totals",
    "countGroup": "User",
    "groupBy": [{"type": "user", "value": "platform", "group_type": "User"}],
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Filtered by User Property
```python
{
  "name": "US Mobile Users",
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [{"event_type": "_active", "filters": [], "group_by": []}],
    "metric": "uniques",
    "countGroup": "User",
    "groupBy": [],
    "interval": 1,
    "segments": [{
      "conditions": [
        {"type": "property", "group_type": "User", "prop_type": "user", "prop": "country", "op": "is", "values": ["United States"]},
        {"type": "property", "group_type": "User", "prop_type": "user", "prop": "platform", "op": "is", "values": ["iOS", "Android"]}
      ]
    }]
  }
}
```

### Event with Event Property Filter
```python
{
  "name": "LDP Pageviews",
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "pageview",
      "filters": [{
        "group_type": "User",
        "subprop_key": "page_type",
        "subprop_op": "is",
        "subprop_type": "event",
        "subprop_value": ["ldp"]
      }],
      "group_by": []
    }],
    "metric": "totals",
    "countGroup": "User",
    "groupBy": [],
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Property Sum (Revenue Example)
```python
{
  "name": "Total Revenue",
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [{
      "event_type": "purchase",
      "filters": [],
      "group_by": [{"type": "event", "value": "revenue"}]
    }],
    "metric": "sums",
    "countGroup": "User",
    "groupBy": [],
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Experiment Variant Comparison
```python
{
  "name": "Leads by Experiment Variant",
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 14 Days",
    "events": [{"event_type": "cobrokelead", "filters": [], "group_by": []}],
    "metric": "uniques",
    "countGroup": "User",
    "groupBy": [{"type": "user", "value": "gp:[Experiment] MBL2510_FEATURE", "group_type": "User"}],
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

## Funnel Patterns

### Basic Lead Funnel
```python
{
  "name": "Visit to Lead Funnel",
  "type": "funnels",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {"event_type": "pageview", "filters": [], "group_by": []},
      {"event_type": "cobrokelead", "filters": [], "group_by": []}
    ],
    "countGroup": "User",
    "segments": [{"conditions": []}]
  }
}
```

### Multi-Step Funnel with Conversion Window
```python
{
  "name": "Search to Lead Funnel (7 day window)",
  "type": "funnels",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {"event_type": "search", "filters": [], "group_by": []},
      {"event_type": "listingclick", "filters": [], "group_by": []},
      {"event_type": "pageview", "filters": [{"group_type": "User", "subprop_key": "page_type", "subprop_op": "is", "subprop_type": "event", "subprop_value": ["ldp"]}], "group_by": []},
      {"event_type": "cobrokelead", "filters": [], "group_by": []}
    ],
    "conversionWindow": {"value": 7, "unit": "day"},
    "countGroup": "User",
    "segments": [{"conditions": []}]
  }
}
```

### Funnel with Platform Breakdown
```python
{
  "name": "Lead Funnel by Platform",
  "type": "funnels",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {"event_type": "pageview", "filters": [], "group_by": []},
      {"event_type": "cobrokelead", "filters": [], "group_by": []}
    ],
    "countGroup": "User",
    "groupBy": [{"type": "user", "value": "platform", "group_type": "User"}],
    "segments": [{"conditions": []}]
  }
}
```

### Any Order Funnel
```python
{
  "name": "Engagement Funnel (Any Order)",
  "type": "funnels",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {"event_type": "search", "filters": [], "group_by": []},
      {"event_type": "saveditem", "filters": [], "group_by": []},
      {"event_type": "cobrokelead", "filters": [], "group_by": []}
    ],
    "order": "any_order",
    "countGroup": "User",
    "segments": [{"conditions": []}]
  }
}
```

## Retention Patterns

### New User Daily Retention
```python
{
  "name": "New User Retention (Daily)",
  "type": "retention",
  "app": "558383",
  "params": {
    "range": "Last 90 Days",
    "startEvent": {"event_type": "_new", "filters": [], "group_by": []},
    "retentionEvents": [{"event_type": "_active", "filters": [], "group_by": []}],
    "retentionMethod": "nday",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Weekly Retention
```python
{
  "name": "Weekly Retention",
  "type": "retention",
  "app": "558383",
  "params": {
    "range": "Last 90 Days",
    "startEvent": {"event_type": "_new", "filters": [], "group_by": []},
    "retentionEvents": [{"event_type": "_active", "filters": [], "group_by": []}],
    "retentionMethod": "nday",
    "countGroup": "User",
    "interval": 7,
    "segments": [{"conditions": []}]
  }
}
```

### Rolling Retention
```python
{
  "name": "Rolling Retention (Day 7+)",
  "type": "retention",
  "app": "558383",
  "params": {
    "range": "Last 90 Days",
    "startEvent": {"event_type": "signup", "filters": [], "group_by": []},
    "retentionEvents": [{"event_type": "_active", "filters": [], "group_by": []}],
    "retentionMethod": "rolling",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Bracket Retention
```python
{
  "name": "Retention Brackets",
  "type": "retention",
  "app": "558383",
  "params": {
    "range": "Last 90 Days",
    "startEvent": {"event_type": "_new", "filters": [], "group_by": []},
    "retentionEvents": [{"event_type": "_active", "filters": [], "group_by": []}],
    "retentionMethod": "bracket",
    "retentionBrackets": [[0,1], [1,7], [7,14], [14,30], [30,60]],
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Feature-Specific Retention
```python
{
  "name": "Lead Submission Retention",
  "type": "retention",
  "app": "558383",
  "params": {
    "range": "Last 90 Days",
    "startEvent": {"event_type": "cobrokelead", "filters": [], "group_by": []},
    "retentionEvents": [{"event_type": "cobrokelead", "filters": [], "group_by": []}],
    "retentionMethod": "nday",
    "countGroup": "User",
    "interval": 7,
    "segments": [{"conditions": []}]
  }
}
```

## Session Patterns

### Average Session Length
```python
{
  "name": "Average Session Length",
  "type": "sessions",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "sessions": [{"filters": [], "group_by": []}],
    "countGroup": "User",
    "sessionType": "average",
    "segments": [{"conditions": []}]
  }
}
```

### Sessions Per User
```python
{
  "name": "Sessions Per User",
  "type": "sessions",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "sessions": [{"filters": [], "group_by": []}],
    "countGroup": "User",
    "sessionType": "peruser",
    "segments": [{"conditions": []}]
  }
}
```

### Total Sessions by Platform
```python
{
  "name": "Total Sessions by Platform",
  "type": "sessions",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "sessions": [{"filters": [], "group_by": []}],
    "countGroup": "User",
    "sessionType": "totalSessions",
    "groupBy": [{"type": "user", "value": "platform", "group_type": "User"}],
    "segments": [{"conditions": []}]
  }
}
```

## Cross-Project Patterns

### Leads Project Query
```python
{
  "name": "Lead Submissions (Leads 2.0 Project)",
  "type": "eventsSegmentation",
  "app": "678364",  // Realtor - Leads 2.0
  "params": {
    "range": "Last 30 Days",
    "events": [{"event_type": "lead_submitted", "filters": [], "group_by": []}],
    "metric": "totals",
    "countGroup": "User",
    "groupBy": [],
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Braze Email Events
```python
{
  "name": "Email Opens (Braze)",
  "type": "eventsSegmentation",
  "app": "674963",  // Consumer Marketing Data Braze
  "params": {
    "range": "Last 30 Days",
    "events": [{"event_type": "Notification Open", "filters": [], "group_by": []}],
    "metric": "totals",
    "countGroup": "User",
    "groupBy": [],
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

## Common Mistakes to Avoid

1. **Invalid interval values** - Only use -3600000, 1, 7, 30, 90
2. **Missing app ID** - Always include `"app": "558383"` or appropriate project
3. **Incorrect property prefix** - Custom properties need `gp:` prefix
4. **Wrong filter location** - Segment conditions vs event filters
5. **Missing conditions array** - Segments need `"conditions": []` even if empty
6. **Assuming event existence** - Search first to verify event names