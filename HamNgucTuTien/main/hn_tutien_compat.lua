local Rules=require('hn_dungeon/restrictions')
AddComponentPostInit('nyx_blink',function(self)
    local old=self.CastAt
    self.CastAt=function(component,x,z,...)
        local fx,_,fz=component.inst.Transform:GetWorldPosition()
        local ok,reason=Rules.CanTeleport(component.inst,fx,fz,x,z)
        if not ok then return false,reason end
        return old(component,x,z,...)
    end
end)
AddComponentPostInit('ttt_travelable',function(self)
    for _,method in ipairs({'BeginTravel','Travel'}) do
        local old=self[method]
        if old then self[method]=function(component,player,...)
            if Rules.DenyTravel(player) then return false end
            return old(component,player,...)
        end end
    end
end)
-- The Tu Tien component invokes onusefn(inst, doer). Wrap the prefab's
-- callback after its constructor; other Tu Tien inventory items are untouched.
AddPrefabPostInit('xd_wmz_tnz',function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0,function()
        local use=inst.components.xd_use_inventory
        if use and use.onusefn then
            local old=use.onusefn
            use.onusefn=function(item,player,...)
                if Rules.DenyTravel(player) then return false end
                return old(item,player,...)
            end
        end
    end)
end)
