# HyperCard Window Chrome - Detailed Specification

**Based on**: The Island of Dr Moreau screenshot (authentic HyperCard aesthetic)

---

## 🪟 Window Title Bar

### Dimensions
- Height: **20px** (compact, not spacious)
- Border: **1px solid #000** (top and sides)
- Bottom border: **2px solid #000** (slightly thicker to separate from content)

### Background
- **Pattern**: Horizontal lines (1px black, 1px white, repeating)
- Or solid **#CCC** if pattern too complex

### Title Text
- Font: **Monaco, "Courier New", monospace** at **10px bold**
- Color: **#000**
- Position: **Left-aligned, 24px from left** (room for close box)
- Vertical: **Centered in 20px height**

### Close Box
- Size: **14×14px square**
- Position: **3px from left, 3px from top**
- Border: **1px solid #000**
- Background: **#EEE**
- Icon: **Two diagonal lines forming X** (1px black)
- States:
  - Default: Light grey (#EEE)
  - Hover: White (#FFF)
  - Active: Dark grey (#CCC)

---

## 📜 Scrollbar Specification

### Visibility
- **ONLY visible when content overflows**
- Hidden completely when not needed (not greyed out, GONE)

### Dimensions
- Width: **16px**
- Position: **Right edge of window, below title bar**

### Components

#### 1. Track
- Background: **#EEE** with dithered pattern (optional)
- Border-left: **1px solid #666**

#### 2. Up Arrow Button
- Size: **16×16px**
- Background: **#CCC**
- Border: **1px solid #000**
- Icon: **▲** (black triangle, 6px height, centered)
- States: Default, Hover (#DDD), Active (#AAA)

#### 3. Down Arrow Button
- Same as up arrow but **▼**
- Position: **Bottom of track**

#### 4. Thumb (Scroll Handle)
- Width: **14px** (2px padding from edges)
- Min height: **20px**
- Background: **#DDD**
- Border: **1px solid #666**
- Inner decoration: **3 horizontal lines** (1px, centered, 2px apart)

#### 5. Behavior
- Thumb size proportional to content vs viewport
- Draggable
- Click track to page up/down

---

## 🖱️ Button Style (Image 2 Authentic)

### Dimensions
- Padding: **4px 12px** (compact)
- Border: **2px solid #000** (heavy, sharp)
- Border-radius: **0** (perfectly square)

### States

#### Default
- Background: **#CCC**
- Border: **2px solid #000**
- Text: **#000, bold, 11px Monaco**

#### Hover
- Background: **#DDD** (slightly lighter)
- Border: **Same**

#### Active (Pressed)
- Background: **#AAA** (darker)
- Border: **Inverted visual effect** (can achieve with box-shadow inset)
- Content: **Shift 1px down and right**

#### Disabled
- Background: **#E5E5E5**
- Border: **1px solid #999** (thinner, lighter)
- Text: **#999**
- Cursor: **not-allowed**

---

## 🎨 Dithered Pattern Backgrounds

### Pattern Style
- **Checkerboard dither**: Alternating pixels of two greys
- Example: `#EEE` and `#F5F5F5` in 2×2 pixel pattern
- Or: `#E8E8E8` and `#F0F0F0` for very subtle

### Implementation (CSS)
```css
.dithered-bg {
  background-image: 
    repeating-linear-gradient(
      0deg,
      #EEE 0px, #EEE 1px,
      #F5F5F5 1px, #F5F5F5 2px
    ),
    repeating-linear-gradient(
      90deg,
      #EEE 0px, #EEE 1px,
      #F5F5F5 1px, #F5F5F5 2px
    );
}
```

### Where to Apply
- Window content areas (very subtle)
- Behind scrollable content
- Optional: Title bar backgrounds

---

## 🔤 Typography

### Primary Font Stack
```css
font-family: 'Monaco', 'Courier New', monospace;
```

### Font Sizes
- Title bars: **10px bold**
- Buttons: **11px bold**
- Body text: **12px normal**
- Small text: **10px normal**

### Anti-Aliasing
```css
-webkit-font-smoothing: none;
-moz-osx-font-smoothing: grayscale;
font-smooth: never;
text-rendering: optimizeSpeed;
```

This makes text appear sharper, more bitmap-like.

---

## 📐 Pixel-Perfect Rules

### All Measurements
- Use **whole pixel values only** (no 1.5px, no rem/em with decimals)
- Borders: 1px or 2px (no fractional)
- Spacing: multiples of 2px (2, 4, 6, 8, 12, 16, 20, 24)

### Border Rendering
```css
* {
  box-sizing: border-box;
}

.sharp-border {
  border: 1px solid #000;
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
}
```

### No Anti-Aliasing
```css
.no-antialias {
  -webkit-font-smoothing: none;
  shape-rendering: crispEdges;
  image-rendering: pixelated;
}
```

---

## 🪟 Window Component Structure

### Complete Window
```html
<div class="mac-window">
  <!-- Title Bar -->
  <div class="mac-title-bar">
    <div class="mac-close-box"></div>
    <span class="mac-title">Window Title</span>
  </div>
  
  <!-- Content Area -->
  <div class="mac-content-area">
    <!-- Content with overflow: auto -->
    [Content here]
  </div>
  
  <!-- Scrollbar appears automatically via CSS when overflow -->
</div>
```

### CSS Structure
```css
.mac-window {
  border: 2px solid #000;
  background: #FFF;
  display: flex;
  flex-direction: column;
}

.mac-title-bar {
  height: 20px;
  background: #CCC; /* or pattern */
  border-bottom: 2px solid #000;
  display: flex;
  align-items: center;
  padding: 0 4px;
  flex-shrink: 0;
}

.mac-close-box {
  width: 14px;
  height: 14px;
  border: 1px solid #000;
  background: #EEE;
  cursor: pointer;
  flex-shrink: 0;
  margin-right: 6px;
}

.mac-title {
  font-family: Monaco, monospace;
  font-size: 10px;
  font-weight: bold;
  color: #000;
}

.mac-content-area {
  flex: 1;
  overflow: auto;
  padding: 8px;
}

/* Custom scrollbar styling */
.mac-content-area::-webkit-scrollbar {
  width: 16px;
}

.mac-content-area::-webkit-scrollbar-track {
  background: #EEE;
  border-left: 1px solid #666;
}

.mac-content-area::-webkit-scrollbar-thumb {
  background: #CCC;
  border: 1px solid #666;
}

.mac-content-area::-webkit-scrollbar-button {
  height: 16px;
  background: #CCC;
  border: 1px solid #000;
}
```

---

## 🎯 Left Window Specific

### Tavern Scene (Fixed)
- Position: **Sticky at top** (position: sticky; top: 0;)
- Always visible when scrolling down
- Image dimensions: **Match window width, ~300-400px height**
- Background: **#000** (if image has transparency)

### Character Content (Scrollable)
- Appears **below** tavern scene
- Only visible when character selected
- Scrollable independently
- Padding: **8px**

### Implementation
```html
<div class="left-window">
  <div class="mac-title-bar">
    <div class="mac-close-box"></div>
    <span class="mac-title">Tavern - The Student</span>
  </div>
  
  <div class="mac-content-area">
    <!-- Sticky tavern scene -->
    <div class="tavern-scene-sticky">
      <img src="tavern.png" alt="Green Man Tavern" />
    </div>
    
    <!-- Scrollable character content -->
    <div class="character-content">
      [Character info, stats, controls]
    </div>
  </div>
</div>
```

```css
.tavern-scene-sticky {
  position: sticky;
  top: 0;
  background: #000;
  z-index: 10;
}

.character-content {
  padding-top: 8px;
  background: #FFF;
}
```

---

## 🔄 Dynamic Title Updates

### Title Bar Content Updates via LiveView

```elixir
# In assigns
@left_window_title = "Tavern - #{@selected_character.name}"
@right_window_title = @current_page_title

# In template
<span class="mac-title"><%= @left_window_title %></span>
```

### Examples
- Left: "Tavern - The Grandmother", "Tavern - The Robot", "Tavern"
- Right: "Database", "Garden Planting Guide", "Living Web", "HyperArk"

---

## ✅ Implementation Checklist

For Cursor prompts:

- [ ] Update all buttons to flat style with 2px black borders
- [ ] Create MacWindowChrome component (title bar + close box)
- [ ] Style scrollbars (webkit-scrollbar CSS)
- [ ] Add dithered pattern backgrounds
- [ ] Update fonts to Monaco with no anti-aliasing
- [ ] Make left window sticky tavern scene
- [ ] Dynamic title bar updates
- [ ] Ensure scrollbars only appear when needed
- [ ] Test with overflowing and non-overflowing content
- [ ] Verify all measurements are whole pixels

---

## 🎨 Color Reference (Quick)

- **Pure Black**: #000
- **Dark Grey**: #333 (rarely used now)
- **Medium Grey**: #666 (borders)
- **Neutral Grey**: #999 (disabled states)
- **Light Grey**: #CCC (button default, title bars)
- **Off-white**: #EEE (backgrounds, scrollbar track)
- **Pure White**: #FFF (content areas)

---

**Version**: 2.0 (Image 2 Authentic)  
**Updated**: Based on user feedback  
**Status**: Ready for implementation