local Router = require "nyx/input"
local Net = require "nyx/skillnet"
local Progression = require "nyx/progression"
-- DST's reticuleaoe prefab applies its own 1.5 AnimState scale on top of
-- Transform scale. idle_1_6 has a six-unit outer ring before that scale.
local GATHER_RETICULE_OUTER_RADIUS = 6 * 1.5

local function Atlas(definition)
    return definition.atlas or (GetInventoryItemAtlas ~= nil
        and GetInventoryItemAtlas(definition.texture)
        or "images/inventoryimages.xml")
end

local function GetOwner(book)
    return book._nyx_skill_owner ~= nil and book._nyx_skill_owner:value() or nil
end

local function ReticuleTargetAllowWater()
    local player = ThePlayer
    local map = TheWorld.Map
    local pos = Vector3()
    for radius = 11.5, 0, -0.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(radius, 0, 0)
        if map:IsPassableAtPoint(pos.x, 0, pos.z, true)
            and not map:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function ConfigureImmediate(book, skill)
    book._nyx_selected_skill = skill
    book.components.spellbook:SetSpellName(Router.SKILLS[skill].label)
    book.components.spellbook:SetSpellAction(nil)
    if TheWorld.ismastersim and book.components.aoespell ~= nil then
        book.components.aoespell:SetSpellFn(nil)
    end
end

local function UpdateReticulePosition(book, pos, fx)
    fx.Transform:SetPosition(pos.x, 0, pos.z)
    if fx.prefab == "reticuleaoe_1_6" then
        local scale = (book._nyx_preview_radius or 6)
            / GATHER_RETICULE_OUTER_RADIUS
        fx.Transform:SetScale(scale, scale, scale)
    end
end

local function ConfigurePointSkill(book, skill)
    local definition = Router.SKILLS[skill]
    book._nyx_selected_skill = skill
    if skill == 'purple_gather' then
        local owner = GetOwner(book)
        local level = owner ~= nil and Net.Read(owner).level or 0
        book._nyx_preview_radius = Progression.Radius(level)
    else
        book._nyx_preview_radius = nil
    end
    book.components.spellbook:SetSpellName(definition.label)
    book.components.spellbook:SetSpellAction(nil)
    local targeting = book.components.aoetargeting
    targeting:SetRange(definition.range)
    targeting:SetAllowWater(true)
    targeting:SetAllowRiding(false)
    targeting:SetDeployRadius(0)
    targeting:SetShouldRepeatCastFn(nil)
    targeting.reticule.reticuleprefab = skill == 'purple_gather'
        and "reticuleaoe_1_6" or "reticuleaoesummontarget_1"
    -- The vanilla ping animates its own Transform scale and would draw a
    -- second, inaccurate range ring after the targeting reticule is gone.
    if skill == 'purple_gather' then
        targeting.reticule.pingprefab = nil
    else
        targeting.reticule.pingprefab = "reticuleaoeping"
    end
    targeting.reticule.targetfn = ReticuleTargetAllowWater
    targeting.reticule.mousetargetfn = nil
    targeting.reticule.updatepositionfn = skill == 'purple_gather'
        and UpdateReticulePosition or nil
    if TheWorld.ismastersim then
        targeting:SetTargetFX("reticuleaoesummontarget_1")
        book.components.aoespell:SetSpellFn(function(inst, doer, pos)
            return Router.CastAt(inst, doer, skill, pos.x, pos.z)
        end)
    end
end

local function ExecuteImmediate(book, skill)
    local owner = GetOwner(book)
    if owner == ThePlayer and Router.CanUsePanel(owner, TheFrontEnd)
        and Router.IsSkillUnlocked(owner, skill) then
        Router.RequestImmediate(skill)
    end
end

local function StartPointTargeting(book)
    local owner = GetOwner(book)
    if owner == ThePlayer and Router.CanUsePanel(owner, TheFrontEnd)
        and Router.IsSkillUnlocked(owner, book._nyx_selected_skill)
        and owner.components.playercontroller ~= nil then
        owner.components.playercontroller:StartAOETargetingUsing(book)
    end
end

local SPELLS = {}
for _, id in ipairs(require('nyx/skilldefs').Order()) do
    local skill=id
    local def=require('nyx/skilldefs').Get(skill)
    local item=Router.SKILLS[skill]
    SPELLS[#SPELLS+1]={label=item.label,tooltip=item.tooltip,atlas=Atlas(item),normal=item.texture,
        onselect=function(book)
            if def.target=='point' then ConfigurePointSkill(book,skill) else ConfigureImmediate(book,skill) end
        end,
        execute=function(book)
            if def.target=='point' then StartPointTargeting(book) else ExecuteImmediate(book,skill) end
        end}
end

local function InstallReplicaOwnerGuard(inst)
    local replica = inst.replica ~= nil and inst.replica.inventoryitem or nil
    if replica == nil or replica._nyx_owner_guard then return end
    local original = replica.IsGrandOwner
    replica.IsGrandOwner = function(self, player)
        local owner = GetOwner(inst)
        if owner ~= nil then return player ~= nil and player == owner end
        return original ~= nil and original(self, player) or false
    end
    replica._nyx_owner_guard = true
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst._nyx_skill_owner = net_entity(inst.GUID, "nyx_skillbook.owner")
    inst:AddTag("nyx_skillbook")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst:AddComponent("spellbook")
    inst.components.spellbook:SetRadius(100)
    inst.components.spellbook:SetFocusRadius(102)
    inst.components.spellbook:SetItems(SPELLS)
    inst.components.spellbook:SetCanUseFn(function(book, user)
        return GetOwner(book) == user
    end)

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetRange(12)
    inst.components.aoetargeting:SetAllowWater(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.validcolour = {0.78, 0.62, 1, 1}
    inst.components.aoetargeting.reticule.invalidcolour = {0.55, 0.1, 0.2, 1}
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
    inst.components.aoetargeting.reticule.twinstickmode = 1
    inst.components.aoetargeting.reticule.twinstickrange = 8

    inst.entity:SetPristine()

    inst.GetNyxOwner = GetOwner

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = InstallReplicaOwnerGuard
        inst:DoTaskInTime(0, InstallReplicaOwnerGuard)
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.cangoincontainer = false
    inst:AddComponent("aoespell")

    inst.BindToOwner = function(book, owner)
        book._nyx_skill_owner:set(owner)
        book.components.inventoryitem:SetOwner(owner)
        book:RemoveFromScene()
        book.entity:SetParent(owner.entity)
        if book.Network ~= nil then book.Network:SetClassifiedTarget(owner) end
        InstallReplicaOwnerGuard(book)
    end
    inst.persists = false
    return inst
end

return Prefab("nyx_skillbook", fn, nil, {
    "reticuleaoe_1_6",
    "reticuleaoesummontarget_1",
    "reticuleaoeping",
})
