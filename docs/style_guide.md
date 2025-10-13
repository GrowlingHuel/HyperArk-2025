# Green Man Tavern - HyperCard Aesthetic Style Guide

**Design Philosophy**: Classic Macintosh HyperCard circa 1987-1995  
**Core Principle**: Strict greyscale, bevel effects, bitmap aesthetic

---

## 🎨 Color Palette

### Greyscale Only
```css
/* Primary Colors - Use ONLY these */
--pure-black: #000000;
--dark-grey: #333333;
--medium-grey: #666666;
--neutral-grey: #999999;
--light-grey: #CCCCCC;
--off-white: #EEEEEE;
--pure-white: #FFFFFF;

/* DO NOT USE any color unless explicitly approved */
/* NO blues, greens, reds, etc. */
```

### Accent Usage (Rare)
- **ONLY** for critical alerts or special emphasis
- If color must be used: single accent color, desaturated
- Requires explicit approval for each use case

---

## 📐 Layout Structure

### Banner + Dual Window System

```
┌─────────────────────────────────────────────┐
│ BANNER MENU (fixed, height: 44px)          │  <- System grey (#999)
│ [Item] [Item ▾] [Item] [Item] [Item]       │
├──────────────┬──────────────────────────────┤
│              │                              │
│  LEFT        │  RIGHT                       │  <- Both white (#FFF)
│  WINDOW      │  WINDOW                      │     with borders
│  300-400px   │  Remaining width             │
│              │                              │
│              │                              │
└──────────────┴──────────────────────────────┘
```

**Rules**:
- Banner always visible (fixed position)
- Left window: contextual info, navigation, filters
- Right window: main content area
- Both windows have 1-2px borders (#666)
- Minimum spacing between windows: 0 (shared border)

---

## 🖼️ Window Components

### Window Frame
```css
.mac-window {
  background: #FFFFFF;
  border: 2px solid #666666;
  box-shadow: 2px 2px 0 #000000; /* Drop shadow effect */
}

.window-title-bar {
  background: linear-gradient(180deg, #CCCCCC 0%, #999999 100%);
  height: 24px;
  border-bottom: 1px solid #666666;
  padding: 4px 8px;
  font-weight: bold;
  font-size: 12px;
}

.window-close-button {
  width: 16px;
  height: 16px;
  border: 1px solid #666666;
  background: #EEEEEE;
  /* Position in top-left of title bar */
}
```

### Window Content
```css
.window-content {
  padding: 12px;
  background: #FFFFFF;
}
```

---

## 🔘 Button Styles

### Default Button (Raised)
```css
.mac-button {
  background: linear-gradient(180deg, #EEEEEE 0%, #CCCCCC 100%);
  border: 2px solid #666666;
  border-top-color: #FFFFFF;
  border-left-color: #FFFFFF;
  border-right-color: #333333;
  border-bottom-color: #333333;
  padding: 6px 16px;
  font-family: 'Chicago', 'Monaco', monospace;
  font-size: 12px;
  font-weight: bold;
  cursor: pointer;
  box-shadow: none;
  border-radius: 0; /* Sharp corners */
}
```

### Button States
```css
.mac-button:hover {
  background: linear-gradient(180deg, #FFFFFF 0%, #DDDDDD 100%);
}

.mac-button:active {
  /* Invert bevel for pressed effect */
  border-top-color: #333333;
  border-left-color: #333333;
  border-right-color: #FFFFFF;
  border-bottom-color: #FFFFFF;
  background: linear-gradient(180deg, #CCCCCC 0%, #DDDDDD 100%);
  transform: translateY(1px);
}

.mac-button:disabled {
  background: #EEEEEE;
  border-color: #999999;
  color: #999999;
  cursor: not-allowed;
}
```

---

## 📝 Form Elements

### Text Input
```css
.mac-text-field {
  background: #FFFFFF;
  border: 2px solid #666666;
  border-top-color: #333333;
  border-left-color: #333333;
  border-right-color: #CCCCCC;
  border-bottom-color: #CCCCCC;
  padding: 6px 8px;
  font-family: 'Monaco', 'Courier New', monospace;
  font-size: 12px;
  border-radius: 0;
}

.mac-text-field:focus {
  outline: 2px solid #000000;
  outline-offset: -4px;
}
```

### Checkbox
```css
.mac-checkbox {
  width: 16px;
  height: 16px;
  border: 1px solid #666666;
  background: #FFFFFF;
  appearance: none;
  cursor: pointer;
}

.mac-checkbox:checked {
  background: #000000;
  /* Draw X with CSS or inline SVG */
}
```

### Radio Button
```css
.mac-radio {
  width: 16px;
  height: 16px;
  border: 1px solid #666666;
  border-radius: 50%;
  background: #FFFFFF;
  appearance: none;
  cursor: pointer;
}

.mac-radio:checked {
  background: radial-gradient(circle, #000000 40%, #FFFFFF 40%);
}
```

---

## 🎯 Typography

### Font Stack
```css
--primary-font: 'Chicago', 'Monaco', 'Courier New', monospace;
--body-font: 'Geneva', 'Helvetica', 'Arial', sans-serif;
```

### Font Sizes
```css
--font-xs: 10px;   /* Captions, hints */
--font-sm: 12px;   /* Body text, buttons */
--font-md: 14px;   /* Emphasis */
--font-lg: 16px;   /* Subheadings */
--font-xl: 18px;   /* Headings */
--font-2xl: 24px;  /* Page titles */
```

### Text Styles
```css
h1, h2, h3 {
  font-weight: bold;
  font-family: var(--primary-font);
}

body, p {
  font-family: var(--body-font);
  font-size: var(--font-sm);
  line-height: 1.4;
}

.monospace {
  font-family: 'Monaco', 'Courier New', monospace;
}
```

---

## 📦 Card/Container Components

### Standard Card
```css
.mac-card {
  background: #FFFFFF;
  border: 1px solid #666666;
  padding: 12px;
  margin-bottom: 8px;
}

.mac-card-header {
  font-weight: bold;
  margin-bottom: 8px;
  padding-bottom: 4px;
  border-bottom: 1px solid #CCCCCC;
}
```

### Inset Panel (for lists, scrollable areas)
```css
.mac-inset-panel {
  background: #EEEEEE;
  border: 2px solid #666666;
  border-top-color: #333333;
  border-left-color: #333333;
  border-right-color: #CCCCCC;
  border-bottom-color: #CCCCCC;
  padding: 8px;
  overflow-y: auto;
}
```

---

## 📊 Spacing System

### Base Unit: 8px

```css
--space-1: 4px;   /* 0.5 units */
--space-2: 8px;   /* 1 unit */
--space-3: 12px;  /* 1.5 units */
--space-4: 16px;  /* 2 units */
--space-6: 24px;  /* 3 units */
--space-8: 32px;  /* 4 units */
```

### Spacing Rules
- Use multiples of 8px for margins/padding
- Minimum touch target: 32px × 32px (for buttons)
- Minimum text-to-border spacing: 8px
- Section spacing: 16-24px

---

## 🎨 Visual Effects

### Drop Shadow (use sparingly)
```css
box-shadow: 2px 2px 0 #000000;
/* Hard shadow, no blur */
```

### Bevel Effect
```css
/* Light source from top-left */
border-top: 2px solid #FFFFFF;
border-left: 2px solid #FFFFFF;
border-right: 2px solid #333333;
border-bottom: 2px solid #333333;
```

### Inset Bevel (for pressed/input fields)
```css
/* Light source from bottom-right */
border-top: 2px solid #333333;
border-left: 2px solid #333333;
border-right: 2px solid #CCCCCC;
border-bottom: 2px solid #CCCCCC;
```

---

## 🖱️ Interactive States

### Hover States
- Slight lightening of background
- NO color change
- NO border change
- Cursor: pointer

### Focus States
```css
:focus {
  outline: 2px solid #000000;
  outline-offset: -4px;
  /* Black outline, inside element */
}
```

### Active/Pressed States
- Invert bevel direction
- 1px translateY (button press effect)
- Darken background slightly

### Disabled States
```css
:disabled {
  background: #EEEEEE;
  color: #999999;
  border-color: #999999;
  cursor: not-allowed;
}
```

---

## 🔔 Dialogs & Modals

### Alert Dialog
```css
.mac-dialog {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: #FFFFFF;
  border: 2px solid #000000;
  box-shadow: 4px 4px 0 #000000;
  padding: 16px;
  min-width: 300px;
  max-width: 500px;
}

.dialog-title {
  font-weight: bold;
  margin-bottom: 12px;
  font-size: 14px;
}

.dialog-message {
  margin-bottom: 16px;
  line-height: 1.4;
}

.dialog-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
```

### Icon in Dialog
- Use simple geometric shapes
- Black on white
- Max size: 32×32px
- Position: left of message text

---

## 📱 Icons

### Style Guidelines
- Simple geometric shapes
- 1-2px stroke weight
- Black on white or white on black
- Sizes: 16px, 24px, 32px
- No gradients, no color
- Clear at small sizes

### Icon Usage
```css
.icon-small { width: 16px; height: 16px; }
.icon-medium { width: 24px; height: 24px; }
.icon-large { width: 32px; height: 32px; }
```

---

## 🚫 What NOT to Do

### Forbidden Styles
- ❌ Rounded corners (except radio buttons)
- ❌ Gradients (except subtle bevels)
- ❌ Box shadows with blur
- ❌ Transparency/opacity (except for overlays)
- ❌ Color (unless explicitly approved)
- ❌ Smooth animations (use instant or stepped)
- ❌ Modern UI patterns (cards with large padding, floating action buttons, etc.)

### Anti-Patterns
- ❌ Don't use Material Design
- ❌ Don't use Bootstrap default styles
- ❌ Don't use smooth easing functions
- ❌ Don't use web fonts (stick to system fonts)

---

## ✅ Quality Checklist

Before considering any component "done":

- [ ] Uses only greyscale colors from palette
- [ ] Has proper bevel effects (if applicable)
- [ ] Sharp corners (no border-radius)
- [ ] System font family
- [ ] Proper interactive states (hover, active, focus, disabled)
- [ ] Keyboard accessible
- [ ] Matches HyperCard reference images
- [ ] 8px spacing grid followed
- [ ] Hard shadows only (no blur)
- [ ] Tested in context with other components

---

## 🎨 Reference Images

[Placeholder for actual HyperCard screenshots]

Key characteristics to emulate:
1. System 7 button bevels
2. Window chrome styling
3. Monospace fonts for code/data
4. Sharp, crisp borders
5. Minimal whitespace
6. High information density

---

## 🔄 Versioning

**Style Guide Version**: 1.0  
**Last Updated**: [Date]  
**Maintained By**: [Your name]

### Change Log
- v1.0: Initial style guide created

---

## 💡 Quick Reference

Copy-paste these into Cursor for consistent styling:

### Button Template
```html
<button class="mac-button">
  Click Me
</button>
```

### Window Template
```html
<div class="mac-window">
  <div class="window-title-bar">
    <span>Window Title</span>
    <button class="window-close-button">×</button>
  </div>
  <div class="window-content">
    [Content here]
  </div>
</div>
```

### Card Template
```html
<div class="mac-card">
  <div class="mac-card-header">Card Title</div>
  <div class="mac-card-body">
    [Content]
  </div>
</div>
```

---

**This style guide is law. No deviations without explicit approval.**