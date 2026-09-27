-- CC : delay drain and increase delta >> [Reward] expertwolf1
if not chasni_getperkexcludeconfig("expertwolf1") then
    AddComponentPostInit("mightiness", function(self)
        local _DoDelta = self.DoDelta
        self.DoDelta = function(_self, delta, ...)
            if _self.inst.components.allachivcoin and _self.inst.components.allachivcoin.expertwolf1 then
                if delta > 0 then
                    delta = delta * 2
                end
            end
            return _DoDelta(_self, delta, ...)
        end
    end)
end

-- CC : mightiness delay with marbled_armor >> [Reward] expertwolf2
if not chasni_getperkexcludeconfig("expertwolf2") then
    AddComponentPostInit("mightiness", function(self)
        local _DoDec = self.DoDec
        self.DoDec = function(_self, ...)
            local is_draining = _self.draining
            if _self.inst.components.inventory:EquipHasTag("marbled_hat") then
                _self.draining = false
            end
            _DoDec(_self, ...)
            _self.draining = is_draining
        end
    end)
end 