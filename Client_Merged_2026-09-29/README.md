# Tiện Ích Client (DST)

One client-only mod combining these locally installed Steam Workshop versions:

| Feature | Workshop ID | Version | Author |
| --- | --- | --- | --- |
| Auto Walking | 2849308125 | 3.8.2 | 川小胖 & Fengying |
| Observer Camera | 1579421388 | 1.3.4 | gcc |
| EMI Continued | 2905450407 | 4.0.11 | Im So HM02 |
| Geometric Drop | 2431691504 | 1.4.8 | Chaosmonkey |
| Geometric Placement | 351325790 | 3.2.0 | rezecib |

The five upstream `modmain.lua` files live in `sources/`; their required
`scripts/`, `images/` and `anim/` files share the mod root. `modinfo.lua`
keeps the other mods' configuration controls, with Vietnamese labels for the
main sections. Extended Map Icons has no menu options; its icons use the
upstream defaults (icons enabled, structure and item persistence enabled,
creature and boss persistence disabled).

The mod icon uses the supplied scroll artwork. `modicon_source.png` preserves
the original image; `modicon.png` is its square preview, and `modicon.tex` with
`modicon.xml` is the texture atlas loaded by Don't Starve Together.

## Changes to Geometric Drop

- Keeps the held item's cursor image visible while grid or circle dropping is
  active. Building or placing an item still uses Geometric Placement's own
  cursor setting.
- Checks each circle placer before moving it and recreates a removed placer.
  This covers the invalid-entity `SetPosition` path reported at line 271 of
  Geometric Drop 1.4.8.

## Install

Copy this entire directory into the game's local `mods` directory. Enable
this mod in the client mod list and disable the five separate Workshop mods
to avoid installing the same hooks twice. The combined mod has a new identity,
so its settings start from the upstream defaults; configure it in the Mods
screen as needed.

## Checks

From this directory, run `lua tests/geometric_drop_test.lua` and
`lua tests/merge_test.lua`. These cover the removed-placer path, cursor
visibility, the five source registrations, and the hidden map icon settings.
An actual game session is still needed to verify visual behavior and native
engine stability.
