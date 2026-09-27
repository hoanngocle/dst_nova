local assets =
{
    Asset("ANIM", "anim/lunar_shadow_books_fxs.zip"),
}

local SHADOW_BONUS_DAMAGE = chasni_getitemconfig("book_shadow", "DMG") or 2
local LUNAR_BONUS_DAMAGE = chasni_getitemconfig("book_lunar", "DMG") or 0.2

local function OnAttackOther(inst, attacker, data)
    local target = data.target
    if attacker and target and attacker.components.health and not attacker.components.health:IsDead() and attacker.components.combat and target.components.health and target.components.health.currenthealth > 0 then
        if attacker.components.health:GetPercent() < 1 then
            local damage = (data.weapon and data.weapon.components.weapon:GetDamage(attacker, target)) or attacker.components.combat.defaultdamage
            attacker.components.health:DoDelta(damage / 10)
        end
    end
end

local function OnUpdateFade(inst)
    if inst.components.sanity then
        inst.components.sanity:SetPercent(0)
    end
end

local function OnAttachedShadow(inst, target)
    if not target.components.health:IsDead() and not target:HasTag("playerghost") then
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0)

        if target.components.combat then
            target.components.combat.externaldamagemultipliers:SetModifier("book_shadow", SHADOW_BONUS_DAMAGE)

            if target._crazytask == nil then
                target._crazytask = target:DoPeriodicTask(FRAMES, OnUpdateFade)
            end

            inst.OnAttackOther_fn = function(_attacker, _data) OnAttackOther(inst, _attacker, _data) end
            inst:ListenForEvent("onhitother", inst.OnAttackOther_fn, target)
        end
        inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
    else
        inst.components.debuff:Stop()
    end
end

local function OnDetachedShadow(inst, target)
    if target.components.combat then
        target.components.combat.externaldamagemultipliers:RemoveModifier("book_shadow")
        inst:RemoveEventCallback("onhitother", inst.OnAttackOther_fn, target)

        if target._crazytask then
            target._crazytask:Cancel()
            target._crazytask = nil
        end
    end
    inst:Remove()
end

local function OnAttachedLunar(inst, target)
    if not target.components.health:IsDead() and not target:HasTag("playerghost") then
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0)

        if target.components.combat then
            target.components.combat.externaldamagemultipliers:SetModifier("book_lunar", LUNAR_BONUS_DAMAGE)
        end

        inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
    else
        inst.components.debuff:Stop()
    end
end

local function OnDetachedLunar(inst, target)
    if target.components.combat then
        target.components.combat.externaldamagemultipliers:RemoveModifier("book_lunar")
    end
    inst:Remove()
end

local function CreateFrontFX(anim)
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")

    inst.persists = false
    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("lunar_shadowfx")
    inst.AnimState:SetBuild("lunar_shadow_books_fxs")

    if anim == "shadow_front" then
    else
        inst.Transform:SetPosition(0.05,0,0)
    end

    inst.AnimState:PlayAnimation(anim, true)
    return inst
end

local function CreateBackFX(anim)
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")

    inst.persists = false
    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("lunar_shadowfx")
    inst.AnimState:SetBuild("lunar_shadow_books_fxs")

    if anim == "shadow_back" then
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetFinalOffset(3)
    else
        inst.Transform:SetPosition(0,0.1,0)
    end

    inst.AnimState:PlayAnimation(anim, true)

    return inst
end

local function InitFXShadow(inst)
    inst._inittask = nil

    if not TheNet:IsDedicated() then
        inst._frontfx = CreateFrontFX("shadow_front")
        inst._frontfx.entity:SetParent(inst.entity)
        inst._backfx = CreateBackFX("shadow_back")
        inst._backfx.entity:SetParent(inst.entity)
    end
end

local function InitFXLunar(inst)
    inst._inittask = nil

    if not TheNet:IsDedicated() then
        inst._frontfx = CreateFrontFX("lunar_front")
        inst._frontfx.entity:SetParent(inst.entity)
        inst._backfx = CreateBackFX("lunar_back")
        inst._backfx.entity:SetParent(inst.entity)
    end
end

local function fn(attachfn, detachfn, FXfn)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")

    inst._inittask = inst:DoTaskInTime(0, FXfn)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(attachfn)
    inst.components.debuff:SetDetachedFn(detachfn)
    inst.components.debuff.keepondespawn = true

    inst.persists = true
    return inst
end

local function shadowfn()
    return fn(OnAttachedShadow, OnDetachedShadow, InitFXShadow)
end

local function lunarfn()
    return fn(OnAttachedLunar, OnDetachedLunar, InitFXLunar)
end

return 
Prefab("book_lunar_buff", lunarfn, assets), 
Prefab("book_shadow_buff", shadowfn, assets)
