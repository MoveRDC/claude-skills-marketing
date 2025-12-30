# Google Ads Keyword & Criterion Fields Reference

Fields for ad_group_criterion resource (keywords, audiences, placements, etc.)

## Core Criterion Fields

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.criterion_id` | int | Criterion ID |
| `ad_group_criterion.resource_name` | string | Full resource path |
| `ad_group_criterion.ad_group` | resource | Parent ad group |
| `ad_group_criterion.type` | enum | KEYWORD, PLACEMENT, AUDIENCE, etc. |
| `ad_group_criterion.status` | enum | ENABLED, PAUSED, REMOVED |
| `ad_group_criterion.negative` | bool | Is negative criterion |

## Keyword-Specific Fields

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.keyword.text` | string | Keyword text |
| `ad_group_criterion.keyword.match_type` | enum | EXACT, PHRASE, BROAD |
| `ad_group_criterion.display_name` | string | Display name |

## Quality Score Fields

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.quality_info.quality_score` | int | Quality Score (1-10) |
| `ad_group_criterion.quality_info.creative_quality_score` | enum | Ad relevance |
| `ad_group_criterion.quality_info.post_click_quality_score` | enum | Landing page experience |
| `ad_group_criterion.quality_info.search_predicted_ctr` | enum | Expected CTR |

## Bid Fields

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.cpc_bid_micros` | int | CPC bid in micros |
| `ad_group_criterion.effective_cpc_bid_micros` | int | Effective CPC bid |
| `ad_group_criterion.effective_cpc_bid_source` | enum | Bid source |
| `ad_group_criterion.cpm_bid_micros` | int | CPM bid in micros |
| `ad_group_criterion.bid_modifier` | float | Bid modifier |
| `ad_group_criterion.percent_cpc_bid_micros` | int | Percent CPC bid |

## Position Estimates

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.position_estimates.first_page_cpc_micros` | int | First page CPC |
| `ad_group_criterion.position_estimates.first_position_cpc_micros` | int | First position CPC |
| `ad_group_criterion.position_estimates.top_of_page_cpc_micros` | int | Top of page CPC |

## Approval Fields

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.approval_status` | enum | APPROVED, DISAPPROVED, etc. |
| `ad_group_criterion.disapproval_reasons` | list | Disapproval reasons |
| `ad_group_criterion.system_serving_status` | enum | System serving status |

## URL Fields

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.final_urls` | list | Final URLs |
| `ad_group_criterion.final_mobile_urls` | list | Mobile final URLs |
| `ad_group_criterion.tracking_url_template` | string | Tracking template |
| `ad_group_criterion.final_url_suffix` | string | Final URL suffix |

## Audience Fields

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.user_list.user_list` | resource | User list resource |
| `ad_group_criterion.audience.audience` | resource | Audience resource |
| `ad_group_criterion.custom_audience.custom_audience` | resource | Custom audience |

## Placement Fields

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.placement.url` | string | Placement URL |
| `ad_group_criterion.youtube_channel.channel_id` | string | YouTube channel ID |
| `ad_group_criterion.youtube_video.video_id` | string | YouTube video ID |

## Demographic Fields

| Field | Type | Description |
|-------|------|-------------|
| `ad_group_criterion.age_range.type` | enum | Age range |
| `ad_group_criterion.gender.type` | enum | Gender |
| `ad_group_criterion.income_range.type` | enum | Income range |
| `ad_group_criterion.parental_status.type` | enum | Parental status |

## Enum Values

### ad_group_criterion.type
- `KEYWORD` - Keywords
- `PLACEMENT` - Managed placements
- `USER_LIST` - Remarketing lists
- `AUDIENCE` - Audiences
- `AGE_RANGE` - Age targeting
- `GENDER` - Gender targeting
- `INCOME_RANGE` - Income targeting
- `PARENTAL_STATUS` - Parental status targeting
- `TOPIC` - Topic targeting
- `LISTING_GROUP` - Shopping product groups
- `WEBPAGE` - Dynamic search ad targets

### ad_group_criterion.keyword.match_type
- `EXACT` - [exact match]
- `PHRASE` - "phrase match"
- `BROAD` - broad match

### ad_group_criterion.status
- `ENABLED` - Active
- `PAUSED` - Paused
- `REMOVED` - Deleted

### Quality Score Components (enum values)
- `BELOW_AVERAGE` - Below average
- `AVERAGE` - Average
- `ABOVE_AVERAGE` - Above average

### ad_group_criterion.approval_status
- `APPROVED` - Approved
- `APPROVED_LIMITED` - Limited approval
- `DISAPPROVED` - Disapproved
- `UNDER_REVIEW` - Under review

## Common Field Combinations

### Keyword Performance
```
campaign.name, ad_group.name, ad_group_criterion.keyword.text, ad_group_criterion.keyword.match_type, ad_group_criterion.status, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions
```

### Quality Score Analysis
```
ad_group_criterion.keyword.text, ad_group_criterion.quality_info.quality_score, ad_group_criterion.quality_info.creative_quality_score, ad_group_criterion.quality_info.post_click_quality_score, ad_group_criterion.quality_info.search_predicted_ctr
```

### Bid Analysis
```
ad_group_criterion.keyword.text, ad_group_criterion.cpc_bid_micros, ad_group_criterion.effective_cpc_bid_micros, ad_group_criterion.position_estimates.first_page_cpc_micros, ad_group_criterion.position_estimates.top_of_page_cpc_micros
```

### Audience Performance
```
ad_group_criterion.audience.audience, ad_group_criterion.bid_modifier, metrics.impressions, metrics.clicks, metrics.conversions
```

## Required Conditions

When querying ad_group_criterion, typically add:
```
ad_group_criterion.type = 'KEYWORD'
ad_group_criterion.status = 'ENABLED'
```

For negative keywords:
```
ad_group_criterion.type = 'KEYWORD'
ad_group_criterion.negative = TRUE
```