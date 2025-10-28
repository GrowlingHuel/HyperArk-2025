# Two-Panel Architecture Implementation Plan

**Project:** Green Man Tavern  
**Date:** October 28, 2025  
**Goal:** Create persistent left/right panel layout where navigation only affects one panel at a time

---

## 🎯 Current Problem

**Issue:** Clicking character dropdown navigates to `/characters/:name` which replaces BOTH panels, closing the Living Web.

**Root Cause:** Each route (`/`, `/characters/:name`, `/living-web`) is a separate LiveView that renders its own complete page structure, including both left and right panels.

---

## ✅ Desired Behavior

```
┌────────────────────────────────────────────┐
│         Banner (always visible)            │
├─────────────────────┬──────────────────────┤
│  LEFT PANEL         │  RIGHT PANEL         │
│  (persistent)       │  (persistent)        │
│                     │                      │
│  • Tavern Home      │  • Welcome           │
│  • Character Chat   │  • Living Web        │
│  • Never unmounts   │  • Garden (future)   │
│                     │  • Database (future) │
└─────────────────────┴──────────────────────┘
```

**Navigation behavior:**
- Character dropdown → Updates LEFT panel only (send message)
- "Living Web" button → Updates RIGHT panel only (live_navigate)
- LEFT panel NEVER unmounts
- RIGHT panel NEVER unmounts
- Both panels persist during all navigation

---

## 🏗️ Architecture Solution: DualPanelLive Pattern

### **Core Concept:**

Create a **parent wrapper LiveView** that:
1. Always renders both panels
2. Uses **LiveComponents** for panel content
3. Handles navigation via `@live_action` and messages
4. Never unmounts during navigation

### **File Structure:**

```
lib/green_man_tavern_web/live/
├── dual_panel_live.ex           # NEW: Parent wrapper
├── dual_panel_live.html.heex    # NEW: Two-panel layout
├── panels/
│   ├── tavern_panel_component.ex      # NEW: Left panel (LiveComponent)
│   ├── tavern_panel_component.html.heex
│   ├── living_web_panel_component.ex  # NEW: Right panel content
│   └── living_web_panel_component.html.heex
├── home_live.ex                 # MODIFY: Becomes simple welcome content
├── character_live.ex            # REMOVE: Merge into tavern panel
└── living_web_live.ex           # MODIFY: Becomes right panel content
```

---

## 📝 Implementation Steps

### **Phase 1: Create DualPanelLive (Parent Wrapper)**

**What it does:**
- Acts as the persistent container for both panels
- Handles routing via `@live_action`
- Renders TavernPanelComponent (left) and content components (right)
- Subscribes to PubSub for inter-panel communication

**File:** `lib/green_man_tavern_web/live/dual_panel_live.ex`

```elixir
defmodule GreenManTavernWeb.DualPanelLive do
  use GreenManTavernWeb, :live_view
  
  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to PubSub for character selection
    Phoenix.PubSub.subscribe(GreenManTavern.PubSub, "navigation")
    
    socket =
      socket
      |> assign(:page_title, "Green Man Tavern")
      |> assign(:left_panel_view, :tavern_home)  # or :character_chat
      |> assign(:selected_character, nil)
      |> assign(:right_panel_action, :welcome)
    
    {:ok, socket}
  end
  
  @impl true
  def handle_params(params, _url, socket) do
    # Route based on @live_action (set by router)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end
  
  defp apply_action(socket, :home, _params) do
    assign(socket, :right_panel_action, :welcome)
  end
  
  defp apply_action(socket, :living_web, _params) do
    assign(socket, :right_panel_action, :living_web)
  end
  
  defp apply_action(socket, :garden, _params) do
    assign(socket, :right_panel_action, :garden)
  end
  
  # Handle character selection from dropdown
  @impl true
  def handle_info({:select_character, character}, socket) do
    socket =
      socket
      |> assign(:left_panel_view, :character_chat)
      |> assign(:selected_character, character)
    
    {:noreply, socket}
  end
  
  def handle_info({:show_tavern_home}, socket) do
    socket =
      socket
      |> assign(:left_panel_view, :tavern_home)
      |> assign(:selected_character, nil)
    
    {:noreply, socket}
  end
end
```

**Template:** `lib/green_man_tavern_web/live/dual_panel_live.html.heex`

```heex
<div class="dual-panel-container">
  <!-- LEFT PANEL: Tavern/Character Area -->
  <div class="left-panel">
    <.live_component
      module={GreenManTavernWeb.TavernPanelComponent}
      id="tavern-panel"
      view={@left_panel_view}
      selected_character={@selected_character}
      current_user={@current_user}
    />
  </div>
  
  <!-- RIGHT PANEL: Content Area -->
  <div class="right-panel">
    <%= case @right_panel_action do %>
      <% :welcome -> %>
        <.live_component
          module={GreenManTavernWeb.WelcomePanelComponent}
          id="welcome-panel"
        />
      
      <% :living_web -> %>
        <.live_component
          module={GreenManTavernWeb.LivingWebPanelComponent}
          id="living-web-panel"
          current_user={@current_user}
        />
      
      <% :garden -> %>
        <div class="mac-window">
          <div class="mac-title-bar">Garden</div>
          <div>Coming soon...</div>
        </div>
    <% end %>
  </div>
</div>

<style>
.dual-panel-container {
  display: flex;
  height: calc(100vh - 40px); /* Subtract banner height */
  overflow: hidden;
}

.left-panel {
  width: 50%;
  overflow-y: auto;
  border-right: 2px solid #000;
}

.right-panel {
  width: 50%;
  overflow-y: auto;
}
</style>
```

---

### **Phase 2: Create TavernPanelComponent (Left Panel)**

**What it does:**
- Shows Tavern home OR character chat
- Handles character chat functionality
- Never unmounts

**File:** `lib/green_man_tavern_web/live/panels/tavern_panel_component.ex`

```elixir
defmodule GreenManTavernWeb.TavernPanelComponent do
  use GreenManTavernWeb, :live_component
  alias GreenManTavern.{Characters, Conversations, AI.ClaudeClient}
  
  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:chat_messages, fn -> [] end)
      |> assign_new(:current_message, fn -> "" end)
      |> assign_new(:is_loading, fn -> false end)
    
    {:ok, socket}
  end
  
  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    # Handle chat message (copy from CharacterLive)
    # ...
  end
  
  # Copy all character chat logic from CharacterLive here
end
```

**Template:** `lib/green_man_tavern_web/live/panels/tavern_panel_component.html.heex`

```heex
<div class="mac-window">
  <%= if @view == :tavern_home do %>
    <!-- Tavern Home View (copy from home_live.html.heex) -->
    <div class="mac-title-bar">Green Man Tavern</div>
    <div class="mac-window-content">
      <!-- Tavern welcome content -->
    </div>
  <% else %>
    <!-- Character Chat View (copy from character_live.html.heex) -->
    <div class="mac-title-bar">
      <%= @selected_character.name %>
    </div>
    <div class="mac-window-content">
      <!-- Chat interface -->
    </div>
  <% end %>
</div>
```

---

### **Phase 3: Convert Living Web to Component**

**File:** `lib/green_man_tavern_web/live/panels/living_web_panel_component.ex`

```elixir
defmodule GreenManTavernWeb.LivingWebPanelComponent do
  use GreenManTavernWeb, :live_component
  
  # Copy all the logic from LivingWebLive here
  # But as a LiveComponent instead of LiveView
end
```

---

### **Phase 4: Update Router**

**File:** `lib/green_man_tavern_web/router.ex`

```elixir
scope "/", GreenManTavernWeb do
  pipe_through [:browser, :require_authenticated_user]
  
  live_session :require_authenticated_user,
    on_mount: [{GreenManTavernWeb.UserAuth, :ensure_authenticated}] do
    
    # All routes go through DualPanelLive
    live "/", DualPanelLive, :home
    live "/living-web", DualPanelLive, :living_web
    live "/garden", DualPanelLive, :garden
    live "/database", DualPanelLive, :database
    
    # Remove old routes:
    # live "/characters/:character_name", CharacterLive
  end
end
```

---

### **Phase 5: Update Character Dropdown Navigation**

**File:** `lib/green_man_tavern_web/components/layouts/root.html.heex`

Change from:
```javascript
window.location.href = `/characters/${characterName}`;
```

To:
```javascript
// Broadcast to DualPanelLive via PubSub
window.liveSocket.getSocket().channels[0].push("character_selected", {
  character_slug: characterName
});
```

Or better yet, use a LiveView event:
```javascript
// Find the DualPanelLive element and push event
const liveView = document.querySelector('[data-phx-main]');
liveView.dispatchEvent(new CustomEvent('phx:select-character', {
  detail: { character_slug: characterName }
}));
```

**In DualPanelLive:**
```elixir
@impl true
def handle_event("select_character", %{"character_slug" => slug}, socket) do
  character = Characters.get_character_by_slug(slug)
  
  socket =
    socket
    |> assign(:left_panel_view, :character_chat)
    |> assign(:selected_character, character)
  
  {:noreply, socket}
end
```

---

### **Phase 6: Update Navigation Links**

**Banner menu buttons should use `phx-click` instead of `navigate`:**

```heex
<button phx-click="navigate_right" phx-value-action="living_web">
  Living Web
</button>
```

**In DualPanelLive:**
```elixir
@impl true
def handle_event("navigate_right", %{"action" => action}, socket) do
  {:noreply, assign(socket, :right_panel_action, String.to_atom(action))}
end
```

---

## 🧪 Testing Plan

### **Phase 1 Test:**
- Navigate to `/` → Should see dual panels
- Both panels should be visible

### **Phase 2 Test:**
- Select character from dropdown
- Left panel should switch to chat
- Right panel should stay unchanged

### **Phase 3 Test:**
- Click "Living Web" button
- Right panel should switch to Living Web
- Left panel should stay unchanged (keep character if selected)

### **Phase 4 Test:**
- Navigate between pages
- Both panels should persist
- No full page reloads

### **Phase 5 Test:**
- Refresh page → State should be maintained via URL params

---

## ⚠️ Potential Issues & Solutions

### **Issue 1: LiveComponents don't have `mount/3`**
**Solution:** Use `update/2` instead and initialize state there

### **Issue 2: Passing large assigns between parent and components**
**Solution:** Only pass IDs, components fetch their own data

### **Issue 3: URL doesn't reflect left panel state**
**Solution:** Add optional query params like `?character=the-grandmother`

### **Issue 4: Browser back button**
**Solution:** Use `push_patch` instead of `assign` to update URL

---

## 📋 Implementation Checklist

- [ ] Phase 1: Create DualPanelLive
- [ ] Phase 2: Create TavernPanelComponent  
- [ ] Phase 3: Convert LivingWebLive to component
- [ ] Phase 4: Update router
- [ ] Phase 5: Update character dropdown
- [ ] Phase 6: Update navigation links
- [ ] Test Phase 1
- [ ] Test Phase 2
- [ ] Test Phase 3
- [ ] Test Phase 4
- [ ] Test Phase 5
- [ ] Commit working version
- [ ] Remove old files (CharacterLive, old HomeLive logic)

---

## 🎯 Key Principles

1. **DualPanelLive is the source of truth** - It manages both panel states
2. **LiveComponents for panels** - They never unmount, only update
3. **PubSub for cross-panel communication** - When one panel needs to affect another
4. **URL params for state** - Right panel state in `@live_action`, left panel state in query params
5. **No full page navigation** - Everything is `push_patch` or component updates

---

## 📚 Resources

- [Phoenix LiveView Components](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html)
- [LiveView Navigation](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#push_patch/2)
- [PubSub for inter-LiveView communication](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html)

---

**End of Plan**

Ready to implement! Follow the phases in order, testing after each one.
