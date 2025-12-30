# Google Ads Metrics Fields Reference

Curated list of commonly used metrics fields. All metrics require a date segment.

## Performance Metrics

| Field | Type | Description |
|-------|------|-------------|
| `metrics.impressions` | int | Total impressions |
| `metrics.clicks` | int | Total clicks |
| `metrics.cost_micros` | int | Cost in micros (divide by 1M) |
| `metrics.ctr` | float | Click-through rate |
| `metrics.average_cpc` | float | Average CPC in micros |
| `metrics.average_cpm` | float | Average CPM in micros |

## Conversion Metrics

| Field | Type | Description |
|-------|------|-------------|
| `metrics.conversions` | float | Conversion count (may be fractional) |
| `metrics.conversions_value` | float | Total conversion value |
| `metrics.conversions_by_conversion_date` | float | Conversions by conversion date |
| `metrics.conversions_value_by_conversion_date` | float | Value by conversion date |
| `metrics.all_conversions` | float | All conversions including cross-device |
| `metrics.all_conversions_value` | float | All conversion value |
| `metrics.view_through_conversions` | int | View-through conversions |
| `metrics.cross_device_conversions` | float | Cross-device conversions |

## Derived Conversion Metrics

| Field | Type | Description |
|-------|------|-------------|
| `metrics.cost_per_conversion` | float | CPA in micros |
| `metrics.conversions_from_interactions_rate` | float | Conversion rate |
| `metrics.conversions_value_per_cost` | float | ROAS |
| `metrics.cost_per_all_conversions` | float | CPA including all conversions |

## Impression Share Metrics

| Field | Type | Description |
|-------|------|-------------|
| `metrics.search_impression_share` | float | Search impression share (0-1) |
| `metrics.search_budget_lost_impression_share` | float | IS lost to budget |
| `metrics.search_rank_lost_impression_share` | float | IS lost to rank |
| `metrics.search_exact_match_impression_share` | float | Exact match IS |
| `metrics.search_top_impression_share` | float | Top position IS |
| `metrics.search_absolute_top_impression_share` | float | Absolute top IS |
| `metrics.content_impression_share` | float | Display network IS |
| `metrics.content_budget_lost_impression_share` | float | Display IS lost to budget |
| `metrics.content_rank_lost_impression_share` | float | Display IS lost to rank |

## Position Metrics

| Field | Type | Description |
|-------|------|-------------|
| `metrics.top_impression_percentage` | float | % impressions in top positions |
| `metrics.absolute_top_impression_percentage` | float | % impressions in position 1 |

## Click Share

| Field | Type | Description |
|-------|------|-------------|
| `metrics.search_click_share` | float | Click share (clicks / eligible clicks) |

## Quality Metrics (Keyword Level)

| Field | Type | Description |
|-------|------|-------------|
| `metrics.historical_quality_score` | int | Historical QS (1-10) |
| `metrics.historical_creative_quality_score` | enum | Ad relevance score |
| `metrics.historical_landing_page_quality_score` | enum | Landing page score |
| `metrics.historical_search_predicted_ctr` | enum | Expected CTR score |

## Video Metrics

| Field | Type | Description |
|-------|------|-------------|
| `metrics.video_views` | int | Video views |
| `metrics.video_quartile_p25_rate` | float | 25% completion rate |
| `metrics.video_quartile_p50_rate` | float | 50% completion rate |
| `metrics.video_quartile_p75_rate` | float | 75% completion rate |
| `metrics.video_quartile_p100_rate` | float | 100% completion rate |

## Auction Insight Metrics

| Field | Type | Description |
|-------|------|-------------|
| `metrics.auction_insight_search_impression_share` | float | Competitor IS |
| `metrics.auction_insight_search_overlap_rate` | float | Overlap rate |
| `metrics.auction_insight_search_position_above_rate` | float | Position above rate |
| `metrics.auction_insight_search_top_impression_percentage` | float | Competitor top IS |
| `metrics.auction_insight_search_absolute_top_impression_percentage` | float | Competitor abs top IS |
| `metrics.auction_insight_search_outranking_share` | float | Outranking share |

## Interaction Metrics

| Field | Type | Description |
|-------|------|-------------|
| `metrics.interactions` | int | Total interactions |
| `metrics.interaction_rate` | float | Interaction rate |
| `metrics.engagements` | int | Engagements |
| `metrics.engagement_rate` | float | Engagement rate |

## Invalid Click Metrics

| Field | Type | Description |
|-------|------|-------------|
| `metrics.invalid_clicks` | int | Invalid clicks filtered |
| `metrics.invalid_click_rate` | float | Invalid click rate |

## Common Metric Combinations

### Basic Performance
```
metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.ctr
```

### Conversion Analysis
```
metrics.conversions, metrics.conversions_value, metrics.cost_per_conversion, metrics.conversions_from_interactions_rate
```

### Competitive Analysis
```
metrics.search_impression_share, metrics.search_budget_lost_impression_share, metrics.search_rank_lost_impression_share, metrics.search_click_share
```

### Position Analysis
```
metrics.top_impression_percentage, metrics.absolute_top_impression_percentage, metrics.search_top_impression_share, metrics.search_absolute_top_impression_share
```