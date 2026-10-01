# Nyx skill buff correction

> **For agentic workers:** Use superpowers:executing-plans for this focused correction and a fresh final review.

**Goal:** All five combat skills include current weapon damage and existing potion/Achievement multipliers once per hit.

**Architecture:** Combine the level-scaled skill base and live weapon damage before `Xd_CalcDamage`. Native Tu Tien 18.1 already applies potion, Achievement perk and damage upgrade modifiers. Explicitly mark Nyx's native effects and recognize the native callback's `inst` at the calculator boundary; do not scale arbitrary hits from the same source file or after `GetAttacked` wrappers.

**Tech Stack:** DST Lua; standalone Lua regression tests.

**Spec:** User-approved behavior in this conversation; preserve existing level rates (0.30/0.25/0.30/0.25/0.15), breakpoints and native combat effects.

## Constraints and review focus

- Keep existing uncommitted character-information work and unrelated edits in the current checkout.
- Do not change balance constants, crit, armor, target-specific native bonuses or PvP rules.
- Test weapon swaps, potion expiry, all five skills, overlapping effects, unrelated attacks and other characters.
- Test invulnerable targets and original calculator arguments/return values.
- Native integration depends on Tu Tien 18.1 callbacks exposing their effect as local `inst`; verify against installed source and test actual callbacks when possible.

## Task: Correct the shared damage path

- [x] Add failing `Nyx_Steam_2026-09-27/tests/skill_damage_test.lua` for combined damage before native modifiers and native effect attribution.
- [x] Change `scripts/util/nyx_skill_damage.lua` to calculate live weapon contribution, mark native effects, and install the calculator hook after mod initialization.
- [x] Update owned fan/night/sword calculation sites and mark domain/fan/river native effects. Register the hook in `modmain.lua`.
- [x] Run the new test, existing Nyx tests and character-info/equipment tests; syntax-check changed Lua files and run `git diff --check`.
- [x] Request focused code review, fix confirmed findings, document formula and verification limits.

## Evidence / execution ledger

- Installed Tu Tien 18.1 `mainfunction.lua`: `Xd_CalcDamage` multiplies `externaldamagemultipliers:Get()` once. Achievement uses `damagePerk` and `damageUpgrade`; potion code writes the same modifier list.
- Native fan damage originates in `xd_mutated_fx.lua`, with `inst.owner` pointing to `xd_htz_firefx`; native river originates in `xd_yunxiao_jjj.lua`, not the prefab name used in the old source matcher.
- Native domain, river and flame callbacks all use local parameter `inst` and call the global calculator before `GetAttacked`.
- RED: the new behavioral test failed at the absent `Calculate` entry point before implementation. GREEN: the new suite passes; the optional integration test also passes using the extracted native calculator with mocked entities/helper inputs.
- Final verification: 19 test files passed across Nyx/TienIch/ThanKhi; 23 changed/new Lua files passed `luac -p`; `git diff --check` passed. Tests use Lua 5.4, not an in-game DST session.
- Fresh reviewer `review_nyx_damage`: no actionable findings. Runtime gameplay and arbitrary third-party calculator wrappers remain unverified. DST's shipped debugtools/stacktrace/dumper also use `debug.getlocal`.
