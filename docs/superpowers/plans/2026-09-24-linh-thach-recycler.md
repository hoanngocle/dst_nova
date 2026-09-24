# Linh Thach Recycler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an independent Don't Starve Together mod that converts stored items into server-authoritative half-stone credit and lets the player withdraw only accepted `xd_lingshi1` items.

**Architecture:** A focused pricing module calculates integer half-stone values and rejection reasons. A networked machine prefab owns the nine-slot container, replicated preview/status values, confirmation state, balance persistence, server-only refinement and withdrawal, while `modmain.lua` provides the container layout, client controls, RPC boundary, strings, and recipe.

**Tech Stack:** Don't Starve Together Lua mod API, Klei container widgets/netvars/mod RPCs, Node.js static contract tests.

**Spec:** `docs/superpowers/specs/2026-09-24-linh-thach-recycler-design.md`

## Global Constraints

- Create a standalone mod in `LinhThachRecycler/`; do not edit Tu Tiên, Achievement local, Nyx, or unrelated existing files.
- Depend on Tu Tiên workshop mod `3721846643` and emit only `xd_lingshi1`.
- Store all credit as integers where one unit equals `0.5` Hạ Phẩm Linh Thạch.
- Recalculate and mutate only on the master simulation; client values are previews.
- Preserve all rejected items, all credit that could not be withdrawn, and both container contents and balance across save/load.
- Require a second click when an accepted batch is worth at least `5` stones (`10` half-units).
- The machine cannot burn or be hammered while it contains an item or any positive half-unit balance.

## Review Focus

- A full inventory, including a full partial stack, must keep every undelivered stone's two half-units in the machine.
- A client must not refine or withdraw through RPC unless the player is near the same open machine.
- Changing a slot after the first high-value click must invalidate the pending confirmation.
- A container item with contents, any `xd_lingshiN`, protected quest item, recycler, or profitable recipe output must remain untouched with a reason.
- Loading malformed or legacy balance data must clamp it to a non-negative integer without losing saved container contents.

---

### Task 1: Mod metadata and pricing policy

**Files:**
- Create: `LinhThachRecycler/modinfo.lua`
- Create: `LinhThachRecycler/scripts/nova_lingshi_pricing.lua`
- Create: `LinhThachRecycler/tests/run_tests.js`

**Interfaces:**
- Consumes: item entities with `prefab`, optional `components.stackable`, `components.finiteuses`, `components.armor`, and `components.container`.
- Produces: `pricing.GetItemQuote(item, all_recipes) -> { accepted, units, count, reason }`, `pricing.GetRawUnitValue(prefab) -> integer`, and exported `VALUES`, `PROTECTED`, `REASON` tables.

- [ ] **Step 1: Write the failing metadata and pricing contract tests**

Create a Node test that asserts the mod dependency and server-required flags, extracts representative values from `nova_lingshi_pricing.lua`, verifies the reject guards exist, and simulates the documented integer durability formula for stack and durability cases.

- [ ] **Step 2: Run the tests to verify RED**

Run: `node LinhThachRecycler/tests/run_tests.js`

Expected: FAIL because `modinfo.lua` and `nova_lingshi_pricing.lua` do not exist.

- [ ] **Step 3: Implement metadata and the pricing module**

Implement explicit half-unit values, protected prefabs, the `^xd_lingshi%d+$` guard, non-empty container rejection, recipe-output profitability detection using `recipe.product`/`recipe.numtogive` and ingredient values, stack multiplication, and durability scaling with `math.floor` and a one-unit minimum.

- [ ] **Step 4: Run the tests to verify GREEN**

Run: `node LinhThachRecycler/tests/run_tests.js`

Expected: PASS for metadata, explicit prices, default half-unit, stack math, durability floor, and rejection contracts.

- [ ] **Step 5: Commit**

Stage only the three files above and commit as `feat: add recycler pricing policy`.

### Task 2: Server-authoritative machine prefab

**Files:**
- Create: `LinhThachRecycler/scripts/prefabs/nova_lingshi_recycler.lua`
- Modify: `LinhThachRecycler/tests/run_tests.js`

**Interfaces:**
- Consumes: `pricing.GetItemQuote`, Klei `container`, `workable`, inventory, netvar, `SpawnPrefab`, save/load, and event APIs.
- Produces: prefab methods `RefreshPreview`, `TryRefine(player)`, `TryWithdraw(player)`, `CanHammer()`, replicated `_nova_balance`, `_nova_preview`, `_nova_status`, `_nova_rejected`, `_nova_confirm`, and save key `nova_balance_units`.

- [ ] **Step 1: Add failing server-state contract tests**

Assert the prefab has nine-slot iteration, a reentrancy guard, revision-based confirmation invalidation, server-side re-quote before removal, removal only after accepted quotes, one-at-a-time withdrawal with `inventory.ignorefull`, deduction only after `GiveItem` succeeds, non-negative integer load clamping, netvar refresh, and conditional hammer workability.

- [ ] **Step 2: Run the tests to verify RED**

Run: `node LinhThachRecycler/tests/run_tests.js`

Expected: FAIL because the machine prefab does not exist.

- [ ] **Step 3: Implement the prefab**

Use the vanilla treasure chest bank/build and 3x3 UI assets. Add a nine-slot container whose content is saved by the component, replicate preview/balance/status, recompute quotes on slot changes, require a revision-matched second high-value click, remove accepted slots and add their exact quoted units on the server, and withdraw one stone per successful inventory insertion while preserving balance on failure. Toggle `workable:SetWorkable` only when both container and balance are empty.

- [ ] **Step 4: Run the tests to verify GREEN**

Run: `node LinhThachRecycler/tests/run_tests.js`

Expected: PASS for all pricing and prefab server-state contracts.

- [ ] **Step 5: Commit**

Stage only the prefab and test file and commit as `feat: implement recycler machine state`.

### Task 3: Container UI, RPC boundary, recipe, and verification

**Files:**
- Create: `LinhThachRecycler/modmain.lua`
- Create: `LinhThachRecycler/README.md`
- Modify: `LinhThachRecycler/tests/run_tests.js`

**Interfaces:**
- Consumes: prefab methods and netvars from Task 2, `containers.widgetsetup`, `widgets/containerwidget`, `MOD_RPC`, `AddModRPCHandler`, and `AddRecipe2`.
- Produces: nine-slot screen with live balance/preview/status, `Luyện hóa`/`Xác nhận` and `Rút` controls, validated server RPC handlers, and the craftable `nova_lingshi_recycler` structure recipe.

- [ ] **Step 1: Add failing integration contract tests**

Assert the mod registers its prefab, extends the container layout without replacing unrelated layouts, sends only machine entities through RPC, validates prefab/range/open-container server-side, displays both controls and replicated values, registers the exact `4 cutstone + 4 boards + 2 goldnugget + 1 gears` Science Two recipe, and documents installation and manual acceptance checks.

- [ ] **Step 2: Run the tests to verify RED**

Run: `node LinhThachRecycler/tests/run_tests.js`

Expected: FAIL because `modmain.lua` and `README.md` do not exist.

- [ ] **Step 3: Implement integration and documentation**

Register a 3x3 top container widget, wrap the container widget open/refresh/close methods to add the withdraw button and status labels only for this prefab, send refine/withdraw requests over namespaced RPCs, validate entity, distance, player inventory, and open state on the server, set Vietnamese strings, and add the Alchemy Engine recipe and placer.

- [ ] **Step 4: Run automated verification**

Run: `node LinhThachRecycler/tests/run_tests.js`

Expected: PASS with a printed count and zero failures.

- [ ] **Step 5: Run repository-scope and syntax-shape checks**

Run: `git diff --check -- LinhThachRecycler docs/superpowers/plans/2026-09-24-linh-thach-recycler.md` and inspect `git status --short`.

Expected: no whitespace errors; only the plan and `LinhThachRecycler/` files belong to this feature.

- [ ] **Step 6: Commit**

Stage only `LinhThachRecycler/modmain.lua`, `LinhThachRecycler/README.md`, and the test file; commit as `feat: add recycler controls and recipe`.

- [ ] **Step 7: Final requirement review**

Re-read the spec and verify every acceptance item against the tests and implementation. Record any DST runtime limitation explicitly; do not claim an in-game run unless a dedicated-server or game session was actually executed.
