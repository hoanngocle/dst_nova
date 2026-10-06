package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path
local Rules = require('nyx/gem_storage')
local function item(id, count)
    local inst = {prefab=id, components={}, valid=true, pickups=0}
    function inst:IsValid() return self.valid end
    inst.components.inventoryitem = {OnPickup=function(_, player)
        inst.pickups=inst.pickups+1
        return inst.destroy_on_pickup
    end}
    if count then
        inst.components.stackable = {StackSize=function() return count end,
            Get=function(_, n) count=count-n; return item(id,n) end}
    end
    return inst
end
local received, original_calls, opens = {}, 0, 0
local capacity=10
local reject=false
local container = {Open=function(_, owner) opens=opens+1 end,
    IsOpenedBy=function() return false end,
    CanAcceptCount=function() return capacity end,
    GiveItem=function(_, inst, slot, pos, drop)
        assert(drop==false)
        if reject then return false end
        received[#received+1]=inst
        inst.components.inventoryitem.owner=container
        return true
    end}
local player={prefab='nyx',components={},HasTag=function() return false end}
function player:PushEvent(event) assert(event=='gotnewitem') end
local storage={GetContainer=function() return container end}
player.components.nyx_gem_storage=storage
local inventory={inst=player,GiveItem=function(_, inst, slot, pos)
    original_calls=original_calls+1
    inst.components.inventoryitem:OnPickup(player,pos)
    inst.components.inventoryitem.owner=player
    return 7
end}
Rules.InstallPickup(inventory)
local gem=item('redgem',4)
assert(inventory:GiveItem(gem)==true and received[1]==gem,
    'pickup enters closed private storage before inventory')
assert(gem.pickups==1 and original_calls==0)
assert(opens==0,'successful pickup must not open storage UI')
capacity=2
local stack=item('xd_lingshi1',5)
assert(inventory:GiveItem(stack)==7)
assert(received[2].components.stackable:StackSize()==2)
assert(stack.components.stackable:StackSize()==3 and stack.pickups==1,
    'partial stack remainder enters inventory, pickup called once per entity')
assert(opens==0,'partial pickup must not open storage UI')
capacity=0
local full=item('bluegem')
assert(inventory:GiveItem(full)==7 and full.pickups==1)
assert(opens==0,'full box leaves pickup in inventory without opening')
capacity=10
local ordinary=item('rocks')
assert(inventory:GiveItem(ordinary)==7)
local withdrawn=item('hh_essence'); withdrawn.prevcontainer=container
assert(inventory:GiveItem(withdrawn)==7,'withdrawn items must not bounce back')
local owned=item('redgem'); owned.components.inventoryitem.owner=player
assert(inventory:GiveItem(owned)==7,'inventory rearrangement is not pickup')
inventory.isloading=true
assert(inventory:GiveItem(item('redgem'))==7,'load must preserve saved inventory slots')
inventory.isloading=false
assert(inventory:GiveItem(item('redgem'),3)==7,'explicit slot transfers remain unchanged')
local consumed=item('redgem'); consumed.destroy_on_pickup=true
local before=#received
inventory:GiveItem(consumed)
assert(#received==before and consumed.pickups==1,'respect native OnPickup destruction')
reject=true
local rejected=item('redgem')
assert(inventory:GiveItem(rejected)==7 and rejected.components.inventoryitem.owner==player,
    'unexpected container rejection falls back without losing the item')
reject=false
local before_open=opens
container.IsOpenedBy=function(_, who) return who==player end
assert(inventory:GiveItem(item('redgem'))==true and opens==before_open,
    'picking another item keeps an already-open box open without toggling')
player.prefab='wilson'
assert(inventory:GiveItem(item('redgem'))==7,'other characters are unchanged')
print('gem_storage_pickup_test: ok')
