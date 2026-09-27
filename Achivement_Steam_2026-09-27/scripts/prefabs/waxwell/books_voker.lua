local assets =
{
    book_voker = {
        Asset("ANIM", "anim/swap_book_voker.zip"),
        Asset("ANIM", "anim/swap_book_invoker.zip"),
        Asset("ANIM", "anim/book_voker.zip"),
        Asset("ATLAS", "images/inventoryimages/book_voker.xml"),
        Asset("IMAGE", "images/inventoryimages/book_voker.tex"),
        Asset("SOUNDPACKAGE", "sound/chasjoker.fev"),
        Asset("SOUND", "sound/chasjoker.fsb"),
    },
}

-- book_voker
local BASE_DAMAGE = chasni_getitemconfig("book_voker", "DMG") or 17
local DAMAGE_MULT = chasni_getitemconfig("book_voker", "EXO") or 6
local HEAL_MULT = chasni_getitemconfig("book_voker", "QUAS") or 0.2
local FAIL_USE = chasni_getitemconfig("book_voker", "FAIL") or 5
local HUGE_FAIL_USE = chasni_getitemconfig("book_voker", "HFAIL") or 10
local function spawnball(angle)
    local ball = chasni_spawnprefab("groundlight_fx")
    ball.Transform:SetScale(.3, .3, .3)
    ball._angle = angle
    return ball
end

local function stopball(inst)
    if inst._rotatingtask == nil then
        inst._rotatingtask:Cancel()
        inst._rotatingtask = nil
    end
    if inst._qwe and #inst._qwe > 0 then
        for _, ball in ipairs(inst._qwe) do
            ball:Remove()
        end
        inst._qwe = {}
    end
end

local function rotateball(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if not owner or inst._qwe == nil then
        stopball(inst)
    end

    for _, ball in ipairs(inst._qwe) do
        local speed = 0.01
        ball._angle = ball._angle and ball._angle + speed or 0
        local distance = 1.2
        local offset = Vector3(distance * math.cos(ball._angle), 0, -distance * math.sin(ball._angle))
        local x, _, z = owner.Transform:GetWorldPosition()
        ball.Transform:SetPosition(x + offset.x, 0, z + offset.z)
    end
end

local function healtask(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner then
        if owner.components.health then
            local q = 0 + (inst._qwei[1] == 1 and 1 or 0) + (inst._qwei[2] == 1 and 1 or 0) + (inst._qwei[3] == 1 and 1 or 0)
            owner.components.health:DoDelta(q * q * HEAL_MULT)
        end
    end
end

local function reticule_target_function(inst)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
end

local function getDamage(inst, attacker, target)
    local e = 0 + (inst._qwei[1] == 3 and 1 or 0) + (inst._qwei[2] == 3 and 1 or 0) + (inst._qwei[3] == 3 and 1 or 0)
    return BASE_DAMAGE + (e * e * DAMAGE_MULT)
end

local function onattack(weapon, attacker, target)
    attacker.AnimState:OverrideSymbol("book_closed", "swap_book_invoker", "book_closed")
    attacker.AnimState:Hide("ARM_carry")
    if attacker and attacker.components.debuffable then
        attacker.components.debuffable:RemoveDebuff("chasni_invis")
    end
end

local function DoFail(inst, owner)
    if owner.components.talker then
        owner.components.talker:Say(GetString(owner, "FAIL_VOKER"))
    end
    inst.components.finiteuses:Use(FAIL_USE)
end

local function DoColdSnap(inst, target, owner)
    if owner and target and target.components.freezable then
        owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/coldsnap", nil, 0.1)

        target.components.freezable:AddColdness(100, 12)
        return
    end
    DoFail(inst, owner)
end

local function DoGhostWalk(inst, owner)
    if owner and owner.components.debuffable then
        owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/ghostwalk", nil, 0.3)

        owner.components.debuffable:RemoveDebuff("chasni_invis")
        owner.components.debuffable:AddDebuff("chasni_invis", "chasni_invis")
        return
    end
    DoFail(inst, owner)
end

local function DoIceWall(inst, position, target, owner)
    if owner and position or target then
        owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/icewall", nil, 0.3)

        local px, py, pz = chasni_getPos(position, target)
        chasni_spawnprefab("voker_icewall", px, py, pz)
        return
    end
    DoFail(inst, owner)
end

local function DoTornado(inst, position, target, owner)
    if owner and (position or target) and target ~= owner then
        owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/tornado", nil, 0.3)

        local x, _, z = owner.Transform:GetWorldPosition()
        local px, _, pz = chasni_getPos(position, target)
        local rad = math.rad(inst:GetAngleToPoint(px, 0, pz))
        local tornado = chasni_spawnprefab("voker_tornado", x, _, z)
        tornado.velx = math.cos(rad)
        tornado.velz = -math.sin(rad)
        return
    end
    DoFail(inst, owner)
end

local SKILL_CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "injoker" }
local DISARM_TIME = 7
local function sparktask(inst)
    SpawnPrefab("electricchargedfx"):SetTarget(inst)
end
local function DoDeafening(inst, owner)
    if owner then
        owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/deafening", nil, 0.3)

        local x, _, z = owner.Transform:GetWorldPosition()
        chasni_spawnprefab("whitefx_ring", x, 0, z)
        local ents = TheSim:FindEntities(x, 0, z, 12, nil, SKILL_CANT_TAGS)
        for _, ent in pairs(ents) do
            if ent and ent ~= inst and ent.components.combat then
                ent.components.combat:BlankOutAttacks(DISARM_TIME)
                if not ent._sparktask then
                    ent._sparktask = ent:DoPeriodicTask(1.5, sparktask)
                end
                if ent._sparktaskender then
                    ent._sparktaskender:Cancel()
                    ent._sparktaskender = nil
                end
                ent._sparktaskender = ent:DoTaskInTime(DISARM_TIME, function(i)
                    if i._sparktask then
                        i._sparktask:Cancel()
                        i._sparktask = nil
                    end
                end)
            end
        end
        return
    end
    DoFail(inst, owner)
end

local function DoForgeSpirit(inst, position, target, owner)
    if owner then
        owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/forgespirit", nil, 0.3)

        local px, py, pz = chasni_getPos(position, target)
        chasni_spawnprefab("voker_forgespirit", px, py, pz)
        return
    end
    DoFail(inst, owner)
end

local PANIC_TIME = 5
local function DoEMP(inst, position, target, owner)
    if owner then
        owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/emp", nil, 0.3)

        local px, py, pz = chasni_getPos(position, target)
        local emp = chasni_spawnprefab("purplefx_ring", px, py, pz)
        emp.Transform:SetScale(0.8, 0.8, 0.8)
        local ents = TheSim:FindEntities(px, 0, pz, 6, nil, SKILL_CANT_TAGS)
        local paniccount = 0
        for _, ent in pairs(ents) do
            if ent and ent ~= inst and ent.components.hauntable and ent.components.hauntable.panicable then
                ent.components.hauntable:Panic(PANIC_TIME)
                paniccount = paniccount + 1
            end
        end
        if owner.components.sanity then
            owner.components.sanity:DoDelta(paniccount * 5)
        end
        return
    end
    DoFail(inst, owner)
end

local function DoAlacrity(inst, target, owner)
    if owner and target and target.components.debuffable then
        owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/alacrity", nil, 0.3)

        target.components.debuffable:RemoveDebuff("voker_alacrity")
        local fx = target.components.debuffable:AddDebuff("voker_alacrity", "voker_alacrity")
        fx.Transform:SetPosition(0, 2.5, 0)
        return
    end
    DoFail(inst, owner)
end

local function DoMeteor(inst, position, target, owner)
    if owner and position or target then
        --owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/meteor", nil, 0.3)

        local px, py, pz = chasni_getPos(position, target)
        chasni_spawnprefab("shadowmeteor", px, py, pz)
        return
    end
    DoFail(inst, owner)
end

local SUNSTRIKE_DAMAGE = 150
local function DoSunStrike(inst, position, target, owner)
    if owner and position or target then
        owner.SoundEmitter:PlaySound("chasjoker/chasni_invoker/sunstrike", nil, 0.3)

        local px, py, pz = chasni_getPos(position, target)
        local sunstrike = chasni_spawnprefab("deer_yellow_circle", px, py, pz)
        sunstrike.voker = owner
        sunstrike.vokerdamage = SUNSTRIKE_DAMAGE
        return
    end
    DoFail(inst, owner)
end

local function DoVokerSpell(inst, target, position)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner == nil then
        return
    end

    local spellname = chasni_getinvokerspellname(inst._qwei)
    if spellname == "QQQ" then DoColdSnap(inst, target, owner)
    elseif spellname == "QQW" then DoGhostWalk(inst, owner)
    elseif spellname == "QQE" then DoIceWall(inst, position, target, owner)
    elseif spellname == "QWW" then DoTornado(inst, position, target, owner)
    elseif spellname == "QWE" then DoDeafening(inst, owner)
    elseif spellname == "QEE" then DoForgeSpirit(inst, position, target, owner)
    elseif spellname == "WWW" then DoEMP(inst, position, target, owner)
    elseif spellname == "WWE" then DoAlacrity(inst, target, owner)
    elseif spellname == "WEE" then DoMeteor(inst, position, target, owner)
    elseif spellname == "EEE" then DoSunStrike(inst, position, target, owner)
    else DoFail(inst, owner) end
    if inst._prevspell and inst._prevspell == spellname then
        inst.components.finiteuses:Use(HUGE_FAIL_USE)
    end
    inst._prevspell = spellname
end

local function perusefn(inst,reader)
    if reader.peruse_web then
        reader.peruse_web(reader)
    end
    reader.components.talker:Say(GetString(reader, "ANNOUNCE_READ_BOOK","BOOK_LIGHT_UPGRADED"))
    return true
end

local book_defs =
{
    {
        name = "book_voker",
        animbuild = "book_voker",
        animbank = "book_voker",
        animplay = "idle",
        swapprefix = "book",
        invename = "book_voker",
        uses = 50,
        read_sanity = 0,
        peruse_sanity = 0,
        deps = { "groundlight_fx" },
        tag = "book_voker",
        onequipfn = function(inst, owner)
            inst._qwe = { spawnball(0), spawnball(2), spawnball(4) }
            inst._qwei = { 0,0,0 }
            inst._qweid = 1
            if inst._rotatingtask == nil then
                inst._rotatingtask = inst:DoPeriodicTask(FRAMES, rotateball)
            end
            if inst._healtask == nil then
                inst._healtask = inst:DoPeriodicTask(1, healtask)
            end
            owner:AddTag("injoker")
        end,
        onunequipfn = function(inst, owner)
            stopball(inst)
            if owner and owner.components.debuffable then
                owner.components.debuffable:RemoveDebuff("chasni_invis")
            end
            if inst._healtask == nil then
                inst._healtask:Cancel()
                inst._healtask = nil
            end
            owner:RemoveTag("injoker")
        end,
        fn = function(inst, reader)
            DoVokerSpell(inst, reader)
            return true
        end,
        perusefn = function(inst,reader) perusefn(inst,reader) end,
    },
}

local function MakeBook(def)
    local prefabs
    if def.deps then
        prefabs = {}
        for i, v in ipairs(def.deps) do
            table.insert(prefabs, v)
        end
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", nil, 0.75)

        inst.AnimState:SetBank(def.animbank)
        inst.AnimState:SetBuild(def.animbuild)
        inst.AnimState:PlayAnimation(def.animplay)

        inst:AddTag("book")
        inst:AddTag("bookcabinet_item")
        if def.tag then
            inst:AddTag(def.tag)
            inst:AddTag("allow_action_on_impassable")

            inst:AddComponent("reticule")
            inst.components.reticule.targetfn = reticule_target_function
            inst.components.reticule.ease = true
            inst.components.reticule.ispassableatallpoints = true
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        -----------------------------------

        inst.def = def
        inst.swap_build = "swap_"..def.animbuild
        inst.swap_prefix = def.swapprefix

        inst:AddComponent("inspectable")
        inst:AddComponent("book")
        inst.components.book:SetOnRead(def.fn)
        inst.components.book:SetOnPeruse(def.perusefn or perusefn)
        inst.components.book:SetReadSanity(def.read_sanity)
        inst.components.book:SetPeruseSanity(def.peruse_sanity)
        inst.components.book:SetFx(def.fx, def.fxmount)

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = def.invename
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..def.invename..".xml"

        if def.onequipfn then
            inst:AddComponent("weapon")
            inst.components.weapon:SetDamage(getDamage)
            inst.components.weapon:SetOnAttack(onattack)
            inst.components.weapon.attackwear = 0 -- >>>> might not have finiteuses

            inst:AddComponent("equippable")
            inst.components.equippable.restrictedtag = "reader"
            inst.components.equippable:SetOnEquip(def.onequipfn)
            inst.components.equippable:SetOnUnequip(def.onunequipfn)

            inst:AddComponent("shadowlevel")
            inst.components.shadowlevel:SetDefaultLevel(4)

            inst:AddComponent("spellcaster")
            inst.components.spellcaster.canuseonpoint_water = true
            inst.components.spellcaster.canuseonpoint = true
            inst.components.spellcaster.canuseontargets = true
            inst.components.spellcaster:SetCanCastFn(function() return true end)
            inst.components.spellcaster:SetSpellFn(function(inst, target, position)
                DoVokerSpell(inst, target, position)
                local owner = inst.components.inventoryitem:GetGrandOwner()
                if owner then
                    owner:PushEvent("chasni_readbook", { book = inst, success = true }) -- >>>> not actually always success. but we dont care
                end
            end)
        end

        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(def.uses)
        inst.components.finiteuses:SetUses(def.uses)
        inst.components.finiteuses:SetOnFinished(inst.Remove)

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.MED_FUEL

        MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab("chasni_"..def.name, fn, assets[def.animbuild], prefabs)
end

local ret = { }
for i, v in ipairs(book_defs) do
    table.insert(ret, MakeBook(v))
end
book_defs = nil
return unpack(ret)
