-- Execute in a disposable world with Tu Tien, Nyx, Achievement and Than Khi.
-- Uses native GetSaveRecord/SpawnSaveRecord; never run on a player's live save.
local player=SpawnPrefab('nyx')
player:DoTaskInTime(3,function()
    player.components.xd_dtlevel:SetLevel(46)
    player.components.levelsystem.healthlevelamount=70
    player.components.levelsystem:loadHealth(player)
    local maxhealth=player.components.health.maxhealth
    local maxhunger=player.components.hunger.max
    local maxsanity=player.components.sanity.max
    local current=math.min(357,maxhealth)
    player.components.health:SetCurrentHealth(current)
    print('STAT_QA_BEFORE',maxhealth,current,maxhunger,maxsanity)
    local function Reload(source,iteration)
        local record=source:GetSaveRecord()
        local loaded=SpawnSaveRecord(record)
        loaded:DoTaskInTime(4,function()
            local h=loaded.components.health
            print('STAT_QA_LOADED',iteration,h.maxhealth,h.currenthealth,
                h._tbc_elixir_base,loaded.components.hunger.max,loaded.components.sanity.max)
            assert(h.maxhealth==maxhealth,'body health lost or duplicated after load')
            assert(h.currenthealth==current,'save/load changed current health')
            assert(loaded.components.xd_dtlevel.level==46,'body realm changed during load')
            assert(loaded.components.hunger.max==maxhunger,'hunger maximum changed during load')
            assert(loaded.components.sanity.max==maxsanity,'sanity maximum changed during load')
            h:_tbc_elixir_refresh()
            assert(h.maxhealth==maxhealth,'resource refresh lost or duplicated body health')
            if iteration<2 then
                Reload(loaded,iteration+1)
            else
                print('STAT_QA_DONE')
            end
        end)
    end
    Reload(player,1)
end)
