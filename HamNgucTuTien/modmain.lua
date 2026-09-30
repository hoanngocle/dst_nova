GLOBAL.setmetatable(env, {__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})
PrefabFiles = {'hn_dungeon_gate','hn_dungeon_exit','hn_dungeon_wall','hn_arena_lava_pond','hn_arena_decor',
    'hn_dungeon_spider','hn_dungeon_pig','hn_dungeon_hounds','hn_hound_projectiles','hn_bosses','hn_beru',
    'hn_ice_fx','hn_corpses','hn_treasure_rock','hn_recovery_bag'}
for _,name in ipairs({'gate_reset','gate_low','gate_high','gate_reset_max','gate_low_max','gate_high_max'}) do
    AddMinimapAtlas('images/minimap/'..name..'.xml')
end
modimport('main/hn_actions.lua')
modimport('main/hn_player_states.lua')
modimport('main/hn_mob_states.lua')
modimport('main/hn_motion_guards.lua')
modimport('main/hn_restrictions.lua')
modimport('main/hn_tutien_compat.lua')
AddPrefabPostInit('world',function(inst)
    if require('hn_dungeon/authority').IsAuthority(inst) then inst:AddComponent('hn_dungeon_manager') end
end)
AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.health or inst.components.inventoryitem or inst.components.container then
        if not inst.components.hn_owned then inst:AddComponent('hn_owned') end
    end
end)
AddComponentPostInit('inventory',function(inv)
    if TheWorld.ismastersim and inv.inst:HasTag('player') then require('hn_dungeon/recovery').WrapInventory(inv) end
end)
AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent('hn_dungeon_cooldown')
    inst:ListenForEvent('ms_becameghost',function(player)
        local manager=TheWorld.components.hn_dungeon_manager
        if manager and manager.players_in_dungeon[player] then manager:Leave(player,'death') end
    end)
end)
local names={HN_DUNGEON_SPIDER='Nhện Hầm Ngục',HN_DUNGEON_PIG='Heo Hầm Ngục',HN_BERU='Beru',
    HN_DUNGEON_FIREHOUND='Sói Lửa',HN_DUNGEON_ICEHOUND='Sói Băng',HN_DUNGEON_SNOWHOUND='Sói Tuyết',
    HN_DUNGEON_LIGHTNINGHOUND='Sói Điện',HN_DUNGEON_HORRORHOUND='Sói Bóng Đêm',HN_TREASURE_ROCK='Mạch Linh Thạch',
    HN_DUNGEON_EXIT='Lối thoát Hầm Ngục',HN_DUNGEON_GATE='Cổng Hầm Ngục',HN_RECOVERY_BAG='Túi thu hồi Hầm Ngục'}
for name,text in pairs(names) do STRINGS.NAMES[name]=text;STRINGS.CHARACTERS.GENERIC.DESCRIBE[name]=text end
AddStategraphPostInit('minotaur',function(sg)
    require('hn_dungeon/vanilla').PatchMinotaurDeath(sg.states.death)
end)
AddComponentPostInit('stackable',function(stack)
    if TheWorld.ismastersim then require('hn_dungeon/stack_ownership').Wrap(stack) end
end)
