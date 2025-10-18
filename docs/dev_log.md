# Green Man Tavern - Development Log

**Project Start Date**: [Current Date]  
**Target Completion**: 55 days (8 weeks)  
**Current Phase**: Phase 1 - Foundation & Custom UI Framework

---

## Log Structure
Each entry should include:
- Date & Time
- Phase/Task Reference
- What was accomplished
- What was attempted but didn't work
- Blockers/Issues
- Next steps
- Time spent

---

### Day 1 – [13.10.25]

#### Morning Session
**Phase 1, Task 1.1: Phoenix Project Initialization**

**Time**: [5:00pm] – [5:45pm] = 45 minutes

**Accomplished**:
- ✅ Created new Phoenix project
- ✅ PostgreSQL database configured (user: jesse)
- ✅ Basic routing established
- ✅ LiveView configured
- ✅ Successfully ran `mix phx.server`
- ✅ Verified localhost:4000 accessible

**Commands executed**:
```bash
mix phx.new . --app green_man_tavern --database postgres --live
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server

Issues encountered:
    • PostgreSQL authentication initially failed with default credentials 
    • Resolved by providing username: jesse 
Solutions:
    • Updated config/dev.exs with correct PostgreSQL username 
Files created/modified:
    • All standard Phoenix 1.7 files 
    • config/dev.exs (database credentials) 
Next steps:
    • Begin Task 1.2: Configure Tailwind with HyperCard styles


---

#### Afternoon Session
**Phase 1, Task 1.2: HyperCard-Style UI Component Library**

**Time**: [Start] - [End] = X hours

**Accomplished**:
- [ ] Created component directory structure
- [ ] MacWindow component completed
- [ ] MacButton component completed
- [ ] MacCard component completed
- [ ] [etc.]

**Cursor.AI prompts used**:
1. [Copy effective prompts here for reference]
2. [This helps refine future prompts]

**Component verification**:
- [ ] Components render correctly
- [ ] Greyscale only maintained
- [ ] Click states work
- [ ] Can compose components together

**Issues encountered**:
- [Any rendering issues, style conflicts, etc.]

**Next steps**:
- Continue with remaining UI components
- Begin Task 1.3: Banner + Dual-Window Layout

---

### Day 2 - [Date]

[Continue same structure]

---

## Code Review Schedule

**Weekly reviews with Claude Code**:
- End of Week 1: Review UI component library
- End of Week 2: Review character system & MindsDB integration
- End of Week 3: Review Living Web diagram
- [Continue for all phases]

---

## Backup Schedule

**Daily backups at end of day**:
- [ ] Day 1 backup: [Location/commit hash]
- [ ] Day 2 backup: [Location/commit hash]
- [ ] Day 3 backup: [Location/commit hash]
- [Continue...]

**Weekly full project export**:
- [ ] Week 1 complete: [Archive location]
- [ ] Week 2 complete: [Archive location]
- [Continue...]

---

## Metrics Tracking

### Time Investment
- Week 1 total: X hours
- Week 2 total: X hours
- Running total: X hours
- Estimated remaining: X hours

### Feature Completion
- Phase 1: X% complete
- Phase 2: X% complete
- Overall V1 progress: X%

### Technical Debt
- Known issues to address later:
  1. [Issue description]
  2. [Issue description]

---

## Learnings & Notes

### What Worked Well
- [Document successful approaches]
- [Effective Cursor prompts]
- [Good architectural decisions]

### What Didn't Work
- [Failed approaches to avoid]
- [Ineffective prompts]
- [Need to refactor later]

### Key Decisions Made
- [Date]: Decision about [X] - Reasoning: [Y]
- [Date]: Chose [X] over [Y] because [Z]

---

## Questions for Future Sessions
- [ ] Question 1
- [ ] Question 2
- [Add as they arise]

---

## Template for Daily Entry

```markdown
### Day X - [Date]

#### [Morning/Afternoon/Evening] Session
**Phase X, Task X.X: [Task Name]**

**Time**: [Start] - [End] = X hours

**Accomplished**:
- [ ] Item 1
- [ ] Item 2

**Cursor.AI prompts used**:
1. [Prompt text]

**Issues encountered**:
- [Description]

**Solutions**:
- [How resolved]

**Next steps**:
- [What's next]
```

---

**Last Updated**: [Auto-update each session]  
**Maintained By**: [Your name]  
**Current Status**: ⚪ Not Started / 🟡 In Progress / 🟢 Completed / 🔴 Blocked
