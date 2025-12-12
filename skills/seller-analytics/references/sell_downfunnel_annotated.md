# sell_downfunnel View - Annotated Definition

## Overview

The `sell_downfunnel` view tracks lead progression through the UpNest conversion funnel, from initial submission through agent matching, interview, award, and transaction close.

**Location**: `rdc_marketing.seller.sell_downfunnel`  
**Grain**: request_id + transaction_type  
**Refresh**: Daily

## Source Tables

| Table | Schema | Purpose |
|-------|--------|---------|
| `qrequest` | `fivetran_martech.upnest_maria_realtor` | Sell request lead data |
| `brequest` | `fivetran_martech.upnest_maria_realtor` | Buy request lead data |
| `event` | `fivetran_martech.upnest_maria_realtor` | Lead lifecycle events |
| `eventtype` | `fivetran_martech.upnest_maria_realtor` | Event type definitions |
| `calltracking` | `fivetran_martech.upnest_maria_realtor` | Outbound call records |

## Funnel Stage Definitions

### Stage Hierarchy (Ordered)

| Code | Stage | Description |
|------|-------|-------------|
| `N/A: Draft` | Incomplete submission | status = 0 |
| `N/A: Duplicate` | Duplicate lead | status = 5 |
| `0: Deleted` | Deleted record | status = -1 |
| `0: Unknown` | Unknown status | status < -1 |
| `0: No Phone` | No phone number | status = 14 |
| `0: User Canceled` | User canceled | status = 11 |
| `0: Postponed` | Postponed | postponedDate not null |
| `0: Rejected` | Rejected by system | status = 4 OR assignedAdmin = 1466 |
| `1: Lead` | New lead | Default (no other condition met) |
| `2: Invited` | Agents invited | firstInvitedDate OR status = 6 |
| `3: Received` | Quote received | firstQuoteDate not null |
| `4: Pre-Interview` | Interview scheduled | firstInterviewDate/firstScheduledInterviewDate OR status = 7 |
| `5: Post-Interview` | Interview completed | firstConfirmInterviewDate OR have_met = 1 |
| `6: Unconfirmed Awarded` | Tentative award | status = 8 |
| `7: Awarded` | Agent awarded | awardedDate not null |
| `8: Listed` | Property listed | listDate OR status = 9 (sell only) |
| `9: Pending` | Under contract | soldFlipDate/pendingDate OR status = 10/13 |
| `a: Sold/Bought` | Transaction closed | soldFlipDate + status = 10 |
| `b: Collected` | Revenue collected | collectedDate OR collectedAmount > 0 |

### Two Stage Perspectives

The view provides two stage fields:

**`furthest_stage`**: Maximum stage ever reached
- Considers `statusBeforeReject` to capture historical progress
- Use for funnel analysis and conversion rates

**`current_stage`**: Current status
- Reflects current state (rejections can regress stage)
- Use for pipeline/inventory analysis

## Page Classification (Lead Source)

Derives lead source from `flow` and `base_url` fields:

```sql
CASE
  -- Legacy/direct UpNest
  WHEN created_on < '2022-07-01' OR brand = 'UPNEST' THEN 'upnest_direct'
  
  -- Flow-based classification
  WHEN LOWER(flow) LIKE 'get_matched%' THEN 'sell'
  WHEN flow IN ('SELLERS_MARKETPLACE', 'SM_YMAL', 'SM_RESULTS_AGENT_CONNECT') THEN 'sm'
  WHEN flow IN ('MY_HOME', 'my_home_dashboard') THEN 'myhome'
  WHEN LOWER(flow) LIKE 'pdp%' THEN 'pdp'
  WHEN LOWER(flow) LIKE 'rsp%' THEN 'rsp'
  WHEN flow = 'RDC_SELL_RFP' THEN 'rdc_sell_rfp'
  
  -- URL-based fallbacks
  WHEN base_url = 'https://www.upnest.com/re/' THEN 'upnest_direct'
  WHEN base_url = 'https://sell.realtor.com/re/' THEN 'rdc_sell_rfp'
  
  ELSE LOWER(flow)
END AS page
```

### Page Values

| Page | Description |
|------|-------------|
| `upnest_direct` | Direct UpNest.com traffic |
| `sell` | Get Matched flow |
| `sm` | Sellers Marketplace |
| `myhome` | My Home dashboard |
| `pdp` | Property Detail Page |
| `rsp` | Results/Search Page |
| `rdc_sell_rfp` | Realtor.com Sell RFP |

## Quality Flags

### Fake/Fraud Detection

```sql
is_fake = (assignedAdmin = 1466 OR rejectReason = 'Fake Request: Email bounce')
is_fraud = (rejectReason = 'Fraud')
is_fake_or_fraud = is_fake OR is_fraud
```

**Admin 1466**: Special admin ID used to flag fake/test leads.

### Rejection Flag

```sql
rejected = (status = 4 OR assignedAdmin = 1466)
```

## Call Tracking Metrics

Uses the longest outbound call per lead (from `calltracking` table):

```sql
-- Qualify to get longest call per lead
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY requestid 
  ORDER BY callduration DESC NULLS LAST
) = 1
```

### Call Success Flags

| Field | Definition | Threshold |
|-------|------------|-----------|
| `call_1d_1min` | Outbound call ≥60s within 1 day | Speed + duration |
| `call_6d_1min` | Outbound call ≥60s within 6 days | Duration |
| `call_2d_2min` | Outbound call >120s within 2 days | Quality call |

```sql
CASE WHEN DATEDIFF(DAY, created_date, ct.createdat) <= 1
          AND ct.callduration >= 60
          AND ct.inbound = FALSE
     THEN TRUE ELSE FALSE END AS call_1d_1min
```

## Conversion Window Flags

Pre-computed flags for common analysis windows:

| Field | Definition |
|-------|------------|
| `pre_interview_14d` | Reached pre-interview within 14 days |
| `post_interview_30d` | Reached post-interview within 30 days |
| `awarded_30d` | Awarded within 30 days |
| `awarded_60d` | Awarded within 60 days |
| `awarded_90d` | Awarded within 90 days |

## Event Data Processing

Events are deduplicated to first occurrence:

```sql
SELECT request_id, et.name, TO_DATE(e.date) AS date
FROM event e
JOIN eventtype et ON e.type_id = et.id
WHERE et.name IN (
  'REQUEST_CREATED',
  'REQUEST_PRE_INTERVIEW',
  'REQUEST_POST_INTERVIEW',
  'REQUEST_SELECTED_WINNER',
  'REQUEST_AWARDED',
  'REQUEST_SOLD',
  'REQUEST_COLLECTED',
  'OUTBOUND_CALL'
)
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY e.request_id, et.name 
  ORDER BY date ASC
) = 1
```

### Date Field Derivation

Interview dates are derived with fallback logic:

```sql
-- Post-interview date: multiple sources
post_interview_date = COALESCE(
  post_interview_event.date,
  matchdate,
  unconfirmed_awarded_event.date,
  awardeddate
)

-- Pre-interview date: falls back to post-interview
pre_interview_date = COALESCE(
  pre_interview_event.date,
  post_interview_date
)
```

## Output Schema

| Field | Type | Description |
|-------|------|-------------|
| `created_date` | DATE | Lead creation date |
| `request_id` | STRING | Unique lead identifier |
| `page` | STRING | Lead source/flow |
| `transaction_type` | STRING | 'buy' or 'sell' |
| `furthest_stage` | STRING | Maximum stage reached |
| `current_stage` | STRING | Current stage |
| `rejected` | BOOLEAN | Is rejected |
| `is_fake` | BOOLEAN | Flagged as fake |
| `is_fraud` | BOOLEAN | Flagged as fraud |
| `is_fake_or_fraud` | BOOLEAN | Either flag |
| `pre_interview_date` | DATE | Pre-interview date |
| `post_interview_date` | DATE | Post-interview date |
| `rejectdate` | DATE | Rejection date |
| `matchdate` | DATE | Agent match date |
| `awardeddate` | DATE | Award date |
| `solddate` | DATE | Sale date |
| `collecteddate` | DATE | Collection date |
| `call_1d_1min` | BOOLEAN | 60s+ call within 1 day |
| `call_6d_1min` | BOOLEAN | 60s+ call within 6 days |
| `call_2d_2min` | BOOLEAN | 120s+ call within 2 days |
| `pre_interview_14d` | BOOLEAN | Pre-interview within 14d |
| `post_interview_30d` | BOOLEAN | Post-interview within 30d |
| `awarded_30d` | BOOLEAN | Awarded within 30d |
| `awarded_60d` | BOOLEAN | Awarded within 60d |
| `awarded_90d` | BOOLEAN | Awarded within 90d |

## Common Query Patterns

### Funnel Conversion Rates
```sql
SELECT 
  page,
  transaction_type,
  COUNT(*) AS total_leads,
  SUM(CASE WHEN furthest_stage >= '4: Pre-Interview' THEN 1 ELSE 0 END) AS to_pre_interview,
  SUM(CASE WHEN furthest_stage >= '7: Awarded' THEN 1 ELSE 0 END) AS to_awarded,
  ROUND(100.0 * SUM(CASE WHEN furthest_stage >= '7: Awarded' THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(*), 0), 2) AS award_rate
FROM rdc_marketing.seller.sell_downfunnel
WHERE created_date >= DATEADD('day', -90, CURRENT_DATE())
  AND NOT is_fake_or_fraud
GROUP BY 1, 2
ORDER BY total_leads DESC;
```

### Call Impact Analysis
```sql
SELECT 
  call_1d_1min,
  COUNT(*) AS leads,
  SUM(CASE WHEN awarded_30d THEN 1 ELSE 0 END) AS awarded_30d,
  ROUND(100.0 * SUM(CASE WHEN awarded_30d THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(*), 0), 2) AS award_rate_30d
FROM rdc_marketing.seller.sell_downfunnel
WHERE created_date >= DATEADD('day', -90, CURRENT_DATE())
  AND NOT is_fake_or_fraud
GROUP BY 1;
```

### Stage Distribution
```sql
SELECT 
  furthest_stage,
  COUNT(*) AS leads,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM rdc_marketing.seller.sell_downfunnel
WHERE created_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1
ORDER BY furthest_stage;
```

## Notes

1. **Buy vs Sell differences**: Buy leads don't have `8: Listed` stage
2. **Stage ordering**: Stages are string-sortable (0, 1, 2... 9, a, b)
3. **Rejection timing**: Check both `furthest_stage` and `current_stage` for full picture
4. **Date nulls**: Many date fields will be NULL for leads that haven't reached that stage
