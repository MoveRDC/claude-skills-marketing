# Amplitude Event Taxonomy Reference

This document provides the complete event and property taxonomy for RDC's Amplitude implementation.

## High-Volume Events

### Discovery Events

| Event | Project | 30-Day Volume | Description |
|-------|---------|---------------|-------------|
| `pageview` | Leads+CS 2.0 | 1.26B | Page view tracking across platforms |
| `[Amplitude] Page Viewed` | Real Time SDK | 952M | Auto-captured page loads |
| `search` | Leads+CS 2.0 | 744M | Search bar usage |
| `listingimpression` | Leads+CS 2.0 | 656M | Listing shown to user |
| `promotedsrpimpression` | Leads+CS 2.0 | 72M | Promoted listing impressions |

### Engagement Events

| Event | Project | 30-Day Volume | Description |
|-------|---------|---------------|-------------|
| `click` | Leads+CS 2.0 | 773M | General click interactions |
| `listingclick` | Leads+CS 2.0 | 240M | Click on a listing |
| `listingClick` | Real Time SDK | 135M | Real-time listing clicks |
| `refinedsearch` | Leads+CS 2.0 | 123M | Search filter modifications |
| `moduleimpression` | Leads+CS 2.0 | 1.43B | UI module visibility |
| `modalimpression` | Leads+CS 2.0 | 127M | Modal/popup visibility |

### Conversion Events

| Event | Project | 30-Day Volume | Description |
|-------|---------|---------------|-------------|
| `RDC Lead Submission` | Leads+CS 2.0 | 1.45M | Lead form submission (source of truth) |
| `rentallead` | Leads+CS 2.0 | 820K | Rental lead submission |
| `cobrokelead` | Leads+CS 2.0 | 391K | Co-broke lead submission |
| `leadformabandon` | Leads+CS 2.0 | 946K | Lead form abandonment |

### Activation Events

| Event | Project | 30-Day Volume | Description |
|-------|---------|---------------|-------------|
| `signin` | Leads+CS 2.0 | 1.52M | User sign-in |
| `signup` | Leads+CS 2.0 | 378K | New user registration |
| `applaunch` | Leads+CS 2.0 | 62M | Mobile app launch |
| `install attributed` | Leads+CS 2.0 | 416K | Attributed app install |

### Experiment Events

| Event | Project | 30-Day Volume | Description |
|-------|---------|---------------|-------------|
| `[Experiment] Assignment` | Leads+CS 2.0 | 5.9B | User assigned to variant |
| `[Experiment] Exposure` | Leads+CS 2.0 | 1.1B | User exposed to variant |

---

## Common Event Properties

### Identity Properties
Properties used for user/session identification.

| Property | Type | Description | Used In |
|----------|------|-------------|---------|
| `visit_id` | string | Session identifier | 124 events |
| `browser_id` | string | Browser-level identity | 109 events |
| `rdc_session_id` | string | RDC session identifier | 109 events |
| `amp_session_id` | string | Amplitude session ID | 108 events |
| `google_click_id_persist` | string | GCLID for attribution | 113 events |
| `cust_visid` | string | Customer visitor ID | 104 events |
| `mobile_id` | string | Mobile device identifier | 107 events |
| `hitid` | string | Hit-level identifier | 122 events |
| `search_id` | string | Search session identifier | 120 events |

### Session Properties
Properties describing the user's session context.

| Property | Type | Description | Used In |
|----------|------|-------------|---------|
| `visit_hit_number` | number | Hit sequence within visit | 123 events |
| `visit_number` | number | User's visit count | 87 events |
| `visit_start_pagename` | string | Entry page name | 114 events |
| `visit_start_page_url` | string | Entry page URL | 64 events |
| `dwell_time_seconds` | number | Time on page/element | 123 events |

### Behavior Properties
Properties describing user actions and page context.

| Property | Type | Description | Used In |
|----------|------|-------------|---------|
| `is_pageview` | number | Is this a pageview event (1/0) | 123 events |
| `page_type_group` | string | Page type classification | 123 events |
| `page_type` | string | Specific page type | 108 events |
| `click_from_page_name` | string | Source page for click | 121 events |
| `previous_page_name` | string | Previous page in journey | 103 events |
| `post_page_event` | string | Page event type | 123 events |
| `site_section` | string | Site section classification | 122 events |

### Search Properties
Properties related to search behavior.

| Property | Type | Description | Used In |
|----------|------|-------------|---------|
| `search_category` | string | Search category (buy/rent/etc) | 103 events |
| `search_type` | string | Search type classification | 89 events |
| `user_search_query` | string | User's search text | 103 events |
| `search_box` | string | Search box used | 88 events |
| `n_filters` | number | Number of filters applied | 115 events |
| `search_filter_one` | string | Primary filter applied | 114 events |
| `search_filter_two` | string | Secondary filter applied | 112 events |
| `search_min_price` | number | Min price filter | 89 events |
| `search_max_price` | number | Max price filter | 92 events |
| `search_number_of_bedrooms_persist` | string | Bedroom filter | 95 events |
| `search_number_of_bathrooms_persist` | string | Bathroom filter | 95 events |
| `expand_search_result` | number | Expanded search triggered | 88 events |

### Listing Properties
Properties related to property listings.

| Property | Type | Description | Used In |
|----------|------|-------------|---------|
| `listing_id_persist` | string | Listing identifier | 118 events |
| `listing_click_source` | string | Where click originated | 111 events |
| `listing_activity` | string | Listing activity type | 105 events |
| `ldp_property_status_persist` | string | Property status on LDP | 117 events |
| `srp_property_status_persist` | string | Property status on SRP | 109 events |
| `property_status_raw` | string | Raw property status | 95 events |
| `ldp_ranking_on_srp` | string | Listing rank on SRP | 106 events |
| `sponsored_listing` | string | Is sponsored (Y/N) | 83 events |
| `is_new_construction` | number | New construction flag | 123 events |
| `property_type` | string | Property type | 70 events |
| `community_id` | string | Community identifier | 115 events |

### Lead Properties
Properties related to lead generation.

| Property | Type | Description | Used In |
|----------|------|-------------|---------|
| `lead_submission_type` | string | Lead form type | 111 events |
| `for_sale_leads` | string | Buy lead indicator | 85 events |
| `not_for_sale_leads` | string | Non-buy lead indicator | 123 events |
| `phone_click_leads` | string | Phone click lead | 83 events |
| `lead_converted` | any | Lead conversion flag | 100 events |
| `page_conversion` | string | Page conversion type | 76 events |
| `lead_placement` | string | Lead form placement | 28 events |
| `connected_agent_conversion_persist` | string | Agent connection flag | 107 events |

### Marketing Properties
Properties related to marketing attribution.

| Property | Type | Description | Used In |
|----------|------|-------------|---------|
| `kpi_channel_view` | string | KPI channel classification | 123 events |
| `paid_vs_organic` | string | Paid or organic traffic | 123 events |
| `campaign` | string | Campaign identifier | varies |
| `ab_test_apps` | string | Active AB tests | 118 events |
| `ab_test_id_list` | string | List of experiment IDs | varies |

### Platform Properties
Properties describing the user's platform.

| Property | Type | Description | Used In |
|----------|------|-------------|---------|
| `experience_type` | string | Platform type (web/app) | 123 events |
| `experience` | string | Experience classification | 123 events |
| `move_device_type` | string | Device type | 123 events |
| `operating_system_type` | string | OS type | 123 events |
| `resolution` | string | Screen resolution | 123 events |
| `web_app_version` | string | App version | 122 events |

### Geographic Properties
Properties related to location.

| Property | Type | Description | Used In |
|----------|------|-------------|---------|
| `city` | string | City | 118 events |
| `state` | string | State | 118 events |
| `zip` | string | ZIP code | 118 events |

---

## RDC Lead Submission Event - Complete Property Reference

The `RDC Lead Submission` event is the source of truth for lead analytics. Key properties:

### Consumer Information
| Property | Type | Description |
|----------|------|-------------|
| `consumer_visitor_id` | string | Consumer's visitor ID |
| `consumer_session_id` | string | Consumer's session ID |
| `consumer_member_id` | string | Consumer's member ID (if registered) |
| `consumer_email_address` | string | Consumer email |
| `consumer_phone_number` | string | Consumer phone |
| `consumer_contact_method_raw` | string | How consumer wants contact |
| `consumer_message_body` | string | Lead message content |

### Lead Classification
| Property | Type | Description |
|----------|------|-------------|
| `lead_vertical` | string | Lead vertical (for_sale, for_rent, Seller, FAR) |
| `lead_product` | string | Lead product type |
| `lead_category_group_raw` | string | Lead category |
| `lead_source_application_name` | string | Source application |
| `lead_form_name` | string | Form name |
| `lead_placement` | string | Form placement location |
| `lead_contact_method` | string | Contact method |
| `user_intent` | string | Inferred user intent |

### Property Information
| Property | Type | Description |
|----------|------|-------------|
| `listing_id` | string | Associated listing ID |
| `property_id` | string | Property identifier |
| `lead_listing_price` | number | Listing price |
| `property_type` | string | Property type |
| `listing_status_raw` | string | Listing status |
| `property_postal_code` | string | Property ZIP |
| `lead_city` | string | Property city |
| `lead_state` | string | Property state |
| `is_new_construction` | number | New construction flag |

### Delivery Information
| Property | Type | Description |
|----------|------|-------------|
| `delivered_flag` | any | Was lead delivered |
| `delivered_to_connections_plus_flag` | number | C+ delivery |
| `delivered_to_mvip_flag` | number | MVIP delivery |
| `delivered_to_upnest_flag` | number | UpNest delivery |
| `delivered_to_seller_partner_flag` | number | Seller partner delivery |
| `delivered_to_veterans_united_flag` | number | VU delivery |
| `delivered_to_readyconnect_concierge_flag` | number | RCC delivery |
| `delivered_to_rental_flag` | number | Rental delivery |
| `delivered_to_advantage_pro_flag` | number | Advantage Pro delivery |
| `delivered_to_basic_free_flag` | number | Basic free delivery |
| `delivered_to_find_a_realtor_flag` | number | FAR delivery |
| `delivered_to_new_construction_sales_builder_flag` | number | NC Sales Builder |
| `delivered_advertiser_id` | string | Delivered advertiser ID |
| `delivered_customer_name` | string | Delivered customer name |
| `total_referral_deliveries` | number | Total referral deliveries |
| `total_non_referral_deliveries` | number | Total non-referral deliveries |

### Revenue Attribution
| Property | Type | Description |
|----------|------|-------------|
| `estimated_future_revenue` | string | EFR value |
| `price_bucket` | any | Price tier bucket |

### Marketing Attribution
| Property | Type | Description |
|----------|------|-------------|
| `first_touch_marketing_channel` | string | First touch channel |
| `last_touch_marketing_channel` | string | Last touch channel |
| `last_touch_marketing_channel_detail` | string | Detailed last touch |
| `campaign` | string | Campaign identifier |

### Platform Context
| Property | Type | Description |
|----------|------|-------------|
| `platform` | string | Platform (web/ios/android) |
| `move_device_type_raw` | string | Device type |
| `experience_type_raw` | string | Experience type |
| `site_section_raw` | string | Site section |

---

## Real Time SDK Event Properties

The Real Time SDK project uses a different property naming convention (Title Case vs snake_case).

### Key Real Time SDK Properties
| Property | Type | Description |
|----------|------|-------------|
| `Page Name` | string | Page name |
| `Page Type` | string | Page type |
| `Previous Page Name` | string | Previous page |
| `Brand Experience` | string | Brand experience |
| `Campaign` | string | Campaign |
| `Site Section` | string | Site section |
| `Link Name` | string | Link clicked |
| `Search Category` | string | Search category |
| `Search City` | string | Search city |
| `Search Results` | number | Result count |
| `Listing ID` | string | Listing identifier |
| `Property ID` | string | Property identifier |
| `UTM Source` | string | UTM source |
| `UTM Medium` | string | UTM medium |
| `UTM Campaign` | string | UTM campaign |

---

## Experiment Properties

### Assignment Event Properties
Properties on `[Experiment] Assignment`:
- `[Experiment] {experiment-key}.variant` - Assigned variant
- `[Experiment] {experiment-key}.details` - Assignment details

### Exposure Event Properties
Properties on `[Experiment] Exposure`:
- `[Experiment] Experiment Key` - Experiment identifier
- `[Experiment] Flag Key` - Feature flag key
- `[Experiment] Variant` - Exposed variant

### User Property for Segmentation
When segmenting by experiment in queries:
```
prop: "gp:[Experiment] experiment-key"
op: "is"
values: ["control", "treatment", "v1", etc.]
```
