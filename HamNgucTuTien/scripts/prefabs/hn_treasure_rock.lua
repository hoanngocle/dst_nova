local function fn()
    local inst=Prefabs.rock1.fn()
    inst.AnimState:SetBuild('rock_treasure')
    if not TheWorld.ismastersim then return inst end
    inst.components.workable:SetWorkLeft(6)
    inst.components.workable:SetOnFinishCallback(function(rock)
        local manager=TheWorld.components.hn_dungeon_manager
        local rewards=require('hn_dungeon/rewards')
        rewards.SpawnLoot(manager,rewards.Roll('rock',rock.hn_reward_tier or 1),rock:GetPosition())
        rock:Remove()
    end)
    local save,load=inst.OnSave,inst.OnLoad
    inst.OnSave=function(i,data) data.hn_reward_tier=i.hn_reward_tier;if save then return save(i,data) end end
    inst.OnLoad=function(i,data,...) if data then i.hn_reward_tier=data.hn_reward_tier end;if load then return load(i,data,...) end end
    return inst
end
return Prefab('hn_treasure_rock',fn,{Asset('ANIM','anim/rock_treasure.zip')},{'rock1'})
