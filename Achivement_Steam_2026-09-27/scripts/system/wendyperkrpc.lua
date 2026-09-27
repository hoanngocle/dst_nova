-- CC : set Wendy Sisturn UI button rpc >> [Reward] expertwendy3
local function Appear(target)
    target.sg:GoToState(target:HasTag("playerghost") and "appear" or "doshortaction")
    target:Show()
end

local function TeleEffect(target)
    SpawnPrefab("statue_transition_2").Transform:SetPosition(target.Transform:GetWorldPosition())
    SpawnPrefab("spawn_fx_medium").Transform:SetPosition(target.Transform:GetWorldPosition())
    if target.DynamicShadow then
        target.DynamicShadow:Enable(true)
    end
end

local function Teleport(target, sisturn)
    if sisturn then
        local teleport = sisturn:GetPosition()
        target.Transform:SetPosition(teleport.x, 0, teleport.z)
        target:SnapCamera()
        target:ScreenFade(true, 2)
        target:DoTaskInTime(1.8, TeleEffect)
    else
        target:SnapCamera()
        target:ScreenFade(true, 2)
        target:DoTaskInTime(1.8, TeleEffect)
    end
end

local function findSisturn(x, z, nearest)
    return TheWorld.components.sisturnregistry and TheWorld.components.sisturnregistry.FindSisturn(TheWorld.components.sisturnregistry, x, z, nearest) or nil
end

local function TeleportNear(target)
    local x, _, z = target.Transform:GetWorldPosition()
    local sisturn = findSisturn(x, z, true)
    Teleport(target, sisturn)
end

local function TeleportFar(target)
    local x, _, z = target.Transform:GetWorldPosition()
    local sisturn = findSisturn(x, z, false)
    Teleport(target, sisturn)
end

AddModRPCHandler("Wendy_Mod", "sisturn_button", function(inst)
    if TheWorld.components.sisturnregistry and TheWorld.components.sisturnregistry:IsActive() then
        inst:DoTaskInTime(0.1, function()
            inst:ScreenFade(false)
            inst:DoTaskInTime(3, Appear, inst)
            inst.sg:GoToState("forcetele")
            inst:Hide()
            inst:DoTaskInTime(1, TeleportNear)
        end)
    else
        inst.components.talker:Say(GetString(inst, "SISTURN_TELE_FAIL"))
    end
end)

AddModRPCHandler("Wendy_Mod", "sisturn_buttonfar", function(inst)
    if TheWorld.components.sisturnregistry and TheWorld.components.sisturnregistry:IsActive() then
        inst:DoTaskInTime(0.1, function()
            inst:ScreenFade(false)
            inst:DoTaskInTime(3, Appear, inst)
            inst.sg:GoToState("forcetele")
            inst:Hide()
            inst:DoTaskInTime(1, TeleportFar)
        end)
    else
        inst.components.talker:Say(GetString(inst, "SISTURN_TELE_FAIL"))
    end
end)