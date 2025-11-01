# UI Fixes: Banner, Scrolling, and Title Bars

This document outlines recent fixes to the banner, scrolling behavior, and panel title bars.

## Problems Solved

### 1. Fixed Banner Positioning
**Problem:** Banner was not locked at the top of the page when scrolling.

**Solution:**
- Changed banner from `position: sticky` to `position: fixed`
- Set explicit positioning: `top: 0; left: 0; right: 0; width: 100%`
- Set `z-index: 1000` to keep it above all other content
- Added inline styles with `!important` to ensure override: `position: fixed !important; top: 0 !important; left: 0 !important; right: 0 !important; width: 100% !important; z-index: 1000 !important;`

**Files Modified:**
- `lib/green_man_tavern_web/components/layouts/root.html.heex` - Banner div inline styles
- `assets/css/app.css` - `.banner` CSS class

---

### 2. Panel Positioning Below Banner
**Problem:** The dual-panel windows were starting at the top of the viewport (y=0), hidden behind the fixed banner.

**Solution:**
- Removed `padding-top: 35px` from body (wasn't working correctly)
- Added `margin-top: 35px` directly to `.dual-panel-container`
- Updated height calculation to `height: calc(100vh - 35px)` to account for banner
- Ensured body has `height: 100vh` and `overflow: hidden !important`

**Files Modified:**
- `lib/green_man_tavern_web/live/dual_panel_live.html.heex` - `.dual-panel-container` styles
- `assets/css/app.css` - `body` styles (removed padding-top)

---

### 3. Missing Title Bars
**Problem:** The grey title bars at the top of each panel (showing "Green Man Tavern", "Living Web", etc.) were not visible.

**Root Cause:** The panels were positioned behind the fixed banner, so the title bars were hidden.

**Solution:**
- Fixed panel positioning (see #2 above) - this exposed the title bars
- Added explicit inline styles to both panel headers with `!important` flags
- Made title bars sticky: `position: sticky !important; top: 0 !important;`
- Set `z-index: 100` to keep them above panel content
- Added comprehensive styling: height, background, border, padding, font, visibility

**Files Modified:**
- `lib/green_man_tavern_web/live/dual_panel_live.html.heex` - `.panel-header` CSS class and inline styles on both header divs

**Key Styling:**
```css
.panel-header {
  height: 20px !important;
  background: #BBBBBB !important;
  border-bottom: 2px solid #000 !important;
  position: sticky !important;
  top: 0 !important;
  z-index: 100 !important;
  /* ... other styles ... */
}
```

---

### 4. Scrollbar Management
**Problem:** Scrollbars appearing when not needed, and page-level scrolling when it shouldn't exist.

**Solution:**
- Set `html` and `body` to `overflow: hidden !important` to prevent page-level scrolling
- Created `ScrollableContentHook` JavaScript hook that dynamically enables/disables scrollbars
- Hook checks if content `scrollHeight > clientHeight` before enabling `overflow-y: auto`
- Only individual panels show scrollbars when their content overflows
- Hook skips containers that handle their own scrolling (living-web-container, journal-container)

**Files Modified:**
- `assets/js/app.js` - Added `ScrollableContentHook`
- `lib/green_man_tavern_web/live/dual_panel_live.html.heex` - Added `phx-hook="ScrollableContent"` to panel content divs

**How It Works:**
1. Hook mounts and checks if content overflows
2. If overflow exists, adds `scrollable` class and sets `overflow-y: auto`
3. If no overflow, removes class and sets `overflow-y: hidden`
4. Rechecks on window resize and LiveView updates

---

### 5. Node Selection Styling (Living Web)
**Problem:** Selected nodes had blue borders (`#0066FF`), violating greyscale aesthetic.

**Solution:**
- Replaced blue selection color with greyscale equivalent
- Selected nodes now have:
  - `5px solid #000` border (thicker than default 2px)
  - `#FFF` background (pure white for contrast)
  - `4px 4px 0 #000` box-shadow (bold black shadow)
- Applied to both `renderNode()` and `addRealNode()` functions
- Updated `syncCheckboxState()` to maintain selection styling

**Files Modified:**
- `assets/js/hooks/xyflow_editor.js` - Updated selection styling in three locations

---

### 6. Chat Window Typography
**Problem:** Chat text was hard to read - too small and wrong font.

**Solution:**
- Updated font size from `11px` to `13px`
- Added `line-height: 1.15` for better spacing
- Applied `font-family: 'Geneva', 'Helvetica', sans-serif` to match Living Web sidebar
- Updated all chat elements: container, usernames, messages, input field, buttons, placeholder text
- Updated JavaScript dynamic message creation to match

**Files Modified:**
- `lib/green_man_tavern_web/live/dual_panel_live.html.heex` - Chat message styles
- `lib/green_man_tavern_web/components/layouts/root.html.heex` - JavaScript dynamic message styles

---

## Key CSS Patterns Used

### Fixed Positioning
```css
position: fixed;
top: 0;
left: 0;
right: 0;
z-index: 1000;
```

### Sticky Positioning
```css
position: sticky;
top: 0;
z-index: 100;
```

### Preventing Page Scrolling
```css
html {
  overflow: hidden !important;
}
body {
  overflow: hidden !important;
  height: 100vh;
}
```

### Dynamic Scrollbars (JavaScript)
```javascript
const needsScroll = element.scrollHeight > element.clientHeight;
if (needsScroll) {
  element.style.overflowY = 'auto';
  element.classList.add('scrollable');
} else {
  element.style.overflowY = 'hidden';
  element.classList.remove('scrollable');
}
```

---

## Files Modified Summary

1. `lib/green_man_tavern_web/components/layouts/root.html.heex`
   - Banner inline styles (fixed positioning)
   - Chat message JavaScript styling

2. `lib/green_man_tavern_web/live/dual_panel_live.html.heex`
   - Panel container margin-top positioning
   - Panel header CSS and inline styles
   - Chat window typography

3. `assets/css/app.css`
   - Banner fixed positioning
   - Body overflow and height constraints
   - HTML overflow prevention

4. `assets/js/app.js`
   - ScrollableContentHook implementation

5. `assets/js/hooks/xyflow_editor.js`
   - Node selection greyscale styling

---

## Testing Checklist

- [x] Banner stays fixed at top when scrolling
- [x] Panels start below banner (35px from top)
- [x] Title bars visible at top of each panel
- [x] Title bars are sticky when scrolling panel content
- [x] No page-level scrollbar (only panel scrollbars when needed)
- [x] Node selection uses greyscale styling
- [x] Chat text is readable (13px, line-height 1.15, Geneva font)
- [x] Scrollbars only appear when content actually overflows

---

## Notes

- Used inline styles with `!important` extensively due to CSS compilation issues and conflicting global styles
- Banner height is 35px - this is hardcoded in multiple places
- Title bars are 20px high with grey background (#BBBBBB)
- All scrollbars use smart detection via JavaScript hooks
- Greyscale aesthetic maintained throughout (black, white, greys only)
