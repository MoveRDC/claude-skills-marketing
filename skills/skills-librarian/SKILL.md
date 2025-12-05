---
name: skills-librarian
version: "2.0.0"
description: |
  Orchestrates the MoveRDC/claude-skills-marketing skill toolkit. Use for: discovering skills, 
  understanding skill relationships, finding knowledge sources, checking versions, installing skills, 
  or creating new skills. Triggers: "skill library", "what skills", "install skill", "skill relationships", 
  "what works with", "check updates", "find documentation", "knowledge sources".
---

# Skills Librarian

Orchestrates the skill toolkit: discovery, relationships, knowledge, and lifecycle.

## Repository Structure

```
MoveRDC/claude-skills-marketing/
├── skills/                 # Skill source folders
├── registry/               # Central registry (NEW)
│   ├── skill-graph.yaml    # Skill relationships
│   ├── knowledge-sources.yaml  # External knowledge pointers
│   └── versions.yaml       # Version tracking
├── dist/                   # Packaged .skill files
├── docs/                   # Documentation
└── config/                 # Configuration
```

## Core Capabilities

### 1. Discover Skills

List available skills with descriptions and triggers.

**Workflow:**
1. Fetch `skills/` directory listing
2. Read each skill's SKILL.md frontmatter
3. Present concise catalog

**Response format:**
```
Available skills:

• rdc-marketing-analytics - SEM campaigns, lead analysis, Snowflake queries
• data-quality-validation - Data validation and schema checking  
• taxonomy-updater - Taxonomy and content classification
• skills-librarian - This skill; manages the toolkit
```

### 2. Map Skill Relationships

**Trigger:** "what works with X" / "skill relationships" / "what complements"

**Workflow:**
1. Fetch `registry/skill-graph.yaml`
2. Find relationships for requested skill
3. Present connections and bundles

**Response format:**
```
rdc-marketing-analytics relationships:

Works well with:
• data-quality-validation → Run validation before analytics queries
• taxonomy-updater → Align taxonomy with analytics dimensions

Recommended bundle: marketing-data-pipeline
  Workflow: Validate data → Run analytics
  Use when: Starting new analysis or debugging data issues
```

**Relationship types:**
- `complements` - Often used together
- `extends` - Builds on another skill's capabilities
- `orchestrates` - Manages other skills (librarian only)

### 3. Find Knowledge Sources

**Trigger:** "where can I learn about" / "find documentation" / "knowledge sources"

**Workflow:**
1. Fetch `registry/knowledge-sources.yaml`
2. Match request to discovery hints or sources
3. Point to specific references or external docs

**Response format:**
```
Knowledge sources for Snowflake queries:

In skills:
• rdc-marketing-analytics/references/schema.md - Table definitions
• rdc-marketing-analytics/references/metrics.md - Metric calculations

External:
• Snowflake Docs: https://docs.snowflake.com
  Useful for: SQL syntax, functions, optimization
```

### 4. Check Versions & Updates

**Trigger:** "check updates" / "what version" / "changelog"

**Workflow:**
1. Fetch `registry/versions.yaml`
2. Compare to installed version (if known) or show current
3. Present recent changes

**Response format:**
```
rdc-marketing-analytics: v1.3.0 (Dec 4, 2025)

Recent changes:
• Added EFR metrics
• Updated schema for Q4 tables
• Added veteran homeowner targeting

No breaking changes since v1.0.0
```

### 5. Install Skills

**Workflow:**
1. Check `dist/` for latest .skill file
2. Provide download link and instructions

**Response format:**
```
To install rdc-marketing-analytics:

1. Download: [rdc-marketing-analytics-v1.3.0.skill](https://github.com/MoveRDC/claude-skills-marketing/raw/main/dist/rdc-marketing-analytics-v1.3.0.skill)
2. Claude Desktop: Settings → Skills → Install
```

### 6. Create New Skills

**Workflow:**
1. Gather: name, description, triggers, use cases
2. Create SKILL.md using template structure
3. Push to `skills/{name}/` via GitHub
4. Update `registry/skill-graph.yaml` with relationships
5. Update `registry/versions.yaml` with initial version
6. Remind to package for dist/

See [references/skill-template.md](references/skill-template.md) for structure.

### 7. Update Existing Skills

**Workflow:**
1. Fetch current content via GitHub
2. Make requested edits
3. Commit changes
4. Update `registry/versions.yaml` with new version entry
5. Update CHANGELOG.md

## GitHub Operations

### Reading Registry
```
github:get_file_contents
  owner: MoveRDC
  repo: claude-skills-marketing
  path: registry/skill-graph.yaml
```

### Reading Skills
```
github:get_file_contents
  owner: MoveRDC
  repo: claude-skills-marketing
  path: skills/{skill-name}/SKILL.md
```

### Creating/Updating Files
```
github:create_or_update_file
  owner: MoveRDC
  repo: claude-skills-marketing
  path: {path}
  branch: main
  message: "{description}"
  content: {content}
  sha: {required for updates}
```

### Multi-file Operations
```
github:push_files
  owner: MoveRDC
  repo: claude-skills-marketing
  branch: main
  message: "{description}"
  files: [{path, content}, ...]
```

## Quick Reference

| User wants | Action |
|------------|--------|
| List skills | Fetch skills/ directory |
| Skill relationships | Fetch registry/skill-graph.yaml |
| Find documentation | Fetch registry/knowledge-sources.yaml |
| Check versions | Fetch registry/versions.yaml |
| Install skill | Link to dist/{name}-{version}.skill |
| Create skill | Use template, push to skills/, update registry |
| Update skill | Edit files, update versions.yaml |

## Conciseness Guidelines

- Lead with action (link, answer, recommendation)
- Skip explanations user didn't ask for
- One-liner when possible, expand only if asked
- For relationships: show the "why" briefly
