local assets =
{
    Asset("ANIM", "anim/readingglasses.zip"),
    Asset("ATLAS", "images/inventoryimages/readingglasses.xml"),
}

local USES = chasni_getitemconfig("readingglasses", "USES") or 30
local SHADOWCREATURE_MUST_TAGS = { "shadowcreature", "_combat", "locomotor" }
local SHADOWCREATURE_CANT_TAGS = { "INLIMBO", "notaunt" }
local function PlayerReadFn(inst, book)
    if inst.components.sanity:IsInsane() then
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 16, SHADOWCREATURE_MUST_TAGS, SHADOWCREATURE_CANT_TAGS)

        if #ents < TUNING.BOOK_MAX_SHADOWCREATURES then
            TheWorld.components.shadowcreaturespawner:SpawnShadowCreature(inst)
        end
    end
end

local function OnRead(owner, data)
    local readingglasses = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    if readingglasses and readingglasses.components.finiteuses and readingglasses:HasTag("readingglasses") then
        readingglasses.components.finiteuses:Use(1)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "readingglasses", "swap_hat")
    owner.AnimState:Show("HAT")

    if owner:HasTag("player") and not owner:HasTag("aspiring_bookworm") then
        if owner.components.reader then
            owner:AddTag("chasni_fastreader")
        else
            owner:AddTag("chasni_tempreader")
            owner:AddTag("reader")
            owner:AddComponent("reader")
            owner.components.reader:SetOnReadFn(PlayerReadFn)
        end

        inst:ListenForEvent("chasni_readbook", OnRead, owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")

    if owner:HasTag("chasni_tempreader") then
        owner:RemoveTag("reader")
        owner:RemoveComponent("reader")
    end
    owner:RemoveTag("chasni_fastreader")
    inst:RemoveEventCallback("chasni_readbook", OnRead, owner)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("readingglasses")
    inst.AnimState:SetBuild("readingglasses")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("readingglasses")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "readingglasses"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/readingglasses.xml"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    return inst
end

return Prefab("chasni_readingglasses", fn, assets)