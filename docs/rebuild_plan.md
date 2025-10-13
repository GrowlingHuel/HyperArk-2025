# Green Man Tavern - Complete Rebuild Plan (Revised)
**Feature-Complete V1 for Desktop**

Based on your specifications: All seven characters, HyperCard aesthetic, banner + dual-window UI, full feature set.

---

## 🎯 V1 Goals - What Users Can Do

**Core Experience:**
1. Navigate via banner menu (HyperArk, Characters, Database, Garden, Living Web)
2. Interact with all Seven Seekers via AI chat
3. Build and edit systems in Living Web diagram (drag-and-drop)
4. See AI-powered opportunity suggestions
5. View/edit personal database
6. Access garden planting guide
7. Complete quests and earn achievements
8. Character trust system (some characters require "proof" before full engagement)
9. Agent memory system (remembers user's projects without full conversation history)

**NOT in V1:**
- Mobile/tablet support
- Social/community features
- External user sharing
- Public leaderboards

---

## 📋 Phase 1: Foundation & Custom UI Framework (Days 1-5)

### Task 1.1: Phoenix Project Initialization
**What to do:**
- Create new Phoenix 1.7+ project
- PostgreSQL database
- Configure for desktop-only (no responsive breakpoints needed)
- Set up LiveView
- Add basic routing

**Verification:**
- `mix phx.server` runs
- Can access localhost:4000
- Database connects

---

### Task 1.2: HyperCard-Style UI Component Library

**What to do:**
Create custom component library for classic Mac/HyperCard aesthetic:

**Components needed:**
1. **MacWindow** - Window frame with title bar
2. **MacButton** - Bevel-style button with click states
3. **MacCard** - Content card with border
4. **MacTextField** - Classic input field
5. **MacScroller** - Scrollable content area
6. **MacMenu** - Dropdown menu items
7. **MacDialog** - Modal dialog box

**Design specifications:**
- Greyscale only (black, white, greys)
- System font or web-safe monospace alternative
- 1-2px borders, bevel effects
- No shadows or gradients (except for button depth)
- Click states: default, hover, active, disabled

**Files to create:**
```
lib/green_man_tavern_web/components/
├── mac_ui/
│   ├── window.ex
│   ├── button.ex
│   ├── card.ex
│   ├── text_field.ex
│   ├── scroller.ex
│   ├── menu.ex
│   └── dialog.ex
```

**Verification:**
- Each component renders in greyscale
- Buttons have proper click states
- Windows look like classic Mac OS
- Components can be composed together

---

### Task 1.3: Banner + Dual-Window Layout System

**What to do:**
Create the master layout that all pages use:

**Layout structure:**
```
┌─────────────────────────────────────────────┐
│ BANNER MENU (fixed top)                     │
│ [HyperArk] [Characters ▾] [Database]       │
│           [Garden] [Living Web]             │
├──────────────┬──────────────────────────────┤
│              │                              │
│   LEFT       │      RIGHT                   │
│   WINDOW     │      WINDOW                  │
│              │                              │
│  (Character  │   (Main Content)            │
│   Context)   │                              │
│              │                              │
│              │                              │
└──────────────┴──────────────────────────────┘
```

**Banner menu items:**
1. **HyperArk** - Main splash/dashboard
2. **Characters** - Dropdown showing all seven
3. **Database** - User's personal database
4. **Garden** - Planting guide
5. **Living Web** - Systems flow diagram

**Left window behavior:**
- Shows character portrait and info when character is active
- Shows context-relevant information
- Fixed width (e.g., 300-400px)

**Right window behavior:**
- Main content area
- Changes based on menu selection
- Full remaining width

**Verification:**
- Banner stays fixed at top during scroll
- Left window shows character when active
- Right window updates without page reload (LiveView)
- Layout looks like classic Mac OS
- Menu dropdowns work

---

### Task 1.4: User Authentication

**What to do:**
- Run `mix phx.gen.auth Accounts User users`
- Customize login/register screens to match HyperCard aesthetic
- Add profile_data JSONB field to users table
- Add primary_character_id field

**Verification:**
- Can register new account
- Can log in/out
- Login screen matches HyperCard design
- Session persists

---

### Task 1.5: Core Database Schema

**Create these tables:**

**1. users (enhanced by auth generator)**
```sql
- id
- email
- hashed_password
- confirmed_at
- profile_data (JSONB): climate_zone, space_type, skill_level, goals
- primary_character_id (FK to characters)
- xp (integer, default 0)
- level (integer, default 1)
- created_at
- updated_at
```

**2. characters**
```sql
- id
- name (e.g., "The Student")
- archetype (e.g., "Knowledge Seeker")
- description (text)
- focus_area (text)
- personality_traits (JSONB array)
- icon_name (string, for rendering)
- color_scheme (string: greyscale values)
- trust_requirement (string: "none", "basic", "intermediate", "advanced")
- mindsdb_agent_name (string, matches MindsDB model name)
```

**3. user_characters (for trust system)**
```sql
- id
- user_id (FK)
- character_id (FK)
- trust_level (integer, 0-100)
- first_interaction_at (timestamp)
- last_interaction_at (timestamp)
- interaction_count (integer)
- is_trusted (boolean, computed from trust_level)
```

**4. systems**
```sql
- id
- name (e.g., "Herb Garden")
- system_type (enum: resource, process, storage)
- category (enum: food, water, waste, energy)
- description (text)
- requirements (text)
- default_inputs (JSONB array)
- default_outputs (JSONB array)
- icon_name (string)
- space_required (string: indoor, outdoor, balcony, yard)
- skill_level (enum: beginner, intermediate, advanced)
```

**5. user_systems**
```sql
- id
- user_id (FK)
- system_id (FK)
- status (enum: planned, active, inactive)
- position_x (integer, for diagram)
- position_y (integer, for diagram)
- custom_notes (text)
- location_notes (text)
- implemented_at (timestamp)
- last_updated (timestamp)
```

**6. connections**
```sql
- id
- from_system_id (FK to systems)
- to_system_id (FK to systems)
- flow_type (enum: active, potential)
- flow_label (string: what's being transferred)
- description (text)
```

**7. user_connections**
```sql
- id
- user_id (FK)
- connection_id (FK)
- status (enum: potential, planned, active, inactive)
- implemented_at (timestamp)
```

**8. quests**
```sql
- id
- title (string)
- description (text)
- character_id (FK)
- quest_type (enum: tutorial, implementation, maintenance, learning, community, challenge)
- difficulty (enum: easy, medium, hard)
- xp_reward (integer)
- required_systems (JSONB array of system_ids)
- instructions (JSONB array of steps)
- success_criteria (JSONB)
```

**9. user_quests**
```sql
- id
- user_id (FK)
- quest_id (FK)
- status (enum: available, active, completed, failed)
- progress_data (JSONB)
- started_at (timestamp)
- completed_at (timestamp)
```

**10. achievements**
```sql
- id
- name (string)
- description (text)
- badge_icon (string)
- unlock_criteria (JSONB)
- xp_value (integer)
- rarity (enum: common, rare, epic, legendary)
```

**11. user_achievements**
```sql
- id
- user_id (FK)
- achievement_id (FK)
- unlocked_at (timestamp)
```

**12. user_projects (for agent memory system)**
```sql
- id
- user_id (FK)
- project_type (string: e.g., "chickens", "herb_garden", "composting")
- status (enum: desire, planning, in_progress, completed, abandoned)
- mentioned_at (timestamp, when first mentioned to an agent)
- confidence_score (float, 0-1, how certain we are this is a real project)
- related_systems (JSONB array of system_ids)
- notes (text, extracted from conversations)
```

**13. conversation_history**
```sql
- id
- user_id (FK)
- character_id (FK)
- message_type (enum: user, agent)
- message_content (text)
- created_at (timestamp)
- extracted_projects (JSONB array of project mentions)
```

**Verification:**
- All migrations run without errors
- Foreign keys enforce relationships
- Indexes on frequently queried fields
- Can manually insert test data

---

## 📋 Phase 2: The Seven Seekers (Days 6-10)

### Task 2.1: Seed Character Data

**Character specifications:**

1. **The Student**
   - Archetype: Knowledge Seeker
   - Focus: Learning, research, documentation
   - Personality: Curious, methodical, asks questions
   - Trust: None (available immediately)
   - Color: Light grey (#CCCCCC)

2. **The Grandmother**
   - Archetype: Elder Wisdom
   - Focus: Traditional methods, heirloom practices
   - Personality: Patient, warm, storytelling
   - Trust: None (available immediately)
   - Color: Medium grey (#999999)

3. **The Farmer**
   - Archetype: Food Producer
   - Focus: Growing, harvesting, practical work
   - Personality: Hands-on, direct, productive
   - Trust: Basic (requires 1 active system)
   - Color: Dark grey (#666666)

4. **The Robot**
   - Archetype: Tech Integration
   - Focus: Automation, optimization, data
   - Personality: Efficient, precise, systematic
   - Trust: Intermediate (requires 3 completed quests)
   - Color: Light grey with patterns (#DDDDDD)

5. **The Alchemist**
   - Archetype: Plant Processor
   - Focus: Preservation, fermentation, medicine
   - Personality: Experimental, mysterious, transformative
   - Trust: Intermediate (requires 2 processing systems)
   - Color: Medium-dark grey (#777777)

6. **The Survivalist**
   - Archetype: Resilience Expert
   - Focus: Preparedness, self-reliance, risk management
   - Personality: Strategic, serious, resourceful
   - Trust: Advanced (requires 5 active systems + closed loop)
   - Color: Dark grey (#555555)

7. **The Hobo**
   - Archetype: Nomadic Wisdom
   - Focus: Minimal resources, adaptability, mobility
   - Personality: Creative, unconventional, free-spirited
   - Trust: Basic (requires conversation with 3 other characters)
   - Color: Light-medium grey (#AAAAAA)

---

## 📋 Remaining Phases Summary

**Phase 3: MindsDB Integration (Days 11-15)**
- Configure MindsDB connection
- Upload permaculture PDFs
- Create all seven AI agents
- Implement agent memory system
- Build context injection

**Phase 4: Living Web (Days 16-21)**
- Seed systems library (40-50 systems)
- SVG diagram rendering
- Drag-and-drop implementation
- Connection management
- Opportunity detection

**Phase 5: Database Module (Days 22-25)**
- Personal database structure
- Editable database view
- Profile management
- Systems tracking
- Notes & journal
- Export functionality

**Phase 6: Garden (Days 26-28)**
- Plant database (50+ plants)
- Planting calendar
- Companion planting suggestions
- Integration with Living Web

**Phase 7: Quest & Progression (Days 29-33)**
- Quest generation from opportunities
- Quest board interface
- Progress tracking
- XP and leveling
- Achievement system

**Phase 8: HyperArk (Days 34-36)**
- Dashboard design
- Activity feed
- Navigation quick links

**Phase 9: Polish & Integration (Days 37-40)**
- Cross-module integration
- Error handling
- Performance optimization
- Visual polish
- Accessibility
- User testing

**Phase 10: Deployment (Days 41-43)**
- Environment configuration
- Production database setup
- MindsDB production
- SSL & security
- Monitoring & logging
- Backup strategy

**Phase 11: Launch (Days 44-45)**
- Final smoke tests
- Soft launch
- Public launch preparation

---

## ✅ Definition of Done for V1

V1 is complete when:
- All 11 phases completed
- All Seven Seekers functional with AI
- Living Web diagram with drag-and-drop
- Personal database module working
- Garden planting guide operational
- Quest system with 35+ quests
- Achievement system with 25+ badges
- Character trust system working
- Agent memory system functional
- HyperCard aesthetic consistent throughout
- Desktop experience polished
- All critical bugs fixed
- User testing completed
- Deployed to production
- Documentation published
- Soft launch successful
- Ready for public launch

---

**Total Timeline**: 55 days (~8 weeks)
**Last Updated**: 2025-01-13