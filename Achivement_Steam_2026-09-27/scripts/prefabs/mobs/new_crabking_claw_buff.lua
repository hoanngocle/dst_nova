local assets =
{
    fire = { Asset("ANIM", "anim/ckc_firedebuff.zip"), },
    ice = { Asset("ANIM", "anim/ckc_icedebuff.zip"), },
    water = { Asset("ANIM", "anim/ckc_waterdebuff.zip"), },
    electric = { Asset("ANIM", "anim/ckc_electricdebuff.zip"), },
}
local FROSTBITTEN_DURATION = chasni_getmobconfig("chasni_ckc", "ICEDUR") or 60
local MAGMASPLASH_DURATION = chasni_getmobconfig("chasni_ckc", "FIRDUR") or 5
local MAGMASPLASH_DAMAGE   = chasni_getmobconfig("chasni_ckc", "FIRDMG") or 200

local function OnAttached(inst, target)
    inst._target = target
    if target and not target:HasTag("playerghost") then
        inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDetached(inst)
    inst:Remove()
end

---- FN
local CANT_TAGS = { "FX", "INLIMBO", "notarget", "noattack", "invisible" }
local function firetick(target)
    chasni_spawnprefab("lavaarena_meteor_splashbase", 0, 0, 0, 1.2, 1.2, 1.2, target.entity)
    local x, y, z = target.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 6, nil, CANT_TAGS, {"player", "crabking_claw_ice"})
    for _, v in ipairs(ents) do
        if v ~= target and v.components.health and not v.components.health:IsDead() then
            if v.components.burnable then
                v.components.burnable:Ignite(true, target)
            end
            v.components.combat:GetAttacked(target, MAGMASPLASH_DAMAGE)
        end
    end
end
local function OnActiveFire(inst)
    local target = inst._target
    if target then
        firetick(target)
        if target._magmasplashtask then
            target._magmasplashtask:Cancel()
            target._magmasplashtask = nil
        end
        target._magmasplashtask = target:DoTaskInTime(MAGMASPLASH_DURATION, function()
            if target._magmasplashperiodictask then
                target._magmasplashperiodictask:Cancel()
                target._magmasplashperiodictask = nil
            end
        end)
        if target._magmasplashperiodictask == nil then
            target._magmasplashperiodictask = target:DoPeriodicTask(1.5, function()
                firetick(target)
            end)
        end
    end
    if inst and inst.components.debuff then
        inst.components.debuff:Stop()
    end
end
local icetick
local function iceinit(target)
    icetick(target)
    target:AddTag("frostbitten")
    if target._frostbittentask then
        target._frostbittentask:Cancel()
        target._frostbittentask = nil
    end
    target._frostbittentask = target:DoTaskInTime(FROSTBITTEN_DURATION, function()
        target:RemoveTag("frostbitten")
        chasni_spawnprefab("crab_king_icefx", 0, 0.3, 0, 0.7, 0.7, 0.7, target.entity)
        if target._frostbittenperiodictask then
            target._frostbittenperiodictask:Cancel()
            target._frostbittenperiodictask = nil
        end
    end)
    if target._frostbittenperiodictask == nil then
        target._frostbittenperiodictask = target:DoPeriodicTask(5, function()
            icetick(target)
        end)
    end
end
icetick = function(target)
    chasni_spawnprefab("crab_king_icefx", 0, 0.3, 0, 0.7, 0.7, 0.7, target.entity)
    local x, y, z = target.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 4, {"player"}, CANT_TAGS)
    for _, v in ipairs(ents) do
        if v ~= target and not v:HasTag("frostbitten") then
            iceinit(v)
        end
    end
end
local function OnActiveIce(inst)
    local target = inst._target
    if target then
        iceinit(target)
    end
    if inst and inst.components.debuff then
        inst.components.debuff:Stop()
    end
end
local function OnActiveWater(inst)
    local target = inst._target
    if target then
        chasni_spawnprefab("crab_king_waterspout", 0, 0.10, 0, 1.5, 1.5, 1.5, target.entity)
        for i = 1, 10 do
            local x, y, z = target.Transform:GetWorldPosition()
            local theta = (target.Transform:GetRotation() + (i * 36))* DEGREES
            local xoffs = 4.5 * math.sin(theta)
            local zoffs = 4.5 * math.cos(theta)
            x = x + xoffs
            z = z + zoffs
            chasni_spawnprefab("crab_king_waterspout", x, y, z)
        end
        local x, y, z = target.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 6, {"player"}, CANT_TAGS)
        for _, v in ipairs(ents) do
            if v.components.inventory then
                v.components.inventory:ForEachEquipment(function(item)
                    v.components.inventory:DropItem(item)
                    if item.Physics and item.Physics:IsActive() then
                        local ix, _, iz = item.Transform:GetWorldPosition()
                        item.Physics:Teleport(ix, .1, iz)
                        item.Physics:SetVel(math.random() * 10 - 5, 10, math.random() * 10 - 5)
                    end
                end)
            end
        end
        ents = TheSim:FindEntities(x, y, z, 6, {"crabking_claw_electric"}, CANT_TAGS)
        for _, v in ipairs(ents) do
            if v.components.health and not v.components.health:IsDead() then
                v:DoTaskInTime(0.1, function()
                    chasni_spawnprefab("shock_machines_fx", 0, 0.1, 0, 2, 2, 2, v.entity)
                    v:DoTaskInTime(1, function()
                        if v.components.health and not v.components.health:IsDead() then
                            v.components.health:Kill()
                        end
                    end)
                end)
            end
        end
    end
    if inst and inst.components.debuff then
        inst.components.debuff:Stop()
    end
end
local function OnActiveElectric(inst)
    local target = inst._target
    if target then
        TheWorld:PushEvent("chasni_ms_sendlightningstrike", target)
    end
    if inst and inst.components.debuff then
        inst.components.debuff:Stop()
    end
end
---- END

local function fn(activefn, bank, build, anim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation(anim)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND) -- for boat

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff.keepondespawn = false
    inst:DoPeriodicTask(0, function(i)
        if inst._target then
            inst.Transform:SetRotation(-inst._target.Transform:GetRotation())
        end
    end)

    inst.persists = false

    inst:ListenForEvent("animover", activefn)

    return inst
end

local function firefn() return fn(OnActiveFire, "ckc_firedebuff", "ckc_firedebuff", "loop") end
local function icefn() return fn(OnActiveIce, "ckc_icedebuff", "ckc_icedebuff", "loop") end
local function waterfn() return fn(OnActiveWater, "ckc_waterdebuff", "ckc_waterdebuff", "loop") end
local function electricfn() return fn(OnActiveElectric, "ckc_electricdebuff", "ckc_electricdebuff", "loop") end

return
Prefab("ckc_fire_debuff", firefn, assets.fire),
Prefab("ckc_ice_debuff", icefn, assets.ice),
Prefab("ckc_water_debuff", waterfn, assets.water),
Prefab("ckc_electric_debuff", electricfn, assets.electric)
