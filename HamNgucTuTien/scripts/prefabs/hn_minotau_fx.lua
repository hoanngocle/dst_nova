-- Solo Guardian visual palette, with all damage delegated to the living owner.
local H=require('hn_dungeon/boss_hazards')
local T=require('hn_dungeon/minotau_tuning')
local function make(name,build,bank,anim,scale,lifetime,kind,asset)
    local function fn()
        local inst=CreateEntity()
        inst.entity:AddTransform();inst.entity:AddAnimState();inst.entity:AddNetwork()
        inst:AddTag('FX');inst:AddTag('NOCLICK');inst:AddTag('notraptrigger')
        inst.persists=false
        inst.AnimState:SetBuild(build);inst.AnimState:SetBank(bank)
        inst.AnimState:PlayAnimation(anim,kind=='fire')
        inst.AnimState:SetMultColour(.05,.05,.05,1)
        inst.Transform:SetScale(scale,scale,scale)
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end
        inst:DoTaskInTime(lifetime,inst.Remove)
        if kind=='fire' then
            inst:DoPeriodicTask(.25,function()
                local owner=inst.hn_boss_owner
                if not H.IsActive(owner) then inst:Remove();return end
                H.Area(owner,inst:GetPosition(),2.2,nil,true)
            end)
        elseif kind=='wave' then
            inst.hn_hitlist={};inst.hn_travelled=0
            inst.SetWaveInfo=function(self,level,dir) self.hn_dir=dir end
            inst:DoPeriodicTask(.1,function()
                local owner=inst.hn_boss_owner
                if not H.IsActive(owner) then inst:Remove();return end
                local pos=inst:GetPosition();local dir=inst.hn_dir or {x=1,z=0}
                H.Area(owner,pos,1.5,1,false,inst.hn_hitlist)
                local nextpos={x=pos.x+dir.x*1.5,z=pos.z+dir.z*1.5}
                if not H.IsInside(owner,nextpos.x,nextpos.z) or not TheWorld.Pathfinder:IsClear(pos.x,0,pos.z,nextpos.x,0,nextpos.z) then inst:Remove();return end
                inst.Transform:SetPosition(nextpos.x,0,nextpos.z)
                inst.AnimState:PlayAnimation('small')
            end)
        else
            inst:ListenForEvent('animover',inst.Remove)
        end
        return inst
    end
    return Prefab(name,fn,{Asset('ANIM','anim/'..(asset or build)..'.zip')})
end
return
    make('hn_minotau_shadowblaze','fire','fire','level2',1.5,T.FIRE_DURATION,'fire'),
    make('hn_minotau_shadowblaze_high','fire','fire','level4',1.5,T.FIRE_DURATION,'fire'),
    make('hn_minotau_shadowblaze_rigidbody','fire','fire','level2',.6,T.FIRE_DURATION,'fire'),
    make('hn_minotau_deadlyshockwave','explode','explode','small',2.1,1.2,'wave'),
    make('hn_minotau_deathshockwave','explode','explode','small',3,2),
    make('hn_minotau_attachedfire_fx','fire_large_character','fire_large_character','loop_small',1,1),
    make('hn_minotau_firecharge_fx','dragonfly_fx','dragonfly_fx','atk',1,2),
    make('hn_minotau_firering_fx','dragonfly_ring_fx','dragonfly_ring_fx','idle',1,2),
    make('hn_minotau_firesplash_fx','dragonfly_ground_fx','dragonfly_ground_fx','idle',1.5,2),
    make('hn_minotau_target_fx','fx_wathgrithr_buff','fx_wathgrithr_buff','quote_electric',1.2,2),
    make('hn_minotau_teleport_fx','deer_ice_burst','deer_ice_burst','loop',2.5,.3),
    make('hn_minotau_teleportpost_fx','atrium_gate','atrium_gate','overload_pre',1.3,.6,nil,'atrium_gate_overload_fx'),
    make('hn_minotau_transform_fx','shadow_rook','shadow_rook','transform',1.2,3),
    make('hn_minotau_weakeningfx','explode','explode','small',1,2),
    make('hn_minotau_shadowpoundring_fx','bearger_ring_fx','bearger_ring_fx','idle',1,2)
