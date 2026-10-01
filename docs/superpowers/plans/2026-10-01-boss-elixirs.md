# Six boss elixirs

**Approved scope:** Copy six player potion visuals from Solo into Thần Khí. Add recipes using real boss drops from DST and Tu Tiên. Eating permanently increases stats up to ten times per type. Achievement shows six independent 0/10 counters. Progress survives save/load, death/revival and component transfer.

| Key | Per use, max ten | At ten | Use after ten |
|---|---|---|---|
| power | +50 true damage | +50 percentage points crit damage | Blocked |
| health | +50 max health | Hot immunity | Restore 100 HP |
| mana | +50 max Hàn Lập/Nyx lingli | Cold immunity | Restore 100 lingli |
| guard | +50 flat damage reduction | Forced sleep immunity | Blocked |
| speed | +2% move speed | Poison immunity | Blocked |
| crit | +10 percentage points crit damage | Freeze immunity | Blocked |

No mana/health/sanity/hunger regeneration and no crit chance increases. Resource bonuses preserve current absolute values on refresh. The health/mana restoration exception begins only after ten prior absorptions. Mana elixir requires the existing `xd_htz_lq` resource; it does not invent a mana bar for characters without one.

**Implementation:** Extend existing Thần Khí effects, immunity and crafting paths. A dedicated `tbc_elixir_progress` component is authoritative. Achievement observes its snapshots rather than independently incrementing `oneat`. Six net counters let clients hide unavailable EAT actions. Server eater validation rejects cap bypasses and whole-stack eating is limited to one potion.

**Assets:** Solo 2.2.7 `hh_dungeon_potions.zip` plus inventory icons for strength, health, mana, guard, speed, crit. New `tbc_elixir_*` IDs avoid colliding with original timed Solo potions.

**Recipes (updated by user request):** One elixir per craft at Shadow Manipulator. Each also needs two gems of its assigned color and five high-grade lingstones. Use actual DST seasonal/raid boss drops for five recipes, retaining the Tu Tiên combination for critical damage:

| Elixir | Boss ingredients | Source | Gem color |
|---|---|---|---|
| power | 1 Dragon Scales | Dragonfly | red |
| health | 2 Royal Jelly | Bee Queen | yellow |
| mana | 1 Deerclops Eyeball | Deerclops | blue |
| guard | 1 Thick Fur | Bearger | orange |
| speed | 3 Down Feathers | Moose/Goose | green |
| crit | 1 Phượng Tủy + 1 Kỳ Lân Nhung | Kim Phượng Thần Niệm + Kỳ Lân Tàn Hồn | purple |

## Steps / ledger

- [x] Write failing progress/resource/eating integration tests.
- [x] Implement defs, authoritative count component and max-health/lingli adapters.
- [x] Copy assets and register potions, recipes, eat limits, client counters and immunity effects.
- [x] Integrate six persistent Achievement counters (parallel worker owns only Achievement).
- [x] Verify repeat loads, level changes, equipment changes, death/revival, ten-use caps, recovery exception, incoming mob hits and UI action filtering.
- [x] Run relevant existing suites, syntax checks and focused review; document deployment and runtime limits.

Preserve prior character-info/Nyx work and unrelated Hầm Ngục edits. No commit or publish requested.

## Verification and deployment

Thần Khí 1.2.0 provides the six recipes at Shadow Manipulator, one bottle per craft. Achievement 1.3.0 displays them in the food group and keeps their completion through repeated achievement rounds. Tiện Ích Information shows all six counters and permanent health/lingli contributions in its source tab.

13 copied files were compared byte for byte with Solo 2.2.7; hashes and verified native loot sources are recorded in `scripts/tbc_elixir/asset_provenance.json`. The updated recipes use installed DST loot plus Tu Tiên 18.1 loot, not synthetic boss cores. DST ingredients were verified in the installed game's `scripts.zip` prefab loot tables for Dragonfly, Bee Queen, Deerclops, Bearger and Moose/Goose.

Review reproduced a health/equipment load-order error and a health-transfer order error before correction. Health now saves its native maximum separately, recomputes equipment against that base, and establishes the target potion maximum before native percentage transfer. Tests cover equipment before/after loading, native maximum changes, unequip/reequip and both transfer orders. Native `player_common.SwapAllCharacteristics` uses unordered component traversal, so both orders matter.

All 26 Lua suites passed, including real installed Tu Tiên damage calculation, real DST Eater, and native Health transfer. Lua syntax validation passed for all 44 changed/new Lua files, and `git diff --check` passed. Focused review of the corrections found no further issues. Tests require extracted engine fixture paths via `DST_TEST_SCRIPTS`, `DST_EATER_SOURCE`, optional `DST_HEALTH_SOURCE`, and `NYX_NATIVE_CALC`. No live game/server session or Workshop upload has been performed. Keep the updated mods together and verify crafting, multiplayer counters and status immunity in game before publishing.
