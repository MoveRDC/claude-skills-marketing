# Knowledge Discovery System

The librarian acts as a strategic intermediary between skills and knowledge repositories, enabling intelligent two-way interaction for knowledge discovery and integration.

## Core Concept

Skills contain structured, actionable knowledge. Repositories (GitHub, Drive, Confluence) contain unstructured documentation, code, reports, and institutional knowledge. The librarian bridges these worlds by:

1. **Discovering knowledge** when skills need information
2. **Integrating knowledge** into new or existing skills
3. **Maintaining links** between skills and source knowledge
4. **Identifying gaps** where knowledge exists but no skill uses it
5. **Tracking evolution** as knowledge updates over time

## Knowledge Sources

### GitHub Repositories

**Use for:**
- Code examples and implementations
- Technical documentation (markdown files)
- Issue discussions and solutions
- Configuration examples
- Scripts and automation

**Tools:**
- `github:search_repositories` - Find relevant repos
- `github:search_code` - Find code snippets
- `github:search_issues` - Find discussions
- `github:get_file_contents` - Read specific files

**Example patterns:**
```
User: "How do we configure Snowflake connection parameters?"

Discovery:
1. Search MoveRDC repos for "snowflake connection config"
2. Find: marketing-infrastructure/snowflake/config-template.yml
3. Extract connection parameters
4. Either: 
   a) Provide directly to user
   b) Suggest adding to snowflake-connector skill
```

### Google Drive

**Use for:**
- Strategy documents
- Analysis reports
- Campaign plans
- Meeting notes
- Presentations

**Tools:**
- `google_drive_search` - Search Drive files
- `google_drive_fetch` - Read specific documents

**Example patterns:**
```
User: "What's our strategy for veteran targeting?"

Discovery:
1. Search Drive: "veteran targeting strategy"
2. Find: "Veteran Audience Strategy Q4 2024.pdf"
3. Read document content
4. Either:
   a) Summarize strategy for user
   b) Suggest creating veteran-targeting skill
```

### Confluence

**Use for:**
- Process documentation
- Team wikis
- Guidelines and policies
- Historical context
- Decision records

**Tools:**
- `Atlassian:search` - Search Confluence
- `Atlassian:getConfluencePage` - Read specific pages

**Example patterns:**
```
User: "What's the approval process for large campaigns?"

Discovery:
1. Search Confluence: "campaign approval process"
2. Find: Marketing/Campaign Guidelines/Approval Workflow
3. Read approval process
4. Either:
   a) Explain process to user
   b) Suggest adding to campaign-management skill
```

## Discovery Workflows

### 1. Just-in-Time Knowledge Retrieval

When user asks question not covered by skills:

```
┌─────────────────────────────────────────────────────────┐
│ Knowledge Discovery Workflow                            │
└─────────────────────────────────────────────────────────┘

User Query: "How do we calculate veteran audience sizes?"

Step 1: Check existing skills
└─> Result: No skill handles this

Step 2: Identify knowledge gap
└─> Need: Veteran audience calculation methodology

Step 3: Search knowledge repositories
├─> GitHub: Search MoveRDC repos
│   └─> Found: marketing-docs/veteran-targeting/
│              audience-sizing.md
├─> Drive: Search "veteran audience"  
│   └─> Found: "Veteran Audience Strategy Q4 2024.pdf"
└─> Confluence: Search "veteran targeting"
    └─> Found: Military Marketing Guidelines page

Step 4: Rank results by relevance
1. audience-sizing.md (90% match - technical guide)
2. Veteran Audience Strategy.pdf (85% match - strategic doc)
3. Military Marketing Guidelines (70% match - general info)

Step 5: Provide knowledge
├─> Direct answer: [Summarize from audience-sizing.md]
└─> Source links: [Links to all 3 resources]

Step 6: Recommend skill creation
"This comes up frequently. Should we create a 
 'veteran-targeting' skill? It would include:
 • Audience sizing methodology
 • VA loan holder identification
 • Targeting recommendations
 
 Knowledge sources available for skill:
 • GitHub: marketing-docs/veteran-targeting/
 • Drive: Veteran strategy docs
 • Confluence: Marketing guidelines"
```

### 2. Proactive Knowledge Integration

Periodically scan repositories for knowledge that should be in skills:

```
┌─────────────────────────────────────────────────────────┐
│ Proactive Integration Workflow                          │
└─────────────────────────────────────────────────────────┘

Weekly scan: Check for new documentation

Step 1: Monitor repository changes
├─> GitHub: Check recent commits to docs/
├─> Drive: Check recently modified files
└─> Confluence: Check recently updated pages

Step 2: Identify relevant updates
Example findings:
• New document: "DSA Campaign Best Practices.pdf"
• Updated: marketing-docs/google-ads/dsa-guidelines.md
• New page: Dynamic Search Ads Optimization

Step 3: Map to existing skills
└─> rdc-marketing-analytics should cover DSA but doesn't

Step 4: Recommend enhancement
"New DSA documentation detected:
 • DSA Campaign Best Practices.pdf (Drive)
 • dsa-guidelines.md (GitHub)
 • Dynamic Search Ads Optimization (Confluence)
 
 Recommendation: Enhance rdc-marketing-analytics with:
 • DSA-specific metrics and analysis
 • DSA optimization rules from guidelines
 • DSA page feed management
 
 Knowledge sources ready to integrate."
```

### 3. Skill-Driven Knowledge Search

When creating/updating skill, search for relevant knowledge:

```
┌─────────────────────────────────────────────────────────┐
│ Skill-Driven Search Workflow                            │
└─────────────────────────────────────────────────────────┘

User: "Create a lead-scoring skill"

Step 1: Identify knowledge needs
Required knowledge:
• Lead scoring methodology
• Lead quality criteria
• Scoring model parameters
• Historical performance data

Step 2: Search repositories
├─> GitHub repos:
│   ├─> marketing-models/lead-scoring/
│   └─> data-science/scoring-algorithms/
├─> Drive:
│   ├─> "Lead Scoring Model v2.3.pdf"
│   ├─> "Lead Quality Analysis Q3 2024.xlsx"
│   └─> "Scoring Criteria Documentation.docx"
└─> Confluence:
    ├─> Lead Management Guidelines
    └─> Scoring Model Changelog

Step 3: Extract relevant information
From GitHub:
• Scoring algorithm implementation
• Feature engineering code
• Model performance metrics

From Drive:
• Business rules for scoring
• Quality thresholds
• Historical accuracy data

From Confluence:
• Process documentation
• Approval requirements
• Change history

Step 4: Integrate into skill
Create lead-scoring skill with:
├─> SKILL.md (methodology from docs)
├─> references/
│   ├─> scoring-model.md (from GitHub)
│   ├─> business-rules.md (from Drive)
│   └─> scoring-criteria.md (from all sources)
└─> metadata.json (including knowledge_sources)

Step 5: Link knowledge sources
{
  "knowledge_sources": [
    {
      "type": "github",
      "url": "https://github.com/MoveRDC/marketing-models/
              tree/main/lead-scoring",
      "description": "Scoring algorithms and implementation"
    },
    {
      "type": "gdrive",
      "path": "Marketing Analytics/Lead Scoring",
      "description": "Business rules and model documentation"
    },
    {
      "type": "confluence",
      "space": "MARKETING",
      "page": "Lead Management Guidelines",
      "description": "Process and approval workflows"
    }
  ]
}
```

## Knowledge Source Tracking

### In metadata.json

Every skill should track its knowledge sources:

```json
{
  "name": "rdc-marketing-analytics",
  "knowledge_sources": [
    {
      "type": "github",
      "url": "https://github.com/MoveRDC/marketing-docs",
      "path": "schemas/snowflake/",
      "description": "Database schema definitions",
      "last_synced": "2024-03-20",
      "critical": true
    },
    {
      "type": "gdrive",
      "path": "Marketing Analytics/Documentation",
      "file_pattern": "*.pdf",
      "description": "Analysis methodologies and reports",
      "last_synced": "2024-03-15",
      "critical": false
    },
    {
      "type": "confluence",
      "space": "MARKETING",
      "page_id": "123456",
      "description": "Marketing metrics glossary",
      "last_synced": "2024-03-18",
      "critical": true
    },
    {
      "type": "external",
      "url": "https://developers.google.com/google-ads/api/docs",
      "description": "Google Ads API documentation",
      "version": "v15",
      "last_synced": "2024-03-10",
      "critical": true
    }
  ]
}
```

### Tracking Fields

- **type**: github | gdrive | confluence | external
- **url/path**: Location of knowledge
- **description**: What knowledge this source provides
- **last_synced**: When skill was last updated from this source
- **critical**: Is this a required source for skill to function?
- **version**: For versioned sources (APIs, etc.)

## Two-Way Synchronization

### Pull: Knowledge → Skill

When knowledge updates, update skill:

```
Knowledge Update Detected:
└─> GitHub commit to marketing-docs/schemas/snowflake/
    New table: CAMPAIGN_ATTRIBUTION

Action:
1. Identify affected skills
   └─> rdc-marketing-analytics uses Snowflake schemas
   
2. Check if skill needs update
   └─> New table could enhance attribution analysis
   
3. Recommend update
   "New Snowflake table detected: CAMPAIGN_ATTRIBUTION
    
    This could enhance rdc-marketing-analytics with:
    • Multi-touch attribution analysis
    • Channel contribution tracking
    • Conversion path analysis
    
    Update skill to include this table?"
```

### Push: Skill → Knowledge

When skill evolves, update documentation:

```
Skill Enhancement Made:
└─> Added DSA metrics to rdc-marketing-analytics

Action:
1. Identify linked documentation
   ├─> GitHub: marketing-docs/metrics/glossary.md
   └─> Confluence: Marketing Metrics Glossary
   
2. Check if documentation needs update
   └─> New metrics should be documented
   
3. Update documentation
   ├─> Add DSA metrics to glossary.md
   └─> Update Confluence page with new metrics
   
4. Commit changes
   "Updated metrics glossary with new DSA metrics
    from rdc-marketing-analytics v2.2.0"
```

## Knowledge Gap Analysis

Identify where knowledge exists but isn't being used:

```
┌─────────────────────────────────────────────────────────┐
│ Knowledge Gap Analysis                                  │
└─────────────────────────────────────────────────────────┘

Periodic scan: Monthly

Step 1: Catalog all knowledge
├─> GitHub: 127 documentation files
├─> Drive: 89 strategy/analysis documents  
└─> Confluence: 234 wiki pages

Step 2: Map to existing skills
For each knowledge item, check:
• Is it referenced by any skill?
• Is its content used in any skill?

Step 3: Identify unused knowledge
Found:
• "Competitor Analysis Framework.pdf" (Drive)
  └─> No skill uses this methodology
  
• "Customer Lifetime Value Model.py" (GitHub)
  └─> No skill implements this model
  
• "Seasonal Campaign Patterns" (Confluence)
  └─> No skill leverages these insights

Step 4: Prioritize by value
Rank by:
• How often is this knowledge accessed?
• How valuable is it to business?
• How much time could a skill save?

Top candidates:
1. Competitor Analysis Framework (High access, high value)
2. Customer LTV Model (Medium access, high value)
3. Seasonal Patterns (High access, medium value)

Step 5: Recommend skill creation
"High-value knowledge found not in any skill:

1. Competitor Analysis Framework
   • Accessed 15 times this quarter
   • Could create 'competitive-intelligence' skill
   • Would automate competitor tracking workflow
   
2. Customer LTV Model  
   • Accessed 10 times this quarter
   • Could create 'customer-lifetime-value' skill
   • Would enable LTV-based campaign optimization
   
Should we prioritize creating these skills?"
```

## Search Strategies

### Multi-source Search

For comprehensive knowledge discovery:

```python
def discover_knowledge(query, context):
    """
    Search across all knowledge sources in parallel
    """
    results = []
    
    # Search GitHub
    github_results = search_github_repos(
        query=query,
        org="MoveRDC",
        repo_patterns=["*-docs", "*-strategy"],
        file_types=[".md", ".py", ".yml"]
    )
    results.extend(github_results)
    
    # Search Google Drive
    drive_results = google_drive_search(
        query=query,
        folders=["Marketing Analytics", "Strategy", "Documentation"],
        mime_types=["application/pdf", "application/vnd.google-apps.document"]
    )
    results.extend(drive_results)
    
    # Search Confluence
    confluence_results = confluence_search(
        query=query,
        spaces=["MARKETING", "ANALYTICS", "STRATEGY"]
    )
    results.extend(confluence_results)
    
    # Rank by relevance
    ranked_results = rank_by_relevance(results, query, context)
    
    return ranked_results
```

### Relevance Ranking

Score results by multiple factors:

```python
def rank_by_relevance(results, query, context):
    """
    Rank search results by relevance
    """
    for result in results:
        score = 0
        
        # Text match quality (0-40 points)
        score += calculate_text_match(result.content, query) * 40
        
        # Recency (0-20 points)
        age_days = (now - result.updated).days
        score += max(0, 20 - (age_days / 30))
        
        # Authority (0-20 points)
        if result.source == "github" and "official-docs" in result.path:
            score += 20
        elif result.source == "confluence" and result.space == "OFFICIAL":
            score += 20
        elif result.source == "drive" and "Strategy" in result.path:
            score += 15
        
        # Access frequency (0-10 points)
        score += min(10, result.access_count / 5)
        
        # Context relevance (0-10 points)
        if context and context_matches(result, context):
            score += 10
        
        result.relevance_score = score
    
    return sorted(results, key=lambda r: r.relevance_score, reverse=True)
```

### Smart Query Expansion

Expand queries to find related knowledge:

```python
def expand_query(original_query):
    """
    Expand query with related terms and synonyms
    """
    expansions = []
    
    # Original query
    expansions.append(original_query)
    
    # Domain-specific synonyms
    synonyms = {
        "campaign": ["ad group", "campaign group", "marketing campaign"],
        "lead": ["conversion", "prospect", "inquiry"],
        "ROAS": ["return on ad spend", "ROI", "ad efficiency"],
        "veteran": ["military", "VA", "service member"]
    }
    
    for term, alts in synonyms.items():
        if term in original_query.lower():
            for alt in alts:
                expansions.append(original_query.replace(term, alt))
    
    # Related concepts
    related = get_related_concepts(original_query)
    expansions.extend(related)
    
    return expansions
```

## Integration Patterns

### Pattern 1: Documentation → Skill Reference

Simple reference to external docs:

```markdown
## Lead Scoring Methodology

For detailed methodology, see:
- [Scoring Model Documentation](https://drive.google.com/file/d/...)
- [Algorithm Implementation](https://github.com/MoveRDC/marketing-models)

Quick reference:
- Score range: 0-100
- Threshold for qualified lead: 70+
- Model updated quarterly
```

### Pattern 2: Documentation → Skill Content

Extract and incorporate content:

```markdown
## Campaign Attribution Windows

Attribution windows vary by campaign type:

| Campaign Type | View Window | Click Window |
|--------------|-------------|--------------|
| Brand Search | 1 day       | 30 days      |
| Non-Brand    | 1 day       | 7 days       |
| Display      | 1 day       | 1 day        |
| Video        | 3 days      | 3 days       |

Source: Marketing Attribution Guidelines (Confluence)
Last updated: 2024-03-15
```

### Pattern 3: Code → Skill Implementation

Incorporate code from repositories:

```markdown
## Calculating Expected Future Revenue (EFR)

Implementation based on data-science/revenue-models/efr.py:

```python
def calculate_efr(lead_score, market, property_type):
    """
    Calculate Expected Future Revenue for a lead
    """
    base_rate = BASE_RATES[market][property_type]
    score_multiplier = lead_score / 100
    market_adj = MARKET_ADJUSTMENTS[market]
    
    return base_rate * score_multiplier * market_adj
```

Constants and market adjustments defined in config/efr-parameters.yml
```

### Pattern 4: Live Integration

Reference that stays synced:

```markdown
## Snowflake Schema

Current schema documentation: [schema.yml](https://github.com/MoveRDC/
marketing-docs/blob/main/schemas/snowflake/rdc_marketing.yml)

⚠️ This is a live reference. Schema may change. 
Check repository for latest version.

Last synced: 2024-03-20
```

## Maintenance and Updates

### Detecting Knowledge Drift

Monitor when knowledge becomes outdated:

```python
def check_knowledge_drift(skill):
    """
    Check if skill's knowledge sources have updated
    """
    drift_detected = []
    
    for source in skill.knowledge_sources:
        if source.type == "github":
            last_commit = get_latest_commit(source.url, source.path)
            if last_commit.date > source.last_synced:
                drift_detected.append({
                    "source": source,
                    "drift_age": (now - source.last_synced).days,
                    "changes": last_commit.message
                })
        
        elif source.type == "gdrive":
            files = get_drive_files(source.path)
            updated_files = [f for f in files 
                           if f.modified > source.last_synced]
            if updated_files:
                drift_detected.append({
                    "source": source,
                    "updated_files": len(updated_files),
                    "drift_age": max((now - f.modified).days 
                                   for f in updated_files)
                })
        
        elif source.type == "confluence":
            page = get_confluence_page(source.page_id)
            if page.updated > source.last_synced:
                drift_detected.append({
                    "source": source,
                    "drift_age": (now - source.last_synced).days,
                    "version": page.version
                })
    
    return drift_detected
```

### Sync Recommendations

When drift detected:

```
Knowledge Drift Detected:
┌─────────────────────────────────────────────────────────┐
│ Skill: rdc-marketing-analytics                          │
│ Source: GitHub marketing-docs/schemas/snowflake/        │
│ Drift age: 12 days                                      │
│                                                         │
│ Changes detected:                                       │
│ • Added table: CAMPAIGN_ATTRIBUTION                     │
│ • Modified table: LEADS (new column: lead_quality_v2)   │
│ • Added table: VETERAN_SEGMENTS                         │
│                                                         │
│ Impact on skill:                                        │
│ • CAMPAIGN_ATTRIBUTION enables new attribution analysis │
│ • lead_quality_v2 improves lead scoring accuracy        │
│ • VETERAN_SEGMENTS enables veteran targeting queries    │
│                                                         │
│ Recommendation:                                         │
│ Update skill to incorporate these schema changes.       │
│                                                         │
│ Action: Update now? [Yes / Review changes / Ignore]     │
└─────────────────────────────────────────────────────────┘
```

## Best Practices

1. **Always track sources**: Include knowledge_sources in metadata.json
2. **Keep links updated**: Maintain accurate paths and URLs
3. **Document sync dates**: Track last_synced for drift detection
4. **Prioritize critical sources**: Mark essential sources as critical
5. **Search broadly first**: Cast wide net, then filter
6. **Rank by relevance**: Don't just return first results
7. **Provide context**: Explain where knowledge came from
8. **Maintain bidirectional links**: Skills ↔ Knowledge
9. **Monitor for drift**: Regular checks for outdated knowledge
10. **Recommend integration**: Suggest turning frequent searches into skills

## Success Metrics

Track effectiveness of knowledge discovery:

- **Discovery success rate**: % of queries answered from repositories
- **Time to knowledge**: How quickly relevant knowledge is found
- **Integration rate**: % of discovered knowledge integrated into skills
- **Drift detection rate**: % of knowledge updates caught
- **User satisfaction**: Feedback on knowledge quality and relevance
- **Coverage**: % of repository knowledge referenced by skills

Target metrics:
- Discovery success: >80%
- Time to knowledge: <30 seconds
- Integration rate: >50% for high-value knowledge
- Drift detection: >90% of changes caught within 7 days
- User satisfaction: >4/5
- Coverage: >60% of frequently accessed docs
