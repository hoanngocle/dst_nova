-- QA world only. A temporary server-only QA mod loads this with modimport.
-- Run the same QA cluster twice: first saves purchases, second verifies restart.
GLOBAL.setmetatable(env, { __index = function(_, key) return GLOBAL.rawget(GLOBAL, key) end })
AddSimPostInit(function()
    if not GLOBAL.TheWorld.ismastersim then return end
    GLOBAL.TheWorld:DoTaskInTime(3, function()
        local G = GLOBAL
        local world = G.TheWorld.components.chasni_globalperks
        assert(world, "global Perk world component must exist")
        local restarting = world.known.eternalcage and world.known.riftcontroller
        local player = assert(G.SpawnPrefab("nyx"))
        player:DoTaskInTime(3, function()
            local coin = player.components.allachivcoin
            assert(coin, "Achievement component must exist")
            coin:OnLoad({ coinamount = 100, eternalcage = false, riftcontroller = true })
            if restarting then
                assert(world.authority.eternalcage == 3 and world.authority.riftcontroller == 3,
                    "restart must recover from native world save, not only legacy JSON")
                assert(G.TUNING.ACH.eternalcage == 1, "native world save lost cage unlock")
                assert(G.TUNING.ACH.riftcontroller == -1, "native world save lost disabled state")
                assert(player.currenteternalcage:value() == 1, "unlock netvar not restored")
                assert(player.currentriftcontroller:value() == -1, "disabled netvar not restored")
                assert(coin.coinamount == 100, "restart charged stars")
                print("GLOBAL_PERK_ENGINE_RELOAD_PASS")
                G.TheSim:Quit()
                return
            end
            -- Explicit locked world states outrank the deliberately stale player backup.
            world:OnLoad({ eternalcage = 0, riftcontroller = 0 })
            coin:pickperk5(player, "eternalcage")
            coin:pickperk5(player, "riftcontroller")
            coin:pickperk5(player, "riftcontroller")
            assert(coin.coinamount == 25, "purchase/toggle star accounting changed")
            assert(player.currenteternalcage:value() == 1)
            assert(player.currentriftcontroller:value() == -1)
            assert(coin:OnSave().riftcontroller == -1)
            assert(world:OnSave().eternalcage == 1)
            world:LoadLegacy(true, '{"eternalcage":0,"riftcontroller":1}')
            assert(G.TUNING.ACH.eternalcage == 1 and G.TUNING.ACH.riftcontroller == -1)
            local saved = player:GetSaveRecord()
            local restored = assert(G.SpawnSaveRecord(saved))
            restored:DoTaskInTime(2, function()
                assert(restored.currenteternalcage:value() == 1)
                assert(restored.currentriftcontroller:value() == -1)
                assert(restored.components.allachivcoin.coinamount == 25)
                G.c_save()
                G.TheWorld:DoTaskInTime(4, function()
                    print("GLOBAL_PERK_ENGINE_SAVE_PASS")
                    G.TheSim:Quit()
                end)
            end)
        end)
    end)
end)
