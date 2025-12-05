# Repository Map

Quick reference for MoveRDC/claude-skills-marketing structure.

## Directory Overview

| Path | Purpose |
|------|--------|
| `skills/` | Skill source folders |
| `registry/` | Central registry (relationships, knowledge, versions) |
| `dist/` | Packaged .skill files for installation |
| `docs/` | User documentation |
| `config/` | Configuration files |

## Registry Files

| File | Purpose |
|------|--------|
| `registry/skill-graph.yaml` | Skill relationships and bundles |
| `registry/knowledge-sources.yaml` | External knowledge pointers |
| `registry/versions.yaml` | Version tracking and changelog |

## Skill Folder Structure

```
skills/{skill-name}/
├── SKILL.md            # Required - main skill definition
└── references/         # Optional - supporting documents
```

## Current Skills

| Skill | Description |
|-------|-------------|
| rdc-marketing-analytics | SEM campaigns, lead analysis, Snowflake |
| data-quality-validation | Data validation and schema checking |
| taxonomy-updater | Taxonomy and content classification |
| skills-librarian | Toolkit orchestration |

## Common Operations

```python
# List skills
github:get_file_contents(owner="MoveRDC", repo="claude-skills-marketing", path="skills")

# Get skill relationships
github:get_file_contents(owner="MoveRDC", repo="claude-skills-marketing", path="registry/skill-graph.yaml")

# Get knowledge sources
github:get_file_contents(owner="MoveRDC", repo="claude-skills-marketing", path="registry/knowledge-sources.yaml")

# Check versions
github:get_file_contents(owner="MoveRDC", repo="claude-skills-marketing", path="registry/versions.yaml")

# Read specific skill
github:get_file_contents(owner="MoveRDC", repo="claude-skills-marketing", path="skills/{name}/SKILL.md")
```
