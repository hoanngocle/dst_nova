local function OnAttached(inst, target)
    if target and (target.components.health == nil or not target.components.health:IsDead()) and not target:HasTag("playerghost") then
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0)

        inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
    else
        inst.components.debuff:Stop()
    end
end

local function OnDetached(inst, target)
    inst:Remove()
end

local function CreateFX(fx, isback, isground)
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")

    inst.persists = false
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBank(fx.bank)
    inst.AnimState:SetBuild(fx.build)
    if fx.animpre then
        inst.AnimState:PlayAnimation(fx.animpre)
        if fx.anim then
            inst.AnimState:PushAnimation(fx.anim, true)
        end
    elseif fx.anim then
        inst.AnimState:PlayAnimation(fx.anim, true)
    end
    if fx.multcolor then
        inst.AnimState:SetMultColour(unpack(fx.multcolor))
    end
    if isback then
        inst.AnimState:SetSortOrder(-1)
    end
    if isground then
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
    end
    if fx.isrotating then
        local function StartRotating(_inst, speed)
            speed = speed or 90

            _inst._rot = 0

            _inst:DoPeriodicTask(FRAMES, function()
                if _inst:IsValid() then
                    _inst._rot = _inst._rot + speed * FRAMES
                    _inst.Transform:SetRotation(_inst._rot)
                end
            end)
        end
        StartRotating(inst, 45)
    end

    inst._fx = fx
    inst.Transform:SetPosition(fx.x or 0, fx.y or 0, 0)
    if fx.scale then
        inst.Transform:SetScale(fx.scale, fx.scale, fx.scale)
    end

    if fx.tick then
        inst:DoPeriodicTask(fx.tick, function()
            inst.AnimState:PlayAnimation(fx.animtick)
            inst.AnimState:PushAnimation(fx.anim)
        end)
    end

    return inst
end

local function SpawnPostFX(parent, fxdata)
    if not fxdata or not fxdata.animpst then return end
    local postfx = CreateFX(fxdata)   -- reuse your CreateFX
    postfx.AnimState:PlayAnimation(fxdata.animpst)
    postfx:ListenForEvent("animqueueover", function() postfx:Remove() end)
    local x,y,z = parent.Transform:GetWorldPosition()
    postfx.Transform:SetPosition(x+(fxdata.x or 0), y+(fxdata.y or 0), z)
end

local function InitFX(inst, frontfx, backfx, groundfx)
    inst._inittask = nil

    if not TheNet:IsDedicated() then
        if frontfx then
            inst._frontfx = CreateFX(frontfx)
            inst._frontfx.entity:SetParent(inst.entity)
        end
        if backfx then
            inst._backfx = CreateFX(backfx, true, false)
            inst._backfx.entity:SetParent(inst.entity)
        end
        if groundfx then
            inst._groundfx = CreateFX(groundfx, false, true)
            inst._groundfx.entity:SetParent(inst.entity)
        end

        inst:ListenForEvent("onremove", function()
            local target = inst.components.debuff and inst.components.debuff.inst
            if target then
                SpawnPostFX(target, frontfx)
                SpawnPostFX(target, backfx)
                SpawnPostFX(target, groundfx)
            else
                SpawnPostFX(inst, frontfx)
                SpawnPostFX(inst, backfx)
                SpawnPostFX(inst, groundfx)
            end
        end)
    end
end
local function makeBuff(name, frontfx, backfx, groundfx)
    local assets = {}
    if frontfx then
        table.insert(assets, Asset("ANIM", "anim/".. frontfx.build ..".zip"))
    end
    if backfx then
        table.insert(assets, Asset("ANIM", "anim/".. backfx.build ..".zip"))
    end
    if groundfx then
        table.insert(assets, Asset("ANIM", "anim/".. groundfx.build ..".zip"))
    end
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst:AddTag("CLASSIFIED")

        inst._inittask = inst:DoTaskInTime(0, function(_inst)
            InitFX(_inst, frontfx, backfx, groundfx)
        end)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)

        inst.components.debuff.keepondespawn = false

        inst.persists = true
        return inst
    end

    return Prefab(name, fn, assets)
end

local lunargroundfx = {
    bank = "lunar_shadowfx", build = "lunar_shadow_books_fxs", anim = "lunar_ground",
}
local gearfrontfx = {
    bank = "productive_fx", build = "productive_fx", animpre = "productive_pre", anim = "productive_loop", animpst = "productive_pst", scale = 2, y = 0.01,
    tick = 60, animtick = "productive_achievement"
}
local lifestealgroundfx = {
    bank = "chasni_back_gas_fx", build = "chasni_back_gas_fx", anim = "RockGas", multcolor = {1,1,1,0.5}, isrotating = true
}
local reflectgroundfx = {
    bank = "chasni_back_gas_fx", build = "chasni_back_gas_fx", anim = "ContaminatedOxygen", multcolor = {1,1,1,0.5}, isrotating = true
}
local critfrontfx = {
    bank = "chasni_rush_buff_fx", build = "chasni_rush_buff_fx", anim = "fx_loop", scale = 2
}
local incapacitatedfrontfx = {
    bank = "anim_incapacitated", build = "anim_incapacitated", anim = "incapacitate_loop", scale = 1.5, y = 2
}
local sporefrontfx = {
    bank = "spore_fx", build = "spore_fx", anim = "working_loop", scale = 2.5, y = 0.7
}
local healedfrontfx = {
    bank = "recently_healed_fx", build = "recently_healed_fx", anim = "upgrade", scale = 2, y = 0.01
}
local mistfx = {
    bank = "water_mist", build = "water_mist", anim = "loop", animpst = "end", scale = 1.5, y = 1.3, multcolor = {1,1,1,0.3}
}
local elecbuff = {
    bank = "elec_charged_fx", build = "elec_charged_fx", anim = "-", tick = 2, animpre = "discharged", animtick = "discharged"
}
local hologramfrontfx = {
    bank = "hologram", build = "hologram", anim = "hologram_group_bloom", scale = 1.5, y = 1.5
}
local hologramgroundfx = {
    bank = "hologram", build = "hologram", anim = "hologram_group_bloom", scale = 2
}
local greengasfx = {
    bank = "plant_spray_impact_fx", build = "plant_spray_impact_fx", anim = "loop", scale = 1.5, y = 1.5
}
local snoregroundfx = {
    bank = "chasni_snore_fx", build = "chasni_snore_fx", anim = "-", animpre = "snore", scale = 1,
    tick = 3, animtick = "snore"
}

return
-- banner_repair
makeBuff("super_critter_buff", nil, nil, lunargroundfx),
-- banner_repair
makeBuff("gear_buff", gearfrontfx),
--chasni_critter_mosq
makeBuff("critter_mosq_buff", nil, nil, lifestealgroundfx),
--chasni_critter_raptor
makeBuff("critter_raptor_buff", critfrontfx),
--chasni_critter_seal
makeBuff("critter_seal_buff", mistfx),
--chasni_critter_stego
makeBuff("critter_stego_buff", nil, nil, reflectgroundfx),
--chasni_critter_elecfish
makeBuff("critter_elecfish_buff", elecbuff),
--chasni_critter_turtle
makeBuff("critter_turtle_buff", hologramfrontfx),
makeBuff("critter_turtle_buff_self", nil, nil, hologramgroundfx),
--chasni_didgerizoo
makeBuff("chasni_didgerizoo_buff", nil, nil, snoregroundfx),


makeBuff("incapacitated_buff", incapacitatedfrontfx),
makeBuff("spore_buff", sporefrontfx),
    makeBuff("healed_buff", healedfrontfx), -->>>> need animover detach
makeBuff("greengas_buff", greengasfx)
