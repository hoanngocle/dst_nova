-- Compose permanent elixir maxima with native recalculation and equipment.
-- Save the native maximum, never the already augmented value.
local M = {}
local function Bonus(inst,kind)
    local p=inst.components and inst.components.tbc_elixir_progress
    return p and p:GetBonus(kind) or 0
end
local function EquipmentMana(inst)
    local state=inst._tbc_affix_mana
    return state and state.max_bonus or 0
end
local function EquipmentHealth(inst,base)
    local state=inst._tbc_passive_state
    if not state then return 0 end
    local bonus=base*(state.health_percent or 0)/100+(state.body_health or 0)
    state.health_bonus=bonus
    return bonus
end
local function Maximum(c,kind)
    local equipment=kind=='health' and EquipmentHealth(c.inst,c._tbc_elixir_base)
        or EquipmentMana(c.inst)
    return math.max(1,c._tbc_elixir_base+Bonus(c.inst,kind)+equipment)
end
local function CaptureExternalHealth(c)
    local previous=c._tbc_elixir_last_max
    if type(previous)=='number' and type(c.maxhealth)=='number'
        and c.maxhealth~=previous then
        -- Tu Tiên can adjust maxhealth directly, bypassing SetMaxHealth.
        -- Fold only that outside delta into the native base before recomputing.
        c._tbc_elixir_base=math.max(1,c._tbc_elixir_base+c.maxhealth-previous)
        -- The equipped percentage also depends on the new native base. Merely
        -- capturing the delta leaves that source stale until an equipment swap.
        c.maxhealth=Maximum(c,'health')
        c._tbc_elixir_last_max=c.maxhealth
        if c.ForceUpdateHUD then c:ForceUpdateHUD(true) end
    end
end
local function Restore(c,kind,value)
    if type(value)~='number' then return end
    if kind=='health' then
        local cap=c.GetMaxWithPenalty and c:GetMaxWithPenalty() or c.maxhealth
        c:SetCurrentHealth(math.max(0,math.min(value,cap)))
    else
        c.current=math.max(0,math.min(value,c.max))
        c:DoDelta(0)
    end
end
function M.Install(c,kind)
    if c._tbc_elixir_resource then return end
    c._tbc_elixir_resource=kind
    local field=kind=='health' and 'maxhealth' or 'max'
    local current=kind=='health' and 'currenthealth' or 'current'
    local setter=kind=='health' and 'SetMaxHealth' or 'SetMax'
    c._tbc_elixir_base=c[field]
    if kind=='health' then c._tbc_elixir_last_max=c.maxhealth end
    if kind=='health' then c._tbc_elixir_capture=CaptureExternalHealth end
    if c[setter] then
        local original=c[setter]
        c[setter]=function(self,value,...)
            self._tbc_elixir_base=value
            local result=original(self,Maximum(self,kind),...)
            if kind=='health' then self._tbc_elixir_last_max=self.maxhealth end
            return result
        end
    end
    if kind=='mana' and c.CheckLevel then
        local original=c.CheckLevel
        c.CheckLevel=function(self,...)
            local previous=self.current
            self.max=self._tbc_elixir_base
            local result=original(self,...)
            self._tbc_elixir_base=self.max
            self.max=self.max+Bonus(self.inst,kind)+EquipmentMana(self.inst)
            Restore(self,kind,previous)
            return result
        end
    end
    if c.OnLoad then
        local original=c.OnLoad
        c.OnLoad=function(self,data,...)
            local loaded=data and data[kind=='health' and 'health' or 'current']
            -- Component load order is unspecified. Tu Tien may have already
            -- applied its body maximum before native health loads current HP.
            if kind=='health' then CaptureExternalHealth(self) end
            local result=original(self,data,...)
            if kind=='health' then CaptureExternalHealth(self) end
            if data and type(data[field])=='number' then self._tbc_elixir_base=data[field] end
            if kind=='health' then self._tbc_elixir_last_max=self.maxhealth end
            self._tbc_elixir_loaded_current=loaded
            return result
        end
    end
    if c.OnSave then
        local original=c.OnSave
        c.OnSave=function(self,...)
            if kind=='health' then CaptureExternalHealth(self) end
            local data,refs=original(self,...)
            if data and type(data[field])=='number' then
                data[field]=self._tbc_elixir_base
            end
            return data,refs
        end
    end
    c._tbc_elixir_refresh=function(self)
        if kind=='health' then CaptureExternalHealth(self) end
        local value=self._tbc_elixir_loaded_current
        if value==nil then value=self[current] end
        local maximum=Maximum(self,kind)
        if kind=='health' then self[field]=maximum else self.max=maximum end
        if kind=='health' then self._tbc_elixir_last_max=self.maxhealth end
        Restore(self,kind,value)
        self._tbc_elixir_loaded_current=nil
        if kind=='health' and self.ForceUpdateHUD then self:ForceUpdateHUD(true) end
    end
    if kind=='health' and c.TransferComponent then
        local original=c.TransferComponent
        c.TransferComponent=function(self,newinst,...)
            -- DST transfers components via pairs(), without a guaranteed order.
            -- Establish the target maximum before native health copies its percentage.
            local progress=self.inst.components.tbc_elixir_progress
            if progress then progress:TransferComponent(newinst) end
            return original(self,newinst,...)
        end
    end
end
function M.Refresh(inst)
    for _,name in ipairs({'health','xd_htz_lq'}) do
        local c=inst.components[name]
        if c and c._tbc_elixir_refresh then c:_tbc_elixir_refresh() end
    end
end
return M
