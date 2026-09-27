local U={}
local EYE_COLOURCUBES={
    day='images/colour_cubes/beaver_vision_cc.tex',
    dusk='images/colour_cubes/beaver_vision_cc.tex',
    night='images/colour_cubes/beaver_vision_cc.tex',
    full_moon='images/colour_cubes/beaver_vision_cc.tex',
}
function U.ApplyEye(inst)
    if inst.components.playervision then
        local active=inst._nyx_eye:value()
        if active then inst.components.playervision:PushForcedNightVision('nyx_eye',1,EYE_COLOURCUBES)
        else inst.components.playervision:PopForcedNightVision('nyx_eye') end
    end
end
function U.ApplyWingsReplica(inst)
    require('nyx/wings_replica').ApplyReplicaState(inst)
end
function U.Prepare(inst,id)
    if id=='moon_wings' and not inst.DoDeltaTaShui then return nil,'Chưa nạp cơ chế đi nước của Tu Tiên.' end
    if id=='moon_wings' and inst.components.rider:IsRiding() then return nil,'Hãy xuống thú cưỡi để mở cánh.' end
    local h={done=false,started=false}
    function h:Start()
        if id=='purple_eye' then
            self.started=true
            inst._nyx_eye:set(true); U.ApplyEye(inst)
            inst.components.sanity.externalmodifiers:SetModifier(inst,.5,'nyx_eye')
            inst.AnimState:SetSymbolBloom('face'); inst.AnimState:SetSymbolLightOverride('face',1)
        elseif id=='moon_wings' then
            self.fx=SpawnPrefab('nyx_wings_fx')
            if not self.fx then return false end
            self.started=true
            self.fx:AttachToOwner(inst)
            local l=inst.components.locomotor
            if not TheWorld:HasTag('cave') then
                self.path=l.pathcaps; self.allow=self.path and self.path.allowocean
                l.pathcaps=l.pathcaps or {}; self.appliedpath=l.pathcaps; l.pathcaps.allowocean=true
            end
            inst.flymode=true; inst._nyx_wings:set(true); inst:DoDeltaTaShui(1); self.water=true
            inst.components.locomotor:SetExternalSpeedMultiplier(inst,'nyx_wings',1.08)
        else return false end
        return true
    end
    function h:Cancel()
        if self.done then return end; self.done=true
        if not self.started then return end
        if id=='purple_eye' then
            inst._nyx_eye:set(false); U.ApplyEye(inst)
            inst.components.sanity.externalmodifiers:RemoveModifier(inst,'nyx_eye')
            inst.AnimState:ClearSymbolBloom('face'); inst.AnimState:SetSymbolLightOverride('face',0)
        else
            inst.flymode=false; inst._nyx_wings:set(false)
            local l=inst.components.locomotor
            if self.appliedpath and l.pathcaps==self.appliedpath then
                l.pathcaps.allowocean=self.allow
                if not self.path and next(l.pathcaps)==nil then l.pathcaps=nil end
            end
            if self.water then inst:DoDeltaTaShui(-1); self.water=false end
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst,'nyx_wings')
            if self.fx and self.fx:IsValid() then self.fx:Remove() end
        end
    end
    function h:IsDone() return self.done end
    function h:CanContinue() return id~='moon_wings' or not inst.components.rider:IsRiding() end
    return h
end
return U
