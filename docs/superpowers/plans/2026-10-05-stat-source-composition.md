# Stat source composition implementation plan

> **For agentic workers:** Execute inline with superpowers:executing-plans; verify each task before proceeding.

**Goal:** Preserve original character stats and compose each owned source once: Achievement perks, Achievement levels, Tu Tien cultivation, elixirs and equipment.

**Architecture:** Retain Tu Tien's native calculations. Each addon updates/removes only its own delta or keyed modifier. Resource maxima use flat additions and each item's existing percentage rule; combat, movement and defense retain their native percentage/flat semantics. Revival penalties apply after the full health maximum.

**Tech Stack:** DST Lua 5.1, standalone Lua regression tests and an isolated dedicated engine.

**Spec:** User instruction in this chat dated 2026-10-05; `docs/MOD_LOAD_AND_STATS.md`.

## Constraints and review focus

- No edits to original Tu Tien, no level-1 reset, no changes to the user's live save.
- Preserve current health/hunger/sanity during reload and ghost status; no bonus duplication.
- Preserve unrelated edits already present from other chats.
- Check flat/percentage equipment, zeroed bonuses, load order, repeated refresh, and death/revival.
- Bump the patch version of each runtime mod changed and keep its description synchronized.

## Tasks

- [x] Add failing tests for Achievement perk/level damage, speed and defense modifiers, including removal at zero without touching another source. Fix the proven modifier errors in `scripts/components/allachivcoin.lua` and `levelsystem.lua`.
- [x] Exercise native base + perk + level + cultivation + elixir + equipment composition for health, hunger and sanity. Fix only failures reproduced in the resource adapters/reload path; validate current values and ghost state.
- [x] Run an engine matrix with source additions/removals, cultivation change, two save/load rounds, equipment changes, penalties and death/revival. Add a reusable engine regression independent of the user's private save.
- [x] Run relevant suites with correct DST dependencies/Lua versions, update versions and stats documentation, and review the final diff. Report engine results separately from mocks and remaining client limitations.

## Findings before implementation

- Actual save copied into isolated QA: health maximum 637.5 = native 287.5 + Achievement levels 350. Native includes original 125; no extra 125 should be injected.
- Perk `speedupfn` and `damageupfn` pass the increment directly to multiplicative modifier APIs; level equivalents correctly use `1 + bonus`. Zero-valued update functions currently leave old modifiers installed.
- The earlier display-only additions from this chat were withdrawn to focus on runtime composition.

## Verification result

- 26 standalone Lua tests passed; UI fixture includes native Widget:SetHoverText, item hook uses Lua 5.1.
- Isolated dedicated engine completed STAT_COMPOSITION_QA_DONE with original Tu Tien: composition, repeated refresh, body level 46 → 47, points, equipment changes, two entity save/load rounds, penalty/current resource preservation, native ghost load and revival events.
- Engine fixture uses valid affix APIs (21% health, 20% weapon speed) and accounts for body +16's separate 29% speed. Native ghost health is 50, not zero; assertions preserve native ghost state and resurrect health.
- Focused independent code review found no actionable issue. Runtime Lua 5.1 syntax, synchronized patch versions, and diff whitespace checks passed.
- Changes remain in repository; Workshop publishing and live client validation were not performed.
