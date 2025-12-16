# Amplitude Data Architecture Reference

This document describes the data architecture, flow, and integration patterns for RDC's Amplitude implementation.

## Overview

RDC's Amplitude implementation consists of multiple data sources feeding into different projects, each optimized for specific use cases.

## Data Types

### 1. Event Data (Clickstream)

**Definition**: Event-level data capturing granular user interactions with realtor.com

**Sources**: 
- Proprietary first-party tracking SDKs (web and native apps)
- Segment (scheduled for deprecation)

**Schema**: Event name, event properties, user properties, timestamps

**Processing Workflow**:
1. User interactions recorded and validated
2. Events routed through Segment (being deprecated)
3. Events transition to Snowflake via Kafka as raw data
4. Analytics layers applied during processing
5. Data restructured into JSON format
6. Uploaded to Amplitude's S3 bucket
7. Appears in Amplitude UI

**Latency**: ~4 hours from user action to Amplitude availability

### 2. Leads Data (Submitted Lead Detail)

**Definition**: LCS lead submission data, unique at the `submitted_lead_id` level

**Sources**: Processed data from Lead Capture System (LCS)

**Schema**: Lead ID, source, activity information at submission time

**Integration**: 
- Ingested into dedicated Realtor - Leads 2.0 project
- Cross-linked with event data in Leads + Clickstream 2.0 portfolio

**Use**: Calculate Lead Submission Rates (LSR), analyze lead quality

### 3. Customer Data (RealStore)

**Definition**: Event-level data capturing interactions on customer-facing pages

**Sources**: RealSuite data ingestion (currently)

**Schema**: Customer user ID, event names, event/user properties

**Future**: Plans to incorporate additional sources for unified customer view

### 4. Consumer Enrichment Data

**Definition**: Supplementary user-level information appended to clickstream

**Sources**: 
- Third-party providers
- Internal predictive models (Medallia, EFR predictions)

**Schema**: Consumer satisfaction scores, estimated future revenues, CRM attributes

**Integration**: Partially implemented, enables advanced segmentation

### 5. Experimentation Data

**Definition**: Experiment bucketing and analysis data

**Sources**: Amplitude APIs and SDKs directly

**Schema**: Assignment events, exposure events (experiment groups, participation)

**Integration**: Fully enabled after migration from Optimizely

---

## Project Architecture

### Primary Analytics Projects

```
┌─────────────────────────────────────────────────────────────────┐
│                    AMPLITUDE ORGANIZATION                        │
│                         (Realtor.com)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ Realtor -       │    │ Real Time SDK - │                    │
│  │ Production      │    │ Prod            │                    │
│  │ (558383)        │    │ (675822)        │                    │
│  │                 │    │                 │                    │
│  │ • Source of     │    │ • Real-time     │                    │
│  │   truth         │    │   data          │                    │
│  │ • All platforms │    │ • Session       │                    │
│  │ • Enriched data │    │   Replay        │                    │
│  │ • ~4hr delay    │    │ • Web only      │                    │
│  └─────────────────┘    └─────────────────┘                    │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ Realtor -       │    │ Leads +         │                    │
│  │ Leads 2.0       │    │ Clickstream 2.0 │                    │
│  │ (678364)        │    │ (670280)        │                    │
│  │                 │    │                 │                    │
│  │ • Lead events   │    │ • Cross-project │                    │
│  │ • EFR data      │    │   analysis      │                    │
│  │ • Delivery flags│    │ • User journeys │                    │
│  └─────────────────┘    └─────────────────┘                    │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ Consumer        │    │ Consumer        │                    │
│  │ Marketing -     │    │ Marketing -     │                    │
│  │ Braze (674963)  │    │ Cordial (678109)│                    │
│  │                 │    │                 │                    │
│  │ • Push/notif    │    │ • Email events  │                    │
│  │ • App engagement│    │ • Unsubscribes  │                    │
│  └─────────────────┘    └─────────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Diagram

```
                    ┌──────────────┐
                    │  User Action │
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Web SDK  │    │ iOS SDK  │    │Android   │
    │ (GTM)    │    │          │    │SDK       │
    └────┬─────┘    └────┬─────┘    └────┬─────┘
         │               │               │
         │    ┌──────────┴───────────────┘
         │    │
         ▼    ▼
    ┌──────────────────┐
    │     Segment      │  ◄── Being deprecated
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │      Kafka       │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐         ┌──────────────────┐
    │    Snowflake     │◄────────│  LCS (Leads)     │
    │  (Raw Events)    │         │  Enrichment Data │
    └────────┬─────────┘         └──────────────────┘
             │
             ▼
    ┌──────────────────┐
    │ Analytics Layer  │
    │ (Transformations)│
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │  Amplitude S3    │
    │   Import         │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │   Amplitude UI   │
    │   (Production)   │
    └──────────────────┘


    ┌──────────────────┐
    │ Real-Time Path:  │
    │                  │
    │ User Action      │
    │      │           │
    │      ▼           │
    │ Amplitude SDK    │
    │ (via GTM)        │
    │      │           │
    │      ▼           │
    │ Amplitude        │
    │ (Real Time SDK)  │
    └──────────────────┘
```

---

## Data Freshness

| Project | Data Source | Latency | Refresh |
|---------|-------------|---------|---------|
| Realtor - Production | Snowflake S3 import | ~4 hours | Continuous |
| Real Time SDK - Prod | Direct SDK | Near real-time | Continuous |
| Realtor - Leads 2.0 | Snowflake | Daily | Nightly batch |
| Consumer Marketing (Braze) | Braze webhook | Near real-time | Continuous |
| Consumer Marketing (Cordial) | Cordial webhook | Near real-time | Continuous |

---

## Identity Resolution

### Amplitude Identity

Amplitude uses a hierarchy for user identification:

1. **User ID** - Set when user authenticates (RDC member ID)
2. **Device ID** - Generated by SDK, persists across sessions
3. **Amplitude ID** - Internal ID assigned by Amplitude

### RDC Identity Fields

| Field | Source | Scope | Persistence |
|-------|--------|-------|-------------|
| `adjusted_uu_id` | Snowflake | Cross-platform | Session |
| `rdc_visitor_id` | RDC systems | Web/App | Long-term |
| `browser_id` | Browser | Web only | Browser storage |
| `mobile_id` | Device | App only | Device |
| `visit_id` | Session | Single session | Session |
| `consumer_member_id` | Authentication | Authenticated users | Permanent |

### Cross-System Mapping

```
Snowflake                    Amplitude
─────────                    ─────────
adjusted_uu_id      →        User ID (when set)
                             Device ID
edw_visitor_id      →        Custom property
client_visitor_id   →        Custom property
visit_id            →        Custom property
```

---

## Contract & Limits

| Metric | Limit |
|--------|-------|
| Events per year | 60 billion |
| Users | Unlimited |
| Data sources | Unlimited (analytics approval required) |
| Historical data | 12 months loaded at contract start |
| Contract term | 3 years (started Jan 2024) |

---

## Governance

### Project Ownership

| Project | Owner Team |
|---------|------------|
| Realtor - Production | DSAP |
| Real Time SDK - Prod | Digital Analytics |
| Realtor - Leads 2.0 | DSAP |
| Consumer Marketing | Digital Analytics |

### Change Request Process

1. Open ticket in Amplitude Change Request (ACR) Jira Project
2. Notification sent to DL-amplitude-governance@realtor.com
3. Changes validated against taxonomy guidelines
4. Q/A validation of event accuracy

### Access

- Access via Okta SSO
- Submit SOFI ticket to enable Amplitude tile
- Currently limited to Product and Analytics orgs

---

## Integration Points

### Snowflake to Amplitude

- S3 bucket import
- JSON format transformation
- Enrichment data join in analytics layer

### Amplitude SDK to Amplitude

- Direct event streaming
- GTM container for web
- Native SDK for mobile apps

### CRM Integrations

- **Braze**: Webhook-based event streaming
- **Cordial**: Webhook-based email event streaming

### Experiment Platform

- Amplitude Experiment SDK
- Local evaluation in client SDKs
- Assignment and exposure event tracking

---

## Monitoring & Maintenance

### Data Quality

- Regular audits via Data Reliability team
- Validation checks on event schemas
- Taxonomy enforcement through ACR process

### Event Health

- Monitor via Developer Portal Event Taxonomy Reference
- Track event volume trends
- Alert on unexpected schema changes

### Support Channels

- Slack: #tools-amplitude
- Amplitude in-app support
- DL-amplitude-governance@realtor.com
