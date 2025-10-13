# Green Man Tavern - Master Project Brief

## Project Overview

**Green Man Tavern** is a modular, database-driven, permaculture-based real-life RPG game/app that gamifies sustainable living practices. Players progress through implementing real-world permaculture systems in their homes and communities, guided by AI agents and structured around archetypal character pathways.

### Core Concept
- Transform permaculture learning and implementation into an engaging RPG experience
- Players earn XP, unlock achievements, and progress by completing real-world sustainable living actions
- Seven distinct character archetypes (The Seven Seekers) provide personalized guidance paths
- Visual systems flow diagrams help players understand connections between their existing and potential permaculture systems

### Primary Objectives
1. Make permaculture accessible and actionable for diverse user contexts (apartment dwellers to homesteaders)
2. Provide personalized, AI-driven guidance adapted to user's space, resources, and goals
3. Visualize system connections to reveal opportunities for closing loops and increasing resilience
4. Build community through shared challenges, achievements, and knowledge exchange
5. Track real-world impact and progression over time

---

## Technical Stack

### Frontend
- **Phoenix LiveView**: Real-time, interactive UI without complex JavaScript frameworks
- **Tailwind CSS**: Utility-first styling
- **Lucide React Icons**: Consistent iconography for systems and characters

### Backend
- **Phoenix Framework** (Elixir): Web framework and real-time features
- **PostgreSQL**: Primary database for user data, systems, achievements, etc.
- **Ecto**: Database wrapper and query builder

### AI/Agent Layer
- **MindsDB**: Hosts AI agents that provide personalized guidance
- **Agent Architecture**: Each character archetype has associated AI agent(s) with specific knowledge domains and personalities
- **Integration**: MindsDB agents query user data from PostgreSQL and provide contextual recommendations

### Development Environment
- **Cursor.AI**: Primary IDE with AI-assisted coding capabilities
- **Version Control**: Git

---

## Key Systems and Modules

### 1. Character System - The Seven Seekers

Seven archetypal characters guide players through different aspects of permaculture:

| Character | Archetype | Focus Area | Key Traits |
|-----------|-----------|------------|------------|
| **The Student** | Knowledge Seeker | Learning & Research | Curious, methodical, documentation-focused |
| **The Grandmother** | Elder Wisdom | Traditional Methods | Experienced, patient, culturally-rooted |
| **The Farmer** | Food Producer | Growing & Harvesting | Hands-on, practical, productive |
| **The Robot** | Tech Integration | Automation & Optimization | Efficient, data-driven, systematic |
| **The Alchemist** | Plant Processor | Preservation & Medicine | Transformative, experimental, chemical knowledge |
| **The Survivalist** | Resilience Expert | Preparedness & Self-reliance | Strategic, resourceful, risk-aware |
| **The Hobo** | Nomadic Wisdom | Minimal Resources & Mobility | Adaptable, creative, low-input solutions |

**Character Selection**:
- Players may identify with one primary character or multi-class
- Each character provides unique quests, achievements, and guidance style
- AI agents embody character personalities in their recommendations

### 2. Systems Flow Diagram

Visual representation of permaculture systems showing:

**Node Types**:
- **Resource Nodes**: Physical systems (herb garden, kitchen, water tank, refrigerator)
- **Process Nodes**: Transformative activities (drying, composting, fermenting, seed saving)
- **Storage Nodes**: Preservation systems (pantry, spice rack, root cellar)

**Connection Types**:
- **Active Connections** (green, solid): Currently functioning flows in user's setup
- **Potential Connections** (orange, dashed): Opportunities to close loops or add efficiency

**Features**:
- Toggle view between "current state" and "potential opportunities"
- Click nodes to see inputs, outputs, and requirements
- Click potential connections to get implementation guidance
- Drag-and-drop from systems library to plan additions

**System Categories**:
1. Food Production (gardens, sprouts, foraging)
2. Processing (drying, fermenting, composting, seed saving)
3. Storage (pantry, refrigerator, root cellar, preserves)
4. Water (collection, filtration, greywater)
5. Waste/Nutrient Cycling (compost, worm bin, bokashi)
6. Energy (solar dehydrator, passive solar, etc.)

### 3. Opportunity Detection System

AI-powered analysis that:
- Scans user's existing systems
- Identifies potential connections and improvements
- Prioritizes suggestions based on:
  - **Quick Wins**: Low cost, low effort, immediate impact
  - **Intermediate Projects**: Moderate investment, significant impact
  - **Long-term Goals**: Major systems, highest resilience gains
- Considers user context (apartment vs. house, budget, time, skill level)
- Presents actionable steps with time/cost/space requirements

### 4. Achievement & Progression System

**Mechanics**:
- **XP**: Earned by completing quests, implementing systems, documenting progress
- **Levels**: Character-specific or overall account level
- **Badges/Achievements**: "Closed Loop Master", "Seed Sovereignty", "Zero Waste Week"
- **Skill Trees**: Unlock advanced techniques and systems as you progress

**Special Achievements**:
- **Closed Loop Master**: Complete a full nutrient cycle (kitchen → compost → garden → kitchen)
- **Seed Sovereignty**: Successfully save and replant seeds from your harvest
- **Four Season Harvest**: Produce food in all four seasons
- **Waste Warrior**: Divert 90%+ of household waste from landfill

### 5. Quest System

**Quest Types**:
1. **Tutorial Quests**: Initial onboarding (set up profile, log first system)
2. **Implementation Quests**: Add new systems or connections
3. **Maintenance Quests**: Regular care tasks (water, harvest, turn compost)
4. **Learning Quests**: Read resources, watch videos, take notes
5. **Community Quests**: Share knowledge, help others, participate in challenges
6. **Challenge Quests**: Time-bound competitions (30-day composting challenge)

**Quest Structure**:
- Clear objective and success criteria
- Step-by-step guidance (especially for beginners)
- Resource links and character-specific tips
- XP reward and potential badge unlock
- Photo/note documentation encouraged

### 6. User Profile & Context System

**Stored Data**:
- **Living Situation**: Apartment, house, farm, etc.
- **Space Available**: Indoor, balcony, yard, acreage
- **Climate Zone**: For plant/technique recommendations
- **Time Availability**: Impacts quest suggestions
- **Budget Level**: Affects recommended investments
- **Skill Level**: Beginner → Intermediate → Advanced → Expert
- **Goals**: Food security, waste reduction, self-sufficiency, etc.
- **Constraints**: Physical limitations, HOA rules, rental restrictions

**Usage**:
- AI agents query this context to personalize recommendations
- Filters available systems and quests
- Adjusts difficulty and pacing of progression

---

## Current Architecture Decisions

### Database Schema (Core Tables)

**users**
- Standard auth fields (id, email, password_hash, etc.)
- profile_data (JSONB): Living situation, space, climate, goals
- primary_character_id (FK)
- created_at, updated_at

**characters**
- id, name, archetype, description
- focus_area, personality_traits (JSONB)
- icon, color_scheme

**user_characters**
- user_id (FK), character_id (FK)
- level, xp, unlocked_at
- Is primary? (boolean)

**systems**
- id, name, type (resource/process/storage)
- category (food/water/waste/energy)
- description, requirements
- default_inputs (JSONB array), default_outputs (JSONB array)

**user_systems**
- user_id (FK), system_id (FK)
- status (planned/active/inactive)
- custom_notes, location_notes
- implemented_at, last_active

**connections**
- id, from_system_id (FK), to_system_id (FK)
- connection_type (active/potential)
- flow_label (what's being transferred)

**user_connections**
- user_id (FK), connection_id (FK)
- status (active/potential/planned)
- implemented_at

**quests**
- id, title, description, character_id (FK)
- quest_type, difficulty
- xp_reward, required_systems (JSONB)
- instructions (JSONB array of steps)

**user_quests**
- user_id (FK), quest_id (FK)
- status (available/active/completed/failed)
- started_at, completed_at
- progress_data (JSONB)

**achievements**
- id, name, description, badge_icon
- unlock_criteria (JSONB)
- xp_value

**user_achievements**
- user_id (FK), achievement_id (FK)
- unlocked_at

### LiveView Architecture

**Key LiveViews**:
1. **TavernLive**: Main navigation hub (The Green Man Tavern scene)
2. **SystemsDiagramLive**: Interactive flow diagram
3. **CharacterLive**: Individual character pages with AI chat
4. **QuestBoardLive**: Available and active quests
5. **ProfileLive**: User settings and progress overview
6. **CommunityLive**: Social features (future)

**State Management**:
- LiveView socket assigns for UI state
- PubSub for real-time updates (quest completion notifications, etc.)
- Ecto queries for data fetching
- MindsDB agent calls for AI recommendations

### MindsDB Agent Integration

**Agent Roles**:
Each character has a dedicated agent with:
- Specialized knowledge base (composting, fermentation, seed saving, etc.)
- Personality prompt matching character archetype
- Access to user's profile and systems data via SQL queries

**Integration Pattern**:
```
User asks question in CharacterLive
  ↓
LiveView sends to Phoenix context function
  ↓
Context queries MindsDB agent endpoint with:
  - User message
  - User context (profile, systems, current quests)
  ↓
Agent responds with personalized guidance
  ↓
Response streamed back to LiveView
  ↓
Displayed in character-themed chat interface
```

### Visual Design System

**Color Palette**:
- Greyscale only: #000, #333, #666, #999, #CCC, #EEE, #FFF
- NO color in V1 (strict HyperCard aesthetic)

**UI Themes**:
- **Tavern Scene**: Warm, medieval tavern atmosphere (adapted to greyscale)
- **Systems Diagram**: Clean, modern flowchart aesthetic with clear hierarchy
- **Character Pages**: Themed to character personality but maintaining greyscale

**Accessibility**:
- High contrast ratios for text
- Clear icons with labels
- Keyboard navigation support
- Desktop-only for V1

---

## Integration Points Between Components

### 1. User Profile ↔ Systems Diagram
- Profile data filters which systems appear in library
- Climate zone affects plant recommendations
- Space constraints hide inapplicable systems

### 2. Systems Diagram ↔ Opportunity Detection
- Active systems analyzed to find potential connections
- Missing "bridge" systems identified
- Opportunities ranked by user's skill level and resources

### 3. Opportunity Detection ↔ Quest Generation
- Detected opportunities automatically generate implementation quests
- Quest difficulty calibrated to user's experience level
- Character-specific flavor added to quest descriptions

### 4. Character Selection ↔ AI Agent
- User's primary character determines default agent for questions
- Multi-class users can switch between character agents
- Agent personality and knowledge domain match character archetype

### 5. Quest Completion ↔ Achievement System
- Quest XP accumulates toward levels and badges
- Certain quest combinations unlock achievements
- Achievements tracked per character and account-wide

### 6. Systems Implementation ↔ Progression
- Adding systems earns XP
- Connecting systems (closing loops) earns bonus XP and potential achievements
- Regular maintenance quests keep systems "active"

### 7. MindsDB Agents ↔ Database
- Agents query user_systems, user_quests, user_profile via MindsDB SQL
- Responses can trigger database updates
- Agent learns from user's documented successes and failures over time

---

## Key Design Principles

1. **Accessibility First**: Work for apartment renters and homesteaders alike
2. **Actionable Guidance**: Every recommendation includes clear next steps
3. **Progressive Disclosure**: Start simple, reveal complexity as users advance
4. **Real-World Focus**: Digital experience serves physical implementation
5. **Personality-Driven**: Character voices make learning engaging and memorable
6. **Data-Informed**: Track real impact, not just engagement metrics
7. **Community-Oriented**: Share knowledge, not just compete

---

## Current Development Status

### Phase 1: MVP Foundation (Current)
1. Set up Phoenix project structure
2. Implement core database schema with migrations
3. Create basic LiveView pages (Tavern, Systems Diagram)
4. Connect MindsDB agents with test character
5. Build simple quest system
6. Implement basic XP and level tracking

**Target**: 55 days to V1 launch

---

## Glossary

- **System**: A physical element in permaculture setup (garden, compost, storage, etc.)
- **Node**: Visual representation of a system in the flow diagram
- **Connection**: Flow of resources/materials between systems
- **Loop**: Closed cycle where outputs become inputs
- **Process Node**: System that transforms inputs to outputs
- **Resource Node**: Source or destination system
- **Opportunity**: AI-detected potential to add systems or connections
- **Quest**: Actionable task that progresses user's permaculture implementation
- **The Seven Seekers**: Character archetypes that guide players

---

**Document Version**: 1.0
**Last Updated**: 2025-01-13
**Status**: Living document - update as architecture evolves