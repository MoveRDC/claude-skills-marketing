---
name: skills-librarian
description: Manages the MoveRDC/claude-skills-marketing skill repository and acts as strategic intermediary between skills and knowledge. Use when users need to discover, install, update, or create skills, understand skill relationships, get recommendations for improvements, manage skill lifecycle, or find relevant knowledge from repositories. Triggers include queries about available skills, skill dependencies, skill improvements, knowledge discovery, installing skills, creating new skills, updating skill content, finding skills for specific use cases, or managing the skill repository. Also use when users mention "skill library", "skill catalog", "install a skill", "add a new skill", "update skill", "which skills work together", "skill dependencies", or "find knowledge about".
---

# Skills Librarian

Manages the MoveRDC/claude-skills-marketing skill repository on GitHub and acts as a strategic intermediary between skills, knowledge repositories, and users. Enables intelligent skill discovery, relationship mapping, lifecycle management, and knowledge integration.

## Repository Structure

```
MoveRDC/claude-skills-marketing/
├── skills/                 # Source skill folders
│   └── {skill-name}/
│       ├── SKILL.md        # Main skill file
│       ├── references/     # Supporting docs
│       └── metadata.json   # Skill metadata (dependencies, version, relationships)
├── dist/                   # Packaged .skill files (installable)
├── docs/                   # User documentation
├── scripts/                # Setup scripts
├── config/                 # Configuration files
└── skill-graph.json        # Skill relationship map
```

## Core Capabilities

### 1. Discover Skills

When user asks about available skills or needs help finding one:

1. Use `github:get_file_contents` to list `/skills` directory
2. For each skill folder, read its `SKILL.md` frontmatter to get name/description
3. Check for `metadata.json` to identify dependencies and relationships
4. Present a concise catalog with trigger keywords and relationships

**Example response format:**
```
Available skills:

• rdc-marketing-analytics - SEM campaigns, lead analysis, Snowflake queries
  Triggers: campaign performance, lead quality, ROAS, CPL, Google Ads
  Works with: snowflake-connector, google-ads-api
  Version: 2.1.0

• snowflake-connector - Database connection and query management
  Triggers: Snowflake queries, data extraction, SQL
  Required by: rdc-marketing-analytics
  Version: 1.5.0
```

### 2. Map Skill Relationships

When user asks about skill connections or dependencies:

**Relationship Types:**
- **Required Dependencies**: Skills that must be present for this skill to function
- **Optional Integrations**: Skills that enhance functionality when present
- **Complementary Skills**: Skills that work well together for common workflows
- **Conflicts**: Skills that may overlap or conflict in functionality

**Workflow:**
1. Read `metadata.json` from skill folder (or parse SKILL.md if no metadata)
2. Build dependency graph across all skills
3. Identify:
   - Direct dependencies (A requires B)
   - Transitive dependencies (A requires B, B requires C)
   - Workflow chains (A → B → C for task X)
   - Conflicting capabilities

**Example queries:**
- "What skills does rdc-marketing-analytics need?"
- "Which skills work together for campaign analysis?"
- "Show me the dependency tree for this skill"
- "What skills complement real-estate-marketing-analytics?"

**Response format:**
```
rdc-marketing-analytics Dependencies:

Required:
└── snowflake-connector (>= 1.5.0)
    └── credentials-manager (>= 1.0.0)

Recommended:
├── google-ads-api (for Google Ads integration)
└── data-visualization (for reporting)

Works well with:
• attribution-modeling (for multi-touch analysis)
• lead-scoring (for lead quality assessment)
```

### 3. Recommend Skill Improvements

When analyzing skills or user requests context-based recommendations:

**Recommendation Engine considers:**
- **Usage patterns**: Which skills are frequently used together
- **Missing capabilities**: Gaps identified from user queries
- **Outdated components**: Skills that reference deprecated APIs or methods
- **Performance issues**: Skills with slow execution or inefficient workflows
- **Knowledge drift**: Skills that reference outdated business logic or data

**Trigger patterns:**
- User repeatedly asks questions a skill should handle but doesn't
- User chains multiple skills where one integrated skill would work better
- User encounters errors from outdated skill logic
- User describes workflow that partially matches existing skill

**Recommendation types:**

1. **Enhancement recommendations**:
   ```
   Recommendation: Enhance rdc-marketing-analytics
   
   Reason: You've asked about DSA campaign analysis 3 times this week, 
   but the skill doesn't cover DSA-specific metrics.
   
   Suggested additions:
   • Add DSA page feed analysis
   • Include dynamic ad performance metrics
   • Add automated DSA optimization rules
   
   Impact: Would handle 80% of your DSA queries automatically
   ```

2. **New skill recommendations**:
   ```
   Recommendation: Create "attribution-modeling" skill
   
   Reason: You frequently query multi-touch attribution across 
   google-ads-api and rdc-marketing-analytics separately.
   
   Would include:
   • Multi-touch attribution models (linear, time-decay, position-based)
   • Cross-channel conversion paths
   • Channel contribution analysis
   
   Dependencies: rdc-marketing-analytics, google-ads-api
   ```

3. **Update recommendations**:
   ```
   Recommendation: Update snowflake-connector
   
   Reason: Snowflake released new performance features (query acceleration)
   that could reduce query time by 40%.
   
   Suggested changes:
   • Add query acceleration service configuration
   • Update connection parameters for Snowflake 8.x
   • Add result caching strategies
   ```

4. **Deprecation warnings**:
   ```
   Warning: rdc-marketing-analytics references deprecated API
   
   Issue: Uses Google Ads API v13, which sunsets in Q2 2025
   
   Action needed:
   • Update to Google Ads API v15
   • Migrate conversion tracking endpoints
   • Update authentication flow
   ```

### 4. Manage Skill Lifecycle

**Version Control:**
- Track skill versions via `metadata.json` or frontmatter
- Maintain CHANGELOG.md for each skill
- Support semantic versioning (MAJOR.MINOR.PATCH)

**Update workflow:**
1. **Check current version**: Read metadata.json or SKILL.md
2. **Determine version bump**: 
   - PATCH: Bug fixes, typo corrections
   - MINOR: New features, backward-compatible changes
   - MAJOR: Breaking changes, API modifications
3. **Update files**: SKILL.md, metadata.json, references
4. **Update CHANGELOG**: Document changes with version
5. **Package**: Create new .skill file in dist/
6. **Notify dependents**: Check skill-graph.json for dependent skills

**Dependency management:**
```json
// metadata.json example
{
  "name": "rdc-marketing-analytics",
  "version": "2.1.0",
  "dependencies": {
    "snowflake-connector": ">=1.5.0",
    "credentials-manager": ">=1.0.0"
  },
  "optionalDependencies": {
    "google-ads-api": ">=2.0.0",
    "data-visualization": ">=1.2.0"
  },
  "conflicts": [],
  "changelog": "CHANGELOG.md"
}
```

**Automated dependency checking:**
When installing/updating a skill:
1. Read metadata.json dependencies
2. Check if required skills are installed
3. Verify version compatibility
4. Suggest installation order if dependencies missing
5. Warn about conflicts

### 5. Install Skills

When user wants to install a skill, provide these steps with dependency checking:

**Installation workflow:**
1. **Check dependencies**: Read skill metadata
2. **Verify requirements**: Ensure all dependencies are available
3. **Suggest installation order**: Dependencies first
4. **Provide download links**: For skill and dependencies
5. **Verify installation**: Suggest test query

**For claude.ai or Claude Desktop:**
```
To install rdc-marketing-analytics:

Dependencies required:
1. snowflake-connector (v1.5.0+)
   Download: [snowflake-connector.skill](https://github.com/MoveRDC/claude-skills-marketing/raw/main/dist/snowflake-connector-v1.5.0.skill)

2. credentials-manager (v1.0.0+)
   Download: [credentials-manager.skill](https://github.com/MoveRDC/claude-skills-marketing/raw/main/dist/credentials-manager-v1.0.0.skill)

Main skill:
3. rdc-marketing-analytics (v2.1.0)
   Download: [rdc-marketing-analytics.skill](https://github.com/MoveRDC/claude-skills-marketing/raw/main/dist/rdc-marketing-analytics-v2.1.0.skill)

Installation steps:
1. Install dependencies first (in order above)
2. In Claude: Settings → Skills → Upload/Install
3. Verify: Ask "What skills do you have?"
4. Test: "Show me Q4 campaign performance"
```

### 6. Strategic Intermediary Role

Act as bridge between skills and knowledge repositories for intelligent discovery:

**Knowledge Discovery:**
When user needs specific expertise not covered by current skills:

1. **Identify knowledge gap**: What information is needed but not in skills
2. **Search repositories**: 
   - GitHub repos (documentation, code, issues)
   - Confluence (internal documentation)
   - Google Drive (reports, analyses, plans)
3. **Assess relevance**: Score documents by relevance to query
4. **Recommend action**:
   - Link to existing knowledge
   - Suggest new skill creation
   - Suggest skill enhancement
   - Provide direct answer if knowledge is simple

**Example workflow:**
```
User: "How do we calculate veteran targeting audiences?"

Librarian analysis:
1. Check skills: rdc-marketing-analytics doesn't cover veteran targeting
2. Search GitHub: Find veteran-targeting.md in docs/
3. Search Drive: Find "Veteran Audience Strategy Q4 2024.pdf"
4. Recommend:
   a) Immediate: Here's the relevant documentation [links]
   b) Future: Should we create a "veteran-targeting" skill?
```

**Two-way interaction with repositories:**
- **Pull knowledge**: Search and retrieve relevant docs when needed
- **Push updates**: When skills evolve, update related documentation
- **Maintain links**: Keep skill references in sync with knowledge repos
- **Track usage**: Identify which knowledge is accessed frequently (candidates for skills)

### 7. Select Relevant Skills

When user describes a task but doesn't know which skill to use:

1. Parse their request for domain keywords
2. Match against skill descriptions and triggers
3. Check for relationship patterns (multiple skills needed?)
4. Recommend the best-fit skill(s) with workflow
5. Provide quick install links if not installed

**Matching keywords by domain:**
- Marketing/SEM/ads/campaigns → rdc-marketing-analytics
- Snowflake/SQL/analytics → snowflake-connector
- Leads/conversion/CPL/ROAS → rdc-marketing-analytics
- Google Ads API → google-ads-api
- Multi-touch attribution → attribution-modeling
- Veteran targeting → veteran-marketing (if exists)

**Multi-skill workflows:**
```
For "Analyze veteran lead quality from Q4 campaigns":

Skills needed:
1. rdc-marketing-analytics (campaign data)
2. lead-scoring (quality assessment)
3. veteran-targeting (audience segments)

Workflow:
1. Pull campaign data with rdc-marketing-analytics
2. Score leads with lead-scoring
3. Segment by veteran status with veteran-targeting
4. Cross-analyze results
```

### 8. Create New Skills

When user wants to add a new skill:

1. **Gather requirements** - Ask about:
   - Use cases and triggers
   - Domain and scope
   - Dependencies (what skills/tools needed?)
   - Related knowledge sources
   - Expected usage frequency

2. **Check for overlaps** - Search existing skills:
   - Would this duplicate functionality?
   - Should we enhance existing skill instead?
   - Would this conflict with other skills?

3. **Design skill structure:**
   ```
   skills/{new-skill-name}/
   ├── SKILL.md           # Main skill definition
   ├── metadata.json      # Version, dependencies, relationships
   ├── CHANGELOG.md       # Version history
   └── references/        # Supporting documents
       ├── schema.md      # Data schemas (if applicable)
       ├── workflows.md   # Common workflows
       └── glossary.md    # Domain terms
   ```

4. **Write SKILL.md** with proper frontmatter and content

5. **Create metadata.json** with dependencies and version

6. **Update skill graph**: Add to skill-graph.json relationships

7. **Commit to repo** via `github:push_files`

8. **Package skill** - Create .skill file for dist/

9. **Update documentation**: README.md, repo docs

See [references/skill-template.md](references/skill-template.md) for structure.

### 9. Update Existing Skills

When user wants to modify a skill:

1. **Fetch current content** using `github:get_file_contents`
   - SKILL.md
   - metadata.json
   - References
   - CHANGELOG.md

2. **Determine version impact**:
   - Breaking change? → MAJOR version bump
   - New feature? → MINOR version bump
   - Bug fix? → PATCH version bump

3. **Check dependents**: Use skill-graph.json to find skills that depend on this one

4. **Make edits** based on user request

5. **Update metadata**: Version number, dependencies if changed

6. **Update CHANGELOG** with version notes and date

7. **Commit changes** via `github:create_or_update_file`

8. **Test dependencies**: Ensure dependent skills still work

9. **Package new version** - New .skill file needed for dist/

10. **Notify stakeholders**: If breaking changes affect other skills

**Update patterns:**
- Add new reference docs → Create in `references/` subfolder
- Modify business logic → Edit SKILL.md or reference files
- Add new tables/schemas → Update schema reference file
- Fix errors → Direct edit with commit message
- Add new dependency → Update metadata.json and skill-graph.json
- Deprecate feature → Update CHANGELOG, add deprecation notice

## Self-Expanding Librarian System

**Vision**: The librarian manages the entire toolkit lifecycle:

1. **Monitors usage patterns**: Identifies frequently asked questions not covered by skills
2. **Suggests improvements**: Proactively recommends new skills or enhancements
3. **Manages dependencies**: Ensures all skills have required dependencies
4. **Updates automatically**: Pulls latest versions from repository
5. **Validates integrity**: Checks for conflicts and compatibility issues
6. **Discovers knowledge**: Searches repos when skills need information
7. **Maintains documentation**: Keeps skill docs in sync with implementations

**Unified Git-based system:**
- All skills stored in single repository (claude-skills-marketing)
- Version control for all changes
- Automated packaging and distribution
- CI/CD for skill validation and testing
- Centralized dependency management

**Future capabilities:**
- Automatic skill generation from documentation
- A/B testing for skill improvements
- Usage analytics and optimization
- Skill marketplace with ratings and reviews
- Automated dependency resolution and installation

## GitHub Operations

### Reading Files
```
github:get_file_contents
  owner: MoveRDC
  repo: claude-skills-marketing
  path: skills/{skill-name}/SKILL.md
```

### Reading Metadata
```
github:get_file_contents
  owner: MoveRDC
  repo: claude-skills-marketing
  path: skills/{skill-name}/metadata.json
```

### Reading Skill Graph
```
github:get_file_contents
  owner: MoveRDC
  repo: claude-skills-marketing
  path: skill-graph.json
```

### Creating/Updating Files
```
github:create_or_update_file
  owner: MoveRDC
  repo: claude-skills-marketing
  path: skills/{skill-name}/SKILL.md
  branch: main
  message: "Update {skill-name}: {description}"
  content: {file content}
  sha: {required for updates - get from get_file_contents}
```

### Multi-file Operations
```
github:push_files
  owner: MoveRDC
  repo: claude-skills-marketing
  branch: main
  message: "Add new skill: {skill-name}"
  files: [
    {path: "skills/{name}/SKILL.md", content: "..."},
    {path: "skills/{name}/metadata.json", content: "..."},
    {path: "skills/{name}/CHANGELOG.md", content: "..."},
    {path: "skills/{name}/references/schema.md", content: "..."}
  ]
```

## Workflow: Add New Skill

1. **Requirements gathering**: Understand use case, dependencies, scope
2. **Overlap check**: Search existing skills for similar functionality
3. **Plan structure**: Define name, description, triggers, references needed, dependencies
4. **Create files**: 
   - SKILL.md (main skill definition)
   - metadata.json (version, dependencies)
   - CHANGELOG.md (initial version entry)
   - references/ (if needed)
5. **Update skill graph**: Add relationships to skill-graph.json
6. **Commit**: Push to `skills/{name}/` folder
7. **Update README**: Add to available skills section
8. **Update global CHANGELOG**: Document the addition
9. **Package**: Create .skill file and add to dist/
10. **Test**: Verify installation and basic functionality

## Workflow: Update Existing Skill

1. **Assess change impact**: Determine version bump (MAJOR/MINOR/PATCH)
2. **Check dependents**: Read skill-graph.json for affected skills
3. **Fetch current files**: Get all relevant files with shas
4. **Make changes**: Update SKILL.md, references, metadata
5. **Update version**: Increment in metadata.json
6. **Update CHANGELOG**: Document changes with new version
7. **Test locally**: Ensure changes work as expected
8. **Commit changes**: Push updated files with descriptive message
9. **Check dependents**: Verify dependent skills still work
10. **Package new version**: Create new .skill file for dist/
11. **Notify**: If breaking changes, notify users/stakeholders

## Workflow: User Wants to Install

Quick response format with dependency checking:

```
To install {skill-name}:

Dependencies (install first):
1. [dependency-skill-v1.0.0.skill](link)
2. [another-dependency-v2.1.0.skill](link)

Main skill:
3. [{skill-name}-v{version}.skill](https://github.com/MoveRDC/claude-skills-marketing/raw/main/dist/{filename}.skill)

Installation:
1. Download all files above in order
2. In Claude: Settings → Skills → Install (upload each)
3. Verify: "What skills do you have?"
4. Test: "{example query}"
```

## Workflow: Knowledge Discovery

When user asks question not covered by existing skills:

1. **Identify gap**: What specific knowledge is needed?
2. **Check skills**: Verify no existing skill covers this
3. **Search repositories**:
   - GitHub MoveRDC org: `github:search_code`, `github:search_repositories`
   - Google Drive: `google_drive_search` for internal docs
   - Confluence: `Atlassian:search` for wiki pages
4. **Evaluate results**: Score by relevance and recency
5. **Provide knowledge**: 
   - Direct links to found documents
   - Summarize key information
   - Suggest whether this should become a skill
6. **Recommend action**:
   - One-off need → Provide answer from found docs
   - Repeated need → Suggest creating new skill
   - Existing skill gap → Suggest enhancement

## Workflow: Recommend Improvements

Continuous monitoring for optimization opportunities:

1. **Track usage patterns**: Note repeated queries, error patterns, workflow chains
2. **Identify gaps**: Questions skills should handle but don't
3. **Analyze performance**: Slow skills, outdated logic, deprecated APIs
4. **Compare to knowledge**: Check if skill logic matches current documentation
5. **Generate recommendations**:
   - Enhancement: Add feature to existing skill
   - New skill: Create skill for common workflow
   - Update: Modernize outdated skill
   - Deprecation: Remove or replace conflicting skill
6. **Present to user**: Explain reasoning, expected impact, implementation effort
7. **If approved**: Proceed with skill creation/update workflow

## Conciseness Guidelines

- Lead with action (download link, command, recommendation)
- Skip explanations user didn't ask for
- One-liner when possible, expand only if asked
- For installation: link + dependencies + 2-step max
- For recommendations: reason + impact + action
- For relationships: tree view or list format
- For knowledge discovery: links first, summary if needed

## Skill Metadata Schema

```json
{
  "name": "skill-name",
  "version": "1.0.0",
  "description": "What the skill does",
  "author": "Team/Person",
  "created": "2024-01-15",
  "updated": "2024-03-20",
  "dependencies": {
    "required-skill": ">=1.0.0",
    "another-skill": "^2.1.0"
  },
  "optionalDependencies": {
    "enhancement-skill": ">=1.0.0"
  },
  "conflicts": [],
  "triggers": [
    "keyword1",
    "keyword2",
    "phrase pattern"
  ],
  "domains": [
    "marketing",
    "analytics"
  ],
  "tools_used": [
    "snowflake:query_snowflake",
    "github:search_repositories"
  ],
  "knowledge_sources": [
    "https://github.com/MoveRDC/marketing-docs",
    "gdrive://folder/Veteran Marketing Strategy"
  ],
  "changelog": "CHANGELOG.md",
  "documentation": "README.md"
}
```

## Skill Graph Schema

```json
{
  "nodes": [
    {
      "id": "rdc-marketing-analytics",
      "version": "2.1.0",
      "type": "skill"
    },
    {
      "id": "snowflake-connector",
      "version": "1.5.0",
      "type": "skill"
    }
  ],
  "edges": [
    {
      "from": "rdc-marketing-analytics",
      "to": "snowflake-connector",
      "type": "requires",
      "version": ">=1.5.0"
    },
    {
      "from": "rdc-marketing-analytics",
      "to": "google-ads-api",
      "type": "integrates-with",
      "version": ">=2.0.0"
    }
  ]
}
```

## Advanced Features

### Conflict Detection
When installing/updating skills, check for:
- Duplicate functionality (two skills handle same triggers)
- Incompatible dependencies (A requires B v1, C requires B v2)
- Tool conflicts (both skills use same tool in incompatible ways)

### Usage Analytics
Track (if enabled):
- Most frequently used skills
- Common skill combinations
- Failed queries that no skill handles
- Skill performance metrics

### Smart Recommendations
Based on context:
- Time of year (Q4 → holiday campaigns skill)
- Recent activities (analyzing leads → suggest lead-scoring skill)
- Error patterns (repeated Snowflake errors → suggest query optimization skill)
- User role/team (marketing → marketing skills, analytics → data skills)
