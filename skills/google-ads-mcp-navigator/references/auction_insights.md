# Auction Insights Reference

Auction Insights provides competitive analysis data showing how your ads perform relative to other advertisers participating in the same auctions.

## Overview

Auction Insights is available for Search and Shopping campaigns. It shows aggregated competitor data at the domain level - you see competitor domains but not their specific campaigns or keywords.

## Available Metrics

| Metric | Field | Description |
|--------|-------|-------------|
| Impression Share | `metrics.auction_insight_search_impression_share` | % of impressions you received vs. total eligible |
| Overlap Rate | `metrics.auction_insight_search_overlap_rate` | How often a competitor's ad showed alongside yours |
| Position Above Rate | `metrics.auction_insight_search_position_above_rate` | How often competitor's ad was above yours when both showed |
| Top of Page Rate | `metrics.auction_insight_search_top_impression_percentage` | % of impressions that appeared at top of page |
| Absolute Top of Page Rate | `metrics.auction_insight_search_absolute_top_impression_percentage` | % of impressions in the #1 position |
| Outranking Share | `metrics.auction_insight_search_outranking_share` | % of auctions where you outranked or showed when competitor didn't |

## Key Segment

The critical segment for auction insights is `segments.auction_insight_domain` which returns competitor domain names.

## Query Patterns

### Campaign-Level Auction Insights
```python
resource: "campaign"
fields: [
    "campaign.id",
    "campaign.name",
    "segments.auction_insight_domain",
    "metrics.auction_insight_search_impression_share",
    "metrics.auction_insight_search_overlap_rate",
    "metrics.auction_insight_search_position_above_rate",
    "metrics.auction_insight_search_top_impression_percentage",
    "metrics.auction_insight_search_absolute_top_impression_percentage",
    "metrics.auction_insight_search_outranking_share"
]
conditions: [
    "campaign.status = 'ENABLED'",
    "segments.date >= '2024-12-01'",
    "segments.date <= '2024-12-17'"
]
```

### Ad Group Level Auction Insights
```python
resource: "ad_group"
fields: [
    "campaign.name",
    "ad_group.name",
    "segments.auction_insight_domain",
    "metrics.auction_insight_search_impression_share",
    "metrics.auction_insight_search_overlap_rate",
    "metrics.auction_insight_search_position_above_rate",
    "metrics.auction_insight_search_outranking_share"
]
conditions: [
    "ad_group.status = 'ENABLED'",
    "segments.date >= '2024-12-01'",
    "segments.date <= '2024-12-17'"
]
```

### Keyword Level Auction Insights
```python
resource: "ad_group_criterion"
fields: [
    "campaign.name",
    "ad_group.name",
    "ad_group_criterion.keyword.text",
    "segments.auction_insight_domain",
    "metrics.auction_insight_search_impression_share",
    "metrics.auction_insight_search_overlap_rate",
    "metrics.auction_insight_search_position_above_rate"
]
conditions: [
    "ad_group_criterion.type = 'KEYWORD'",
    "ad_group_criterion.status = 'ENABLED'",
    "segments.date >= '2024-12-01'",
    "segments.date <= '2024-12-17'"
]
```

### Daily Competitor Trend
```python
resource: "campaign"
fields: [
    "segments.date",
    "campaign.name",
    "segments.auction_insight_domain",
    "metrics.auction_insight_search_impression_share",
    "metrics.auction_insight_search_outranking_share"
]
conditions: [
    "campaign.status = 'ENABLED'",
    "segments.date >= '2024-12-01'",
    "segments.date <= '2024-12-17'"
]
orderings: ["segments.date ASC"]
```

## Interpreting Results

### Your Domain Row
Results include a row for your own domain showing your aggregate performance. This is useful as a benchmark.

### Overlap Rate Analysis
- **High overlap** (>50%): Frequent direct competition with this advertiser
- **Low overlap** (<20%): Rarely competing in same auctions (different targeting)

### Position Above Rate Analysis
- **>50%**: Competitor usually beats you when you both show
- **<50%**: You usually beat this competitor
- **Close to 50%**: Even competition

### Outranking Share Analysis
- Combines position wins AND cases where you showed and competitor didn't
- Higher is better - indicates competitive advantage
- 100% would mean you always beat them (very rare)

### Impression Share Analysis
- Compare your IS to competitors to gauge market share
- If competitor has higher IS, they're capturing more eligible impressions
- Low IS + high overlap = budget or bid constraints vs. this competitor

## Limitations

1. **Aggregated data only** - Cannot see competitor spend, bids, or keywords
2. **Domain-level** - No visibility into competitor campaign structure
3. **Search and Shopping only** - Not available for Display, Video, etc.
4. **Minimum threshold** - Very low volume keywords may not show competitor data
5. **Delayed data** - Typically 24-48 hours behind

## Common Analysis Use Cases

### Identify Top Competitors
Query auction insights at campaign level, rank by overlap rate to find who you compete with most frequently.

### Competitive Position Tracking
Track outranking share over time against key competitors to measure relative performance changes.

### Budget Impact Analysis
Compare your impression share to competitors - if they have higher IS and higher outranking share, they may have larger budgets or better ad rank.

### Bid Strategy Optimization
If position above rate is consistently high for a competitor across keywords, consider bid adjustments or ad quality improvements.

## Integration with Snowflake

Auction insights from Google Ads can supplement RDC's marketing data:

```sql
-- After exporting auction insights to Snowflake
-- Join with campaign performance for complete competitive view
SELECT 
    ai.campaign_name,
    ai.competitor_domain,
    ai.overlap_rate,
    ai.outranking_share,
    cp.spend,
    cp.conversions,
    cp.roas
FROM auction_insights ai
JOIN campaign_performance cp 
    ON ai.campaign_id = cp.campaign_id
    AND ai.date = cp.event_date
WHERE ai.date >= DATEADD('day', -30, CURRENT_DATE())
```

## Tips

1. **Focus on high-overlap competitors** - They're your real competition
2. **Track trends, not snapshots** - Single day data is noisy
3. **Segment by campaign type** - Brand vs. non-brand show different competitive landscapes
4. **Combine with your own metrics** - Auction insights alone don't show ROI impact
5. **Use for bid strategy decisions** - If losing to competitors on valuable terms, consider bid increases