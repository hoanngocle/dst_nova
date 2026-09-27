local POOP_DURATION = 3
local function OnAttached(inst, target)
    if not target.components.health:IsDead() and not target:HasTag("playerghost") then
        inst.entity:SetParent(target.entity)
        inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
        inst:ListenForEvent("chasni_blocked", function() 
            inst.AnimState:PlayAnimation("hit")
            inst.AnimState:PushAnimation("idle_loop", true)
        end, target)
    else
        inst.components.debuff:Stop()
    end
end

local function OnDetached(inst, target)
    inst:kill_fx()
end

local function OnTimerDone(inst, data)
    if data.name == "decay" then
        inst.components.debuff:Stop()
    end
end

local function kill_fx(inst)
    inst.AnimState:PlayAnimation("close")
    inst:DoTaskInTime(.6, inst.Remove)
end

local function MakeShield(name, duration, bank, data)
    local assets =
    {
        Asset("ANIM", "anim/"..bank..".zip" or "anim/forcefield.zip"),
    }
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.entity:AddSoundEmitter()

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst:AddTag("CLASSIFIED")

        inst.AnimState:SetBank(bank or "forcefield")
        inst.AnimState:SetBuild(bank or "forcefield")
        inst.AnimState:PlayAnimation("open")
        inst.AnimState:PushAnimation("idle_loop", true)
        if data and data.rgb then
            inst.AnimState:SetMultColour(data.rgb.r, data.rgb.g, data.rgb.b, data.rgb.a)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff.keepondespawn = false

        inst:AddComponent("timer")
        if duration then
            inst.components.timer:StartTimer("decay", duration)
        end

        inst:ListenForEvent("timerdone", OnTimerDone)
        inst.kill_fx = kill_fx
        inst.persists = false

        return inst
    end

    return Prefab(name, fn, assets)
end

return
MakeShield("wormwood_poop_shield_buff", POOP_DURATION, "forcefieldegg"),
MakeShield("hulkhat_shield_buff", nil, "forcefieldartifact"),
MakeShield("chasni_critter_crab_shield_buff", nil, "forcefieldlunar", {rgb = {r = 0, g = 0.4, b = 1, a = 1}})