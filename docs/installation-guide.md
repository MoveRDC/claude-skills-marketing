# Installation Guide

Complete guide for installing and using Claude skills from this repository.

## Prerequisites

- Access to Claude Desktop or claude.ai
- Skills feature enabled in your Claude account
- Member of MoveRDC GitHub organization (for access to this repository)

## Installation Steps

### 1. Download the Skill File

**Option A: Via GitHub Web Interface**
1. Navigate to the `dist/` folder in this repository
2. Click on the latest skill file (e.g., `rdc-marketing-analytics-v1.1.skill`)
3. Click the "Download" button
4. Save to your Downloads folder

**Option B: Via Git Clone**
```bash
git clone https://github.com/MoveRDC/claude-skills-marketing.git
cd claude-skills-marketing/dist
# Skill files are here
```

### 2. Install in Claude

**Claude Desktop:**
1. Open Claude Desktop
2. Click on your profile/settings
3. Navigate to "Skills" section
4. Click "Install Skill" or "Add Skill"
5. Select the downloaded .skill file OR drag and drop it
6. Confirm installation

**claude.ai (Web):**
1. Go to https://claude.ai
2. Click the menu icon (☰) or your profile
3. Select "Skills" or "Settings" → "Skills"
4. Click "Upload Skill" or "Add Skill"
5. Select the downloaded .skill file
6. Confirm installation

### 3. Verify Installation

Ask Claude:
```
"What skills do you have?"
```

You should see "real-estate-marketing-analytics" or "RDC Marketing Analytics" in the list.

### 4. Test the Skill

Try a test query to ensure it's working:

```
"What tables do you know about in RDC_ANALYTICS?"
```

Claude should describe the LEADS, CLICKSTREAM, and PROPERTY_LISTINGS tables.

Or try:
```
"Explain what a DSA campaign is in our context"
```

Claude should provide marketing-specific context about Dynamic Search Ads.

## Updating to New Versions

When a new version is released:

### Simple Update (Recommended)

1. **Download new .skill file** from the `dist/` folder
2. **Install in Claude** (same process as initial installation)
3. **Existing skill will be replaced** automatically
4. **Verify** by checking the version in Claude

### Manual Removal (If Needed)

If you want to explicitly remove the old version first:

**Claude Desktop:**
1. Settings → Skills
2. Find "RDC Marketing Analytics"
3. Click "Remove" or "Uninstall"
4. Install new version

**claude.ai:**
1. Skills menu
2. Find the skill
3. Remove it
4. Upload new version

## Troubleshooting

### Skill Doesn't Appear After Installation

**Check:**
- File downloaded completely (should be ~10KB)
- Skills feature is enabled in your Claude account
- You're in the correct Skills section (not general settings)

**Try:**
- Restart Claude Desktop (if using desktop app)
- Refresh browser page (if using claude.ai)
- Reinstall the skill
- Check for error messages during installation

### Skill Installed But Not Activating

**Verify activation with specific queries:**
```
"Using our RDC marketing analytics skill, show me the key tables"
```

**Check:**
- Skill name appears in your skills list
- You're asking questions that should trigger the skill (marketing analytics, Snowflake, campaigns)
- Try explicitly mentioning the skill in your query

**If still not working:**
- Remove and reinstall
- Try with a fresh conversation
- Check if there are skill conflicts (too many skills installed)

### Getting Outdated Information

**Cause:** You may have an older version installed

**Solution:**
1. Check the version: Look at the filename of your installed skill
2. Compare to latest in `dist/` folder
3. Download and install the latest version
4. Verify update by asking about recently added content

### File Won't Download

**GitHub Authentication:**
- Ensure you're logged into GitHub
- Verify you have access to MoveRDC organization
- Check repository permissions

**Browser Issues:**
- Try a different browser
- Clear cache and try again
- Use git clone as alternative

## Best Practices

### Keep Skills Updated

**Monthly Check:**
- Review the CHANGELOG for updates
- Install new versions when released
- Test after updating to ensure it works

**Watch for Announcements:**
- Check #marketing-analytics Slack channel
- Monitor GitHub repository notifications
- Review team emails about skill updates

### Use Effectively

**Trigger the Skill:**
- Ask domain-specific questions (campaigns, leads, DMAs)
- Reference Snowflake tables or schemas
- Mention marketing analytics concepts

**Leverage the Knowledge:**
- Ask about available analysis patterns
- Request example queries for common tasks
- Inquire about metric definitions or business rules

**Don't Over-Rely:**
- Skills complement Claude's capabilities, don't replace thinking
- Verify important business decisions
- Cross-reference critical data

### Share with Team

**Onboarding New Members:**
1. Share this repository link
2. Guide them through installation
3. Demonstrate with example queries
4. Encourage exploration and questions

**Keep Everyone Aligned:**
- Announce updates in team channels
- Encourage reinstallation after updates
- Share useful queries or patterns discovered

## Multiple Skills

### Installing Additional Skills

You can install multiple skills simultaneously. Claude will use the appropriate skill based on your query.

**Tips:**
- Keep skill count reasonable (5-10 max)
- Remove unused skills to reduce context overhead
- Related skills work together (e.g., marketing + data analysis)

### Skill Conflicts

If multiple skills cover similar domains:
- Claude will try to use the most relevant one
- You can explicitly mention which skill to use
- Consider consolidating overlapping skills

## Security Notes

### Protect the Skill Files

- Don't share .skill files outside MoveRDC
- Don't commit them to public repositories
- Only download from trusted sources (this repo)

### Repository Access

- This is a private repository - keep access controlled
- Don't share GitHub URLs publicly
- Report unauthorized access

### Skill Content

Skills contain:
- Internal business logic
- Database schemas
- Process information

**Do not:**
- Screenshot and share externally
- Include actual query results in skill
- Add PII or sensitive customer data

## Getting Help

### Installation Issues

1. **Check this guide** for troubleshooting steps
2. **Search GitHub issues** for similar problems
3. **Ask in #marketing-analytics** Slack channel
4. **Contact skill maintainer** (@mikael)

### Usage Questions

1. **Try asking Claude** directly about the skill
2. **Review the README** for example queries
3. **Check CONTRIBUTING.md** for more details
4. **Open a GitHub issue** for clarification

### Feature Requests

1. **Open an issue** with "Enhancement" label
2. **Describe the use case** and benefit
3. **Provide examples** if applicable
4. **Tag the maintainer** for visibility

## Advanced: Automated Updates

For power users who want automatic skill updates:

### Git Pull + Reinstall Script

```bash
#!/bin/bash
# update-skills.sh

cd ~/claude-skills-marketing
git pull origin main

# Latest skill file
SKILL_FILE=$(ls -t dist/*.skill | head -1)

echo "Installing: $SKILL_FILE"
# On macOS:
open -a "Claude" "$SKILL_FILE"

# Or manually install via Claude interface
```

Run monthly or when notified of updates.

## Feedback

Your feedback improves the skills for everyone:

- **Installation problems?** Open an issue
- **Confusing documentation?** Suggest improvements  
- **Feature ideas?** Share in CONTRIBUTING.md format
- **General feedback?** Post in Slack or GitHub discussions

---

**Questions?** Contact @mikael on Slack or open a GitHub issue.

**Updated**: December 2, 2024
