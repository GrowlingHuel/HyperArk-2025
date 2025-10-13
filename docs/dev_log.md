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

**Issues encountered**:
- None yet / [needed to change postgres details: using [my name]]

**Solutions**:
- [changed postgres login details as above]

**Files created/modified**:
- `mix.exs`
- `config/dev.exs`
- [List key files]

**Next steps**:
- Begin Task 1.2: HyperCard UI Component Library

---

#### Afternoon Session
**Phase 1, Task 1.2: HyperCard-Style UI Component Library**

**Time**: 17:45 – 20:05 = 2h 20m

**Accomplished**:
- ✅ Created `lib/green_man_tavern_web/components/mac_ui/` library
- ✅ Implemented components:
  - `MacUI.Button` – flat System 7 style (Monaco 11px, #CCC, 2px #000, hover/active/disabled)
  - `MacUI.Card` – white with 1px grey border
  - `MacUI.TextField` – inset bevel, Monaco monospace, focus outline
  - `MacUI.Checkbox` – square with X when checked
  - `MacUI.WindowChrome` – title bar (20px), close box (14×14), content area
- ✅ Added `MacUI` entry module and wired into `html_helpers`
- ✅ Added master layout with banner + dual-window (left 300px, right flexible)
- ✅ Left window sticky tavern scene section + character content placeholder
- ✅ Custom scrollbars (16px) shown only on overflow
- ✅ Dithered background patterns for subtle texture
- ✅ Global typography set to Monaco; crisp, pixelated rendering
- ✅ Banner menu buttons converted to flat System 7 style

**Cursor.AI prompts used**:
1. [Copy effective prompts here for reference]
2. [This helps refine future prompts]

**Component verification**:
- [ ] Components render correctly
- [ ] Greyscale only maintained
- [ ] Click states work
- [ ] Can compose components together

**Issues encountered**:
- PostgreSQL auth initially failed with default creds; resolved using user `jesse`
- HEEx alias not allowed inside templates – switched to fully-qualified component names
- Placeholder routes (`/database`, `/garden`, `/living-web`) produce warnings (expected)
- Legacy layout render warning noted (non-blocking)

**Next steps**:
- Add real routes for Database/Garden/Living Web or hide links until ready
- Replace logo/scene asset placeholder (`/images/tavern_scene.png`) with final art
- Iterate on title bar pattern (optional dither), add ▲/▼ glyph art for scrollbar buttons
- Begin wiring dynamic titles (`@left_window_title`, `@right_window_title`) from LiveViews

---

### Change Log (13.10.25)

**Components**
- Added: `lib/green_man_tavern_web/components/mac_ui/button.ex`
- Added: `lib/green_man_tavern_web/components/mac_ui/card.ex`
- Added: `lib/green_man_tavern_web/components/mac_ui/text_field.ex`
- Added: `lib/green_man_tavern_web/components/mac_ui/checkbox.ex`
- Added: `lib/green_man_tavern_web/components/mac_ui/window_chrome.ex`
- Updated: `lib/green_man_tavern_web/components/mac_ui.ex` (delegates)

**Layouts**
- Updated: `lib/green_man_tavern_web/components/layouts/master.html.heex` – banner + dual-window using `<MacUI.window_chrome>`; sticky tavern scene
- Updated: `lib/green_man_tavern_web/components/layouts/root.html.heex` to render master layout

**Pages**
- Updated: `lib/green_man_tavern_web/controllers/page_html/home.html.heex` – demo with MacUI components

**Styles** (`assets/css/app.css`)
- Global Monaco typography; anti-aliasing disabled
- Pixel-perfect helpers (`* { box-sizing: border-box; }`, `.no-antialias`, `.sharp-border`)
- Banner buttons updated to flat #CCC, 2px #000
- Mac button flattened; hover/active/disabled states
- Window chrome: patterned title bar, close box positioning, content area
- Custom scrollbars for `.mac-window-content`/`.mac-content-area`
- Dithered background utilities
- Removed left-window shadow; use shared 2px seam

**Verification**
- `mix compile` – OK (warnings: placeholder routes, legacy layout render)
- `mix phx.server` – app boots; layout and components render

**Time spent**: 2h 20m

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
