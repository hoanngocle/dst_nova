local M={}
local function gather(container,items,seen)
    for _,slots in ipairs({container.itemslots or container.slots or {},container.equipslots or {},{container.activeitem}}) do
        for _,item in pairs(slots) do
            if not seen[item] then
                seen[item]=true;items[#items+1]=item
                if item.components.container then gather(item.components.container,items,seen) end
            end
        end
    end
end
function M.Store(items,manager,owner)
    local bag
    local function newbag()
        local b=SpawnPrefab('hn_recovery_bag')
        if b then
            b.Transform:SetPosition(manager.run_gate_x or 0,0,manager.run_gate_z or 0)
            b.components.hn_recovery.owner=owner
            b.components.hn_recovery.recovery_id=tostring(b.GUID)
        end
        return b
    end
    for _,item in ipairs(items) do
        if item:IsValid() and item.components.inventoryitem and not item.components.inventoryitem:IsHeld() then
            if item.components.hn_owned then item.components.hn_owned.claimed=true end
            bag=bag or newbag()
            if not bag or not bag.components.container:GiveItem(item,nil,nil,false) then
                bag=newbag()
                if not bag or not bag.components.container:GiveItem(item,nil,nil,false) then
                    item.Transform:SetPosition(manager.run_gate_x or 0,0,manager.run_gate_z or 0)
                end
            end
        end
    end
end
function M.WrapInventory(inv)
    if inv.hn_recovery_wrapped then return end;inv.hn_recovery_wrapped=true
    local old=inv.DropEverything
    inv.DropEverything=function(self,ondeath,...)
        local manager=TheWorld.components.hn_dungeon_manager
        if not ondeath or not manager or not self.inst:HasTag('in_hn_dungeon') then return old(self,ondeath,...) end
        local items={};gather(self,items,{})
        old(self,ondeath,...)
        M.Store(items,manager,self.inst.userid)
    end
end
function M.RescueContainer(entity,manager)
    local container=entity.components.container;if not container then return end
    local rescued={}
    for slot,item in pairs(container.slots) do
        local owned=item.components.hn_owned
        if not owned or not owned.run_id or owned.claimed then
            local removed=container:RemoveItemBySlot(slot)
            if removed then rescued[#rescued+1]=removed end
        elseif item.components.container then M.RescueContainer(item,manager) end
    end
    M.Store(rescued,manager,'party')
end
return M
