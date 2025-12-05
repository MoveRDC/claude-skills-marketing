# Enhanced Skills Librarian - Quick Reference

## What Can the Librarian Do?

### 🔍 **Skill Discovery**
- "What skills are available?"
- "Find skills for campaign analysis"
- "Show me all marketing skills"
- "Which skill handles veteran targeting?"

### 📦 **Skill Installation**
- "Install rdc-marketing-analytics"
- "What dependencies does this skill need?"
- "Install attribution-modeling with all dependencies"

### 🔗 **Relationship Mapping** ⭐ NEW
- "What skills does rdc-marketing-analytics depend on?"
- "Which skills work together for campaign analysis?"
- "Show me the dependency tree"
- "Are there any conflicts between these skills?"

### 💡 **Smart Recommendations** ⭐ NEW
- "Any recommendations for improving my skills?"
- "Should we create a new skill for this workflow?"
- "Is my skill up to date?"
- "What skills am I missing?"

### 📚 **Knowledge Discovery** ⭐ NEW
- "Find documentation about veteran targeting"
- "Search for campaign strategy docs"
- "Where's the lead scoring methodology?"
- "Show me related knowledge from Drive/Confluence/GitHub"

### 🔧 **Skill Management**
- "Create a new skill for lead scoring"
- "Update rdc-marketing-analytics"
- "Add DSA metrics to the marketing skill"

### 📊 **Workflows** ⭐ NEW
- "What workflows use rdc-marketing-analytics?"
- "Show me the campaign analysis workflow"
- "How do I run multi-touch attribution?"

## Common Workflows

### Install a Skill (with Dependencies)
```
You: "Install attribution-modeling"

Librarian: 
"attribution-modeling requires:
 1. snowflake-connector (v1.5.0+)
    [Download link]
 2. rdc-marketing-analytics (v2.0.0+)
    [Download link]
 3. attribution-modeling (v1.0.0)
    [Download link]
    
 Install all dependencies in order, then test with:
 'Analyze attribution for Q4 campaigns'"
```

### Get a Recommendation
```
You: (After asking about DSA campaigns 3 times)

Librarian:
"💡 Recommendation: Enhance rdc-marketing-analytics
 
 I notice you're asking about DSA campaign performance 
 frequently. Should we add:
 • DSA page feed analysis
 • Dynamic ad performance metrics
 • Automated optimization rules
 
 Impact: Handle 80% of your DSA queries automatically
 Effort: Medium (2-3 hours)
 
 Proceed? [Yes / Not now]"
```

### Discover Knowledge
```
You: "How do we calculate veteran audience sizes?"

Librarian:
"No skill currently covers this. Let me search for docs...

Found:
1. GitHub: audience-sizing.md
2. Drive: Veteran Strategy Q4 2024.pdf
3. Confluence: Military Marketing Guidelines

[Provides summary from docs]

This comes up often. Should we create a 
'veteran-targeting' skill?"
```

### Check Skill Relationships
```
You: "What skills work together for campaign analysis?"

Librarian:
"Campaign Performance Analysis workflow uses:

rdc-marketing-analytics (campaign data)
    ↓
lead-scoring (lead quality)
    ↓
attribution-modeling (multi-touch attribution)

To run: 'Analyze campaign performance for Q4 with 
        lead quality and attribution'"
```

## Key Concepts

### Dependencies
- **Required**: Must have for skill to work
- **Optional**: Enhances functionality
- **Conflicts**: Can't use together
- **Integrates**: Works well together

### Recommendations
- **Enhancement**: Improve existing skill
- **New Skill**: Create skill for common task
- **Update**: New API version or features
- **Workflow**: Use existing skill combinations
- **Optimization**: Better performance

### Knowledge Sources
- **GitHub**: Code, docs, configurations
- **Drive**: Strategy docs, reports, analyses
- **Confluence**: Wiki, processes, guidelines

### Version Numbers
- **MAJOR.MINOR.PATCH** (e.g., 2.1.0)
- **MAJOR**: Breaking changes
- **MINOR**: New features (compatible)
- **PATCH**: Bug fixes

## Trigger Phrases

### For Relationships
- "dependencies"
- "what does X need"
- "works with"
- "conflicts with"
- "dependency tree"

### For Recommendations
- "recommendations"
- "suggestions"
- "should we create"
- "improvements"
- "optimize"

### For Knowledge
- "find documentation"
- "search for"
- "where's the"
- "how do we"
- "methodology"

### For Workflows
- "workflow"
- "how do I run"
- "what's the process"
- "which skills for"

## Pro Tips

### 1. Let the Librarian Discover Gaps
When you ask something a skill should handle but doesn't, 
the librarian will:
- Search for relevant documentation
- Suggest creating/enhancing skills
- Track patterns for recommendations

### 2. Check Dependencies Before Installing
Always ask "What dependencies does X need?" before 
installing to understand the full picture.

### 3. Use Workflows for Common Tasks
Instead of chaining multiple skills manually, ask:
"What's the workflow for [task]?"

### 4. Trust the Recommendations
The librarian learns from your patterns. When it suggests
improvements, it's based on your actual usage.

### 5. Link Knowledge to Skills
When you find useful docs, tell the librarian:
"Add this to the marketing skill's knowledge sources"

### 6. Keep Skills Updated
Ask monthly: "Any outdated skills?" to catch deprecations
and new features.

## What's Different?

### Before (v1.x)
- ✅ Find skills
- ✅ Install skills
- ✅ Create skills
- ✅ Update skills

### Now (v2.0) - Enhanced
- ✅ All previous features
- ⭐ Map skill relationships
- ⭐ Smart recommendations
- ⭐ Knowledge discovery
- ⭐ Workflow optimization
- ⭐ Automatic dependency checking
- ⭐ Drift detection
- ⭐ Usage pattern analysis

## Examples by Role

### Marketing Analyst
```
"Find skills for campaign analysis"
→ Shows rdc-marketing-analytics + related skills + workflows

"What's my workflow for monthly campaign review?"
→ Shows Campaign Performance Analysis workflow

"Any recommendations?"
→ Suggests adding DSA metrics based on your queries
```

### Skill Developer
```
"Create lead-scoring skill"
→ Searches for scoring docs, shows available knowledge

"What dependencies does this need?"
→ Shows required skills and version constraints

"Check for conflicts"
→ Validates no conflicts with existing skills
```

### Team Lead
```
"What skills do we have?"
→ Complete catalog with relationships

"Which skills need updates?"
→ Shows outdated skills and API deprecations

"What knowledge isn't in any skill?"
→ Knowledge gap analysis
```

## Getting Started

### First Time User
1. "What skills are available?"
2. "What does rdc-marketing-analytics do?"
3. "Install rdc-marketing-analytics"
4. "What workflows use this skill?"

### Regular User
1. Use skills normally
2. When you see a recommendation, consider it
3. If you search for docs often, ask about creating a skill
4. Check "Any recommendations?" monthly

### Skill Maintainer
1. Keep metadata.json updated
2. Link knowledge sources
3. Watch for drift notifications
4. Review and act on enhancement recommendations

## Troubleshooting

### "Skill won't install"
→ Check dependencies: "What dependencies does X need?"

### "Getting errors using skill"
→ Check version: "Is X up to date?"

### "Can't find documentation"
→ Try knowledge search: "Search for [topic] in Drive"

### "Doing same task repeatedly"
→ Ask: "Should we create a skill for this?"

### "Skill seems slow"
→ Ask: "Any optimization recommendations for X?"

## Advanced Features

### Pattern Detection
The librarian learns from:
- Repeated similar queries
- Skill usage sequences
- Knowledge searches
- Error patterns

### Drift Detection
Automatically monitors:
- GitHub repo changes
- Drive document updates
- Confluence page edits
- API version changes

### Smart Ranking
Prioritizes recommendations by:
- Impact (how much it helps)
- Frequency (how often needed)
- Urgency (time sensitive?)
- Ease (implementation effort)

## Getting Help

### Quick Help
- "How does the librarian work?"
- "What can you do?"
- "Help with skills"

### Specific Help
- "How do I check dependencies?"
- "How do recommendations work?"
- "How does knowledge discovery work?"

### Examples
- "Show me an example of a workflow"
- "Example of a good metadata.json"
- "How should I structure a new skill?"

---

**Version**: 2.0.0
**Last Updated**: 2024-12-05
**Full Documentation**: See IMPLEMENTATION-GUIDE.md
