local interrupt_controls = {}

--the keys to stop the autowalking 
for control = CONTROL_ATTACK, CONTROL_MOVE_RIGHT do
    interrupt_controls[control] = true	 
end

local function IsInGame()
	return ThePlayer and ThePlayer.HUD
end

local function IsInTyping()
	return  ThePlayer.HUD:HasInputFocus()
end

local function IsInMap()
	return ThePlayer.HUD:IsMapScreenOpen()

end

local function IsCursorOnHUD()
	local input = TheInput
	return input.hoverinst and input.hoverinst.Transform == nil
	--idk why function GetHUDEntityUnderMouse() sometime return false because hoverinst.entity:Isvalid() get false
	--so i remove it 
end

local function CanMouseActionLocomote(self, right) -- right: yes-rightclick,  no-leftclick
	-- do some early check for some special case 
	if TheInput:GetWorldEntityUnderMouse() == ThePlayer then return false end -- click myself
	if right and self.placer ~= nil then return false end -- early quit eg: has soulhop rightclick action but actually not triggered

	local bufferedaction
	-- action can be nil
	if right then
		bufferedaction = self:GetRightMouseAction() 
	else
		bufferedaction = self:GetLeftMouseAction() or BufferedAction(self.inst, nil, ACTIONS.WALKTO, nil, TheInput:GetWorldPosition())
	end
	
	if bufferedaction and
		(not (bufferedaction.action.instant or bufferedaction.action.do_not_locomote or bufferedaction.options.instant)	-- eg:Open Command Wheel
		or bufferedaction.action == ACTIONS.WALKTO) then
		-- print(bufferedaction)
		return true
	end

	return false
end

--keybind to stop the autowalking and remove the mappin(the dest icon)
AddComponentPostInit("playercontroller",function(self)
	local OnControl_old = self.OnControl
	 self.OnControl = function(self, control, down)
	 
		local pathfollower = ThePlayer and ThePlayer.components.ngl_pathfollower
		local should_ignore_control = down and self._hack_ignore_held_controls or (not down and self._hack_ignore_ups_for and self._hack_ignore_ups_for[control])
		if not should_ignore_control and pathfollower and pathfollower:HasDest() and IsInGame() then		
			--print("InGame",IsInGame(),"InMap:",IsInMap(),"Intype:",IsInTyping())
			--when you open the map and type in command box it actually IsNotInMap
			
			--press Direction key in game screen
			if not IsInMap() and not IsInTyping() and interrupt_controls[control] then
				pathfollower:ForceStop()
			--press space key in map screen	
			elseif IsInMap() and control == CONTROL_ACTION then
				pathfollower:ForceStop()
			--press mouse key except your backpack,craftmenu and other HUD
			elseif not IsInMap() and not IsInTyping() and not IsCursorOnHUD() and (control == CONTROL_PRIMARY or control == CONTROL_SECONDARY)
				and CanMouseActionLocomote(self, control == CONTROL_SECONDARY) then
				pathfollower:ForceStop()
				--print("hoverinst:",TheInput.hoverinst,"valid:",TheInput.hoverinst.entity:IsValid(),"visible:",TheInput.hoverinst.entity:IsVisible())
			end
		end
		return OnControl_old(self, control, down)
	end
	
	local OnMapAction_old = self.OnMapAction
	self.OnMapAction = function(self, actioncode, ...)
		local action = actioncode and ACTIONS_BY_ACTION_CODE[actioncode]
		if action and action.map_action then
			local pathfollower = ThePlayer and ThePlayer.components.ngl_pathfollower
			if pathfollower then
				pathfollower:ForceStop()
			end
		end
		return OnMapAction_old(self, actioncode, ...)
	end
	

end)