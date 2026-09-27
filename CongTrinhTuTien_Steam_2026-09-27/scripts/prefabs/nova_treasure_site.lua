local logic = require("nova_treasure_logic")
local rewards = require("nova_treasure_rewards")

local assets = {
    Asset("ANIM", "anim/hh_items.zip"),
    Asset("ATLAS", "images/hh_icon/hh_items.xml"),
    Asset("IMAGE", "images/hh_icon/hh_items.tex"),
}

local function OnDug(inst, digger)
    if digger == nil then
        inst.components.workable:SetWorkLeft(1)
        return
    end

    local success = logic.ResolveSite(inst, digger, rewards, SpawnPrefab, function(name)
        return Prefabs[name] ~= nil
    end)
    if not success and digger.components.talker ~= nil then
        digger.components.talker:Say("Kho báu chưa xuất hiện, đào lại nhé.")
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("hh_treasure_build.tex")
    inst.AnimState:SetBank("hh_items")
    inst.AnimState:SetBuild("hh_items")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:OverrideSymbol("hh_remove_stone", "hh_items", "hh_treasure_build")
    MakeObstaclePhysics(inst, 0.4)
    inst:AddTag("nova_treasure_site")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnDug)
    return inst
end

return Prefab("nova_treasure_site", fn, assets)
