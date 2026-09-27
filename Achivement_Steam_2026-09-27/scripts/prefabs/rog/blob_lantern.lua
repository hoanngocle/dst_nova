local assets =
{
    Asset("ANIM", "anim/blob_lamp.zip"),
    Asset("ATLAS", "images/inventoryimages/blob_lamp.xml"),
    Asset("INV_IMAGE", "lantern_lit"),
}

local prefabs =
{
    "blob_lanternlight",
    "crabstaff_lunar_fx",
}

local DAMAGE = 17
local ATTACK_RANGE = 4
local HIT_RANGE = 4.5
local SPEED = chasni_getitemconfig("blob_lantern", "SPD") or 0.5
local function onremovelight(light)
    light._lantern._light = nil
end

local function turnon(inst)
    local owner = inst.components.inventoryitem.owner

    if inst._light == nil then
        inst._light = SpawnPrefab("blob_lanternlight")
        inst._light._lantern = inst
        inst:ListenForEvent("onremove", onremovelight, inst._light)
    end
    inst._light.entity:SetParent((owner or inst).entity)
end

local function turnoff(inst)
    if inst._light ~= nil then
        inst._light:Remove()
    end
end

local function OnRemove(inst)
    if inst._light ~= nil then
        inst._light:Remove()
    end
end

local function ondropped(inst)
    turnoff(inst)
    turnon(inst)
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_blob_lamp", "swap_sword_lunarplant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    chasni_equipanimatedswaphand(inst, owner)
    turnon(inst)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    chasni_equipanimatedswaphand(inst, nil)
end

--------------------------------------------------------------------------

local function lightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetColour(200 / 255, 225 / 255, 190 / 255)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(4)
    inst.Light:SetFalloff(.95)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    return inst
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("blob_lamp")
    inst.AnimState:SetBuild("blob_lamp")
    inst.AnimState:PlayAnimation("drop", true)

    inst:AddTag("light")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(frame)
    inst._fxswap = SpawnPrefab("blob_lantern_fx")
    inst._fxswap.AnimState:PlayAnimation("idle", true)
    inst._fxswap.AnimState:SetFrame(frame)
    chasni_equipanimatedswaphand(inst, nil)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)
    inst.components.weapon:SetRange(ATTACK_RANGE, HIT_RANGE)
    inst.components.weapon:SetElectric()

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/blob_lamp.xml"
    inst.components.inventoryitem.imagename = "blob_lamp"
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(turnoff)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = SPEED

    inst._light = nil
    inst.OnRemoveEntity = OnRemove
    turnon(inst)

    return inst
end

local function fxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()
    inst.Transform:SetScale(0.4,0.4,0.4)

    inst:AddTag("FX")

    inst.AnimState:SetBank("blob_lamp")
    inst.AnimState:SetBuild("blob_lamp")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("colouradder")

    inst.persists = false
    return inst
end

return 
Prefab("blob_lantern", fn, assets, prefabs),
Prefab("blob_lanternlight", lightfn),
Prefab("blob_lantern_fx", fxfn)
