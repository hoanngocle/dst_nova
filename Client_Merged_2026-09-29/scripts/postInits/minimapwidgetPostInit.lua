local PathLineGroup = require "widgets/ngl_pathlinegroup"
local DestIcon = require "widgets/ngl_desticon"
local Widget = require "widgets/widget"

local ROT_REPEAT = .25

-------------------------ADD MORE KEYBIND------------
local function DoRotate(right)
    -- if not TheCamera:CanControl() then
		-- print("can't control")
        -- return
    -- end

    local rotamount = right and 45 or -45
    if not IsPaused() then
        TheCamera:SetHeadingTarget(TheCamera:GetHeadingTarget() + rotamount)
        --UpdateCameraHeadings()
    end
	--print("rot:"..rotamount)
end

local function AddRotForMinimap(self)
	local old_OnControl = self.OnControl
	self.OnControl = 
		function (self, control, down)
		    local isenabled, ishudblocking = ThePlayer.components.playercontroller:IsEnabled()
			if not isenabled and not ishudblocking then
				return
			end
			
			local time = GetStaticTime()
			-- local time = os.clock()
			local invert_rotation = Profile:GetInvertCameraRotation()
			if 	self.lastrottime == nil or time - self.lastrottime > ROT_REPEAT then	
				if control == CONTROL_ROTATE_LEFT or control == CONTROL_ROTATE_RIGHT then
					DoRotate(control == (invert_rotation and CONTROL_ROTATE_LEFT or CONTROL_ROTATE_RIGHT))
					self.lastrottime = time
				end
			end
			return old_OnControl(self, control, down)
		end

end

local function AddResetKeyForMinimap(self)
	local old_OnMouseButton = self.OnMouseButton
	self.OnMouseButton = 
		function (self, button, down, x, y)
			if button == MOUSEBUTTON_MIDDLE and down then
				self.minimap:ResetOffset()
			end
			
			if old_OnMouseButton ~= nil then
				return old_OnMouseButton(self, button, down, x, y)
			end
			return true
		end
end
----------------------ADD MORE FUNCTIONS-------------------------------
local function MiniMapWidget_GetMapPosition(self)
	local x_cursor, y_cursor = TheSim:GetPosition()
	local x_widgetcenter, y_widgetcenter = self.img:GetWorldPosition():Get()
	local w, h = self.img:GetSize()
	local scale = self.img:GetScale()
	local x = (x_cursor - x_widgetcenter)*(2-self.uvscale)/scale.x + w/2
	local y = (y_cursor - y_widgetcenter)*(2-self.uvscale)/scale.y + h/2
	--print(uvscale)
	--print(self.parent:GetScale():Get())
	--print(self:GetScale())
	x = 2 * x / w - 1
    y = 2 * y / h - 1
	return x, y
end

local function MiniMapWidget_GetWorldPositionAtCursor(self)
    local x, y = self:GetCursorPosition()
	--print("gt-mappos:",x,y)
    x, y = self.minimap:MapPosToWorldPos(x, y, 0)
	--print("gt_worldpos:",x,y)
    return x, 0, y -- Coordinate conversion from minimap widget to world.
end

-- ScreenPos: original point(0,0) is center of MiniMapHUD
local function MiniMapWidget_WorldPosToScreenPos(self, x, z)
	local map_x, map_y = self.minimap:WorldPosToMapPos(x, z, 0)
	
	local w, h = self.img:GetSize()
	local scale = self.img:GetScale()
	local map_x = map_x * w * scale.x /(2 - self.uvscale)/ 2
	local map_y = map_y * h * scale.y /(2 - self.uvscale)/ 2
    local screen_x = map_x /scale.x
    local screen_y = map_y /scale.y 
	
    return screen_x, screen_y
end
--------------------------FIX ORINGINAL FNS------------------------
---fix OnUpdate----
local function MiniMapWidget_OnUpdate(self, dt)
	if not self.shown then return end
	if not self.focus then return end
	if not self.img.focus then return end

	if TheInput:IsControlPressed(CONTROL_PRIMARY) then
		local pos = TheInput:GetScreenPosition()
		if self.lastpos then
			--local scale = 1/(self.uvscale*self.uvscale)
			local dx = ( pos.x - self.lastpos.x )*(2-self.uvscale)
			local dy = ( pos.y - self.lastpos.y )*(2-self.uvscale)
			self.minimap:Offset( dx, dy )
		end
		
		self.lastpos = pos
	else
		self.lastpos = nil
	end
end

---fix OnShow---- someone may dont like that minimap zoom tracked by map screen
local function MiniMapWidget_OnShow(self)
	if self:IsOpen() then
		self:EnableMinimapUpdating()
	end
	self.minimap:Zoom(self.mapscreenzoom + 0.75 - self.minimap:GetZoom())
	self.minimapzoom = self.mapscreenzoom + 0.75
	self.minimap:ResetOffset()
end


-- fix the issue holding Map Control(Pressing M) will make the Map get offset reset
local MINIMAP_TEMP_IGNORE_RESET = false
local function AddOnShowPatch(self)
	local minimap = self.minimap and getmetatable(self.minimap).__index  -- userdata, MiniMap Component in C++ side
	if minimap then
		local old_Zoom = minimap.Zoom
		minimap.Zoom = function(self, ...)
			if MINIMAP_TEMP_IGNORE_RESET then
				-- print("blocking zoom")
				return 
			end
			return old_Zoom and old_Zoom(self, ...)
		end
		local old_ResetOffset = minimap.ResetOffset
		minimap.ResetOffset = function(self, ...)
			if MINIMAP_TEMP_IGNORE_RESET then
				-- print("blocking resetoffset")
				return 
			end
			return old_ResetOffset and old_ResetOffset(self, ...)
		end
	end
	local old_OnShow = self.OnShow
	self.OnShow = function (self, was_hidden, ...)
		-- if not was_hidden then
		-- 	return old_OnShow(self, was_hidden)
		-- end

		MINIMAP_TEMP_IGNORE_RESET = was_hidden
		local ret = old_OnShow(self, was_hidden, ...)
		MINIMAP_TEMP_IGNORE_RESET = false
		return ret
	end
end

-- fix the crash about MiniMap C side component in single shard world(no caves)
-- copied from lw (Dont Starve Alone Mod -- modmain/misc.lua)
local function AddEngineSideCrashPatch(self)
	local old_UpdateTexture = self.UpdateTexture
	self.UpdateTexture = function(self)
		if GetTick() <= 4 then
			self.inst:DoTaskInTime(.5, function()
				local w, h = self.img:GetSize()
				old_UpdateTexture(self)
				self.img:SetSize(w, h)
			end)
		else
			return old_UpdateTexture(self)
		end
	end
end

-----------------------------ADD AUTOWALK TRIGGER--------------------------
local function AddAutoMoveTriggerForMiniMap(self)
	local old_OnMouseButton = self.OnMouseButton
	self.OnMouseButton = function (self, button, down, x, y)
		local is_trigger_clicked, is_additional_travel = CheckClickedAndGetTravelType(button)
		if is_trigger_clicked and down then		
			local topscreen = TheFrontEnd:GetActiveScreen()
			if topscreen == ThePlayer.HUD then
				if self.minimap ~= nil then
					local x, _, z = self:GetWorldPositionAtCursor()
					local target_pos = Vector3(x, 0, z)
					ThePlayer.components.ngl_pathfollower:Travel(target_pos, is_additional_travel)
				end
			end
		else --control except mouserightdown
			return	old_OnMouseButton and old_OnMouseButton(self, button, down, x, y)
		end
	end
end

local function AddImgResizeWatcher(self)
	if self.img ~= nil then
		local old_SetSize = self.img.SetSize
		self.img.SetSize = function(img, w, h, ...)
			local ret = old_SetSize(img, w, h, ...)
			if self.paintWidget ~= nil then
				self.paintWidget:SetScissor(-w/2,-h/2,w,h)
			end
			return ret
		end
	end
end
	
local function AddPathWidgetsForMiniMap(self, pathline_enabled, desticon_enabled)
	-------------------------PAINT WIDGET-----------------------
	self.paintWidget = self.img:AddChild(Widget("PaintWidget"))
	-- lw newbee 
	-- hide the widget outside this area
	self.paintWidget:SetScissor(-self.mapsize.w/2,-self.mapsize.h/2,self.mapsize.w,self.mapsize.h)
	------------------------SHOW PATH LINES-----------------------------
	-- add pathline widget 

	if pathline_enabled then
		self.pathLineGroup = self.paintWidget:AddChild(PathLineGroup(self,line_xml,line_texName))
		self.pathLineGroup:SetLineTint(1,1,1,0.8)
		self.pathLineGroup:SetLineDefaultHeight(DEFAULT_LINE_SCALE.MinimapWidget)
	end
		
	-----------------------SHOW DEST ICON------------------------------
	-- to hide the icon outside the minimap area, i add it as pathlinegroup's child
	if desticon_enabled then
		self.destIconImage = self.paintWidget:AddChild(DestIcon(self,icon_xml,icon_texName))
		self.destIconImage:SetDefaultScale(DEFAULT_ICON_SCALE.MinimapWidget)
	end
end

------------------------------APPLY-------------------------------
local maps_trigger_str = GetModConfigData("MAPS_TRIGGER")
local patch_enabled = GetModConfigData("PATCH_MINIMAP")
local minimap_trigger_enabled = (maps_trigger_str == "Both") or (maps_trigger_str == "MiniMap")

local ui_settings_str = GetModConfigData("UI_DISPLAY")
local pathline_enabled = ui_settings_str == "Both" or ui_settings_str == "PathLine"
local desticon_enabled = ui_settings_str == "Both" or ui_settings_str == "DestIcon"
AddClassPostConstruct("widgets/minimapwidget",
	function(self)
		self.GetCursorPosition = MiniMapWidget_GetMapPosition
		self.GetWorldPositionAtCursor = MiniMapWidget_GetWorldPositionAtCursor
		self.WorldPosToScreenPos = MiniMapWidget_WorldPosToScreenPos
		-- better to use hook instead of override to tweak it
		--self.OnUpdate = MiniMapWidget_OnUpdate 
		--self.OnShow = MiniMapWidget_OnShow
		if minimap_trigger_enabled then
			AddAutoMoveTriggerForMiniMap(self)
		end
		AddPathWidgetsForMiniMap(self, pathline_enabled, desticon_enabled)
		AddImgResizeWatcher(self)
		AddRotForMinimap(self)
		AddResetKeyForMinimap(self)
		if patch_enabled then -- this patch could make some device stop updating their minimap, idk why
			AddOnShowPatch(self)
		end
		AddEngineSideCrashPatch(self)
end)

