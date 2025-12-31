# Google Ads Segment Fields Reference

Segments break down metrics by various dimensions. Each segment adds a dimension to your query results.

## Time Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.date` | string | Date (YYYY-MM-DD) - **Required for metrics** |
| `segments.week` | string | Week starting Monday |
| `segments.month` | string | Month (YYYY-MM-01) |
| `segments.quarter` | string | Quarter (YYYY-QN) |
| `segments.year` | int | Year |
| `segments.day_of_week` | enum | MONDAY through SUNDAY |
| `segments.hour` | int | Hour of day (0-23) |

## Device Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.device` | enum | MOBILE, DESKTOP, TABLET, CONNECTED_TV, OTHER |

## Network Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.ad_network_type` | enum | SEARCH, SEARCH_PARTNERS, CONTENT, YOUTUBE_SEARCH, YOUTUBE_WATCH, MIXED |

## Geographic Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.geo_target_country` | resource | Country criterion |
| `segments.geo_target_region` | resource | State/region criterion |
| `segments.geo_target_metro` | resource | Metro area criterion |
| `segments.geo_target_city` | resource | City criterion |
| `segments.geo_target_postal_code` | resource | Postal code criterion |
| `segments.geo_target_most_specific_location` | resource | Most specific location |

## Conversion Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.conversion_action` | resource | Conversion action resource |
| `segments.conversion_action_name` | string | Conversion action name |
| `segments.conversion_action_category` | enum | Conversion category |
| `segments.external_conversion_source` | enum | Conversion source |
| `segments.conversion_lag_bucket` | enum | Days to conversion bucket |

## Click Type Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.click_type` | enum | Type of click (headline, sitelink, etc.) |
| `segments.slot` | enum | Ad position slot |

## Keyword Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.keyword.info.text` | string | Keyword text |
| `segments.keyword.info.match_type` | enum | Match type |
| `segments.keyword.ad_group_criterion` | resource | Keyword criterion |

## Search Term Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.search_term` | string | Actual search query |
| `segments.search_term_match_type` | enum | How term matched |

## Product Segments (Shopping)

| Field | Type | Description |
|-------|------|-------------|
| `segments.product_brand` | string | Product brand |
| `segments.product_category_level1` | string | Category L1 |
| `segments.product_category_level2` | string | Category L2 |
| `segments.product_category_level3` | string | Category L3 |
| `segments.product_item_id` | string | Product ID |
| `segments.product_title` | string | Product title |
| `segments.product_type_l1` | string | Product type L1 |
| `segments.product_channel` | enum | ONLINE, LOCAL |
| `segments.product_condition` | enum | NEW, REFURBISHED, USED |

## Auction Insight Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.auction_insight_domain` | string | Competitor domain |

## Ad Destination Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.ad_destination_type` | enum | Where ad leads (APP, WEBSITE, etc.) |

## Campaign/Ad Group Segments

| Field | Type | Description |
|-------|------|-------------|
| `segments.campaign` | resource | Campaign resource |
| `segments.ad_group` | resource | Ad group resource |

## Enum Values

### segments.device
- `MOBILE` - Mobile phones
- `DESKTOP` - Desktop computers
- `TABLET` - Tablets
- `CONNECTED_TV` - Connected TVs
- `OTHER` - Other devices

### segments.ad_network_type
- `SEARCH` - Google Search
- `SEARCH_PARTNERS` - Search partners
- `CONTENT` - Display Network
- `YOUTUBE_SEARCH` - YouTube search
- `YOUTUBE_WATCH` - YouTube videos
- `MIXED` - Cross-network

### segments.day_of_week
- `MONDAY`, `TUESDAY`, `WEDNESDAY`, `THURSDAY`, `FRIDAY`, `SATURDAY`, `SUNDAY`

### segments.click_type
- `HEADLINE` - Headline click
- `SITELINK` - Sitelink click
- `CALL` - Call click
- `LOCATION` - Location click
- `APP_DEEPLINK` - App deeplink
- `BREADCRUMB` - Breadcrumb click

### segments.conversion_lag_bucket
- `LESS_THAN_ONE_DAY`
- `ONE_TO_TWO_DAYS`
- `TWO_TO_THREE_DAYS`
- `THREE_TO_FOUR_DAYS`
- `FOUR_TO_FIVE_DAYS`
- `FIVE_TO_SIX_DAYS`
- `SIX_TO_SEVEN_DAYS`
- `SEVEN_TO_EIGHT_DAYS`
- ... (continues through `SIXTY_TO_NINETY_DAYS`)

## Common Segment Combinations

### Daily Trend
```
segments.date
```

### Device Breakdown
```
segments.date, segments.device
```

### Geographic Analysis
```
segments.date, segments.geo_target_region
```

### Network Performance
```
segments.date, segments.ad_network_type
```

### Hour of Day
```
segments.date, segments.hour
```

### Conversion Path Analysis
```
segments.date, segments.conversion_action_name, segments.conversion_lag_bucket
```

### Competitive Analysis
```
segments.date, segments.auction_insight_domain
```

## Important Notes

1. **Date segment is required** when querying metrics
2. **Segments multiply rows** - each segment dimension creates additional rows
3. **Some segments are incompatible** - check API docs for restrictions
4. **Geographic segments** return criterion resource names, not human-readable names
5. **Conversion segments** split metrics by conversion action