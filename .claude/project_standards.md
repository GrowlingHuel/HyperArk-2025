# How to Save project_standards.md

## 📋 Quick Instructions

### Step 1: Create the File

```bash
# From your project root
mkdir -p .claude
touch .claude/project_standards.md
```

### Step 2: Copy the Standards

1. Open the artifact: `Green Man Tavern - Project Standards & Conventions`
2. Click the copy button (or select all with Cmd+A / Ctrl+A)
3. Copy to clipboard

### Step 3: Paste into File

**Option A: Using terminal editor (vim/nano)**
```bash
nano .claude/project_standards.md
# Then Cmd+V or Ctrl+V to paste
# Then Ctrl+X then Y to save (for nano)
```

**Option B: Using VS Code**
```bash
# Open VS Code in your project
code .claude/project_standards.md

# Then paste the content and save (Cmd+S / Ctrl+S)
```

**Option C: Using your text editor**
1. Open `.claude/project_standards.md` file directly
2. Paste the content
3. Save

### Step 4: Verify It Saved

```bash
# Check file exists and has content
wc -l .claude/project_standards.md
# Should show a large number of lines (400+)

# View first few lines
head -20 .claude/project_standards.md
```

### Step 5: Commit to Git

```bash
git add .claude/project_standards.md
git commit -m "Add project standards and conventions document

- Comprehensive guide to architecture patterns
- HyperCard aesthetic requirements
- Database conventions and security rules
- LiveView patterns and best practices
- Testing standards
- Naming conventions
- Documentation requirements
- Common mistakes to avoid"

git push origin main
```

---

## ✅ Verify Setup

After saving, you should have:

```
project root/
└── .claude/
    ├── project_standards.md ← Just created
    └── audit_results/       ← Folder for audit reports
```

---

## 🎯 Next Steps

Now that you have created `.claude/project_standards.md`:

1. **Before running your audit**: Commit this file
   ```bash
   git status  # Should show project_standards.md as added
   git add .
   git commit -m "Add project standards"
   ```

2. **When running Claude Code audits**: Claude Code will reference this file to understand your conventions

3. **For team members**: They can read this to understand project standards

4. **For updating**: Whenever you discover a new pattern or convention, add it here

---

## 📚 What This File Contains

This comprehensive standards document includes:

- ✅ Project identity and philosophy
- ✅ Three-layer architecture explanation
- ✅ File organization conventions
- ✅ Database rules and schema patterns
- ✅ HyperCard aesthetic requirements (CRITICAL)
- ✅ UI component styles
- ✅ Layout structure specifications
- ✅ Seven Seekers character system
- ✅ Systems Flow Diagram (Living Web) model
- ✅ LiveView conventions and patterns
- ✅ Security and authentication rules
- ✅ Testing requirements
- ✅ Naming conventions (Elixir, database, web)
- ✅ Documentation standards
- ✅ MindsDB integration patterns
- ✅ Common mistakes to avoid
- ✅ Pre-commit checklist

**Total**: ~600 lines of comprehensive project guidance

---

## 🚀 You're Ready for the Audit!

Once this file is saved and committed:

1. ✅ You have all three reference files:
   - `.claude/project_standards.md` (just created)
   - `AUDIT_BASELINE.md` (ready to fill)
   - `IMPLEMENTATION_LOG.md` (ready to fill)

2. ✅ Your project is clean:
   - No build artifacts
   - No uncommitted changes (after commit)
   - Clean git history

3. ✅ You're ready to run the initial audit with Claude Code

---

## 📞 Troubleshooting

### File won't save?
- Make sure `.claude/` folder exists: `mkdir -p .claude`
- Try different editor if nano/vim not working
- Use VS Code - most reliable

### Content looks incomplete?
- Make sure you copied the ENTIRE artifact
- Check the artifact shows when scrolling down
- May need to scroll down in artifact view to see full content

### Git commit fails?
- Check git status: `git status`
- Make sure file is added: `git add .claude/project_standards.md`
- Then commit again

---

## ✨ What's Next

**After saving this file:**

```bash
# Verify everything is ready
git status              # Should be clean
.claude/               # Should have project_standards.md
mix ecto.migrations    # Should show all "up"

# You're ready to run the audit!
# Follow the Claude Code Setup Guide
```

---

**You've now created a living reference document for your entire team and Claude Code audits!** 🎉