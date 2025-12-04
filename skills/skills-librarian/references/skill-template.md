# Skill Template

Use this template when creating new skills.

## Minimal SKILL.md Structure

```markdown
---
name: {skill-name}
description: {What it does}. Use when {triggers/contexts}. Triggers include {specific keywords}.
---

# {Skill Title}

Brief overview of the skill's purpose.

## Core Workflow

When a {domain} task is requested:
1. Step one
2. Step two
3. Step three

## Key Concepts

- **Term A** - Definition
- **Term B** - Definition

## References

- See [references/detail.md](references/detail.md) for {what it contains}
```

## Frontmatter Rules

**name**: lowercase-with-hyphens, matches folder name

**description**: Must include:
- What the skill does (first sentence)
- When to use it (trigger contexts)
- Specific trigger keywords

Example:
```yaml
description: Analyzes marketing campaign data. Use when working with SEM campaigns, lead metrics, or Snowflake queries. Triggers include Google Ads, ROAS, CPL, lead quality, campaign performance.
```

## When to Use References Folder

Use `references/` when:
- Content exceeds ~200 lines
- Information is looked up occasionally, not always needed
- Separating concerns (schema vs business logic vs glossary)

Don't create references for:
- Small additions (add to SKILL.md directly)
- Content needed on every invocation

## Naming Conventions

- Skill folder: `lowercase-with-hyphens`
- SKILL.md: Always uppercase
- Reference files: `snake_case.md` or `kebab-case.md`
- Skill file (dist): `{name}-v{version}.skill`

## Checklist Before Committing

- [ ] Frontmatter has name and description
- [ ] Description includes trigger keywords
- [ ] Body explains core workflow
- [ ] References are linked from SKILL.md
- [ ] No sensitive data (credentials, PII)
