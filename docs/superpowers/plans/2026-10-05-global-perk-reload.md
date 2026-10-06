# Global Perk reload repair

Goal: preserve purchased global Perks when the self-hosted world is closed and reopened.
Scope: Achievement only; no character stats, cultivation progress or user save edits.

1. Reproduce missing immediate purchase persistence with the real coin component.
2. Add a world save component as the authoritative store. Read legacy JSON once on the server; failed/late reads must not erase loaded or purchased states.
3. Recover unlocked legacy player fields only where the world has no authoritative value. Save numeric states to distinguish unlocked-but-disabled (-1) from locked (0).
4. Test purchase/reload, disabled state, late legacy callback, malformed/missing JSON, legacy player recovery and retired Perks. Run existing Achievement Lua regressions and syntax checks.
5. Bump Achievement to 1.3.6 and document that in-game acceptance and Workshop deployment remain separate.

Review focus: world data must override stale player fields; clients must never write global files; retired Perks remain removed; save migration must not charge stars or change stats; callback order must not lose purchases.

Completed: all seven standalone Achievement Lua regressions passed, seven changed/new Lua files passed syntax checks, and focused code review found no remaining important issues. The regression first failed because purchases did not persist immediately; additional failing cases covered late UI replication and late valid legacy data overriding a stale player backup.

Native DST dedicated build 747465 passed purchase/toggle accounting, actual player GetSaveRecord/SpawnSaveRecord, world save and restart in isolated QA cluster GlobalPerks136. A further restart passed with deliberately conflicting legacy JSON and asserted authority came from the native world save. Successful logs: .tmp-extra-bosses/engine/global-perk-save-clean.log, global-perk-reload-final.log, global-perk-reload-authority.log. Earlier QA attempts failed due to QA sandbox setup and leftover QA processes occupying the port; these were corrected before the successful runs.

User save and live client were not modified. Workshop deployment and confirmation in the user's self-hosted session remain pending. Recovery can only restore unlocks still present in the legacy file or player backup; already-erased history is not reconstructed by granting arbitrary Perks.
