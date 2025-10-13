# Green Man Tavern - Backup & Git Workflow Strategy

**Purpose**: Never lose work, always able to rollback, track progress clearly

---

## 🔄 Git Repository Setup

### Initial Repository Creation

```bash
# In project root
git init
git add .
git commit -m "Initial commit: Phoenix project skeleton"
git branch -M main

# Create .gitignore if not exists
echo "_build/
deps/
*.ez
*.beam
/config/*.secret.exs
.elixir_ls/
priv/static/
npm-debug.log
.DS_Store
logs/
.env" > .gitignore

git add .gitignore
git commit -m "Add .gitignore"
```

### Create Remote Repository (Optional but Recommended)

```bash
# On GitHub/GitLab, create new repository "green-man-tavern"
git remote add origin [your-repo-url]
git push -u origin main
```

---

## 📦 Commit Strategy

### Commit After Each Cursor Prompt

After each successful Cursor.AI prompt completion:

```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "Phase [X], Task [X.X]: [Task name]

- [Specific change 1]
- [Specific change 2]
- [Specific change 3]

Verification: [What you verified]"

# Example:
git commit -m "Phase 1, Task 1.3: Create HyperCard UI Component Library

- Created MacButton component with bevel effects
- Created MacWindow component with title bar
- Created MacCard component
- All components use greyscale palette
- Added proper hover/active states

Verification: All components render correctly in Storybook"
```

### Commit Message Format

```
[Phase X, Task X.X]: [Short description]

[Detailed changes as bullet points]

Verification: [What was tested/verified]
[Optional: Files affected]
[Optional: Breaking changes]
```

---

## 🏷️ Tagging Strategy

### Tag Major Milestones

```bash
# After completing each major task
git tag -a v0.1.0 -m "Phase 1 Complete: Foundation & UI Framework
- All core UI components built
- Master layout system working
- Database schema created
- Dev tools configured"

git push origin v0.1.0
```

### Tagging Convention

**Format**: `vMAJOR.MINOR.PATCH`

**For V1 Development**:
- v0.1.0: Phase 1 complete (Foundation)
- v0.2.0: Phase 2 complete (Characters)
- v0.3.0: Phase 3 complete (MindsDB)
- v0.4.0: Phase 4 complete (Living Web)
- v0.5.0: Phase 5 complete (Database)
- v0.6.0: Phase 6 complete (Garden)
- v0.7.0: Phase 7 complete (Quests)
- v0.8.0: Phase 8 complete (HyperArk)
- v0.9.0: Phase 9 complete (Polish)
- v0.10.0: Phase 10 complete (Deployment prep)
- v1.0.0: Public launch!

**Patch versions** (v0.1.1, v0.1.2, etc.):
- Bug fixes within a phase
- Minor improvements
- Documentation updates

---

## 💾 Backup Schedule

### Daily Backups (End of Each Work Session)

```bash
# Create dated backup branch
git checkout -b backup/YYYY-MM-DD
git push origin backup/YYYY-MM-DD
git checkout main

# Backup to external drive (if available)
tar -czf ~/Backups/green-man-tavern-YYYY-MM-DD.tar.gz .

# Backup to cloud (if available)
# Upload to Google Drive, Dropbox, etc.
```

### Weekly Full Archive

Every Sunday evening:

```bash
# Create archive of entire project
cd ..
tar -czf green-man-tavern-week-N-YYYY-MM-DD.tar.gz green_man_tavern/

# Store in multiple locations:
# 1. External hard drive
# 2. Cloud storage (Google Drive, Dropbox)
# 3. Network drive (if available)
```

---

## 🔙 Rollback Procedures

### Undo Last Commit (Not Pushed)

```bash
# Undo commit but keep changes
git reset --soft HEAD~1

# Undo commit and discard changes (CAREFUL!)
git reset --hard HEAD~1
```

### Rollback to Specific Tag

```bash
# View all tags
git tag -l

# Check out specific version
git checkout v0.3.0

# Create new branch from that point
git checkout -b rollback-to-v0.3.0

# If you want to make this the new main:
git checkout main
git reset --hard v0.3.0
git push origin main --force  # CAREFUL with force push!
```

### Rollback Specific File

```bash
# Restore single file from last commit
git checkout HEAD -- path/to/file.ex

# Restore file from specific commit
git checkout abc123 -- path/to/file.ex
```

---

## 🌿 Branch Strategy

### Main Branches

- **main**: Stable, working code only
- **dev**: Active development (optional for solo dev)

### Feature Branches

When working on complex features:

```bash
# Create feature branch
git checkout -b feature/character-trust-system

# Work on feature...
# Commit regularly
git add .
git commit -m "WIP: Character trust calculation"

# When complete and tested:
git checkout main
git merge feature/character-trust-system
git branch -d feature/character-trust-system
```

### Backup Branches

Keep backup branches for major milestones:

```bash
git checkout -b backup/phase-1-complete
git push origin backup/phase-1-complete
git checkout main
```

Never delete backup branches!

---

## 📊 Project Health Checks

### Daily Health Check (5 minutes)

```bash
# Run tests
mix test

# Check for compilation warnings
mix compile --warnings-as-errors

# Format code
mix format

# If all pass:
git add .
git commit -m "Daily health check: All systems green"
```

### Weekly Deep Check (15 minutes)

```bash
# Update dependencies
mix deps.get
mix deps.clean --unused

# Run database migrations (verify)
mix ecto.migrate

# Check for security issues
mix deps.audit

# Review open tasks
git log --since="1 week ago" --oneline

# Backup complete project
# (see Weekly Full Archive above)
```

---

## 🚨 Emergency Recovery

### If Project Gets Corrupted

**1. Check if git can help:**
```bash
git status
git log
# If commits exist, can rollback to last good state
git reset --hard HEAD~1
```

**2. If git can't help, restore from backup:**
```bash
# From most recent backup branch
git checkout backup/YYYY-MM-DD

# Or from tar archive
cd ~/Projects
tar -xzf ~/Backups/green-man-tavern-YYYY-MM-DD.tar.gz
```

**3. If all else fails:**
- Restore from cloud backup
- Restore from external drive
- Worst case: Restart from last tagged version

---

## 📝 Backup Checklist Template

```markdown
## Daily Backup Checklist

Date: [YYYY-MM-DD]

- [ ] All changes committed to git
- [ ] Tests passing (mix test)
- [ ] Code formatted (mix format)
- [ ] Backup branch created and pushed
- [ ] Daily work logged in dev log
- [ ] No uncommitted changes (git status clean)
- [ ] Tar backup created (if working day)

## Weekly Backup Checklist

Week ending: [YYYY-MM-DD]

- [ ] Full project tar archive created
- [ ] Archive uploaded to Google Drive
- [ ] Archive copied to external drive
- [ ] All backup branches pushed to remote
- [ ] Dependencies updated
- [ ] Security audit run
- [ ] Code review with Claude Code completed
- [ ] Next week's priorities documented
```

---

## 🔐 What to Backup

### Always Backup
- ✅ All source code (lib/, config/, priv/)
- ✅ Database schema (migrations)
- ✅ Documentation (docs/, README)
- ✅ Assets (static files, images)
- ✅ Configuration files (.cursorrules, .formatter.exs)
- ✅ Dev logs and style guides

### Don't Need to Backup
- ❌ _build/ (generated)
- ❌ deps/ (can reinstall)
- ❌ node_modules/ (can reinstall)
- ❌ .elixir_ls/ (generated)
- ❌ Database contents (unless production - we're dev only)

### Backup Separately (Sensitive)
- 🔒 .env files (if used)
- 🔒 API keys
- 🔒 Credentials
- Store these encrypted, not in git!

---

## 📅 Backup Schedule Summary

| Frequency | Action | Time Required |
|-----------|--------|---------------|
| After each Cursor prompt | Git commit | 1 min |
| End of work session | Backup branch + tar | 5 min |
| End of day | Daily checklist | 5 min |
| End of week | Full archive + cloud | 15 min |
| After each phase | Tagged release | 2 min |

**Total backup time per week**: ~45 minutes  
**Protection level**: Very high

---

## 🛡️ Disaster Recovery Plan

### Level 1: Minor Issue (Lost work from last hour)
**Recovery**: `git reset --hard HEAD`  
**Time**: Instant  
**Data loss**: Last uncommitted changes only

### Level 2: Corrupted files (Last few commits)
**Recovery**: `git reset --hard v0.X.0` (last tag)  
**Time**: Instant  
**Data loss**: Work since last tag (max 1-2 days)

### Level 3: Git repository corrupted
**Recovery**: Restore from backup branch  
**Time**: 5 minutes  
**Data loss**: Max 1 day (last backup branch)

### Level 4: Computer failure
**Recovery**: Restore from tar backup  
**Time**: 15 minutes  
**Data loss**: Max 1 day (last tar backup)

### Level 5: Complete data loss (very unlikely)
**Recovery**: Restore from cloud + external drive  
**Time**: 30 minutes  
**Data loss**: Max 1 week (last weekly archive)

---

## 🎯 Quick Reference Commands

### Save Work
```bash
git add .
git commit -m "[Phase X, Task X.X]: Description"
git push origin main
```

### Create Checkpoint
```bash
git tag -a v0.X.Y -m "Description"
git push origin v0.X.Y
```

### Daily Backup
```bash
git checkout -b backup/$(date +%Y-%m-%d)
git push origin backup/$(date +%Y-%m-%d)
git checkout main
```

### Emergency Rollback
```bash
git log --oneline  # Find good commit
git reset --hard abc123  # Replace abc123 with commit hash
```

### Restore from Backup
```bash
git checkout backup/YYYY-MM-DD
git checkout -b recovery
# Test, verify, then merge to main if good
```

---

## ✅ Pre-Work Session Checklist

Before starting each work session:

```bash
# 1. Verify on main branch
git checkout main

# 2. Pull latest (if using remote)
git pull origin main

# 3. Verify clean state
git status  # Should be clean

# 4. Run quick health check
mix test

# 5. Ready to work!
```

---

## ✅ Post-Work Session Checklist

After finishing each work session:

```bash
# 1. Stage all changes
git add .

# 2. Commit with good message
git commit -m "[Phase X]: Work done today"

# 3. Create backup branch
git checkout -b backup/$(date +%Y-%m-%d)
git push origin backup/$(date +%Y-%m-%d)
git checkout main

# 4. Push to remote
git push origin main

# 5. Create tar backup (optional but recommended)
cd ..
tar -czf ~/Backups/gmt-$(date +%Y-%m-%d).tar.gz green_man_tavern/

# 6. Update dev log
# (note what was accomplished)

# 7. Done!
```

---

**Remember**: It takes 5 minutes to backup, but hours/days to recreate lost work. Always backup before trying anything experimental!