package.path='ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
local Install=require('tbc_elixir/install')
local counts={power=9,health=10,mana=10}
local player={components={},GetTbcElixirCount=function(_,k) return counts[k] or 0 end}
player.components.tbc_elixir_progress={
    CanConsume=function(_,k) return k=='health' or k=='mana' or (counts[k] or 0)<10 end,
}
local eaten=0
local eater={inst=player,eatwholestack=true,TestFood=function() return true end,
    Eat=function(self,food)
        eaten=eaten+1
        assert(not self.eatwholestack,'only consume one elixir')
        food.stack=food.stack-1
        counts.power=counts.power+1
        return true,nil,'original'
    end}
Install.WrapEater(eater)
local food={prefab='tbc_elixir_power',stack=12}
assert(eater:TestFood(food,{}))
local a,b,c=eater:Eat(food)
assert(a and b==nil and c=='original','preserve native returns')
assert(food.stack==11 and eaten==1 and eater.eatwholestack==true)
assert(not eater:TestFood(food,{}) and not eater:Eat(food),'cap also rejects direct Eat')
assert(food.stack==11 and eaten==1,'blocked use preserves stack')
assert(eater:TestFood({prefab='tbc_elixir_health'},{}),'health recovery remains available')
assert(eater:TestFood({prefab='tbc_elixir_mana'},{}),'mana recovery remains available')
assert(eater:TestFood({prefab='meatballs'},{}),'ordinary food unaffected')
local eatAction,dropAction={},{}
local picker={inst=player,GetInventoryActions=function() return {{action=eatAction},{action=dropAction}} end}
Install.WrapPicker(picker,{EAT=eatAction})
local actions=picker:GetInventoryActions(food)
assert(#actions==1 and actions[1].action==dropAction,'hide only capped EAT action')
actions=picker:GetInventoryActions({prefab='tbc_elixir_health'})
assert(#actions==2,'recovery still has EAT action')
-- Client path uses replicated count and has no server progress component.
player.components.tbc_elixir_progress=nil
actions=picker:GetInventoryActions(food)
assert(#actions==1,'client cap from net counter')
print('elixir_eating_test: cap, recovery, single-stack consumption and client actions passed')
