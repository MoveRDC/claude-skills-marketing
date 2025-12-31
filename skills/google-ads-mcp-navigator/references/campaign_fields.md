# Google Ads Campaign Fields Reference

Curated list of commonly used campaign resource fields.

## Core Campaign Fields

| Field | Type | Description |
|-------|------|-------------|
| `campaign.id` | int | Campaign ID |
| `campaign.name` | string | Campaign name |
| `campaign.resource_name` | string | Full resource path |
| `campaign.status` | enum | ENABLED, PAUSED, REMOVED |
| `campaign.serving_status` | enum | Current serving status |

## Campaign Configuration

| Field | Type | Description |
|-------|------|-------------|
| `campaign.advertising_channel_type` | enum | SEARCH, DISPLAY, SHOPPING, VIDEO, PERFORMANCE_MAX |
| `campaign.advertising_channel_sub_type` | enum | Sub-channel type |
| `campaign.bidding_strategy_type` | enum | Bidding strategy |
| `campaign.campaign_budget` | resource | Budget resource name |

## Bidding Configuration

| Field | Type | Description |
|-------|------|-------------|
| `campaign.bidding_strategy` | resource | Portfolio bidding strategy |
| `campaign.bidding_strategy_type` | enum | Strategy type |
| `campaign.manual_cpc.enhanced_cpc_enabled` | bool | ECPC enabled |
| `campaign.maximize_conversions.target_cpa_micros` | int | Target CPA |
| `campaign.maximize_conversion_value.target_roas` | float | Target ROAS |
| `campaign.target_cpa.target_cpa_micros` | int | Target CPA |
| `campaign.target_roas.target_roas` | float | Target ROAS |
| `campaign.target_spend.target_spend_micros` | int | Target spend |

## Network Settings

| Field | Type | Description |
|-------|------|-------------|
| `campaign.network_settings.target_google_search` | bool | Google Search enabled |
| `campaign.network_settings.target_search_network` | bool | Search partners enabled |
| `campaign.network_settings.target_content_network` | bool | Display network enabled |

## Date Settings

| Field | Type | Description |
|-------|------|-------------|
| `campaign.start_date` | string | Start date (YYYY-MM-DD) |
| `campaign.end_date` | string | End date (YYYY-MM-DD) |

## Shopping Settings

| Field | Type | Description |
|-------|------|-------------|
| `campaign.shopping_setting.merchant_id` | int | Merchant Center ID |
| `campaign.shopping_setting.feed_label` | string | Feed label |
| `campaign.shopping_setting.campaign_priority` | int | Priority (0, 1, 2) |

## Labels

| Field | Type | Description |
|-------|------|-------------|
| `campaign.labels` | list | Applied label resource names |

## URL Settings

| Field | Type | Description |
|-------|------|-------------|
| `campaign.tracking_url_template` | string | Tracking template |
| `campaign.final_url_suffix` | string | Final URL suffix |

## Geo Targeting

| Field | Type | Description |
|-------|------|-------------|
| `campaign.geo_target_type_setting.positive_geo_target_type` | enum | Location targeting type |
| `campaign.geo_target_type_setting.negative_geo_target_type` | enum | Location exclusion type |

## Status Values

### campaign.status
- `ENABLED` - Campaign is active
- `PAUSED` - Campaign is paused
- `REMOVED` - Campaign is deleted

### campaign.advertising_channel_type
- `SEARCH` - Search Network campaign
- `DISPLAY` - Display Network campaign
- `SHOPPING` - Shopping campaign
- `VIDEO` - Video campaign (YouTube)
- `PERFORMANCE_MAX` - Performance Max campaign
- `LOCAL` - Local campaign
- `SMART` - Smart campaign
- `DEMAND_GEN` - Demand Gen campaign
- `HOTEL` - Hotel campaign
- `DISCOVERY` - Discovery campaign (deprecated)

### campaign.bidding_strategy_type
- `MANUAL_CPC` - Manual CPC
- `MANUAL_CPM` - Manual CPM
- `MAXIMIZE_CONVERSIONS` - Maximize conversions
- `MAXIMIZE_CONVERSION_VALUE` - Maximize conversion value
- `TARGET_CPA` - Target CPA
- `TARGET_ROAS` - Target ROAS
- `TARGET_SPEND` - Target spend (Maximize clicks)
- `TARGET_IMPRESSION_SHARE` - Target impression share
- `ENHANCED_CPC` - Enhanced CPC

## Common Field Combinations

### Campaign Overview
```
campaign.id, campaign.name, campaign.status, campaign.advertising_channel_type, campaign.bidding_strategy_type
```

### Campaign Settings Audit
```
campaign.name, campaign.status, campaign.network_settings.target_google_search, campaign.network_settings.target_search_network, campaign.network_settings.target_content_network
```

### Bidding Analysis
```
campaign.name, campaign.bidding_strategy_type, campaign.target_cpa.target_cpa_micros, campaign.maximize_conversion_value.target_roas
```

### Shopping Campaigns
```
campaign.name, campaign.shopping_setting.merchant_id, campaign.shopping_setting.feed_label, campaign.shopping_setting.campaign_priority
```