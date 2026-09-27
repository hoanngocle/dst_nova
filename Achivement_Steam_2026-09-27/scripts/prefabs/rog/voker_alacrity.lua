local BONUS_DAMAGE = chasni_getitemconfig("book_voker", "AL_DMG") or 20
local DURATION = chasni_getitemconfig("book_voker", "AL_DUR") or 120
local function OnAttached(inst, target)
    if not target.components.health:IsDead() and not target:HasTag("playerghost") then
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0)
        if target.components.planardamage then
            target.components.planardamage:AddBonus(target, BONUS_DAMAGE, "alacrity")
        end
        inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
    else
        inst.components.debuff:Stop()
    end
end

local function OnDetached(inst, target)
    if target.components.planardamage then
        target.components.planardamage:RemoveBonus(target, "alacrity")
    end
    inst:Remove()
end

local function OnTimerDone(inst, data)
    if data.name == "decay" then
        inst.components.debuff:Stop()
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")

    inst.Transform:SetScale(0.5, 0.5, 0.5)
    inst.AnimState:SetBank("brilliance_projectile_fx")
    inst.AnimState:SetBuild("brilliance_projectile_fx")
    inst.AnimState:PlayAnimation("blast1")
    inst.AnimState:SetSymbolMultColour("light_bar", 1, 0.4, 1, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(.5)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff.keepondespawn = false

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("decay", DURATION)
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst:ListenForEvent("animover", function(inst, data)
        if math.random() < 0.5 then
            inst.AnimState:PlayAnimation("blast2")
        else
            inst.AnimState:PlayAnimation("blast1")
        end
    end)

    inst.persists = false

    return inst
end

return Prefab("voker_alacrity", fn)
