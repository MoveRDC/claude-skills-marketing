# Clickstream_Detail View Definition - Annotated

This document provides an annotated version of the `RDC_ANALYTICS.CLICKSTREAM.CLICKSTREAM_DETAIL` view, explaining the logic behind key derived fields.

## Source Table
The view is built from `rdc_core.fact.fct_product_event_detail` with a join to `fivetran_referral.pg_public.zipcode_flipped` for market flag determination.

---

## Field Groups and Derivation Logic

### 1. Identity Fields
```sql
-- Primary user identifier (normalized GUID format)
REGEXP_SUBSTR(
  LOWER(COALESCE(post_prop_web_client_visitor_id, persisted_client_mapi_visitor_id)),
  '[a-z0-9]+-[a-z0-9]+-[a-z0-9]+-[a-z0-9]+-[a-z0-9]+.*'
) AS adjusted_uu_id

-- Original identifiers
post_prop_web_client_visitor_id AS rdc_visitor_id,          -- Web visitor ID
persisted_client_mapi_visitor_id AS client_mapi_visitor_id, -- Mobile API ID
message_id,                                                  -- Unique event key
visit_id,                                                    -- Session identifier
CASE WHEN TRIM(persisted_identity_id) <> '' 
     THEN persisted_identity_id END AS member_id            -- Logged-in user ID
```

### 2. Marketing Channel Attribution
```sql
-- Raw channels
last_touch_marketing_channel,
visit_persisted_last_touch_marketing_channel AS visit_last_touch_marketing_channel,
first_touch_marketing_channel_raw AS first_touch_marketing_channel,

-- KPI Channel View (simplified grouping for reporting)
CASE
  WHEN LOWER(last_touch_marketing_channel) = 'direct (typed/bookmarked)' THEN 'direct'
  WHEN LOWER(last_touch_marketing_channel) = 'organic social' THEN 'owned social'
  WHEN LOWER(last_touch_marketing_channel) IN (
    'paid search', 'display/social ads', 'affiliates', 
    'other campaigns', 'digital brand', 'direct mail'
  ) THEN 'total paid'
  WHEN LOWER(last_touch_marketing_channel) IN ('mobile unknown', 'misc sources') THEN 'unknown'
  WHEN LOWER(last_touch_marketing_channel) IN ('email', 'organic search') 
    THEN LOWER(last_touch_marketing_channel)
  ELSE 'others'
END AS kpi_channel_view,

-- Paid vs Organic (binary classification)
CASE
  WHEN LOWER(last_touch_marketing_channel) IN (
    'organic search', 'email', 'direct (typed/bookmarked)', 
    'session refresh', 'organic social', 'referring domains', 'notifications'
  ) THEN 'organic'
  WHEN LOWER(last_touch_marketing_channel) IN (
    'paid search', 'display/social ads', 'affiliates', 
    'other campaigns', 'paid social', 'digital brand'
  ) THEN 'paid'
  WHEN LOWER(last_touch_marketing_channel) IN ('partner', 'public relations') THEN 'others'
  ELSE 'unknown'
END AS paid_vs_organic
```

### 3. Device Type Classification
```sql
-- move_device_type: Prioritizes mobile detection first
CASE
  WHEN mobile_device_type IN ('ios', 'android') THEN 'mobile phone'
  WHEN user_agent ILIKE '%Android%' THEN 'mobile phone'
  WHEN user_agent ILIKE '%iPhone%' THEN 'mobile phone'
  WHEN user_agent ILIKE '%iPad%' THEN 'tablet'
  -- Screen size calculation for tablets (diagonal > 7 inches)
  WHEN SQRT(
    POWER(mobile_screen_height / (mobile_screen_density * 160), 2) + 
    POWER(mobile_screen_width / (mobile_screen_density * 160), 2)
  ) > 7 THEN 'tablet'
  WHEN user_agent ILIKE '%Windows NT%' THEN 'desktop'
  WHEN user_agent ILIKE '%Macintosh%' THEN 'desktop'
  ELSE 'other'
END AS move_device_type,

-- device_type: Normalized version (mobile_phone -> mobile_phone)
CASE
  WHEN move_device_type = 'mobile phone' THEN 'mobile_phone'
  ELSE move_device_type
END AS device_type
```

### 4. Experience Type (Platform Classification)
```sql
CASE
  -- Mobile Apps: Native iOS/Android
  WHEN (
    experience IN ('rdc-mobile-core', 'rdc-mobile-rentals')
    OR site_section IN ('core-android', 'core-ios', 'rentals-ios', 'rentals-android')
    OR experience IN ('core_android', 'core_ios', 'rentals_ios', 'rentals_android')
  ) THEN 'mobile apps'
  
  -- Mobile Web: Responsive site on mobile device
  WHEN (
    experience IN ('rdc-responsive', 'rdc-google-amp', 'web', ...)
    OR subdomain = 'www.realtor.com'
  ) AND experience <> 'rdc-mobile-core'
    AND move_device_type IN ('mobile phone', 'tablet')
  THEN 'mobile web'
  
  -- Web: Desktop browser
  WHEN (
    experience IN ('rdc-responsive', 'rdc-google-amp', 'web', ...)
    OR subdomain = 'www.realtor.com'
  ) AND experience <> 'rdc-mobile-core'
  THEN 'web'
  
  ELSE 'others'
END AS experience_type
```

### 5. Platform (Simplified)
```sql
CASE
  WHEN LOWER(experience) LIKE '%ios%' THEN 'ios'
  WHEN LOWER(experience) LIKE '%android%' THEN 'android'
  WHEN LOWER(experience_type) = 'mobile web' THEN 'mobile_web'
  WHEN LOWER(experience_type) = 'web' THEN 'desktop'
  ELSE 'unknown'
END AS platform
```

### 6. Product Vertical Classification
```sql
-- Primary business line based on page_name_or_url patterns
CASE
  -- For Sale: Listings available for purchase
  WHEN REGEXP_LIKE(page_name_or_url, '^for_sale:.*')
    OR (page_name_or_url = 'core-ios:srp' 
        AND REGEXP_LIKE(srp_property_status_hit, '^srp:for-sale.*'))
    OR (page_name_or_url = 'core-ios:ldp' 
        AND REGEXP_LIKE(ldp_property_status_hit, '^ldp:for_sale.*'))
  THEN 'for_sale'
  
  -- For Rent: Rental listings
  WHEN REGEXP_LIKE(page_name_or_url, '^for_rent.*')
    OR page_name_or_url = 'news_insights:advice_rent'
    AND page_name_or_url <> 'for_rent:hpa_landing'
  THEN 'for_rent'
  
  -- Not For Sale LDP: Off-market or recently sold properties
  WHEN COALESCE(click_from_page_name, page_name_or_url) LIKE ANY (
    'not_for_sale:ldp%', 'just_taken_off_market:ldp'
  ) AND (
    sub_property_status_raw IN ('off_market', 'recently_sold')
    OR ldp_property_status_hit IN ('ldp:not_for_sale', 'ldp:off_market', 'ldp:recently_sold')
  )
  THEN 'not_for_sale_ldp'
  
  -- Owner/Seller: Seller marketplace, My Home, Agent Connection
  WHEN REGEXP_LIKE(page_name_or_url, '^not_for_sale:sellers_marketplace.*')
    OR REGEXP_LIKE(page_name_or_url, '^agentconnection:.*')
    OR REGEXP_LIKE(page_name_or_url, '^my_home:.*')
    OR page_name_or_url LIKE 'not_for_sale:seller_guides:%'
    OR page_name_or_url = 'not_for_sale:rcs_questionnaire'
  THEN 'owner_seller'
  
  -- Finance section
  WHEN page_name_or_url LIKE 'finance%' THEN 'sub_finance'
  
  -- Realtor pages
  WHEN site_section IN ('realtors') THEN 'realtorpage'
END AS product_vertical
```

### 7. Page Type Group (Standardized)
```sql
CASE
  WHEN page_type IN ('adp', 'agent_details', 'office_details', 'team_details') 
    THEN 'far detail page'
  WHEN page_type IN ('home', 'home-returning', 'home-new', 'home-landing', 'hp') 
    THEN 'home'
  WHEN page_type IN ('ldp', 'ldp-quickview', 'ldp_quickview', 'ldp-seller-summary') 
    THEN 'ldp'
  WHEN page_type IN ('srp_list', 'srp_map', 'srp_listmap', 'srp', 'list', 'map') 
    THEN 'srp'
  WHEN page_type LIKE '%my_acct%' 
    THEN 'my-acct'
  WHEN page_type IN ('calculator', 'rate-table', 'finance') 
    THEN 'mortgage'
  WHEN page_type IN ('news_article', 'article', 'articles') 
    THEN 'article'
  -- ... many more mappings
  ELSE 'others'
END AS page_type_group
```

### 8. New Construction Flag
```sql
CASE
  WHEN (
    -- SRP for new home communities
    page_name_or_url LIKE '%srp_new_home_communities%'
    OR page_name_or_url = 'for_sale:new_construction'
    OR page_name_or_url = 'for_sale:new_construction_srp'
  ) OR (
    -- LDP for new construction properties
    property_status_hit IN ('for_sale', 'new_community', 'new_construction', 'ready_to_build')
    AND sub_property_status_raw IN ('new_plan', 'spec_home', 'new_community')
    AND product_type_vertical = 'ldp'
  )
  THEN 1
  ELSE 0
END AS is_new_construction
```

### 9. Action Event Classification
```sql
CASE
  WHEN LOWER(event_name) = 'saveditem' AND save_item = 'listing' 
    THEN 'saved listing'
  WHEN LOWER(event_name) = 'saveditem' AND save_item = 'search' 
    THEN 'saved search'
  WHEN LOWER(event_name) LIKE '%share%' AND LOWER(event_name) <> 'cancel_share' 
    THEN 'share'
  WHEN LOWER(event_name) = 'refinedsearch' 
    THEN 'refined searches'
  WHEN LOWER(event_name) = 'search' 
    THEN 'search_box_searches'
  WHEN LOWER(event_name) = 'signup' 
    THEN 'registered'
  WHEN LOWER(event_name) = 'signin' 
    THEN 'signedin'
END AS action_event
```

### 10. Lead-Related Flags
```sql
-- Not For Sale Lead flag
CASE
  WHEN LOWER(event_name) = 'notforsalelead' 
    OR LOWER(event_name) = 'notforsalephonelead'
  THEN 'y'
  ELSE 'n'
END AS not_for_sale_leads,

-- Lead GUID (cleaned)
CASE
  WHEN NOT persisted_lead_guid IS NULL
    AND persisted_lead_guid > '0'
    AND TRIM(persisted_lead_guid) <> ''
  THEN LOWER(persisted_lead_guid)
END AS inquiry_lead_id,

-- Lead Submission Type
CASE
  WHEN REGEXP_LIKE(click_from_page_name, '^for_sale:.*') THEN 'for_sale'
  WHEN REGEXP_LIKE(click_from_page_name, '^for_rent.*') THEN 'for_rent'
  WHEN click_from_page_name = 'not_for_sale:ldp' 
    AND not_for_sale_leads = 'y' THEN 'not_for_sale_ldp'
  WHEN click_from_page_name LIKE 'not_for_sale:sellers_marketplace%' 
    AND not_for_sale_leads = 'y' THEN 'sellers_marketplace'
  WHEN click_from_page_name LIKE 'my_home%' 
    AND not_for_sale_leads = 'y' THEN 'my_home'
END AS lead_submission_type
```

### 11. Filter Count Calculation
```sql
-- Count of search filters applied (counts semicolons)
CASE
  WHEN NOT search_filter_one IS NULL
    AND search_filter_one <> ''
    AND RIGHT(search_filter_one, 1) <> ';'
  THEN LENGTH(persisted_search_filter_one) + 1 
       - LENGTH(REPLACE(persisted_search_filter_one, ';', ''))
  ELSE LENGTH(persisted_search_filter_one) 
       - LENGTH(REPLACE(persisted_search_filter_one, ';', ''))
END AS n_filters
```

### 12. Pure Market Flag
```sql
-- Is the ZIP code in an active market?
CASE
  WHEN NOT zip IS NULL
    AND LOWER(zip_source.is_active) = 'true'
    AND TO_DATE(zip_source.created_at) <= event_date_mst
  THEN 1
  ELSE 0
END AS is_pure_market
```

### 13. Visit Start Page (First hit of session)
```sql
-- Capture the landing page for each session
CASE
  WHEN REGEXP_SUBSTR(visit_id, '\\d+-\\d+-\\d+T\\d+:\\d+:\\d+\\.\\d+Z') 
       = client_sdk_timestamp
  THEN LOWER(post_pagename)
END AS visit_start_pagename
```

---

## Key Filters Applied

The view applies these critical filters:

```sql
WHERE
  -- Must have a visitor ID
  (NOT rdc_visitor_id IS NULL OR NOT client_mapi_visitor_id IS NULL)
  
  -- Exclude RMN-connected traffic
  AND COALESCE(is_rmn_connected, FALSE) = FALSE
  
  -- Time sanity check (within 1 hour)
  AND (DATEDIFF(HOUR, client_sdk_timestamp, client_time_gmt) <= 1
       OR DATEDIFF(HOUR, client_sdk_timestamp, client_time_gmt) >= -1)
  
  -- Exclude high-volume impression events
  AND NOT LOWER(persisted_event_name) IN ('listingimp', 'expexposure')

QUALIFY
  -- Deduplicate by message_id, keeping latest
  ROW_NUMBER() OVER (PARTITION BY message_id ORDER BY datetime_gmt DESC) = 1
```

---

## Common Query Patterns

### 1. Session-level aggregation
```sql
SELECT 
    visit_id,
    adjusted_uu_id,
    MIN(datetime_mst) as session_start,
    MAX(datetime_mst) as session_end,
    COUNT(*) as total_hits,
    SUM(is_pageview) as pageviews,
    MAX(inquiry_lead_id) as lead_submitted
FROM rdc_analytics.clickstream.clickstream_detail
WHERE event_date_mst = CURRENT_DATE() - 1
GROUP BY 1, 2;
```

### 2. User journey to lead
```sql
SELECT 
    visit_id,
    page_name_or_url,
    page_type_group,
    datetime_mst,
    inquiry_lead_id
FROM rdc_analytics.clickstream.clickstream_detail
WHERE event_date_mst = CURRENT_DATE() - 1
  AND adjusted_uu_id = '<specific_user_id>'
ORDER BY datetime_mst;
```

### 3. Marketing channel effectiveness
```sql
SELECT 
    kpi_channel_view,
    paid_vs_organic,
    COUNT(DISTINCT adjusted_uu_id) as users,
    COUNT(DISTINCT visit_id) as sessions,
    COUNT(DISTINCT inquiry_lead_id) as leads
FROM rdc_analytics.clickstream.clickstream_detail
WHERE event_date_mst >= CURRENT_DATE() - 7
  AND product_vertical = 'for_sale'
GROUP BY 1, 2
ORDER BY 3 DESC;
```
