local assets = {
    Asset("ANIM", "anim/axe_axe.zip"),
    Asset("ANIM", "anim/swap_axe_axe.zip"),
    Asset("ATLAS", "images/inventoryimages/axe_axe.xml"),
    Asset("SOUNDPACKAGE", "sound/axe.fev"),
    Asset("SOUND", "sound/axe.fsb"),
}

local DAMAGE = chasni_getitemconfig("axe_axe", "DMG") or 66.6
local USES = chasni_getitemconfig("axe_axe", "USES") or 666
local RANGE = chasni_getitemconfig("axe_axe", "RNG") or 20
local WORK_MULT = chasni_getitemconfig("axe_axe", "WRKM") or 4
local WORK_CONSUMPTION = chasni_getitemconfig("axe_axe", "WRKC") or 1
local TAG = {"CHOP_workable"}
local function onwork(owner, data)
    owner:RemoveEventCallback("working", onwork)
    local x, y, z = owner.Transform:GetWorldPosition()
    local aoeworking = false
    local ents = TheSim:FindEntities(x, y, z, RANGE, TAG, chasni_TAG_NOTARGET)
    for _, v in pairs(ents) do
        if v ~= data.target and (v.prefab == data.target.prefab) and v.components.workable and v.components.workable:CanBeWorked() and v.components.workable:GetWorkAction() == ACTIONS.CHOP then
            local vx, vy, vz = v.Transform:GetWorldPosition()
            chasni_spawnprefab("hacking_tall_grass_fx", vx, vy, vz)
            v.components.workable:WorkedBy(owner, WORK_MULT)
            aoeworking = true
        end
    end
    if aoeworking then
        owner:ShakeCamera(CAMERASHAKE.SIDE, 1, 0.02, 0.25)
        owner.SoundEmitter:PlaySound("turnoftides/common/together/driftwood/chop")
    end
    owner:ListenForEvent("working", onwork)
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_axe_axe", "swap_axe")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    owner:ListenForEvent("working", onwork)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    owner:RemoveEventCallback("working", onwork)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("axe")
    inst.AnimState:SetBuild("axe_axe")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("weapon")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/axe_axe.xml"
    inst.components.inventoryitem.imagename = "axe_axe"

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, WORK_MULT)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, WORK_CONSUMPTION)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("axe_axe", fn, assets)
