local assets =
{
    Asset("ANIM", "anim/bramblefx.zip"),
}

local assets_ring =
{
    Asset("ANIM", "anim/bearger_ring_fx.zip"),
}

local MAXRANGE = 3
local DAMAGE = chasni_getitemconfig("bramblechest", "DMG") or 51 -- damage from bramble tower on its own file
local NO_TAGS = { "bramble_resistant", "INLIMBO", "notarget", "noattack", "invisible", "playerghost" }
local COMBAT_TARGET_TAGS = { "_combat" }

local function OnUpdateThorns(inst)
    inst.range = inst.range + .75
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, inst.range + 3, COMBAT_TARGET_TAGS, NO_TAGS)) do
        if not inst.ignore[v] and v:IsValid() and v.entity:IsVisible() and v.components.combat and not (v.components.inventory and v.components.inventory:EquipHasTag("bramble_resistant")) and not (chasni_hastag2(v, "expertworm1")) then
            local range = inst.range + v:GetPhysicsRadius(0)
            if v:GetDistanceSqToPoint(x, y, z) < range * range then
                if inst.owner and not inst.owner:IsValid() then
                    inst.owner = nil
                end
                if inst.owner then
                    if inst.owner.components.combat and inst.owner.components.combat:CanTarget(v) then
                        inst.ignore[v] = true
                        v.components.combat:GetAttacked(v.components.follower and v.components.follower:GetLeader() == inst.owner and inst or inst.owner, inst.damage)
                        if inst.knockback then
                            v:PushEvent("knockback", { knocker = inst, radius = 5 })
                        end
                    end
                elseif v.components.combat:CanBeAttacked() then
                    inst.ignore[v] = true
                    v.components.combat:GetAttacked(inst, inst.damage)
                    if inst.knockback then
                        v:PushEvent("knockback", { knocker = inst, radius = 5 })
                    end
                end
            end
        end
    end
    if inst.range >= MAXRANGE then
        inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateThorns)
    end
end

local function MakeFX(name)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:AddTag("FX")
        inst:AddTag("thorny")
        inst.Transform:SetFourFaced()

        inst.AnimState:SetBank("bramblefx")
        inst.AnimState:SetBuild("bramblefx")
        inst.AnimState:PlayAnimation("idle")
        inst:SetPrefabNameOverride("bramblefx")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("updatelooper")
        inst.components.updatelooper:AddOnUpdateFn(OnUpdateThorns)

        inst:ListenForEvent("animover", inst.Remove)
        inst.persists = false
        inst.damage = DAMAGE
        inst.knockback = false
        inst.range = .75
        inst.ignore = {}

        return inst
    end

    return Prefab(name, fn, assets)
end

local function MakeFXRing(name)
    local function PlayRingAnim(proxy)
        local inst = CreateEntity()
        inst:AddTag("FX")
        inst.entity:SetCanSleep(false)
        inst.persists = false

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst.Transform:SetFromProxy(proxy.GUID)

        inst.AnimState:SetBank("bearger_ring_fx")
        inst.AnimState:SetBuild("bearger_ring_fx")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetFinalOffset(3)

        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetMultColour(127/255, 255/255, 193/255, 1)

        inst:ListenForEvent("animover", inst.Remove)
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("FX")

        if not TheNet:IsDedicated() then
            inst:DoTaskInTime(0, PlayRingAnim)
        end
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false
        inst:DoTaskInTime(3, inst.Remove)
        return inst
    end

    return Prefab(name, fn, assets_ring)
end

return 
MakeFX("bramblefx_new"), 
MakeFXRing("bramblefx_ring")
