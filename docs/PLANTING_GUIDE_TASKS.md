# Planting Guide - Working Plan and Checklist

This document tracks the remaining work for the right-panel Planting Guide and records what’s already done.

## Current status (done)
- Banner: Added "Planting Guide" link (phx-click navigate="planting_guide").
- Navigation: `:planting_guide` supported in `dual_panel_live.ex`; header and content branch added in `dual_panel_live.html.heex`.
- Data source (MVP): JSON-backed loader at `lib/green_man_tavern/planting_guide/json_data.ex`.
- Sample data files:
  - `priv/data/planting_guide/families.json`
  - `priv/data/planting_guide/plants.json`
  - `priv/data/planting_guide/planting_windows.json`
  - `priv/data/planting_guide/companions.json`
- Filters: month buttons (Jan–Dec), hemisphere (N/S), climate, family; selected state reflected in UI.
- Rendering: Plant cards with family/climate and windows (month abbreviations) filtered by hemisphere.

## Remaining work (Phase 1 - JSON MVP)
1) Card enrichment (high priority)
- Show companions per plant:
  - Good companions list (from `companions.json` relation = "good").
  - Bad companions list (from `companions.json` relation = "bad").
- Show action chips for selected month and hemisphere (from `planting_windows.json`):
  - E.g., `[Plant]`, `[Harvest]`, based on the `action` field.

2) Data quality (keep minimal but useful)
- Add a handful of additional plants and windows across multiple climates and families to demonstrate filter variety.
- Keep strictly greyscale and concise; no color accents.

3) UX polish (HyperCard aesthetic)
- Ensure sharp borders, system fonts only, no rounded corners, no smooth animations.
- Add subtle hover state (e.g., invert border/background slightly in greyscale) for buttons.
- Keyboard accessibility: ensure month buttons and selects are reachable; add `aria-pressed` to month/hemisphere toggles (in place already) and `aria-label`s where useful.

4) Resilience and logging
- Gracefully handle missing/invalid JSON (fallback to empty lists).
- Console log minimal debug lines for filter changes (temporary; remove for prod).

## Optional Phase 2 (DB-backed)
- Migrations: create `plant_families`, `plants`, `planting_windows`, `companions` tables with indexes.
- Schemas: `GreenManTavern.PlantingGuide.*` modules.
- Context: Ecto queries to replace JSON filtering; preload companions.
- Seeds: import a small dataset; keep within greyscale guidelines.
- Feature-flag or config to switch between JSON and DB sources.

## Testing (later)
- Unit tests for JSON filtering (month, family, climate, hemisphere).
- LiveView smoke tests: mount, filter changes, card rendering.

## Out of scope for MVP
- New routes (Planting Guide lives in the right panel only).
- Smooth animations or non-greyscale designs.
- Large data imports.

## Milestones
- M1 (JSON MVP completed):
  - Companions and action chips rendered; minimal added data; basic accessibility pass.
- M2 (Polish):
  - More sample entries, minor layout tweaks, reduced debug logs.
- M3 (DB option - if requested):
  - Migrations, schemas, context, seeds, switch control.

## Notes
- LiveView independence maintained: left panel remains unchanged when using Planting Guide.
- Performance: JSON is small and loaded on demand; acceptable for MVP.
