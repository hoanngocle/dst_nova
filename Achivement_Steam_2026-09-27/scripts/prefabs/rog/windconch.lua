local assets =
{
    Asset("ANIM", "anim/wind_conch.zip"),
	Asset("ANIM", "anim/swap_wind_conch.zip"),
    Asset("ATLAS", "images/inventoryimages/windconch.xml"),
    Asset("ANIM", "anim/crab_king_winter_build.zip"),
}

local prefabs =
{
    "chasni_sealnado",
}

local SPAWN_DIST = 25
local USES = chasni_getitemconfig("windconch", "USES") or 2
local BOSS_PREFAB = "chasni_sealnado"

SetSharedLootTable("chasni_crabqueen", {
    {"jellybean_green",                 1.00},
    {"jellybean_green",                 0.25},
    {"jellybean_red",                   1.00},
    {"jellybean_red",                   0.25},
    {"jellybean_yellow",                1.00},
    {"jellybean_yellow",                0.25},
    {"chasni_crab_fireorgan",           1.00},
    {"chasni_crab_fireorgan",           0.50},
    {"chasni_crab_fireorgan",           0.25},
    {"chasni_crab_iceorgan",            1.00},
    {"chasni_crab_iceorgan",            0.50},
    {"chasni_crab_iceorgan",            0.25},
    {"chasni_crab_waterorgan",          1.00},
    {"chasni_crab_waterorgan",          0.50},
    {"chasni_crab_waterorgan",          0.25},
    {"chasni_crab_electricorgan",       1.00},
    {"chasni_crab_electricorgan",       0.50},
    {"chasni_crab_electricorgan",       0.25},
    {"chasni_crab_lunarorgan",          1.00},
    {"chasni_crab_lunarorgan",          0.50},
    {"chasni_crab_lunarorgan",          0.25},
    {"chasni_crab_shadoworgan",         1.00},
    {"chasni_crab_shadoworgan",         0.50},
    {"chasni_crab_shadoworgan",         0.25},
})

local function ConvertCrabking(crabking)
    if not crabking:HasTag("chasni_crabqueen") and not crabking:HasTag("hostile") and crabking.components.health and crabking.components.health:GetPercent() == 1 then
        crabking.sg:GoToState("chasni_transform_pre")

        crabking:AddTag("chasni_crabqueen")
        if crabking.components.lootdropper then
            crabking.components.lootdropper:SetChanceLootTable("chasni_crabqueen")
        end
    end
end

local function OnPlayed(inst, owner)
    if owner then
        local pos = Vector3(owner.Transform:GetWorldPosition())
        local crabkings = TheSim:FindEntities(pos.x,pos.y,pos.z, 15, {"crabking"})
        if #crabkings > 0 then
            for _,crabking in ipairs(crabkings) do
                ConvertCrabking(crabking)
            end
        else
            owner:DoTaskInTime(1.5, function()
            local pt = owner:GetPosition()
            local spawn_pt = chasni_getspawnpoint(pt, SPAWN_DIST)
            if spawn_pt then
                local boss = SpawnPrefab(BOSS_PREFAB)
                if boss then
                    boss.Physics:Teleport(spawn_pt:Get())
                    boss:FacePoint(pt:Get())
                    if boss.components.combat then
                        boss.components.combat:SetTarget(owner)
                    end
                end
            end
            end)
        end
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("wind_conch")
    inst.AnimState:SetBuild("wind_conch")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("tool")
    inst:AddTag("horn")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("instrument")
    inst.components.instrument.range = 0
    inst.components.instrument:SetOnPlayedFn(OnPlayed)
    inst.components.instrument.override_sound = "DLChasni/DLChasni/chasni_rocflute/conch"

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.PLAY)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "windconch"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/windconch.xml"

    MakeHauntableLaunch(inst)

    inst.hornbuild = "swap_wind_conch"
    inst.hornsymbol = "swap_horn"

    return inst
end

return Prefab("chasni_windconch", fn, assets, prefabs)
