```
Create the main landing page (HyperArk) that users see after logging in.

Create lib/green_man_tavern_web/live/hyperark_live.ex

This should be a LiveView that:
- Uses the master layout
- Left window: Quick stats (Level, XP, Systems count, Achievements)
- Right window: Welcome message, Active quests summary, Recent achievements, Opportunities

For now, use placeholder data since we don't have auth yet:
- Mock user data in socket assigns
- Static content to verify layout works
- All styled in HyperCard aesthetic

Template should be in lib/green_man_tavern_web/live/hyperark_live.html.heex

Include:
- Welcome message with user name
- "Your Permaculture Journey" section
- Active quests list (3 mock quests with progress bars)
- Recent achievements (2-3 mock badges)
- Opportunities section (2 suggestions)
- All using MacCard components
- All text in system fonts
- Pure greyscale styling

Add route in router.ex:
live "/", HyperarkLive, :index

Verify page renders correctly at localhost:4000/
```

---

## 🎯 Prompt 8: Set Up Claude Code Integration

```
Configure the project to work with Claude Code for periodic code reviews.

1. Create a .cursorrules file in the project root with:

```
# Green Man Tavern - Cursor Rules

## Project Context
This is a Phoenix LiveView application for a permaculture-based RPG game.

## Design Constraints
- STRICT HyperCard/Classic Mac aesthetic (greyscale only, no modern UI)
- Banner + dual-window layout on all pages
- No mobile responsive (desktop only for V1)
- System fonts only (Geneva, Monaco, Chicago)

## Code Style
- Follow Elixir style guide
- Use function components for UI
- LiveView for all interactive pages
- Ecto for all database access
- No inline styles (use Tailwind utilities + custom CSS)

## File Organization
- Components in lib/green_man_tavern_web/components/
- LiveViews in lib/green_man_tavern_web/live/
- Contexts in lib/green_man_tavern/
- Schemas in lib/green_man_tavern/[context]/

## Testing Requirements
- Test all business logic
- Test LiveView mount and event handling
- Test database queries
- No need for E2E tests yet

## MindsDB Integration (future)
- All AI agent calls through dedicated context module
- Cache responses when possible
- Handle timeouts gracefully
```

2. Create docs/architecture.md documenting:
   - Technology stack
   - Database schema overview
   - LiveView structure
   - Component library
   - Integration points

3. Create docs/code_review_checklist.md with items to verify:
   - HyperCard aesthetic maintained
   - No color used (greyscale only)
   - Proper error handling
   - Database queries optimized
   - Components reusable
   - Tests passing

4. Verify Claude Code can access project:
   - Run: claude-code --help (to verify installation)
   - Test: Ask Claude Code to summarize the project structure
```

---

## 🎯 Prompt 9: Create Development Utilities

```
Create helpful development utilities and scripts.

1. Create lib/mix/tasks/dev.setup.ex:
   - Task that runs full setup (deps.get, ecto.setup, etc.)
   - Verifies PostgreSQL is running
   - Creates database if needed
   - Runs migrations
   - Seeds sample data (when we have seeds)

2. Create lib/mix/tasks/dev.reset.ex:
   - Drops database
   - Recreates database
   - Runs migrations
   - Runs seeds
   - Useful for fresh starts

3. Create priv/repo/seeds/characters.exs:
   - Seeds all 7 characters with their data
   - The Student, Grandmother, Farmer, Robot, Alchemist, Survivalist, Hobo
   - Include all fields: name, archetype, description, focus_area, personality_traits, etc.

4. Update seeds.exs to import the character seeds:
```elixir
Code.require_file("seeds/characters.exs", __DIR__)
```

5. Create a dev_helpers.exs file for IEx:
   - Shortcuts to query common data
   - Helper to create test users
   - Helper to view current schema
   
Add to .iex.exs:
```elixir
import_file_if_available("dev_helpers.exs")
```

Verify:
- mix dev.setup works
- mix dev.reset works
- mix run priv/repo/seeds.exs populates characters
- Can query Character in IEx: GreenManTavern.Characters.Character |> GreenManTavern.Repo.all()
```

---

## 🎯 Prompt 10: Add Logging and Debugging Tools

```
Set up proper logging and debugging for development.

1. Add Logger configuration in config/dev.exs:
   - Log LiveView events
   - Log database queries
   - Log errors with full stacktraces
   - Colored output for readability

2. Create lib/green_man_tavern/telemetry.ex:
   - Instrument database queries
   - Track LiveView mount times
   - Monitor memory usage
   - Log slow operations (>500ms)

3. Add debug helpers in lib/green_man_tavern_web/live_helpers.ex:
   - Helper to inspect socket assigns
   - Helper to log LiveView events
   - Helper to trace data flow

4. Create a logs/ directory in .gitignore

5. Add Phoenix LiveDashboard to dependencies:
   - Add to mix.exs
   - Configure route in router.ex (only in dev)
   - Protect with basic auth or dev-only

Update router.ex to include:
```elixir
if Mix.env() == :dev do
  scope "/dev" do
    pipe_through :browser
    forward "/dashboard", Phoenix.LiveDashboard.Router
  end
end
```

Verify:
- Can access /dev/dashboard in browser
- See real-time metrics
- Database queries logged to console
- LiveView events visible in logs
```

---

## 🎯 Next Steps After Initial Setup

Once you've run prompts 1-10, you'll have:

✅ Phoenix application running
✅ Database configured with core schema
✅ HyperCard UI component library
✅ Banner + dual-window layout system
✅ HyperArk landing page
✅ The 7 Characters seeded
✅ Development tools configured
✅ Logging and debugging ready
✅ Claude Code integration set up

**Then we proceed to:**
- Phase 1, Task 1.4: User Authentication
- Phase 2: Character System Implementation
- Phase 3: MindsDB Integration

---

## 📝 Notes for Each Prompt

### Success Criteria
After each prompt, verify:
1. No compilation errors
2. No warnings (fix if possible)
3. Matches HyperCard style guide
4. Can be run/tested immediately
5. Documented in code comments

### If Prompt Fails
1. Check error message carefully
2. Verify prerequisites met
3. Try breaking into smaller prompts
4. Ask for clarification/modification
5. Document issue in dev log

### Cursor.AI Tips
- Be specific about file locations
- Reference existing files when building on them
- Request verification steps at end of each prompt
- Ask for tests when appropriate
- Request comments/documentation

---

## 🔄 Backup After Each Prompt

After successful completion of each prompt:

```bash
git add .
git commit -m "Phase 1: [Task description]"
git tag -a v0.0.[N] -m "Checkpoint: [Description]"
```

Keep a backup log:
- v0.0.1: Project initialized
- v0.0.2: Tailwind configured
- v0.0.3: UI components created
- v0.0.4: Master layout created
- v0.0.5: Database schema created
- v0.0.6: Dev environment configured
- v0.0.7: HyperArk landing page created
- v0.0.8: Claude Code integration
- v0.0.9: Dev utilities created
- v0.0.10: Logging and debugging configured

---

## 🎯 Estimated Time per Prompt

- Prompt 1: 5 minutes (project init)
- Prompt 2: 5 minutes (CSS config)
- Prompt 3: 20-30 minutes (component library)
- Prompt 4: 20-30 minutes (layout system)
- Prompt 5: 15-20 minutes (database schema)
- Prompt 6: 10 minutes (dev environment)
- Prompt 7: 15-20 minutes (HyperArk page)
- Prompt 8: 10 minutes (Claude Code setup)
- Prompt 9: 20 minutes (dev utilities)
- Prompt 10: 15 minutes (logging)

**Total: ~2-3 hours for complete foundation setup**

---

## 🚨 Common Issues and Solutions

### Issue: Cursor can't find Phoenix
**Solution**: Ensure Elixir/Phoenix installed globally. Run `mix archive.install hex phx_new`

### Issue: Database connection fails
**Solution**: Verify PostgreSQL running. Check credentials in config/dev.exs

### Issue: Tailwind not compiling
**Solution**: Run `npm install` in assets/ directory. Verify package.json exists.

### Issue: Components not rendering
**Solution**: Check component is imported in root layout. Verify syntax.

### Issue: LiveView not updating
**Solution**: Clear browser cache. Verify LiveSocket# Cursor.AI Setup Prompts for Green Man Tavern

**How to use**: Copy each prompt into Cursor.AI's chat interface in sequence. Wait for completion before proceeding to next prompt.

---

## 🎯 Prompt 1: Project Initialization

```
Create a new Phoenix 1.7+ application for a project called "green_man_tavern".

Requirements:
- Use PostgreSQL as the database
- Include LiveView
- Enable Ecto for database management
- Set up basic routing
- Configure for desktop-only (no mobile responsive needed for V1)
- Use Tailwind CSS for styling

Project structure should be:
- Standard Phoenix 1.7 directory layout
- Keep it minimal - no unnecessary generators yet
- Database name: green_man_tavern_dev

After creation, verify:
1. Project compiles without errors
2. Database connection works
3. Can run `mix phx.server` successfully
4. Can access localhost:4000

Do NOT generate authentication yet - we'll do that separately.
Do NOT create any UI components yet.

Just the base Phoenix application skeleton.
```

---

## 🎯 Prompt 2: Configure Tailwind & Custom CSS

```
Configure Tailwind CSS for a strict HyperCard/Classic Macintosh aesthetic.

In assets/css/app.css, add this AFTER the Tailwind imports:

/* HyperCard Aesthetic - Greyscale Palette */
:root {
  --pure-black: #000000;
  --dark-grey: #333333;
  --medium-grey: #666666;
  --neutral-grey: #999999;
  --light-grey: #CCCCCC;
  --off-white: #EEEEEE;
  --pure-white: #FFFFFF;
  
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-6: 24px;
  --space-8: 32px;
  
  --font-xs: 10px;
  --font-sm: 12px;
  --font-md: 14px;
  --font-lg: 16px;
  --font-xl: 18px;
  --font-2xl: 24px;
}

body {
  font-family: 'Geneva', 'Helvetica', 'Arial', sans-serif;
  font-size: var(--font-sm);
  color: var(--pure-black);
  background: var(--light-grey);
  margin: 0;
  padding: 0;
}

Update tailwind.config.js to extend the theme with our greyscale palette:

theme: {
  extend: {
    colors: {
      'pure-black': '#000000',
      'dark-grey': '#333333',
      'medium-grey': '#666666',
      'neutral-grey': '#999999',
      'light-grey': '#CCCCCC',
      'off-white': '#EEEEEE',
      'pure-white': '#FFFFFF',
    },
    fontFamily: {
      'mac': ['Chicago', 'Monaco', 'Courier New', 'monospace'],
      'system': ['Geneva', 'Helvetica', 'Arial', 'sans-serif'],
    },
    spacing: {
      '1': '4px',
      '2': '8px',
      '3': '12px',
      '4': '16px',
      '6': '24px',
      '8': '32px',
    }
  }
}

Verify the configuration compiles correctly.
```

---

## 🎯 Prompt 3: Create HyperCard UI Component Library

```
Create a reusable component library for HyperCard-style UI elements in Phoenix LiveView.

Create these files in lib/green_man_tavern_web/components/mac_ui/:

1. window.ex - MacWindow component
2. button.ex - MacButton component  
3. card.ex - MacCard component
4. text_field.ex - MacTextField component
5. checkbox.ex - MacCheckbox component

Each component should:
- Use only greyscale colors from our palette
- Have proper bevel effects (light source from top-left)
- Support all necessary attributes
- Be keyboard accessible
- Have clear documentation

For MacButton specifically:
- Default state: light-to-dark gradient with raised bevel
- Hover state: slightly lighter
- Active state: inverted bevel with 1px translateY
- Disabled state: grey with no interactivity
- Accept: label, click handler, disabled flag, custom classes

For MacWindow:
- Title bar with gradient background
- Close button (optional)
- Content area with white background
- 2px border with drop shadow
- Accept: title, closable (boolean), content slot

Start with just these 5 components. Each should be a function component that can be called like:

<MacUI.button label="Click Me" phx-click="handle_click" />
<MacUI.window title="My Window">
  [content here]
</MacUI.window>

Use Tailwind utility classes where possible, custom CSS for complex bevels.
```

---

## 🎯 Prompt 4: Create Master Layout Structure

```
Create the banner + dual-window layout system that will be used across all pages.

Create lib/green_man_tavern_web/components/layouts/master.html.heex with:

Structure:
1. Fixed banner at top (44px height, system grey background)
2. Left window (fixed width 300-400px, white background, scrollable)
3. Right window (remaining width, white background, scrollable)

The banner should contain:
- App name/logo on left: "🍃 The Green Man Tavern"
- Menu items: HyperArk, Characters (dropdown), Database, Garden, Living Web
- All styled as HyperCard buttons

Both left and right windows should:
- Have 2px borders (medium-grey)
- White backgrounds
- Proper bevel effects
- Share a border between them (no gap)
- Have drop shadows

Create corresponding CSS in app.css for:
.master-layout
.banner-menu
.left-window  
.right-window

The layout should be defined so that individual pages can:
- Set left window content via assigns
- Set right window content as main content
- Hide left window if needed

Make it a proper Phoenix layout that can be used like:
<.master_layout left_content={...} right_content={...} />

Ensure it's responsive to window resizing (but desktop-only, no mobile breakpoints).
```

---

## 🎯 Prompt 5: Set Up Core Database Schema

```
Generate Ecto migrations for the core database schema.

Create migrations for these tables (in order):

1. users (basic fields only for now, we'll add auth later):
   - id (uuid primary key)
   - email (string, unique, not null)
   - profile_data (jsonb, default {})
   - primary_character_id (bigint, nullable, foreign key added later)
   - xp (integer, default 0)
   - level (integer, default 1)
   - timestamps

2. characters:
   - id (bigserial primary key)
   - name (string, not null)
   - archetype (string, not null)
   - description (text)
   - focus_area (string)
   - personality_traits (jsonb, default [])
   - icon_name (string)
   - color_scheme (string)
   - trust_requirement (string)
   - mindsdb_agent_name (string)
   - timestamps

3. user_characters (join table for trust system):
   - id (bigserial primary key)
   - user_id (uuid, foreign key to users)
   - character_id (bigint, foreign key to characters)
   - trust_level (integer, default 0)
   - first_interaction_at (timestamp)
   - last_interaction_at (timestamp)
   - interaction_count (integer, default 0)
   - is_trusted (boolean, default false)
   - timestamps

4. systems:
   - id (bigserial primary key)
   - name (string, not null)
   - system_type (string, not null) -- resource, process, storage
   - category (string, not null) -- food, water, waste, energy
   - description (text)
   - requirements (text)
   - default_inputs (jsonb, default [])
   - default_outputs (jsonb, default [])
   - icon_name (string)
   - space_required (string)
   - skill_level (string)
   - timestamps

5. user_systems:
   - id (bigserial primary key)
   - user_id (uuid, foreign key to users)
   - system_id (bigint, foreign key to systems)
   - status (string, default 'planned')
   - position_x (integer)
   - position_y (integer)
   - custom_notes (text)
   - location_notes (text)
   - implemented_at (timestamp)
   - timestamps

Create corresponding Ecto schemas in lib/green_man_tavern/ for:
- Accounts.User
- Characters.Character
- Characters.UserCharacter
- Systems.System
- Systems.UserSystem

Include proper associations and validations.

After creating migrations, run:
mix ecto.migrate

Verify all tables created successfully.
```

---

## 🎯 Prompt 6: Configure Development Environment

```
Set up proper development environment configuration.

1. Update config/dev.exs with:
   - Proper database connection pooling
   - LiveView configuration
   - Debug logging for development
   - Hot reloading enabled

2. Create .gitignore entries for:
   - _build/
   - deps/
   - .elixir_ls/
   - priv/static/
   - .env (if we add one later)

3. Create a README.md with:
   - Project description (Green Man Tavern - Permaculture RPG)
   - Prerequisites (Elixir, Phoenix, PostgreSQL, MindsDB)
   - Setup instructions
   - How to run locally
   - Architecture overview (Phoenix LiveView + MindsDB agents)

4. Set up .formatter.exs for consistent code formatting

5. Create priv/repo/seeds.exs (empty for now, we'll populate later)

Verify everything works:
- mix format runs without errors
- mix compile succeeds
- mix test runs (even if no tests yet)
- iex -S mix phx.server starts successfully
```

---

## 🎯 Prompt 7: Create HyperArk Landing Page (Splash)

```
Create the main landing page (HyperArk) that users see after logging in.

Create lib/green_man_tavern_web/live/hyperark_live.ex

This should be a LiveView that: