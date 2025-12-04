# Publishing godot-mcp-shadows to GitHub

## Step-by-Step Guide

### 1. Create GitHub Repository

**Option A: Via Web Interface** (Recommended)

1. Go to https://github.com/new
2. Repository settings:
   - **Name**: `godot-mcp-shadows`
   - **Description**: `Godot MCP fork adapted for Shadows of the Moth game project and Godot 4.5 + Qwen3-Coder integration`
   - **Visibility**: Public ✅
   - **Initialize**: ❌ Do NOT initialize with README (we already have one)
   - **License**: MIT (matches upstream)
3. Click **Create repository**

**Option B: Via GitHub CLI**

```bash
gh repo create godot-mcp-shadows \
  --public \
  --description "Godot MCP fork for Shadows of the Moth + Godot 4.5 + Qwen3-Coder" \
  --source . \
  --remote origin \
  --push
```

### 2. Link Local Repository to GitHub

After creating the repository on GitHub, you'll see setup instructions. Use the "push an existing repository" section:

```bash
cd /home/justin/Desktop/projects_Copy/godot-mcp-shadows

# Add your GitHub repository as origin
git remote add origin https://github.com/YOUR_USERNAME/godot-mcp-shadows.git

# Verify remotes (should show both upstream and origin)
git remote -v

# Should output:
# origin    https://github.com/YOUR_USERNAME/godot-mcp-shadows.git (fetch)
# origin    https://github.com/YOUR_USERNAME/godot-mcp-shadows.git (push)
# upstream  https://github.com/Coding-Solo/godot-mcp.git (fetch)
# upstream  https://github.com/Coding-Solo/godot-mcp.git (push)

# Push to GitHub
git push -u origin main
```

### 3. Configure Repository Settings

#### A. Add Topics (GitHub web interface)

Go to repository → About → Settings (gear icon) → Add topics:
- `godot`
- `godot-engine`
- `godot4`
- `godot45`
- `mcp`
- `model-context-protocol`
- `ai-tools`
- `qwen`
- `game-development`
- `scene-automation`

#### B. Update Repository Description

**Description**: `Godot MCP fork for Shadows of the Moth - Automate scene creation with Godot 4.5 + Qwen3-Coder-30B`

**Website**: Link to Shadows of the Moth repository (if public)

#### C. Enable Issues/Discussions

- ✅ Issues: Enabled
- ✅ Discussions: Optional (recommended for Q&A)
- ✅ Projects: Optional
- ✅ Wiki: Optional

### 4. Create Initial GitHub Release (Optional)

```bash
# Tag the current state
git tag -a v0.1.0-fork -m "Initial fork with Shadows of the Moth documentation"
git push origin v0.1.0-fork

# Or use GitHub CLI
gh release create v0.1.0-fork \
  --title "v0.1.0 - Initial Fork" \
  --notes "Initial fork of godot-mcp with Shadows of the Moth integration documentation"
```

### 5. Add Fork Badge to README

Edit `README.md` (or `README_FORK.md`) and add at the top:

```markdown
# Godot MCP - Shadows of the Moth Fork

[![Original Repo](https://img.shields.io/badge/upstream-godot--mcp-blue)](https://github.com/Coding-Solo/godot-mcp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Godot](https://img.shields.io/badge/Godot-4.5%2B-478cbf?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![Node](https://img.shields.io/badge/Node-20%2B-339933?logo=node.js&logoColor=white)](https://nodejs.org/)

> **Fork Focus**: Adapted for [Shadows of the Moth](LINK_TO_YOUR_GAME_REPO) game project with Qwen3-Coder-30B integration
```

Commit and push:
```bash
git add README.md
git commit -m "docs: Add badges and fork attribution"
git push origin main
```

---

## Recommended GitHub Actions

### 1. CI Build Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'

    - name: Install dependencies
      run: npm install

    - name: Build
      run: npm run build

    - name: Verify build output
      run: |
        test -f build/index.js || exit 1
        test -f build/scripts/godot_operations.gd || exit 1

    - name: Upload build artifacts
      uses: actions/upload-artifact@v3
      with:
        name: build-output
        path: build/
```

### 2. Upstream Sync Workflow

Create `.github/workflows/sync-upstream.yml`:

```yaml
name: Sync Upstream

on:
  schedule:
    # Run weekly on Monday at 00:00 UTC
    - cron: '0 0 * * 1'
  workflow_dispatch:  # Allow manual trigger

jobs:
  sync:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0

    - name: Add upstream remote
      run: |
        git remote add upstream https://github.com/Coding-Solo/godot-mcp.git || true
        git fetch upstream

    - name: Check for updates
      id: check
      run: |
        git merge-base --is-ancestor upstream/main HEAD
        echo "needs_update=$?" >> $GITHUB_OUTPUT

    - name: Create PR if updates available
      if: steps.check.outputs.needs_update != '0'
      run: |
        git checkout -b sync-upstream-$(date +%Y%m%d)
        git merge upstream/main --no-edit || echo "Manual merge needed"
        git push origin sync-upstream-$(date +%Y%m%d)

        gh pr create \
          --title "Sync with upstream godot-mcp" \
          --body "Automated sync with upstream changes from godot-mcp" \
          --label "upstream-sync"
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Maintaining Your Fork

### Sync with Upstream Regularly

```bash
# Fetch upstream changes
git fetch upstream

# Check what's new
git log HEAD..upstream/main --oneline

# Merge upstream changes
git merge upstream/main

# Resolve conflicts if any
# Test to ensure custom operations still work

# Push to your fork
git push origin main
```

### Keep Documentation Updated

When adding new operations:
1. Update `README_FORK.md` with operation documentation
2. Add examples to `SETUP.md`
3. Update `GODOT_MCP_INTEGRATION.md` in Shadows of the Moth repo
4. Tag new version: `git tag v0.X.0-fork`

---

## Attribution & Licensing

### Required Attribution

Since this is a fork, always maintain attribution to the original:

**In README**:
```markdown
## Credits

This project is a fork of [godot-mcp](https://github.com/Coding-Solo/godot-mcp) by Coding-Solo.

### Original Project
- **Repository**: https://github.com/Coding-Solo/godot-mcp
- **License**: MIT
- **Author**: Coding-Solo

### Fork Modifications
- Adapted for Shadows of the Moth game project
- Added custom scene creation operations
- Qwen3-Coder-30B integration
- Godot 4.5 compatibility enhancements
```

### License

Keep the MIT license from upstream. Add your copyright for fork-specific changes:

```
MIT License

Copyright (c) 2024 Coding-Solo (Original godot-mcp)
Copyright (c) 2024 YOUR_NAME (Shadows of the Moth fork)

Permission is hereby granted...
```

---

## Checklist

Before making repository public:

- [ ] ✅ All commits have proper messages
- [ ] ✅ README_FORK.md exists and is complete
- [ ] ✅ SETUP.md has installation instructions
- [ ] ✅ LICENSE file includes both original and fork copyrights
- [ ] ✅ Upstream remote is configured correctly
- [ ] ✅ .gitignore prevents committing build artifacts
- [ ] ✅ No sensitive information in commit history
- [ ] ⏭️ GitHub repository created
- [ ] ⏭️ Local repo linked to GitHub origin
- [ ] ⏭️ Initial push completed
- [ ] ⏭️ Topics/tags added to repository
- [ ] ⏭️ Description and website links configured

---

## Post-Publication

### 1. Link from Shadows of the Moth

Update `Shadows_of_the_Moth/docs/GODOT_MCP_INTEGRATION.md`:

```markdown
## Fork Repository

We maintain a fork of godot-mcp with project-specific operations:

**Repository**: https://github.com/YOUR_USERNAME/godot-mcp-shadows

See the fork's README for:
- Custom operations for our game
- Qwen integration guide
- Scene templates
- Setup instructions
```

### 2. Optional: Submit PR to Upstream

If you add generally useful features, consider contributing back:

```bash
# Create feature branch
git checkout -b feature/useful-operation

# Make changes (keep them general-purpose, not game-specific)
# Commit with clear messages

# Push to your fork
git push origin feature/useful-operation

# Create PR on upstream repo
gh pr create --repo Coding-Solo/godot-mcp \
  --title "feat: Add useful operation" \
  --body "Description of changes..."
```

### 3. Announce Fork (Optional)

- Share on Godot forums/Discord
- Tweet about automated scene creation with Qwen
- Write blog post about your workflow

---

## Support & Maintenance

### Issues

- **Upstream issues**: Report to https://github.com/Coding-Solo/godot-mcp
- **Fork-specific issues**: Report to your fork repository
- **Shadows of the Moth issues**: Report to game repository

### Updates

Commit to reviewing and merging upstream changes monthly to avoid drift.

---

## Quick Commands Reference

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/godot-mcp-shadows.git

# Add upstream remote (if not already)
git remote add upstream https://github.com/Coding-Solo/godot-mcp.git

# Sync with upstream
git fetch upstream && git merge upstream/main

# Push changes
git push origin main

# Create new tag
git tag v0.X.0-fork && git push origin v0.X.0-fork

# View commit history
git log --oneline --graph --all
```

---

You're now ready to publish your fork as a public repository! 🎉

Next step: Run the commands in Section 2 to link and push to GitHub.
