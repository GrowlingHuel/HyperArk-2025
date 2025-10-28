# Green Man Tavern - Architecture Diagram

> **Last Updated**: October 28, 2025
> **Status Legend**: ✅ Complete | 🚧 In Progress | 📋 Planned

---

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     GREEN MAN TAVERN PLATFORM                        │
│                    Phoenix LiveView Application                      │
└─────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
   ┌────▼────┐                 ┌────▼────┐              ┌──────▼──────┐
   │  User   │                 │   AI    │              │  Living Web │
   │  Auth   │                 │Character│              │   System    │
   │         │                 │  Chat   │              │   Design    │
   └────┬────┘                 └────┬────┘              └──────┬──────┘
        │                           │                           │
   ✅ Complete                  ✅ Complete                 ✅ Complete
                                                          🚧 Polish needed
```

---

## 2. LiveView → Context → Schema Architecture

### 2.1 Request Flow Diagram

```mermaid
graph TD
    User[User Browser] -->|WebSocket| Router[Phoenix Router]
    Router -->|mount/handle_event| DualPanelLive[DualPanelLive]

    DualPanelLive -->|Characters.list_characters| CharactersContext[Characters Context]
    DualPanelLive -->|Diagrams.get_or_create_diagram| DiagramsContext[Diagrams Context]
    DualPanelLive -->|Conversations.create_message| ConversationsContext[Conversations Context]
    DualPanelLive -->|AI.CharacterContext.build_prompt| AIContext[AI Context]

    CharactersContext -->|Ecto queries| CharacterSchema[(Character Schema)]
    CharactersContext -->|Ecto queries| UserCharacterSchema[(UserCharacter Schema)]

    DiagramsContext -->|Ecto queries| DiagramSchema[(Diagram Schema)]

    ConversationsContext -->|Ecto queries| ConversationHistorySchema[(ConversationHistory Schema)]

    AIContext -->|HTTP POST| ClaudeAPI[Anthropic Claude API]
    AIContext -->|Documents.Search| DocumentsContext[Documents Context]

    DocumentsContext -->|Ecto queries| DocumentChunkSchema[(DocumentChunk Schema)]

    CharacterSchema -->|belongs_to| PostgreSQL[(PostgreSQL Database)]
    UserCharacterSchema -->|belongs_to| PostgreSQL
    DiagramSchema -->|belongs_to| PostgreSQL
    ConversationHistorySchema -->|belongs_to| PostgreSQL
    DocumentChunkSchema -->|belongs_to| PostgreSQL

    style DualPanelLive fill:#4CAF50
    style ClaudeAPI fill:#FF9800
    style PostgreSQL fill:#2196F3
```

### 2.2 LiveView Routing Structure

```
lib/green_man_tavern_web/router.ex
│
├─ Public Routes (no auth)
│  ├─ POST /register → UserRegistrationLive ✅
│  ├─ POST /login → UserSessionLive ✅
│  └─ DELETE /logout ✅
│
└─ Authenticated Routes (on_mount: ensure_authenticated)
   ├─ GET / → DualPanelLive (:home) ✅
   │           │
   │           ├─ Left Panel: Character Selection
   │           └─ Right Panel: Living Web Canvas
   │
   └─ GET /living-web → DualPanelLive (:living_web) ✅
```

### 2.3 LiveView → Context Mapping Table

| LiveView | Primary Contexts Used | Purpose | Status |
|----------|----------------------|---------|--------|
| `DualPanelLive` | Characters, Diagrams, Conversations, AI, Systems | Main app interface | ✅ Complete |
| `CharacterLive` | Characters, Conversations, AI | Individual character chat | ✅ Complete (legacy) |
| `LivingWebLive` | Diagrams, Systems | System design canvas | ✅ Integrated into DualPanel |
| `UserSessionLive` | Accounts | Login | ✅ Complete |
| `UserRegistrationLive` | Accounts | Registration | ✅ Complete |
| `HomeLive` | Characters, Conversations | Original home page | 🚧 Deprecated, kept for reference |

---

## 3. AI Character Query Flow

### 3.1 Complete Message Processing Pipeline

```mermaid
sequenceDiagram
    participant User
    participant DualPanelLive
    participant ConversationsCtx
    participant AIContext
    participant DocumentsSearch
    participant ClaudeAPI
    participant CharactersCtx
    participant Database

    User->>DualPanelLive: Types message & clicks send

    Note over DualPanelLive: handle_event("send_message")

    DualPanelLive->>ConversationsCtx: create_message(user_id, char_id, "user", message)
    ConversationsCtx->>Database: INSERT conversation_history
    Database-->>ConversationsCtx: %ConversationHistory{}

    DualPanelLive->>DualPanelLive: Add to UI messages list
    DualPanelLive->>User: Show user message (optimistic update)

    DualPanelLive->>DualPanelLive: send(self(), {:process_with_claude, ...})
    Note over DualPanelLive: Async processing starts

    DualPanelLive->>AIContext: search_knowledge_base(message, limit: 5)
    AIContext->>DocumentsSearch: search_chunks(query, limit: 5)
    DocumentsSearch->>Database: SELECT * FROM document_chunks WHERE...
    Database-->>DocumentsSearch: [chunk1, chunk2, ...]
    DocumentsSearch-->>AIContext: [%{content, title, score}]

    DualPanelLive->>AIContext: build_system_prompt(character)
    AIContext-->>DualPanelLive: "You are #{name}, #{archetype}..."

    DualPanelLive->>ClaudeAPI: POST /v1/messages
    Note over ClaudeAPI: Model: claude-sonnet-4<br/>Max tokens: 2000
    ClaudeAPI-->>DualPanelLive: {content: [{text: "response"}]}

    DualPanelLive->>ConversationsCtx: create_message(user_id, char_id, "character", response)
    ConversationsCtx->>Database: INSERT conversation_history

    DualPanelLive->>CharactersCtx: update_trust_level(user_id, char_id, delta)
    CharactersCtx->>Database: UPDATE user_characters SET trust_level = ...

    DualPanelLive->>User: Push character response to UI

    Note over DualPanelLive: is_loading = false
```

### 3.2 AI Integration Components

```
lib/green_man_tavern/ai/
│
├─ claude_client.ex ✅
│  └─ Functions:
│     ├─ chat(message, system_prompt, context) → HTTP POST
│     ├─ parse_response(body) → Extract text from JSON
│     └─ Error handling with fallback messages
│
└─ character_context.ex ✅
   └─ Functions:
      ├─ build_system_prompt(character)
      │  ├─ Character name, archetype, description
      │  ├─ Focus area (e.g., "Traditional Methods")
      │  ├─ Personality traits (formatted list)
      │  └─ Role & behavior instructions
      │
      └─ search_knowledge_base(query, opts)
         ├─ Call Documents.Search.search_chunks()
         ├─ Format results with [Source: title]
         └─ Return context string for Claude
```

### 3.3 Knowledge Base Search Pipeline

```
User Query: "How do I build a compost system?"
    │
    ▼
Documents.Search.search_chunks(query, limit: 5)
    │
    ├─ Extract keywords: ["build", "compost", "system"]
    │  (Remove stop words: "how", "do", "I", "a")
    │
    ├─ SQL Query:
    │  SELECT * FROM document_chunks
    │  WHERE content ILIKE '%build%'
    │     OR content ILIKE '%compost%'
    │     OR content ILIKE '%system%'
    │  AND character_count >= 100
    │  ORDER BY relevance_score DESC
    │  LIMIT 5
    │
    └─ Return:
       [
         %{content: "...", title: "Composting Guide", score: 0.85},
         %{content: "...", title: "Waste Systems", score: 0.72},
         ...
       ]

Status: ✅ Working (keyword-based)
Future: 📋 Vector embeddings with pgvector
```

### 3.4 Trust Level Calculation

```elixir
# Location: lib/green_man_tavern_web/live/dual_panel_live.ex:416-426
# Status: ✅ Working, 🚧 Simple algorithm

defp calculate_trust_delta(user_message, character_response) do
  message_length = String.length(user_message)
  response_length = String.length(character_response)

  cond do
    message_length > 50 and response_length > 100 -> 0.1  # Substantial conversation
    message_length > 20 and response_length > 50 -> 0.05  # Moderate engagement
    true -> 0.01  # Basic interaction
  end
end

# Future Enhancement: 📋
# - Sentiment analysis
# - Question complexity scoring
# - User satisfaction ratings
# - Time spent in conversation
```

---

## 4. Dual-Panel Layout Structure

### 4.1 Visual Layout Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Browser Window                                 │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                     Top Navigation Bar                          │  │
│  │  [Green Man Tavern Logo]    [Living Web]    [User: jesse] [▼]  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────┬─────────────────────────────────────┐  │
│  │      LEFT PANEL         │         RIGHT PANEL                 │  │
│  │   (Character Zone)      │      (Living Web Zone)              │  │
│  │                         │                                     │  │
│  │  ┌──────────────────┐   │   ┌──────────────────────────────┐ │  │
│  │  │ Tavern Home      │   │   │  Living Web Canvas           │ │  │
│  │  │ or               │   │   │  or                          │ │  │
│  │  │ Character Chat   │   │   │  Home View                   │ │  │
│  │  └──────────────────┘   │   └──────────────────────────────┘ │  │
│  │                         │                                     │  │
│  └─────────────────────────┴─────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘

Status: ✅ Complete (Commit 5360ffa - Oct 28, 2025)
```

### 4.2 State Management in DualPanelLive

```elixir
# lib/green_man_tavern_web/live/dual_panel_live.ex

socket.assigns = %{
  # User & Auth
  current_user: %User{},           # ✅ From on_mount hook

  # Left Panel State
  view_mode: :home | :character,   # ✅ Toggle between tavern/character
  selected_character: %Character{} | nil,  # ✅ Currently selected character
  characters: [%Character{}],      # ✅ All available characters
  chat_messages: [%{}],            # ✅ Current conversation messages
  is_loading: boolean,             # ✅ Character response pending
  user_message: "",                # ✅ Form input binding

  # Right Panel State
  right_panel_view: :home | :living_web,  # ✅ Toggle canvas/home
  diagram: %Diagram{},             # ✅ Current user's diagram
  available_projects: [%Project{}], # ✅ System templates

  # Trust & Relationships
  user_characters: [%UserCharacter{}],  # ✅ Trust tracking

  # PubSub Topics
  # - "user:#{user_id}:characters" (character updates)
  # - "user:#{user_id}:diagrams" (diagram updates)
}
```

### 4.3 Panel Navigation Events

```mermaid
stateDiagram-v2
    [*] --> HomeView: User logs in

    HomeView --> CharacterView: select_character event
    CharacterView --> HomeView: show_tavern_home event

    HomeView --> LivingWebView: navigate_right(:living_web)
    LivingWebView --> HomeView: navigate_right(:home)

    CharacterView --> CharacterViewWithCanvas: navigate_right(:living_web)
    CharacterViewWithCanvas --> CharacterView: navigate_right(:home)

    note right of HomeView
        Left: Tavern home
        Right: Home view
    end note

    note right of CharacterView
        Left: Character chat
        Right: Home view
    end note

    note right of LivingWebView
        Left: Tavern home
        Right: Living Web canvas
    end note

    note right of CharacterViewWithCanvas
        Left: Character chat
        Right: Living Web canvas
        (SIMULTANEOUS)
    end note
```

### 4.4 Key Event Handlers

| Event | Handler Location | Purpose | Status |
|-------|-----------------|---------|--------|
| `select_character` | `dual_panel_live.ex:113` | Switch to character chat | ✅ |
| `show_tavern_home` | `dual_panel_live.ex:135` | Return to home | ✅ |
| `navigate_right` | `dual_panel_live.ex:142` | Toggle right panel | ✅ |
| `send_message` | `dual_panel_live.ex:163` | Send chat message | ✅ |
| `node_added` | `dual_panel_live.ex:306` | Add system to canvas | ✅ |
| `node_moved` | `dual_panel_live.ex:348` | Update node position | ✅ |
| `edge_added` | `dual_panel_live.ex:376` | Connect systems | ✅ |

---

## 5. Database Schema & Relationships

### 5.1 Entity Relationship Diagram

```mermaid
erDiagram
    USERS ||--o{ USER_CHARACTERS : has
    USERS ||--o{ DIAGRAMS : owns
    USERS ||--o{ CONVERSATION_HISTORY : creates
    USERS ||--o{ USER_SYSTEMS : instantiates
    USERS ||--o{ USER_QUESTS : undertakes
    USERS ||--o{ USER_ACHIEVEMENTS : earns

    CHARACTERS ||--o{ USER_CHARACTERS : tracked_by
    CHARACTERS ||--o{ CONVERSATION_HISTORY : participates_in
    CHARACTERS ||--o{ QUESTS : offers

    DOCUMENTS ||--o{ DOCUMENT_CHUNKS : contains

    SYSTEMS ||--o{ USER_SYSTEMS : instantiated_as
    SYSTEMS ||--o{ CONNECTIONS : source
    SYSTEMS ||--o{ CONNECTIONS : target

    PROJECTS ||--o{ DIAGRAMS : referenced_in

    USER_SYSTEMS ||--o{ USER_CONNECTIONS : connects_from
    USER_SYSTEMS ||--o{ USER_CONNECTIONS : connects_to

    USERS {
        int id PK
        string email UK
        string hashed_password
        datetime inserted_at
    }

    CHARACTERS {
        int id PK
        string name
        string archetype
        text description
        string focus_area
        string_array personality_traits
        string icon_name
        string color_scheme
        string trust_requirement
    }

    USER_CHARACTERS {
        int id PK
        int user_id FK
        int character_id FK
        int trust_level
        int interaction_count
        boolean is_trusted
        datetime first_interaction_at
        datetime last_interaction_at
    }

    CONVERSATION_HISTORY {
        int id PK
        int user_id FK
        int character_id FK
        string message_type
        text message_content
        string_array extracted_projects
        datetime inserted_at
    }

    DIAGRAMS {
        int id PK
        int user_id FK
        string name
        text description
        jsonb nodes
        jsonb edges
        datetime inserted_at
        datetime updated_at
    }

    PROJECTS {
        int id PK
        string name
        text description
        string category
        jsonb inputs
        jsonb outputs
        string_array constraints
        string icon_name
        string skill_level
    }

    DOCUMENTS {
        int id PK
        string title
        string file_path
        int total_chunks
        jsonb metadata
        datetime processed_at
    }

    DOCUMENT_CHUNKS {
        int id PK
        int document_id FK
        text content
        int chunk_index
        int character_count
        jsonb metadata
    }
```

### 5.2 Schema Status Table

| Schema | File Path | Relationships | Status |
|--------|-----------|---------------|--------|
| **User** | `lib/green_man_tavern/accounts/user.ex` | has_many :user_characters, :diagrams, :conversations | ✅ Complete |
| **Character** | `lib/green_man_tavern/characters/character.ex` | has_many :user_characters, :conversations, :quests | ✅ Complete |
| **UserCharacter** | `lib/green_man_tavern/characters/user_character.ex` | belongs_to :user, :character | ✅ Complete |
| **ConversationHistory** | `lib/green_man_tavern/conversations/conversation_history.ex` | belongs_to :user, :character | ✅ Complete |
| **Diagram** | `lib/green_man_tavern/diagrams/diagram.ex` | belongs_to :user | ✅ Complete |
| **Project** | `lib/green_man_tavern/systems/project.ex` | (templates, no direct FK) | ✅ Complete |
| **System** | `lib/green_man_tavern/systems/system.ex` | has_many :user_systems, :connections | ✅ Complete, 🚧 Minimal UI |
| **UserSystem** | `lib/green_man_tavern/systems/user_system.ex` | belongs_to :user, :system | ✅ Complete, 🚧 Minimal UI |
| **Connection** | `lib/green_man_tavern/systems/connection.ex` | belongs_to :source_system, :target_system | ✅ Complete, 🚧 Minimal UI |
| **UserConnection** | `lib/green_man_tavern/systems/user_connection.ex` | belongs_to :user, :source_user_system, :target_user_system | ✅ Complete, 🚧 Minimal UI |
| **Document** | `lib/green_man_tavern/documents/document.ex` | has_many :chunks | ✅ Complete |
| **DocumentChunk** | `lib/green_man_tavern/documents/document_chunk.ex` | belongs_to :document | ✅ Complete |
| **Quest** | `lib/green_man_tavern/quests/quest.ex` | belongs_to :character, has_many :user_quests | ✅ Schema, 📋 No UI |
| **UserQuest** | `lib/green_man_tavern/quests/user_quest.ex` | belongs_to :user, :quest | ✅ Schema, 📋 No UI |
| **Achievement** | `lib/green_man_tavern/achievements/achievement.ex` | has_many :user_achievements | ✅ Schema, 📋 No UI |
| **UserAchievement** | `lib/green_man_tavern/achievements/user_achievement.ex` | belongs_to :user, :achievement | ✅ Schema, 📋 No UI |

### 5.3 Key Database Constraints

```sql
-- User Characters (Trust Tracking)
ALTER TABLE user_characters
  ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
  ADD CONSTRAINT unique_user_character UNIQUE (user_id, character_id);
  -- Status: ✅ Enforced

-- Conversation History (User-Scoped)
ALTER TABLE conversation_history
  ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE;
  -- Status: ✅ Enforced
  -- All queries automatically scoped by user_id

-- Document Chunks (Cascade Delete)
ALTER TABLE document_chunks
  ADD CONSTRAINT fk_document FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE;
  -- Status: ✅ Enforced

-- Diagrams (User-Scoped)
ALTER TABLE diagrams
  ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
  -- Status: ✅ Enforced
```

---

## 6. Module Integration Points

### 6.1 Context Dependency Graph

```mermaid
graph TD
    DualPanelLive[DualPanelLive<br/>✅ Main Interface]

    CharactersCtx[Characters Context<br/>✅ Character CRUD]
    AICtx[AI Context<br/>✅ Claude Integration]
    ConversationsCtx[Conversations Context<br/>✅ Chat History]
    DiagramsCtx[Diagrams Context<br/>✅ Living Web Storage]
    DocumentsCtx[Documents Context<br/>✅ Knowledge Base]
    SystemsCtx[Systems Context<br/>✅ System Management]
    AccountsCtx[Accounts Context<br/>✅ User Auth]

    ClaudeAPI[Anthropic Claude API<br/>✅ External Service]

    DualPanelLive -->|list_characters| CharactersCtx
    DualPanelLive -->|build_prompt| AICtx
    DualPanelLive -->|create_message| ConversationsCtx
    DualPanelLive -->|get_diagram| DiagramsCtx
    DualPanelLive -->|list_projects| SystemsCtx

    AICtx -->|search_knowledge_base| DocumentsCtx
    AICtx -->|POST /v1/messages| ClaudeAPI

    CharactersCtx -->|update_trust| ConversationsCtx

    style DualPanelLive fill:#4CAF50
    style ClaudeAPI fill:#FF9800
    style AICtx fill:#FFC107
```

### 6.2 Cross-Module Communication

| From Module | To Module | Integration Point | Purpose | Status |
|-------------|-----------|-------------------|---------|--------|
| **AI Context** | **Documents Context** | `search_knowledge_base/2` | RAG for character responses | ✅ |
| **AI Context** | **Claude API** | `chat/3` | Get AI responses | ✅ |
| **Characters Context** | **Conversations Context** | `update_trust_level/4` | Track interaction quality | ✅ |
| **DualPanelLive** | **All Contexts** | Direct function calls | Orchestrate business logic | ✅ |
| **Diagrams Context** | **Systems Context** | Project template lookup | Enrich nodes with project data | ✅ |
| **User Auth** | **All Contexts** | `user_id` parameter | User-scoped queries | ✅ |

### 6.3 PubSub Topics (Real-time Updates)

```elixir
# Location: lib/green_man_tavern_web/live/dual_panel_live.ex:48-51

Phoenix.PubSub.subscribe(GreenManTavern.PubSub, "user:#{user_id}:characters")
Phoenix.PubSub.subscribe(GreenManTavern.PubSub, "user:#{user_id}:diagrams")

# Broadcast events:
# - character_trust_updated
# - diagram_updated
# - new_achievement_unlocked (future)

# Status: ✅ Infrastructure ready, 🚧 Minimal usage
```

### 6.4 External Service Integrations

```
┌─────────────────────────────────────────────────────────────┐
│                   Green Man Tavern App                       │
└──────────────────┬──────────────────────────────────────────┘
                   │
       ┌───────────┼───────────────┐
       │                           │
   ┌───▼────┐                 ┌────▼─────┐
   │ Claude │                 │PostgreSQL│
   │  API   │                 │ Database │
   │        │                 │          │
   └────────┘                 └──────────┘

   ✅ Complete                ✅ Complete

   Endpoint:                  Local:
   api.anthropic.com          localhost:5432

   Model:                     Version:
   claude-sonnet-4            PostgreSQL 14+

   Config:                    Features:
   ANTHROPIC_API_KEY          - JSONB support
   (env variable)             - Full-text search
                              - Indexes on FKs

   Future: 📋
   - Vector embeddings
     (pgvector extension)
```

---

## 7. Data Flow: Complete User Journey

### 7.1 User Chats with Character about Permaculture

```mermaid
sequenceDiagram
    autonumber

    participant Browser
    participant DualPanelLive
    participant Conversations
    participant AI
    participant Documents
    participant ClaudeAPI
    participant Characters
    participant Database

    Browser->>DualPanelLive: User types: "How do I build a compost system?"

    DualPanelLive->>Conversations: create_message(user_id, char_id, "user", message)
    Conversations->>Database: INSERT INTO conversation_history
    Database-->>Conversations: %ConversationHistory{id: 123}

    DualPanelLive->>Browser: Show user message (optimistic UI)
    DualPanelLive->>Browser: Show loading indicator

    DualPanelLive->>AI: search_knowledge_base("How do I build a compost system?")
    AI->>Documents: search_chunks(query, limit: 5)
    Documents->>Database: SELECT * FROM document_chunks WHERE...
    Database-->>Documents: [chunk1: "Composting basics...", chunk2: "Layer brown/green..."]
    Documents-->>AI: [%{content, title, score}]
    AI-->>DualPanelLive: Context string with sources

    DualPanelLive->>AI: build_system_prompt(character)
    AI-->>DualPanelLive: "You are The Grandmother, Elder Wisdom..."

    DualPanelLive->>ClaudeAPI: POST /v1/messages
    Note over ClaudeAPI: System: "You are The Grandmother..."<br/>User: "CONTEXT: [chunks]<br/>QUESTION: How do I build..."
    ClaudeAPI-->>DualPanelLive: "To build a compost system, start by..."

    DualPanelLive->>Conversations: create_message(user_id, char_id, "character", response)
    Conversations->>Database: INSERT INTO conversation_history

    DualPanelLive->>Characters: update_trust_level(user_id, char_id, +0.1)
    Characters->>Database: UPDATE user_characters SET trust_level = trust_level + 0.1

    DualPanelLive->>Browser: Show character response
    DualPanelLive->>Browser: Hide loading indicator
```

### 7.2 User Designs System in Living Web

```mermaid
sequenceDiagram
    autonumber

    participant Browser
    participant XyFlowCanvas
    participant DualPanelLive
    participant Diagrams
    participant Systems
    participant Database

    Browser->>XyFlowCanvas: User drags "Compost System" from sidebar
    XyFlowCanvas->>Browser: Trigger custom event "node_added_event"

    Browser->>DualPanelLive: phx-event: "node_added"
    Note over Browser,DualPanelLive: Payload: {project_id: 5, x: 300, y: 200, temp_id: "temp_xyz"}

    DualPanelLive->>Systems: get_project(5)
    Systems->>Database: SELECT * FROM projects WHERE id = 5
    Database-->>Systems: %Project{name: "Compost System", category: "waste"}
    Systems-->>DualPanelLive: %Project{}

    DualPanelLive->>DualPanelLive: Generate node_id = "node_1730123456_abc"

    DualPanelLive->>Diagrams: update_diagram(diagram, %{nodes: updated_nodes_map})
    Diagrams->>Database: UPDATE diagrams SET nodes = $1
    Note over Database: nodes: {"node_1730123456_abc" => {project_id: 5, x: 300, y: 200}}

    DualPanelLive->>DualPanelLive: Enrich node with project data
    Note over DualPanelLive: Add name, category, icon, etc.

    DualPanelLive->>Browser: push_event("node_added_success", enriched_node)
    Browser->>XyFlowCanvas: Update node with server ID and data
    XyFlowCanvas->>Browser: Render node on canvas with label
```

---

## 8. Security Architecture

### 8.1 Authentication & Authorization Flow

```
User Login Request
    ↓
Accounts.authenticate_user(email, password)
    ↓
Argon2.verify_pass(password, hashed_password) ✅
    ↓
Phoenix.Token.sign(conn, "user session", user_id) ✅
    ↓
Set HTTPOnly Cookie (expires: 60 days) ✅
    ↓
All LiveView requests include session token
    ↓
on_mount(:ensure_authenticated) hook
    ↓
Phoenix.Token.verify(socket, "user session", token, max_age: 60 days) ✅
    ↓
If valid: Load user, assign to socket
If invalid: Redirect to /login
    ↓
All context calls include user_id parameter
    ↓
Ecto queries automatically scope by user_id ✅
```

### 8.2 Security Features Checklist

| Feature | Implementation | Location | Status |
|---------|---------------|----------|--------|
| Password Hashing | Argon2 (via Comeonin) | `user.ex` changeset | ✅ |
| Session Tokens | Phoenix.Token (signed) | `router.ex` on_mount | ✅ |
| CSRF Protection | Phoenix built-in | `endpoint.ex` | ✅ |
| XSS Prevention | Phoenix.HTML.html_escape | All templates | ✅ |
| User-Scoped Queries | Ecto `where(user_id: ^user_id)` | All contexts | ✅ |
| HTTPOnly Cookies | `http_only: true` | `endpoint.ex` | ✅ |
| SameSite Policy | `same_site: "Lax"` | `endpoint.ex` | ✅ |
| API Key Security | Environment variable | `config/runtime.exs` | ✅ |
| SQL Injection Prevention | Ecto parameterized queries | All schemas | ✅ |
| Rate Limiting | - | - | 📋 Planned |

---

## 9. Performance Optimizations

### 9.1 Database Indexes

```sql
-- Automatically created by Ecto migrations ✅

CREATE INDEX idx_user_characters_user_id ON user_characters(user_id);
CREATE INDEX idx_user_characters_character_id ON user_characters(character_id);
CREATE INDEX idx_conversation_history_user_id ON conversation_history(user_id);
CREATE INDEX idx_conversation_history_character_id ON conversation_history(character_id);
CREATE INDEX idx_diagrams_user_id ON diagrams(user_id);
CREATE INDEX idx_document_chunks_document_id ON document_chunks(document_id);

-- Recommended additions: 📋
CREATE INDEX idx_document_chunks_content_gin ON document_chunks USING gin(to_tsvector('english', content));
-- (Full-text search performance)

CREATE INDEX idx_conversation_history_inserted_at ON conversation_history(user_id, inserted_at DESC);
-- (Faster conversation history loading)
```

### 9.2 LiveView Performance Patterns

| Pattern | Implementation | Benefit | Status |
|---------|---------------|---------|--------|
| **Async Processing** | `send(self(), {:process_with_claude, ...})` | Non-blocking AI calls | ✅ |
| **Optimistic Updates** | Add user message to UI before DB insert | Feels instant | ✅ |
| **Targeted Updates** | `push_event` for specific DOM changes | Minimal re-render | ✅ |
| **PubSub** | Subscribe to user-specific topics | Real-time without polling | ✅ |
| **Pagination** | `LIMIT 20` on conversations | Fast initial load | 🚧 Partial |
| **Debouncing** | Input delay before search | Reduce API calls | 📋 Planned |
| **Caching** | - | Reduce DB queries | 📋 Planned |

---

## 10. Testing Strategy

### 10.1 Test Coverage (Current State)

```
test/
├─ green_man_tavern/
│  ├─ accounts_test.exs         🚧 Basic tests
│  ├─ characters_test.exs       📋 Needs expansion
│  ├─ conversations_test.exs    📋 Needs expansion
│  ├─ documents_test.exs        📋 Needs expansion
│  └─ ai/
│     └─ claude_client_test.exs 📋 Needs mocking
│
└─ green_man_tavern_web/
   ├─ live/
   │  └─ dual_panel_live_test.exs 📋 Minimal coverage
   └─ controllers/
      └─ page_controller_test.exs ✅ Basic

Estimated Coverage: ~15-20%
Recommended Target: 70-80%
```

### 10.2 Priority Test Areas

| Area | Test Type | Priority | Reason |
|------|-----------|----------|--------|
| **User Authentication** | Integration | HIGH | Security critical |
| **User-Scoped Queries** | Unit | HIGH | Prevent data leaks |
| **Claude API Client** | Unit (mocked) | HIGH | External dependency |
| **Knowledge Base Search** | Unit | MEDIUM | Core feature |
| **Trust Calculation** | Unit | MEDIUM | Business logic |
| **Diagram Persistence** | Integration | MEDIUM | Data integrity |
| **Character Context Building** | Unit | LOW | Simple logic |

---

## 11. Deployment Architecture

### 11.1 Current Setup

```
Development Environment (Current)
┌─────────────────────────────────────┐
│  Local Machine (localhost:4000)     │
│  ┌─────────────────────────────┐    │
│  │  Phoenix Server              │    │
│  │  - mix phx.server            │    │
│  │  - LiveView WebSocket        │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │  PostgreSQL                  │    │
│  │  - localhost:5432            │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
         │
         ├─ External: Anthropic Claude API
         └─ Assets: esbuild, tailwind (watch mode)

Status: ✅ Working
```

### 11.2 Production Deployment (Recommended)

```
Production Environment (Suggested)
┌─────────────────────────────────────────────────┐
│  Cloud Provider (Fly.io / Render / Railway)     │
│  ┌───────────────────────────────────────────┐  │
│  │  Phoenix App (Containerized)              │  │
│  │  - Release build (mix release)            │  │
│  │  - Multiple instances (horizontal scale)  │  │
│  │  - Health checks                          │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │  PostgreSQL (Managed)                     │  │
│  │  - Automatic backups                      │  │
│  │  - Connection pooling                     │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │  CDN (Static Assets)                      │  │
│  │  - Compiled JS/CSS                        │  │
│  │  - Image assets                           │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
         │
         └─ External: Anthropic Claude API (HTTPS)

Required Env Vars:
  - SECRET_KEY_BASE
  - DATABASE_URL
  - ANTHROPIC_API_KEY
  - PHX_HOST

Status: 📋 Planned
```

---

## 12. Future Enhancements

### 12.1 Roadmap

| Feature | Description | Priority | Dependencies | Status |
|---------|-------------|----------|--------------|--------|
| **Vector Embeddings** | Semantic search with pgvector | HIGH | pgvector extension, Claude embeddings API | 📋 |
| **Multi-Character Debates** | Group conversations between characters | MEDIUM | Enhanced AI context management | 📋 |
| **System Validation** | AI analyzes Living Web designs for issues | MEDIUM | Claude function calling | 📋 |
| **Gamification UI** | Quests, achievements, progress tracking | LOW | Frontend design work | 📋 |
| **PDF Upload** | Users upload their own documents | MEDIUM | File storage (S3), processing queue | 📋 |
| **Mobile App** | React Native or Flutter | LOW | API endpoints, auth tokens | 📋 |
| **Analytics Dashboard** | User engagement metrics | LOW | Time-series database | 📋 |
| **Community Features** | Share designs, comment on systems | MEDIUM | Social features, moderation | 📋 |

### 12.2 Technical Debt Items

| Item | Impact | Effort | Priority |
|------|--------|--------|----------|
| Remove debug logging | Cleaner console, security | 30 mins | HIGH |
| Fix Tailwind CSS v4 | Maintainable styling | 1-2 hours | HIGH |
| Improve trust algorithm | Better engagement metrics | 2-3 hours | MEDIUM |
| Add comprehensive tests | Prevent regressions | 5-10 hours | MEDIUM |
| Implement rate limiting | Prevent API abuse | 2-3 hours | MEDIUM |
| Add error tracking | Better debugging | 1 hour | LOW |

---

## 13. Key File Reference

### 13.1 Critical Files by Layer

**LiveViews (Presentation)**
- `lib/green_man_tavern_web/live/dual_panel_live.ex:1-451` ✅ Main app interface
- `lib/green_man_tavern_web/live/character_live.ex:1-320` ✅ Legacy character view
- `lib/green_man_tavern_web/live/user_session_live.ex:1-134` ✅ Login
- `lib/green_man_tavern_web/live/user_registration_live.ex:1-129` ✅ Registration

**Contexts (Business Logic)**
- `lib/green_man_tavern/characters.ex` ✅ Character management
- `lib/green_man_tavern/conversations.ex` ✅ Chat history
- `lib/green_man_tavern/diagrams.ex` ✅ Living Web persistence
- `lib/green_man_tavern/documents.ex` ✅ Knowledge base
- `lib/green_man_tavern/accounts.ex` ✅ User auth

**AI Integration**
- `lib/green_man_tavern/ai/claude_client.ex:1-80` ✅ API client
- `lib/green_man_tavern/ai/character_context.ex:1-120` ✅ Prompt building

**Schemas (Data)**
- `lib/green_man_tavern/accounts/user.ex` ✅ User model
- `lib/green_man_tavern/characters/character.ex` ✅ Character model
- `lib/green_man_tavern/conversations/conversation_history.ex` ✅ Message model
- `lib/green_man_tavern/diagrams/diagram.ex` ✅ Diagram model

**Configuration**
- `config/config.exs` ✅ Application config
- `config/runtime.exs` ✅ Runtime env (API keys)
- `lib/green_man_tavern_web/router.ex` ✅ Routes

**Database**
- `priv/repo/migrations/` ✅ 23 migration files
- `priv/repo/seeds/` ✅ Characters, projects, systems

---

## 14. Summary: Overall System Health

| Component | Completeness | Quality | Notes |
|-----------|--------------|---------|-------|
| **Authentication** | 100% | 9/10 | ✅ Secure, production-ready |
| **Character AI** | 100% | 9/10 | ✅ Robust, async, good error handling |
| **Chat Interface** | 95% | 8/10 | ✅ Working, 🚧 polish needed |
| **Living Web** | 90% | 7/10 | ✅ Functional, 🚧 debug logging, CSS issues |
| **Knowledge Base** | 80% | 7/10 | ✅ Working, 📋 needs embeddings |
| **Database Schema** | 100% | 8/10 | ✅ Well-designed, normalized |
| **Testing** | 15% | 5/10 | 🚧 Needs significant expansion |
| **Documentation** | 60% | 7/10 | ✅ Code readable, 🚧 sparse inline docs |

**Overall Assessment**: The Green Man Tavern is a well-architected, feature-rich platform with solid fundamentals. The dual-panel architecture and Claude integration are production-ready. Main focus areas:
1. **Immediate**: Remove debug logging, fix Tailwind CSS
2. **Short-term**: Add tests, implement vector embeddings
3. **Long-term**: Gamification UI, advanced AI features

---

*This architecture diagram is current as of October 28, 2025. For updates, see git history.*
