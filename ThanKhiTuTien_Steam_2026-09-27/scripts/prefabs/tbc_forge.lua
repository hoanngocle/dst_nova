local Rules = require("tbc_rules")

local assets = {
    Asset("ANIM", "anim/lo_ren.zip"),
    Asset("ATLAS", "images/lo_ren.xml"),
    Asset("IMAGE", "images/lo_ren.tex"),
}
-- The placed forge and its placer share the corrected lo_ren animation origin.
local FORGE_SCALE = 1.82

local function OnHammered(inst)
    inst.components.container:DropEverything()
    local fx = SpawnPrefab("collapse_small")
    if fx ~= nil then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("metal")
    end
    inst:Remove()
end

local function ForgeFn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    MakeObstaclePhysics(inst, 0.8)
    inst.AnimState:SetBank("lo_ren")
    inst.AnimState:SetBuild("lo_ren")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetScale(FORGE_SCALE, FORGE_SCALE, FORGE_SCALE)
    inst.MiniMapEntity:SetIcon("lo_ren.tex")
    inst:AddTag("structure")
    inst._tbc_forge_state = net_string(inst.GUID, "tbc_forge.state", "tbc_forge_dirty")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("tbc_forge")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)

    function inst:TBCUpdateState()
        local item = self.components.container:GetItemInSlot(1)
        local upgrade = item ~= nil and item.components.tbc_upgrade or nil
        local state = ""
        if upgrade ~= nil then
            local opener = nil
            for player in pairs(self.components.container.openlist or {}) do
                opener = player
                break
            end
            local luck = opener ~= nil and opener.components ~= nil
                and opener.components.tbc_luck ~= nil and opener.components.tbc_luck:GetBonus() or 0
            local kind, current, next_value = upgrade:GetStrengthenPreview()
            local cost = Rules.StrengthenCost(upgrade.level)
            local chance = Rules.StrengthenProbability(upgrade.level, luck)
            state = string.format("%d|%s|%s|%s|%.2f|%d|%.2f", upgrade.level, kind,
                current ~= nil and string.format("%.2f", current) or "-",
                cost ~= nil and next_value ~= nil and string.format("%.2f", next_value) or "-",
                chance * 100, cost or 0, luck * 100)
        end
        if self._tbc_last_state ~= state then
            self._tbc_last_state = state
            self._tbc_forge_state:set(state)
        end
    end
    inst:ListenForEvent("itemget", inst.TBCUpdateState)
    inst:ListenForEvent("itemlose", inst.TBCUpdateState)
    inst.components.container.onopenfn = inst.TBCUpdateState
    inst:DoPeriodicTask(1, function(forge)
        if next(forge.components.container.openlist or {}) ~= nil then
            forge:TBCUpdateState()
        end
    end)
    inst:TBCUpdateState()
    return inst
end

return Prefab("tbc_forge", ForgeFn, assets, { "collapse_small" }),
    MakePlacer("tbc_forge_placer", "lo_ren", "lo_ren", "idle", nil, nil, nil, FORGE_SCALE)
