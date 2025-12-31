# RDC Amplitude Events Taxonomy

Reference for event naming conventions and common events in the Realtor.com Amplitude implementation.

## Event Naming Conventions

### Standard Events
RDC events use lowercase naming without spaces:
- `pageview` - Page view
- `search` - Search performed
- `click` - Generic click action
- `signin` - User sign in
- `signup` - Account creation

### Lead Events
Lead events follow the pattern: `{vertical}{type}lead`
- `cobrokelead` - Cobroke listing lead
- `advantagelead` - New Construction listing lead
- `rentallead` - Rental property lead
- `farlead` - Find a Realtor lead

### Compound Lead Events
More specific lead types:
- `forsalecobroketextlead` - For sale cobroke text lead
- `forsalecobrokephonelead` - For sale cobroke phone lead
- `forsaleadvantagephonelead` - For sale advantage phone lead
- `forsaleadvantagetextlead` - For sale advantage text lead
- `rentalphonelead` - Rental phone lead
- `rentalbasiclead` - Rental basic lead
- `rentalshowcaselead` - Rental showcase lead

### Impression Events
- `pageview` - Full page load
- `modalimpression` - Modal display
- `moduleimpression` - Dynamic module load
- `componentimpression` - Component impression
- `listingimpression` - Listing card impression

## Complete Event Reference

### Core Engagement Events

| Event | Display Name | Description |
|-------|--------------|-------------|
| `pageview` | Viewed a page | Page load tracking |
| `search` | Performed a search | Search bar usage |
| `refinedsearch` | Refined search details | Filter modification on SRP |
| `click` | Performed a click | Generic click (when no specific event) |
| `listingclick` | listingclick | Listing card click |
| `saveditem` | Saved Item | Listing or search saved |
| `share` | Shared a home | Any share action |
| `emailshare` | Shared via email | Email share |
| `socialshare` | socialshare | Social media share |
| `successful_share` | Shared successfully | Completed share action |

### User Account Events

| Event | Display Name | Description |
|-------|--------------|-------------|
| `signup` | Created RDC account (Signup) | New account creation |
| `signin` | Signed-in | User login |
| `signout` | Signed-out | User logout |
| `claimhome` | Claimed a home | Home ownership claim |

### Lead Events - For Sale

| Event | Display Name | Description |
|-------|--------------|-------------|
| `cobrokelead` | Submitted cobroke lead | Cobroke listing lead |
| `advantagelead` | advantagelead | New Construction listing lead |
| `forsaleagentconnection` | For Sale Agent Connection Lead | Agent connection product lead |
| `forsalecobrokephonelead` | Submitted for sale cobroke phone lead | Phone lead on cobroke |
| `forsalecobroketextlead` | Submitted for sale cobroke text lead | Text lead on cobroke |
| `forsaleadvantagephonelead` | Submitted for sale advantage phone lead | Phone lead on advantage |
| `forsaleadvantagetextlead` | Submitted for sale advantage text lead | Text lead on advantage |
| `notforsalelead` | Submitted not for sale lead | Lead on sold/off-market listing |
| `buylead` | buylead | Generic buy lead |

### Lead Events - Rental

| Event | Display Name | Description |
|-------|--------------|-------------|
| `rentallead` | Submitted rental lead | Rental property lead |
| `rentalphonelead` | Submitted rental phone lead | Rental phone lead |
| `rentalbasiclead` | Submitted rental basic lead | Basic rental lead |
| `rentalbasicphonelead` | Submitted rental basic phone lead | Basic rental phone lead |
| `rentalshowcaselead` | Submitted rental showcase lead | Showcase rental lead |
| `rentalshowcasephonelead` | Submitted rental showcase phone lead | Showcase rental phone lead |
| `forrentcobroketextlead` | Submitted for rent cobroke text lead | Rental cobroke text lead |

### Lead Events - Other

| Event | Display Name | Description |
|-------|--------------|-------------|
| `farlead` | Submitted find a realtor (FAR) lead | Find a Realtor lead |
| `newconstructiondirectlead` | Submitted direct new construction lead | New construction lead |

### Notification Events

| Event | Display Name | Description |
|-------|--------------|-------------|
| `pushnotificationoptin` | Opted-in to push notification | Push notification opt-in |
| `pushnotificationoptout` | Opted-out of push notification | Push notification opt-out |

### Impression Events

| Event | Display Name | Description |
|-------|--------------|-------------|
| `modalimpression` | Served a page modal | Modal popup display |
| `moduleimpression` | Served a page module | Dynamic module load |
| `srpmodalimpression` | Served SRP modal | Search results page modal |
| `componentimpression` | componentimpression | Component impression |
| `listingimpression` | listingimpression | Listing card impression |

### App Events

| Event | Display Name | Description |
|-------|--------------|-------------|
| `applaunch` | Opened mobile app | Mobile app launch |
| `session_start` | [Amplitude] Start Session | Session start |

### Experiment Events

| Event | Display Name | Description |
|-------|--------------|-------------|
| `[Experiment] Exposure` | [Experiment] Exposure | Amplitude experiment exposure |
| `[Experiment] Assignment` | [Experiment] Assignment | Amplitude experiment assignment |
| `expexposure` | expexposure | Legacy experiment exposure |

### Amplitude SDK Events

| Event | Display Name | Description |
|-------|--------------|-------------|
| `[Amplitude] Page Viewed` | [Amplitude] Page Viewed | Amplitude SDK page view |
| `session_start` | [Amplitude] Start Session | Amplitude SDK session start |

## Meta Event Types

Special system events for aggregate analysis:

| Event Type | Description | Common Use |
|------------|-------------|------------|
| `_active` | Any non-inactive event | DAU, MAU, active users |
| `_new` | First event by new user | New user tracking |
| `_all` | All events | Total event volume |
| `_any_revenue_event` | Revenue-generating events | Revenue analysis |
| `$popularEvents` | Top events by volume | Taxonomy exploration |

## Event Properties

### Common Event Properties

Properties that appear on most events:

| Property | Type | Description |
|----------|------|-------------|
| `page_type` | string | Page type (ldp, srp, cdp, etc.) |
| `vertical` | string | Business vertical (buy, rent, sell) |
| `platform` | string | User platform |
| `listing_id` | string | Property listing ID |
| `search_id` | string | Search session ID |
| `experiment_variants` | string | Active experiment variants |

### Page Types

| Value | Description |
|-------|-------------|
| `ldp` | Listing Detail Page |
| `srp` | Search Results Page |
| `cdp` | Community Detail Page |
| `home` | Homepage |
| `far` | Find a Realtor |
| `myhome` | My Home dashboard |

### Verticals

| Value | Description |
|-------|-------------|
| `buy` | For sale listings |
| `rent` | Rental listings |
| `sell` | Seller services |
| `new_homes` | New construction |
| `mortgage` | Mortgage services |

## Discovering Events

### Search for Events
```python
Amplitude:search(
  entityTypes=["EVENT"],
  appIds=[558383],
  query="lead",
  limit=50
)
```

### Get Event Properties
After finding exact event name:
```python
Amplitude:get_event_properties(
  projectId="558383",
  eventType="cobrokelead"
)
```

### Explore Popular Events
```python
{
  "name": "Popular Events",
  "type": "eventsSegmentation",
  "app": "558383",
  "params": {
    "range": "Last 7 Days",
    "events": [{"event_type": "$popularEvents", "filters": [], "group_by": []}],
    "metric": "totals",
    "countGroup": "User",
    "groupBy": [],
    "interval": 1,
    "segments": [{"conditions": []}]
  }
}
```

## Project-Specific Events

### Realtor - Leads 2.0 (678364)
Lead-specific events with enhanced attribution:
- `lead_submitted` - Generic lead submission
- Lead events with additional attribution properties

### Consumer Marketing Data Braze (674963)
Email and push notification events:
- `Notification Open` - Push notification opened
- `Nudge Click` - Nudge interaction
- Campaign-specific events

### Consumer Marketing Data Cordial (678109)
Email engagement events:
- `Email Open` - Email opened
- `Email Click` - Email link click
- `Email Unsubscribe` - Unsubscribe action

### Real Time SDK - Prod (675822)
Browser SDK events with session replay:
- Standard web events
- Session replay metadata
- Performance metrics
