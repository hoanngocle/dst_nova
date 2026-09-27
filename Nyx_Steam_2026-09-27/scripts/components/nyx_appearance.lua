local Catalog=require('nyx/appearance')
local Appearance=Class(function(self,inst)
    self.inst=inst; self.build=''
    self.refresh=function() inst:DoTaskInTime(0,function() self:Apply() end) end
    for _,event in ipairs({'ms_becameghost','ms_respawnedfromghost','equip','unequip','newstate'}) do inst:ListenForEvent(event,self.refresh) end
end)
function Appearance:Apply()
    local inst=self.inst
    if not inst:IsValid() then return end
    local build=inst:HasTag('playerghost') and 'ghost_eva_build' or (self.build~='' and self.build or 'eva_purple')
    if inst.AnimState:GetBuild()~=build then inst.AnimState:SetBuild(build) end
end
function Appearance:Set(build)
    if type(build)~='string' or (build~='' and not Catalog.valid[build]) then return false end
    self.build=build; self.inst._nyx_appearance:set(build); self:Apply(); return true
end
function Appearance:OnSave() return {build=self.build} end
function Appearance:OnLoad(data) self:Set(type(data)=='table' and data.build or '') end
return Appearance
