require "functions/helperfunctions"

local assets =
{
    Asset("ANIM", "anim/chasni_watchpaint.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_watchpaint.xml")
}

local prefabs =
{
    "watchpaint_fx",
    "paint_fx",
    "drawing_flower",
    "drawing_love",
    "drawing_smile",
    "drawing_thumb",
    "drawing_star",
    "drawing_balloon",
    "drawing_bubble",
    "drawing_egg",
    "drawing_rocket",
    "drawing_plane",
    "drawing_plant",
    "drawing_cactus",
    "drawing_merm",
    "drawing_unicorn",
}

local ICON_SCALE = .4
local ICON_RADIUS = 50
local SPELL_RADIUS = 200
local SPELL_FOCUS_RADIUS = SPELL_RADIUS + 2
local DAMAGE = chasni_getitemconfig("watchpaint", "DMG") or 1
local function DoPaint(inst, doer, painttype)
    local x, y, z = doer.Transform:GetWorldPosition()
    local sticker = chasni_spawnprefab("drawing_"..painttype, x, y, z)
    sticker.Transform:SetRotation(doer.Transform:GetRotation() - 90)
    return true
end

local function ChangeColour(inst, doer, colour)
    local watch = inst.components.container and inst.components.container:GetItemInSlot(1)
    if watch and watch.ChasniChangeColour then
        watch:ChasniChangeColour(nil, colour)
        return true
    end
end

local function OnOpenSpell(inst)
    local inventoryitem = inst.replica.inventoryitem
    if inventoryitem then
        inventoryitem:OverrideImage("waxwelljournal_open")
    end
end

local function OnCloseSpell(inst)
    local inventoryitem = inst.replica.inventoryitem
    if inventoryitem then
        inventoryitem:OverrideImage(nil)
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_chasni_watchpaint", "swap_sword_lunarplant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    chasni_equipanimatedswaphand(inst, owner)

    if inst.components.container and inst.keep_closed ~= owner.userid then
        inst.components.container:Open(owner)
    end

    owner:AddTag("watchpainter")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    chasni_equipanimatedswaphand(inst, nil)

    if inst.components.container then
        inst.keep_closed = inst.components.container.opencount == 0 and owner.userid or nil
        inst.components.container:Close()
    end

    owner:RemoveTag("watchpainter")
end

local watchcolours = { "black", "blue", "brown", "gray", "green", "indigo", "lime", "mint", "moon", "orange", "pink", "purple", "red", "shadow", "tosca", "white", "yellow", }

local emojis = { "flower", "love", "smile", "thumb", "star", "balloon", "bubble", "egg", "rocket", "plane", "plant", "cactus", "merm", "unicorn", }

local SPELLS_WATCH = {}
for _, colour in ipairs(watchcolours) do
    local name = STRINGS.NAMES["WATCHPAINT_"..string.upper(colour)]
    table.insert(SPELLS_WATCH, {
        label = name,
        onselect = function(inst)
            inst.components.spellbook:SetSpellName(name)
            inst:AddTag("watchpaint")
            if TheWorld.ismastersim then
                inst.components.spellbook:SetSpellFn(function(inst, doer)
                    return ChangeColour(inst, doer, colour)
                end)
            end
        end,
        execute = chasni_StartInstantCasting,
        atlas = "images/inventoryimages/watches_colour_icon.xml",
        normal = colour..".tex",
        widget_scale = ICON_SCALE,
        hit_radius = ICON_RADIUS,
    })
end
local SPELLS_EMOJI = {}
for _, emoji in ipairs(emojis) do
    local name = STRINGS.NAMES["WATCHPAINT_"..string.upper(emoji)]
    table.insert(SPELLS_EMOJI, {
        label = name,
        onselect = function(inst)
            inst.components.spellbook:SetSpellName(name)
            inst:AddTag("watchpaint")
            if TheWorld.ismastersim then
                inst.components.spellbook:SetSpellFn(function(inst, doer)
                    return DoPaint(inst, doer, emoji)
                end)
            end
        end,
        execute = chasni_StartInstantCasting,
        atlas = "images/inventoryimages/chasni_drawing.xml",
        normal = emoji..".tex",
        widget_scale = ICON_SCALE,
        hit_radius = ICON_RADIUS,
    })
end

local function ItemGet(inst)
    inst.components.spellbook:SetItems(SPELLS_WATCH)
end

local function ItemLose(inst)
    inst.components.spellbook:SetItems(SPELLS_EMOJI)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chasni_watchpaint")
    inst.AnimState:SetBuild("chasni_watchpaint")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("watchpaintbrush")

    inst:AddComponent("spellbook")
    inst.components.spellbook:SetRequiredTag("watchpainter")
    inst.components.spellbook:SetRadius(SPELL_RADIUS)
    inst.components.spellbook:SetFocusRadius(SPELL_FOCUS_RADIUS)
    inst.components.spellbook:SetItems(SPELLS_EMOJI)
    inst.components.spellbook:SetOnOpenFn(OnOpenSpell)
    inst.components.spellbook:SetOnCloseFn(OnCloseSpell)

    inst:ListenForEvent("itemget", ItemGet)
    inst:ListenForEvent("itemlose", ItemLose)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst:DoTaskInTime(3, function()
            if inst.replica and inst.replica.container and inst.replica.container:GetItemInSlot(1) then
                inst.components.spellbook:SetItems(SPELLS_WATCH)
            end
        end)
        return inst
    end

    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(frame)
    inst._fxswap = SpawnPrefab("watchpaint_fx")
    inst._fxswap.AnimState:PlayAnimation("swap_energy", true)
    inst._fxswap.AnimState:SetFrame(frame)
    chasni_equipanimatedswaphand(inst, nil)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_watchpaint"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_watchpaint.xml"

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("watchpaint")

    return inst
end

local function fxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("chasni_watchpaint")
    inst.AnimState:SetBuild("chasni_watchpaint")
    inst.AnimState:PlayAnimation("swap_energy", true)
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

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
Prefab("watchpaint", fn, assets, prefabs),
Prefab("watchpaint_fx", fxfn, assets)
