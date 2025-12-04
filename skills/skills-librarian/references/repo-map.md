# Repository Map

Quick reference for MoveRDC/claude-skills-marketing structure.

## Directory Overview

| Path | Purpose | Operations |
|------|---------|------------|
| `skills/` | Skill source folders | Read, Create, Update |
| `dist/` | Packaged .skill files | Read (users download from here) |
| `docs/` | User documentation | Read, Update |
| `scripts/` | Setup scripts | Read |
| `config/` | Configuration | Read |

## Key Files

| File | Purpose |
|------|---------||
| `README.md` | Repository overview, quick start |
| `CHANGELOG.md` | Version history |
| `CONTRIBUTING.md` | Contribution guidelines |

## Skill Folder Structure

```
skills/{skill-name}/
├── SKILL.md            # Required - main skill definition
└── references/         # Optional - supporting documents
    ├── schema.md       # Database schemas
    ├── business_logic.md # Rules and formulas
    └── glossary.md     # Terms and acronyms
```

## Current Skills

| Skill | Path | Description |
|-------|------|-------------|
| rdc-marketing-analytics | `skills/rdc-marketing-analytics/` | Real estate marketing SEM, leads, Snowflake |

## File Locations for Common Tasks

**Installing a skill**: Download from `dist/{skill-name}-v{version}.skill`

**Reading skill details**: `skills/{skill-name}/SKILL.md`

**Adding new skill**: Create folder in `skills/`, push SKILL.md

**Updating skill content**: Edit files in `skills/{skill-name}/`

**Checking latest version**: List `dist/` folder, find highest version number

## GitHub Operations Quick Reference

```python
# List skills
github:get_file_contents(owner="MoveRDC", repo="claude-skills-marketing", path="skills")

# Read skill
github:get_file_contents(owner="MoveRDC", repo="claude-skills-marketing", path="skills/{name}/SKILL.md")

# List available downloads
github:get_file_contents(owner="MoveRDC", repo="claude-skills-marketing", path="dist")

# Create new skill
github:push_files(
  owner="MoveRDC", 
  repo="claude-skills-marketing",
  branch="main",
  message="Add {skill-name} skill",
  files=[
    {path: "skills/{name}/SKILL.md", content: "..."},
    {path: "skills/{name}/references/file.md", content: "..."}
  ]
)

# Update existing file (requires sha)
github:create_or_update_file(
  owner="MoveRDC",
  repo="claude-skills-marketing", 
  path="skills/{name}/SKILL.md",
  branch="main",
  message="Update ...",
  content="...",
  sha="{from get_file_contents}"
)
```
