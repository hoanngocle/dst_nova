local Defs=require('tbc_elixir/defs')
local Resources=require('tbc_elixir/resources')
local M={}
local unpack_values=unpack or table.unpack
local function Pack(...) return {n=select('#',...),...} end
local function CanConsume(player,key)
    local progress=player.components and player.components.tbc_elixir_progress
    if progress then return progress:CanConsume(key) end
    if player.HasTag and player:HasTag('playerghost') then return false end
    local row=Defs.BY_KEY[key]
    local count=player.GetTbcElixirCount and player:GetTbcElixirCount(key) or 0
    return row and (row.recovery or count<Defs.LIMIT) or false
end
function M.WrapEater(eater)
    if eater._tbc_elixir_wrapped then return end
    eater._tbc_elixir_wrapped=true
    local test,eat=eater.TestFood,eater.Eat
    eater.TestFood=function(self,food,...)
        local key=food and Defs.BY_PREFAB[food.prefab]
        if key then
            local progress=self.inst.components.tbc_elixir_progress
            return progress~=nil and progress:CanConsume(key)
        end
        return test(self,food,...)
    end
    eater.Eat=function(self,food,...)
        local key=food and Defs.BY_PREFAB[food.prefab]
        if not key then return eat(self,food,...) end
        if not self:TestFood(food,{}) then return false end
        local previous=self.eatwholestack
        self.eatwholestack=false
        local result=Pack(pcall(eat,self,food,...))
        self.eatwholestack=previous
        if not result[1] then error(result[2],0) end
        return unpack_values(result,2,result.n)
    end
end
function M.WrapPicker(picker,actions)
    local original=picker.GetInventoryActions
    picker.GetInventoryActions=function(self,food,...)
        local result=original(self,food,...)
        local key=food and Defs.BY_PREFAB[food.prefab]
        if key and not CanConsume(self.inst,key) then
            for i=#result,1,-1 do
                if result[i].action==actions.EAT then table.remove(result,i) end
            end
        end
        return result
    end
end
function M.Install(env,G)
    env.AddComponentPostInit('health',function(c)
        if c.inst:HasTag('player') then Resources.Install(c,'health') end
    end)
    env.AddComponentPostInit('xd_htz_lq',function(c) Resources.Install(c,'mana') end)
    env.AddComponentPostInit('eater',M.WrapEater)
    env.AddComponentPostInit('playeractionpicker',function(c) M.WrapPicker(c,G.ACTIONS) end)
    env.AddPlayerPostInit(function(inst)
        for _,key in ipairs(Defs.ORDER) do
            inst['_tbc_elixir_'..key]=G.net_smallbyte(inst.GUID,'tbc_elixir.'..key,'tbc_elixir_dirty')
        end
        inst.GetTbcElixirCount=function(player,key)
            local progress=player.components and player.components.tbc_elixir_progress
            if progress then return progress:GetCount(key) end
            local net=player['_tbc_elixir_'..tostring(key)]
            return net and net:value() or 0
        end
        if not G.TheWorld.ismastersim then return end
        inst:AddComponent('tbc_elixir_progress')
        local function refresh()
            if inst:IsValid() then inst.components.tbc_elixir_progress:Refresh() end
        end
        inst:ListenForEvent('ms_respawnedfromghost',refresh)
        inst:DoTaskInTime(0,refresh)
        inst:DoTaskInTime(1,refresh)
    end)
    for _,key in ipairs(Defs.ORDER) do
        local row=Defs.BY_KEY[key]
        env.RegisterInventoryItemAtlas(row.atlas,row.icon..'.tex')
        G.STRINGS.NAMES[row.prefab:upper()]=row.name
        G.STRINGS.RECIPE_DESC[row.prefab:upper()]=row.description
        local ingredients={}
        for _,entry in ipairs(row.ingredients) do
            local id=entry[1]
            if id:sub(1,3)=='xd_' then
                ingredients[#ingredients+1]=G.Ingredient(id,entry[2],
                    'images/inventoryimages/'..id..'.xml',nil,id..'.tex')
            else
                ingredients[#ingredients+1]=G.Ingredient(id,entry[2])
            end
        end
        env.AddRecipe2(row.prefab,ingredients,G.TECH.MAGIC_THREE,
            {numtogive=1,atlas=row.atlas,image=row.icon..'.tex'},{'MAGIC','RESTORATION'})
    end
end
return M
