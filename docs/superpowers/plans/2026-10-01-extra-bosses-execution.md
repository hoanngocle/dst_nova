# Execution ledger — plan: 2026-10-01-port-remaining-solo-bosses.md

Approved by user: “Bỏ qua, xử lý plan trước đó đã làm đi”. Outside-map treasure monsters excluded.

Base: 21d8f233. Preserve existing uncommitted Igris/release changes and unrelated Achievement/NOVA changes.
Preflight: factory consumes extra_boss_defs; Guardian consumes phase component and hazard API; all new entities must use manager Track and current run epoch; waves enabled after dependencies exist.

Ruling: implement in current checkout to preserve the existing approved Igris/release changes; no git staging of unrelated files.
Task 1 started: executable contracts for base stats, phases and safe hazards.

Task 1/3/4 contracts: watched 5 failures (missing modules), then 5 passes. Verified DST build 747465 health:SetVal emits minhealth before death and supports SetMinHealth.
Task 2: source pig SGs ported; removal of workable destruction and non-locomotor instant kills; new temporary walls and speed component reuse.
Task 3/4 Ruling: rewrite Guardian's obfuscated attack/FX glue into readable arena modules rather than importing unsafe global damage, ruins-respawner, and chest code. Keep attack families, source animations, phase/HP rules; FX use bounded tasks instead of extra FX stategraphs. Cost: visual timing may differ from Solo; renderer comparison remains necessary.
Task 5 pool contract: observed failure with 3 bosses, expanded to 6. Corrected owner epoch field to the manager's actual hn_dungeon_run_epoch; engine and integration tests cover actual Track.

Final independent review: 2 P1 and 1 P2 accepted. RED engine regression reproduces charge/gore entering walk_stop, no movement, and teleport landing without damage (HN_REG_DONE 4). Wave cast regression fails before new shared-cast helper. Fix pass: suppress locomote during busy attacks, execute teleport impact before timeout transition, restore four cardinal waves at radius 3 with shared per-cast hit set.
Final: Ruling: renderer, late-join/reconnect, simultaneous Solo activation and final time-to-kill cannot be certified by headless tests; retain explicit pending acceptance checklist and source-timing caveat. Cost: visual/network issues or balance adjustments may remain until human playtest.
Final: Ruling: unrelated Achievement/NOVA edits stay outside release; prior approved Igris fix stays in HamNguc package. Cost: unrelated staged work remains for its own commit.

Final: fixed teleport impact and interrupted charge/gore — dedicated engine regression RED 4 failures → GREEN 4 passes, HN_REG_DONE 0. Shared-wave regression RED missing helper → GREEN four offset rays / one target hit. Full Lua suite 43/43, Igris assets 2/2, dependency closure passed.
Final review deferred minors: none. Human renderer/network and combat-balance acceptance remain pending as documented, not represented as passed.

Final full-stack engine: 37 checks passed, HN_EXTRA_DONE 0 and HN_REG_DONE 0, no Lua errors/missing animations. Final Lua suite 44/44; 87 Lua syntax files. Client acceptance remains pending.
Ruling: consolidate the verified, interdependent runtime and prior Igris fix into one release commit instead of intermediate incomplete commits; cost is coarser rollback granularity.
