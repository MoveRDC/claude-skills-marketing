---
name: rdc-amplitude-navigator
description: Comprehensive guide to RDC's Amplitude analytics platform for product analytics, experimentation, and user behavior analysis. Use when querying clickstream data, lead submission events, experiment analysis, session replays, or funnel/retention metrics. Triggers include queries about pageviews, clicks, leads, experiments, LSR, EFR in Amplitude, or any Amplitude chart/dashboard exploration.
---

# RDC Amplitude Navigator Skill

This skill provides comprehensive knowledge of RDC's Amplitude implementation, including project structure, event taxonomy, experimentation patterns, and query strategies for marketing and product analytics.

## Quick Reference

### Project Registry

| Project ID | Name | Primary Use | Data Source |
|------------|------|-------------|-------------|
| **558383** | Realtor - Production | Source of truth clickstream + enrichment | Snowflake → S3 import (~4hr delay) |
| **675822** | Real Time SDK - Prod | Real-time traffic, Session Replay | Amplitude SDK via GTM |
| **678364** | Realtor - Leads 2.0 | Lead submission events, EFR | Snowflake lead data |
| **670280** | Leads + Clickstream 2.0 | Cross-project analysis (leads + behavior) | Combined view |
| **674963** | Consumer Marketing Data Braze | Push/notification engagement | Braze integration |
| **678109** | Consumer Marketing Data Cordial | Email engagement events | Cordial integration |
| **756754** | White Label Sites | HighRises, Homefinder traffic | Amplitude SDK |
| **717063** | Seller Leads Exploration | UpNest + seller journey analysis | Combined sources |

### Project Selection Logic

```
User behavior / clickstream analysis?
├── Need real-time data or Session Replay? → Real Time SDK - Prod (675822)
└── Need enriched source-of-truth data? → Realtor - Production (558383)

Lead analysis?
├── Lead counts, EFR, delivery flags? → Realtor - Leads 2.0 (678364)
└── Lead submission + user journey? → Leads + Clickstream 2.0 (670280)

CRM engagement?
├── Email metrics? → Consumer Marketing Data Cordial (678109)
└── Push/notification metrics? → Consumer Marketing Data Braze (674963)

Experiment analysis?
└── Use project where experiment is deployed (check flag key prefix)
```

### Core Events by Volume (30-day)

| Event | Project | 30-Day Volume | Use Case |
|-------|---------|---------------|----------|
| `[Experiment] Assignment` | Leads+CS 2.0 | 5.9B | Experiment bucketing |
| `pageview` | Leads+CS 2.0 | 1.3B | Page-level traffic |
| `[Experiment] Exposure` | Leads+CS 2.0 | 1.1B | Experiment analysis |
| `[Amplitude] Page Viewed` | Real Time SDK | 952M | Real-time traffic |
| `click` | Leads+CS 2.0 | 773M | User interactions |
| `search` | Leads+CS 2.0 | 744M | Search behavior |
| `listingimpression` | Leads+CS 2.0 | 656M | Listing visibility |
| `listingclick` | Leads+CS 2.0 | 240M | Listing engagement |
| `refinedsearch` | Leads+CS 2.0 | 123M | Search refinement |
| `RDC Lead Submission` | Leads+CS 2.0 | 1.5M | Lead conversion |

### Event Categories

| Category | Events | Purpose |
|----------|--------|---------|
| **Discovery Events** | pageview, search, promotedsrpimpression | User discovery behavior |
| **Refinement Events** | refinedsearch, saveditem, share, calculatemonthlycost | User refinement actions |
| **Conversion Events** | rentallead, cobrokelead | Lead conversions |
| **Activation Events** | signin, signup, install attributed, notificationcardselected | User activation |
| **Home Engagement Events** | Account \| Claim Home, My Home interactions | Seller/owner engagement |
| **Autocapture** | [Amplitude] Page Viewed, session_start, session_end | SDK auto-tracked |

## Workflow

When a query involves Amplitude data:

1. **Identify the analysis type:**
   - Traffic/behavior → Realtor - Production or Real Time SDK
   - Lead metrics → Realtor - Leads 2.0
   - Experiment analysis → Project where experiment deployed
   - Cross-journey analysis → Leads + Clickstream 2.0

2. **Load relevant reference docs:**
   - Event taxonomy → [references/event_taxonomy.md](references/event_taxonomy.md)
   - Lead analysis → [references/lead_analysis_patterns.md](references/lead_analysis_patterns.md)
   - Experimentation → [references/experimentation_guide.md](references/experimentation_guide.md)
   - Data architecture → [references/data_architecture.md](references/data_architecture.md)

3. **Use appropriate Amplitude tools:**
   - `search` → Find existing charts, dashboards, events, metrics
   - `query_dataset` → Ad-hoc segmentation, funnel, retention queries
   - `query_charts` → Execute existing chart definitions
   - `query_experiment` → Experiment statistical analysis
   - `get_session_replays` → Behavioral session analysis

4. **Apply correct filters and segments:**
   - Always specify `projectId` (appId) for queries
   - Use `gp:` prefix for custom user properties
   - Use experiment property format: `gp:[Experiment] flag-key`

## Critical Business Logic

### Lead Verticals (target_vertical / lead_vertical)
```
for_sale    → Buy leads
for_rent    → Rental leads  
Seller      → Sell leads (delivered_to_upnest_flag or delivered_to_seller_partner_flag)
FAR         → Find a Realtor leads
```

### Lead Delivery Flags
Key boolean properties on `RDC Lead Submission`:
- `delivered_to_connections_plus_flag` → C+ delivery
- `delivered_to_mvip_flag` → MVIP delivery
- `delivered_to_upnest_flag` → UpNest/Seller delivery
- `delivered_to_veterans_united_flag` → VU delivery
- `delivered_to_readyconnect_concierge_flag` → RCC delivery

### Marketing Channel Attribution
- `first_touch_marketing_channel` → Initial acquisition channel
- `last_touch_marketing_channel` → Converting channel
- `last_touch_marketing_channel_detail` → Granular channel detail

### Experiment Analysis
- **Assignment Event**: `[Experiment] Assignment` - when user bucketed
- **Exposure Event**: `[Experiment] Exposure` - when user actually sees variant
- **Analysis should use exposure-based cohorts** for accurate measurement
- Experiment properties: `[Experiment] Experiment Key`, `[Experiment] Variant`

### Key Identity Fields
- `visit_id` → Session identifier
- `browser_id` → Browser-level identity
- `rdc_visitor_id` → RDC visitor identity
- `consumer_visitor_id` → Consumer identity on leads
- `amp_session_id` → Amplitude session ID

## Common Query Patterns

### Daily Active Users
```javascript
// query_dataset definition
{
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 30 Days",
    "events": [{"event_type": "_active", "filters": [], "group_by": []}],
    "metric": "uniques",
    "countGroup": "User",
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

### Lead Submission by Vertical
```javascript
{
  "type": "eventsSegmentation",
  "app": "678364",
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

### Funnel: Search → Listing Click → Lead
```javascript
{
  "type": "funnels",
  "app": "670280",
  "params": {
    "range": "Last 30 Days",
    "events": [
      {"event_type": "search", "filters": [], "group_by": []},
      {"event_type": "listingclick", "filters": [], "group_by": []},
      {"event_type": "RDC Lead Submission", "filters": [], "group_by": []}
    ],
    "countGroup": "User",
    "conversionWindow": {"value": 7, "unit": "day"},
    "segments": [{"conditions": []}]
  }
}
```

### New User Retention
```javascript
{
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

### Experiment Variant Comparison
```javascript
// For experiment analysis, use query_experiment tool with experiment ID
// Or segment by experiment property:
{
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 14 Days",
    "events": [{"event_type": "pageview", "filters": [], "group_by": []}],
    "metric": "uniques",
    "countGroup": "User",
    "segments": [
      {
        "name": "Control",
        "conditions": [{
          "type": "property",
          "group_type": "User",
          "prop_type": "user",
          "prop": "gp:[Experiment] my-experiment-key",
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
          "prop": "gp:[Experiment] my-experiment-key",
          "op": "is",
          "values": ["treatment"]
        }]
      }
    ]
  }
}
```

## Data Caveats

### Data Freshness
- **Realtor - Production**: ~4 hour delay (batch processing from Snowflake)
- **Real Time SDK**: Near real-time (direct SDK)
- **Leads 2.0**: Daily refresh from LCS

### Cross-Project Analysis
- Use `Leads + Clickstream 2.0` (670280) for combined user journeys
- Cross-project funnels require events from same portfolio
- User identity may not match perfectly across projects

### Experiment Analysis Considerations
- Use **exposure events**, not assignment events, for analysis
- Statistical significance requires adequate sample size
- Dashboard metrics ≠ Experiment UI statistical readout
- Check for SRM (Sample Ratio Mismatch) before trusting results

### Property Naming
- Custom properties use `gp:` prefix in queries
- Experiment flags: `gp:[Experiment] experiment-key`
- Some properties have `_persist` suffix (session-persisted values)

## Reference Documents

- **[event_taxonomy.md](references/event_taxonomy.md)** - Complete event and property definitions
- **[lead_analysis_patterns.md](references/lead_analysis_patterns.md)** - Lead submission analysis workflows
- **[experimentation_guide.md](references/experimentation_guide.md)** - Experiment setup and analysis
- **[data_architecture.md](references/data_architecture.md)** - Data flow and architecture overview

## Tips for Effective Queries

1. **Always specify projectId** - Tools require explicit project selection
2. **Use search tool first** - Find existing charts before building ad-hoc queries
3. **Check event existence** - Use `get_event_properties` to verify event/property names
4. **Prefer existing metrics** - Use `query_metric` for standardized KPI definitions
5. **Mind data freshness** - Real-time vs batch-processed data have different latencies
6. **Use appropriate grain** - User vs Event counting changes interpretation significantly
7. **Validate with Session Replay** - Use `get_session_replays` to verify behavioral hypotheses
