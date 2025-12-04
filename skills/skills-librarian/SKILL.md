---
name: skills-librarian
description: Manages the MoveRDC/claude-skills-marketing skill repository. Use when users need to discover, install, update, or create skills. Triggers include queries about available skills, installing skills, creating new skills, updating skill content, finding skills for specific use cases, or managing the skill repository. Also use when users mention "skill library", "skill catalog", "install a skill", "add a new skill", or "update skill".
---

# Skills Librarian

Manages the MoveRDC/claude-skills-marketing skill repository on GitHub.

## Repository Structure

```
MoveRDC/claude-skills-marketing/
├── skills/                 # Source skill folders
│   └── {skill-name}/
│       ├── SKILL.md        # Main skill file
│       └── references/     # Supporting docs
├── dist/                   # Packaged .skill files (installable)
├── docs/                   # User documentation
├── scripts/                # Setup scripts
└── config/                 # Configuration files
```

## Core Capabilities

### 1. Discover Skills

When user asks about available skills or needs help finding one:

1. Use `github:get_file_contents` to list `/skills` directory
2. For each skill folder, read its `SKILL.md` frontmatter to get name/description
3. Present a concise catalog with trigger keywords

**Example response format:**
```
Available skills:

• rdc-marketing-analytics - SEM campaigns, lead analysis, Snowflake queries
  Triggers: campaign performance, lead quality, ROAS, CPL, Google Ads
```

### 2. Install Skills

When user wants to install a skill, provide these steps:

**For claude.ai or Claude Desktop:**
```
1. Download: https://github.com/MoveRDC/claude-skills-marketing/raw/main/dist/{skill-name}-{version}.skill
2. In Claude: Settings → Skills → Upload/Install
3. Verify: Ask "What skills do you have?"
```

To find the latest version, check the `dist/` folder for the most recent `.skill` file.

### 3. Select Relevant Skills

When user describes a task but doesn't know which skill to use:

1. Parse their request for domain keywords
2. Match against skill descriptions and triggers
3. Recommend the best-fit skill(s)
4. Provide quick install link

**Matching keywords by domain:**
- Marketing/SEM/ads/campaigns → rdc-marketing-analytics
- Snowflake/SQL/analytics → rdc-marketing-analytics
- Leads/conversion/CPL/ROAS → rdc-marketing-analytics

### 4. Create New Skills

When user wants to add a new skill:

1. **Gather requirements** - Ask about use cases, triggers, domain
2. **Create skill structure:**
   ```
   skills/{new-skill-name}/
   ├── SKILL.md
   └── references/   (if needed)
   ```
3. **Write SKILL.md** with proper frontmatter:
   ```yaml
   ---
   name: skill-name
   description: What it does and when to trigger it.
   ---
   ```
4. **Commit to repo** via `github:create_or_update_file` or `github:push_files`
5. **Package skill** - Remind user to create .skill file for dist/

See [references/skill-template.md](references/skill-template.md) for structure.

### 5. Update Existing Skills

When user wants to modify a skill:

1. **Fetch current content** using `github:get_file_contents`
2. **Make edits** based on user request
3. **Commit changes** via `github:create_or_update_file`
4. **Update CHANGELOG** with version notes
5. **Remind about packaging** - New .skill file needed for dist/

**Update patterns:**
- Add new reference docs → Create in `references/` subfolder
- Modify business logic → Edit SKILL.md or reference files
- Add new tables/schemas → Update schema reference file
- Fix errors → Direct edit with commit message

## GitHub Operations

### Reading Files
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
  files: [{path: "...", content: "..."}]
```

## Workflow: Add New Skill

1. **Plan**: Define name, description, triggers, references needed
2. **Create**: Build SKILL.md following template
3. **Commit**: Push to `skills/{name}/` folder
4. **Update README**: Add to available skills section
5. **Update CHANGELOG**: Document the addition
6. **Package**: Create .skill file and add to dist/

## Workflow: User Wants to Install

Quick response format:
```
To install {skill-name}:

1. Download the skill file:
   [Download {skill-name}.skill](https://github.com/MoveRDC/claude-skills-marketing/raw/main/dist/{filename}.skill)

2. In Claude, go to Settings → Skills → Install

3. Test with: "{example query}"
```

## Conciseness Guidelines

- Lead with action (download link, command)
- Skip explanations user didn't ask for
- One-liner when possible, expand only if asked
- For installation: link + 2-step max
