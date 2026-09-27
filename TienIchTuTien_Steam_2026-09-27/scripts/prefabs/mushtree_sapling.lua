local asporen_assets =
{
    Asset("ATLAS", "images/inventoryimages/asporen.xml"),
    Asset("IMAGE", "images/inventoryimages/asporen.tex"),
    Asset("ANIM", "anim/asporen.zip")
}

local asporen_prefabs =
{
    "asporen",
    "mushtree_small",
    "mushtree_medium",
    "mushtree_tall"
}

local ASPOREN_GROWTIME = {base=TUNING.TOTAL_DAY_TIME*4, random=TUNING.TOTAL_DAY_TIME}

local function mushtreeGetSize()
    if TheWorld:HasTag("cave") then
        if TheWorld.state.iscaveday then
            return "mushtree_medium" -- Red Mushtree
        elseif TheWorld.state.iscavenight then
            return "mushtree_tall" -- Blue Mushtree
        else -- TheWorld.state.iscavedusk
            return "mushtree_small" -- Green Mushtree
        end
    else
        if TheWorld.state.isday then
            return "mushtree_medium" -- Red Mushtree
        elseif TheWorld.state.isnight then
            return "mushtree_tall" -- Blue Mushtree
        else -- TheWorld.state.isdusk
            return "mushtree_small" -- Green Mushtree
        end
    end
end

local function growtree(inst)
    local tree = SpawnPrefab(inst.growprefab)
    if tree then
        tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        --tree:growfromseed()
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
        inst:Remove()
    end
end

local function stopgrowing(inst)
    inst.components.timer:StopTimer("grow")
end

local function startgrowing(inst)
    if not inst.components.timer:TimerExists("grow") then
        local growtime = GetRandomWithVariance(ASPOREN_GROWTIME.base, ASPOREN_GROWTIME.random)
        inst.components.timer:StartTimer("grow", growtime)
    end
end

local function ontimerdone(inst, data)
    if data.name == "grow" then
        growtree(inst)
    end
end

local function digup(inst, digger)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function sapling_fn(bank, build, anim, growprefabfn, tag, fireproof, overrideloot)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)

        inst:AddTag(tag)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.growprefab = growprefabfn()
        inst.StartGrowing = startgrowing

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", ontimerdone)
        startgrowing(inst)

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(overrideloot or {"twigs"})

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnFinishCallback(digup)
        inst.components.workable:SetWorkLeft(1)

        if not fireproof then
            MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
            inst:ListenForEvent("onignite", stopgrowing)
            inst:ListenForEvent("onextinguish", startgrowing)
            MakeSmallPropagator(inst)

            MakeHauntableIgnite(inst)
        else
            MakeHauntableWork(inst)
        end

        return inst
    end
    return fn
end

STRINGS.NAMES.MUSHTREE_SAPLING = "Mushtree Sapling"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUSHTREE_SAPLING = "It's a sapling covered in fungus, gross." 

--inst.AnimState:PlayAnimation("idle_planted")
return Prefab("mushtree_sapling", sapling_fn("pinecone", "asporen", "idle_planted", mushtreeGetSize, "mushtree", false, {"asporen"}), asporen_assets, asporen_prefabs)
