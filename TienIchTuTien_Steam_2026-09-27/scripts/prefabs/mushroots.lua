
local function MakeMushroot(data)

    local rootassets = 
    {
        Asset("ATLAS", "images/inventoryimages/"..data.animname.."_mushroot.xml"),
        Asset("IMAGE", "images/inventoryimages/"..data.animname.."_mushroot.tex"),
		Asset("ANIM", "anim/mushroots.zip"),
    }

    local notags = {'NOBLOCK', 'player', 'FX'}
--[[
    local function test_ground(inst, pt)
        local tiletype = GetGroundTypeAtPosition(pt)
        local ground_OK = tiletype ~= GROUND.ROCKY and tiletype ~= GROUND.ROAD and tiletype ~= GROUND.IMPASSABLE and
                            tiletype ~= GROUND.UNDERROCK and tiletype ~= GROUND.WOODFLOOR and 
                            tiletype ~= GROUND.CARPET and tiletype ~= GROUND.CHECKER and tiletype < GROUND.UNDERGROUND
        
        if ground_OK then
            local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 4, nil, notags) -- or we could include a flag to the search?
            local min_spacing = inst.components.deployable.min_spacing or 2

            for k, v in pairs(ents) do
                if v ~= inst and v.entity:IsValid() and v.entity:IsVisible() and not v.components.placer and v.parent == nil then
                    if distsq( Vector3(v.Transform:GetWorldPosition()), pt) < min_spacing*min_spacing then
                        return false
                    end
                end
            end
            return true
        end
        return false
    end
]]

    local function OnDeploy(inst, pt, deployer) 
        local flower = SpawnPrefab(data.name)
        if flower then
            flower.Transform:SetPosition(pt.x, pt.y, pt.z)
            flower.SoundEmitter:PlaySound("dontstarve/common/mushroom_up")
            flower.components.pickable:OnTransplant()
            flower.rain = 20 + math.random(10)
            inst.components.stackable:Get():Remove()
        end
    end

    local function rootfn(Sim)
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        
        inst.AnimState:SetBank("mushrooms")
        inst.AnimState:SetBuild("mushroots")
        inst.AnimState:PlayAnimation(data.animname.."_cap")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("deployable")
		-- inst.components.deployable.test = test_ground
		inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        inst.components.deployable.ondeploy = OnDeploy
        inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)


        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")
        
        MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
        MakeSmallPropagator(inst)
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..data.animname.."_mushroot.xml"
        
        return inst
    end

    return Prefab( "common/inventory/"..data.animname.."_mushroot", rootfn, rootassets)
end

local data = { {name = "red_mushroom", animname="red"}, 
               {name = "green_mushroom", animname="green"},
               {name = "blue_mushroom", animname="blue"}
           }
local prefabs = {}

for k,v in pairs(data) do
    local root = MakeMushroot(v)
    table.insert(prefabs, root)
    table.insert(prefabs, MakePlacer( "common/"..v.animname.."_mushroot_placer", "mushrooms", "mushrooms", v.animname ))
end

STRINGS.NAMES.RED_MUSHROOT = "Red Mushroot"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.RED_MUSHROOT = "I should plant this if I want more deadly mushrooms." 
STRINGS.NAMES.GREEN_MUSHROOT = "Green Mushroot"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GREEN_MUSHROOT = "I should plant this if I want more funky mushrooms." 
STRINGS.NAMES.BLUE_MUSHROOT = "Blue Mushroot"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BLUE_MUSHROOT = "I should plant this if I want more healthy mushrooms." 

return unpack(prefabs) 
