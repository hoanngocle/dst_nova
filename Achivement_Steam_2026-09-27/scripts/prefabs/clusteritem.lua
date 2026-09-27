local Clusters = {}

local function MakeCluster(item)
    local function OnBuild(inst, data)
        inst.components.clustercraftbuild:BuildCluster(inst, data.builder)
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("clustercraftbuild")
        inst.components.clustercraftbuild:InitCondition(item.prefab or item.name, item.seed or "dug_".. item.name, 3, item.spacing)

        inst:ListenForEvent("onbuilt", OnBuild)
        inst.persists = false

        return inst
    end

    local function placer_postinit_fn(inst)
        local xstart, xend = -(3/2 - 0.5), (3/2 - 0.5)
        local zstart, zend = -(3/2 - 0.5), (3/2 - 0.5)
        local spawn_pts= {}
        for kz = zstart, zend, 1 do
            for kx = xstart, xend, 1 do
                table.insert(spawn_pts, { x = ((kx * item.spacing) + kx), y = 0, z = ((kz * item.spacing) + kz) })
            end
        end
        for _, v in pairs(spawn_pts) do
            if v.x ~= 0 or v.z ~= 0 then
                local placer2 = CreateEntity()

                placer2.entity:SetCanSleep(false)
                placer2.persists = false

                placer2.entity:AddTransform()
                placer2.entity:AddAnimState()

                placer2:AddTag("CLASSIFIED")
                placer2:AddTag("NOCLICK")
                placer2:AddTag("placer")

                placer2.AnimState:SetBank(item.bank or item.name)
                placer2.AnimState:SetBuild(item.build or item.name)
                placer2.AnimState:PlayAnimation(item.anim or "idle")
                placer2.AnimState:SetLightOverride(1)

                placer2.entity:SetParent(inst.entity)
                placer2.Transform:SetPosition(v.x, v.y, v.z)

                inst.components.placer:LinkEntity(placer2)
            end
        end
    end
    table.insert(Clusters, Prefab(item.name.."_cluster_cz", fn))
    table.insert(Clusters, MakePlacer(item.name.."_cluster_cz_placer", item.bank or item.name, item.build or item.name, item.anim or "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, 8))
end

local clusteritem =
{
    {
        name = "berrybush",
        anim = "dead",
        spacing = 1,
    },
    {
        name = "berrybush2",
        anim = "dead",
        spacing = 1,
    },
    {
        name = "berrybush_juicy",
        anim = "dead",
        spacing = 1,
    },
    {
        name = "sapling",
        spacing = 0,
    },
    {
        name = "sapling_moon",
        spacing = 0,
    },
    {
        name = "marsh_bush",
        spacing = 0,
    },
    {
        name = "grass",
        build = "grass1",
        spacing = 0,
    },
    {
        name = "monkeytail",
        bank = "grass",
        build = "reeds_monkeytails",
        spacing = 0,
    },
    {
        name = "rock_avocado_bush",
        bank = "rock_avocado",
        build = "rock_avocado_build",
        anim = "dead1",
        spacing = 1,
    },
    {
        name = "bananabush",
        anim = "dead",
        spacing = 1,
    },
    {
        name = "butterfly",
        bank = "flowers",
        build = "flowers",
        anim = "f1",
        seed = "butterfly",
        spacing = 0.5,
    },
    {
        name = "moonbutterfly",
        bank = "baby_moon_tree",
        build = "baby_moon_tree",
        seed = "moonbutterfly",
        spacing = 2.5,
    },
    {
        name = "pinecone",
        anim = "idle_planted",
        prefab = "pinecone_sapling",
        seed = "pinecone",
        spacing = 1,
    },
    {
        name = "twiggy_nut",
        anim = "idle_planted",
        prefab = "twiggy_nut_sapling",
        seed = "twiggy_nut",
        spacing = 1,
    },
    {
        name = "acorn",
        anim = "idle_planted",
        prefab = "acorn_sapling",
        seed = "acorn",
        spacing = 1,
    },
    {
        name = "marblebean",
        anim = "idle_planted",
        prefab = "marblebean_sapling",
        seed = "marblebean",
        spacing = 1,
    },
    {
        name = "livingtree_root",
        bank = "livingtree_root",
        build = "livingtree_root",
        anim = "placer",
        seed = "livingtree_root",
        spacing = 1,
    },
    {
        name = "beemine",
        bank = "bee_mine",
        build = "bee_mine",
        seed = "beemine",
        spacing = 0,
    },
    {
        name = "trap_bramble",
        seed = "trap_bramble",
        spacing = 0,
    },
    {
        name = "trap_teeth",
        seed = "trap_teeth",
        spacing = 0,
    },
    {
        name = "trap_starfish",
        bank = "star_trap",
        build = "star_trap",
        anim = "trap_idle",
        spacing = 1,
    },
    {
        name = "trap_flytrap",
        bank = "pakun",
        build = "pakun",
        anim = "trap_idle",
        spacing = 1,
    },
}

for _, v in ipairs(clusteritem) do
    MakeCluster(v)
end

return unpack(Clusters)