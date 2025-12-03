#!/bin/bash
# Setup script for claude-skills-marketing repository

echo "🚀 Setting up claude-skills-marketing repository"
echo ""

# Step 1: Create repository on GitHub
echo "📝 Step 1: Create the repository on GitHub"
echo ""
echo "Please go to: https://github.com/organizations/MoveRDC/repositories/new"
echo ""
echo "Repository settings:"
echo "  - Name: claude-skills-marketing"
echo "  - Description: Claude AI skill packages for RDC Marketing Analytics team"
echo "  - Visibility: Private (recommended)"
echo "  - DO NOT initialize with README, .gitignore, or license"
echo ""
read -p "Press Enter once you've created the repository..."

# Step 2: Push to GitHub
echo ""
echo "📤 Step 2: Pushing code to GitHub..."
cd /home/claude/claude-skills-marketing

# Set the remote (using token from environment or hardcoded)
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Using token from script..."
    git remote set-url origin https://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@github.com/MoveRDC/claude-skills-marketing.git
else
    echo "Using token from environment..."
    git remote set-url origin https://$GITHUB_TOKEN@github.com/MoveRDC/claude-skills-marketing.git
fi

# Push to main branch
echo "Pushing to main branch..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Success! Repository is live at:"
    echo "   https://github.com/MoveRDC/claude-skills-marketing"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Visit the repository URL above"
    echo "  2. Verify all files are there"
    echo "  3. Share with your team!"
    echo "  4. Consider adding a repository description and topics"
else
    echo ""
    echo "❌ Push failed. This could be because:"
    echo "  1. Repository doesn't exist yet - create it first"
    echo "  2. Token doesn't have proper permissions"
    echo "  3. Network connectivity issue"
    echo ""
    echo "Try creating the repository manually and running this script again."
fi
