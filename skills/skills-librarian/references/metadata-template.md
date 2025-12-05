# Skill Metadata Template

This file provides the template and guidelines for creating `metadata.json` files for skills.

## Purpose

The `metadata.json` file provides machine-readable metadata about a skill including:
- Version information
- Dependencies (required and optional)
- Trigger keywords
- Relationships with other skills
- Knowledge sources
- Tools used

## Required Fields

```json
{
  "name": "skill-name",
  "version": "1.0.0",
  "description": "Brief description of what the skill does"
}
```

## Full Schema

```json
{
  "name": "skill-name",
  "version": "1.0.0",
  "description": "Brief description of what the skill does",
  "author": "Team Name or Person",
  "created": "2024-01-15",
  "updated": "2024-03-20",
  "license": "MIT",
  
  "dependencies": {
    "required-skill-name": ">=1.0.0",
    "another-required-skill": "^2.1.0"
  },
  
  "optionalDependencies": {
    "enhancement-skill": ">=1.0.0",
    "complementary-skill": "^1.5.0"
  },
  
  "conflicts": [
    "conflicting-skill-name"
  ],
  
  "triggers": [
    "keyword1",
    "keyword2", 
    "keyword phrase",
    "regex:pattern.*"
  ],
  
  "domains": [
    "marketing",
    "analytics",
    "real-estate"
  ],
  
  "tools_used": [
    "snowflake:query_snowflake",
    "github:search_repositories",
    "google_drive_search"
  ],
  
  "knowledge_sources": [
    {
      "type": "github",
      "url": "https://github.com/MoveRDC/marketing-docs",
      "description": "Marketing documentation and guidelines"
    },
    {
      "type": "gdrive", 
      "path": "Marketing Analytics/Veteran Strategy",
      "description": "Veteran targeting strategy documents"
    },
    {
      "type": "confluence",
      "space": "MARKETING",
      "description": "Marketing team wiki"
    }
  ],
  
  "tags": [
    "analytics",
    "marketing",
    "sem"
  ],
  
  "maturity": "stable",
  
  "changelog": "CHANGELOG.md",
  "documentation": "README.md",
  
  "maintainers": [
    {
      "name": "Team Name",
      "email": "team@example.com"
    }
  ]
}
```

## Field Descriptions

### Core Fields

- **name**: Skill identifier (lowercase-with-hyphens)
- **version**: Semantic version (MAJOR.MINOR.PATCH)
- **description**: One-line description of skill purpose
- **author**: Creator of the skill
- **created**: Creation date (YYYY-MM-DD)
- **updated**: Last update date (YYYY-MM-DD)
- **license**: License type (e.g., MIT, Apache-2.0)

### Dependency Fields

- **dependencies**: Required skills for this skill to function
  - Key: skill name
  - Value: version constraint
    - `>=1.0.0` - Version 1.0.0 or higher
    - `^2.1.0` - Compatible with 2.x (2.1.0 to <3.0.0)
    - `~1.5.0` - Approximately 1.5.x (1.5.0 to <1.6.0)
    - `1.2.3` - Exact version

- **optionalDependencies**: Skills that enhance but aren't required
- **conflicts**: Skills that conflict with this one (can't be installed together)

### Discovery Fields

- **triggers**: Keywords and patterns that should invoke this skill
  - Simple keywords: `"google ads"`
  - Multi-word phrases: `"campaign performance"`
  - Regex patterns: `"regex:CPL|CPA|ROAS"`

- **domains**: Broad categories this skill belongs to
  - Examples: marketing, analytics, finance, operations

- **tags**: Specific tags for categorization and search
  - More granular than domains
  - Examples: sem, ppc, attribution, conversion-tracking

### Integration Fields

- **tools_used**: MCP tools this skill requires or commonly uses
  - Format: `"tool_namespace:tool_name"`
  - Examples: `"snowflake:query_snowflake"`, `"github:search_repositories"`

- **knowledge_sources**: External knowledge repositories this skill references
  - Can include GitHub repos, Google Drive folders, Confluence spaces
  - Used by librarian to discover related knowledge

### Quality Fields

- **maturity**: Development stage
  - `experimental` - Early development, may change significantly
  - `beta` - Feature complete but may have bugs
  - `stable` - Production ready
  - `deprecated` - No longer maintained, use alternative

- **changelog**: Path to changelog file
- **documentation**: Path to additional documentation
- **maintainers**: Contact info for skill maintainers

## Version Constraint Examples

```json
{
  "dependencies": {
    "skill-a": "1.2.3",           // Exact version
    "skill-b": ">=1.0.0",         // 1.0.0 or higher
    "skill-c": ">=1.0.0 <2.0.0",  // 1.x only
    "skill-d": "^1.5.0",          // 1.5.0 to <2.0.0
    "skill-e": "~1.5.0",          // 1.5.0 to <1.6.0
    "skill-f": "*"                // Any version (not recommended)
  }
}
```

## Creating metadata.json for New Skills

1. **Start with template**: Copy required fields above
2. **Add dependencies**: List all required skills with version constraints
3. **Define triggers**: List all keywords that should invoke this skill
4. **Set maturity**: Start with `experimental` or `beta`
5. **Document sources**: Add all knowledge repositories used
6. **List tools**: Include all MCP tools the skill uses
7. **Validate**: Ensure JSON is valid and all referenced skills exist

## Updating metadata.json

When updating a skill:

1. **Increment version**: Follow semantic versioning
   - MAJOR: Breaking changes
   - MINOR: New features, backward compatible
   - PATCH: Bug fixes

2. **Update dependencies**: If new dependencies added or version requirements changed

3. **Update date**: Set `updated` field to current date

4. **Update maturity**: Promote from experimental → beta → stable when appropriate

5. **Add knowledge sources**: If skill now references new documentation

6. **Update tools**: If skill now uses additional MCP tools

## Example: Real Marketing Analytics Skill

```json
{
  "name": "rdc-marketing-analytics",
  "version": "2.1.0",
  "description": "Real estate marketing analytics for SEM campaigns, lead analysis, and Snowflake queries",
  "author": "Marketing Analytics Team",
  "created": "2024-01-10",
  "updated": "2024-03-15",
  "license": "MIT",
  
  "dependencies": {
    "snowflake-connector": ">=1.5.0",
    "credentials-manager": ">=1.0.0"
  },
  
  "optionalDependencies": {
    "google-ads-api": ">=2.0.0",
    "data-visualization": ">=1.2.0"
  },
  
  "conflicts": [],
  
  "triggers": [
    "campaign performance",
    "lead quality",
    "ROAS",
    "CPL", 
    "CPA",
    "google ads",
    "sem analysis",
    "conversion tracking",
    "marketing metrics",
    "regex:(CPL|CPA|ROAS|EFR)"
  ],
  
  "domains": [
    "marketing",
    "analytics",
    "real-estate"
  ],
  
  "tools_used": [
    "snowflake:query_snowflake",
    "google_drive_search",
    "web_search"
  ],
  
  "knowledge_sources": [
    {
      "type": "github",
      "url": "https://github.com/MoveRDC/marketing-docs",
      "description": "Marketing documentation and schema definitions"
    },
    {
      "type": "gdrive",
      "path": "Marketing Analytics/Documentation",
      "description": "Marketing analytics reports and strategy docs"
    },
    {
      "type": "confluence",
      "space": "MARKETING",
      "description": "Marketing team processes and guidelines"
    }
  ],
  
  "tags": [
    "analytics",
    "marketing",
    "sem",
    "ppc",
    "conversion-tracking",
    "snowflake",
    "real-estate"
  ],
  
  "maturity": "stable",
  
  "changelog": "CHANGELOG.md",
  "documentation": "README.md",
  
  "maintainers": [
    {
      "name": "Marketing Analytics Team",
      "email": "marketing-analytics@move.com"
    }
  ]
}
```

## Best Practices

1. **Keep triggers specific**: Use exact terms users would say
2. **Version constraints loosely**: Use `>=` unless you need exact versions
3. **Document knowledge sources**: Help librarian find related information
4. **Update regularly**: Keep metadata in sync with skill changes
5. **Use semantic versioning**: Make version numbers meaningful
6. **Track maturity accurately**: Don't mark as stable until thoroughly tested
7. **List all tools**: Complete tool list helps with dependency planning
8. **Group by domain**: Consistent domains aid in skill discovery
