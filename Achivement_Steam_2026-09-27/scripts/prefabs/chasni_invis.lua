local function OnAttached(inst, target)
    if not target.components.health:IsDead() and not target:HasTag("playerghost") then
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0)
        target.AnimState:SetMultColour(0.5, 0.8, 1, 0.3)
        if target.components.locomotor then
            target.components.locomotor:SetExternalSpeedMultiplier(target, "ghostwalk", 1.5)
        end
        target:AddTag("debugnoattack")
        target:AddTag("notarget")
        target:AddTag("invisible")
        inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
    else
        inst.components.debuff:Stop()
    end
end

local function OnDetached(inst, target)
    target.AnimState:SetMultColour(1, 1, 1, 1)
    target:RemoveTag("debugnoattack")
    target:RemoveTag("notarget")
    target:RemoveTag("invisible")
    if target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, "ghostwalk")
    end
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:Hide()

    if not TheWorld.ismastersim then
        inst:DoTaskInTime(0, inst.Remove)
        return inst
    end

    inst.persists = false
    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff.keepondespawn = false

    return inst
end

return Prefab("chasni_invis", fn)
