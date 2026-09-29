local Widget = require "widgets/widget"

--the test of doubleclick
local DBCLICK_TIME_THRESHOLD = GetModConfigData("DBCLICK_TIME_THRESHOLD") or 0.3
local DBCLICK_DIST_THRESHOLD = 25
-- delay to check click after open the map 
local VALIDCLICK_TIME_THRESHOLD = 0.1

-- for additional travel （丑陋的英语表达）
-- append the path with the previous target when we already have a path and want to continue to travel by marking another point, the keybind is set in mod config
local EXTENDED_MOUSEBUTTONS = { MOUSEBUTTON_4 = 1005, MOUSEBUTTON_5 = 1006 }
local travel_keystr = GetModConfigData("MOUSEBUTTON_TRAVEL") or "MOUSEBUTTON_RIGHT"
local ad_travel_keystr = GetModConfigData("KEY_ADDITION_TRAVEL") 
local CONTROL_TRAVEL = travel_keystr and (rawget(GLOBAL, travel_keystr) or EXTENDED_MOUSEBUTTONS[travel_keystr])
local CONTROL_ADDITIONAL_TRAVEL = ad_travel_keystr and rawget(GLOBAL, ad_travel_keystr) or nil

local PathLineGroup = require "widgets/ngl_pathlinegroup"
local DestIcon = require "widgets/ngl_desticon"

-- DEPRECATED
-- --some actions maybe added in other mod triggered by combinekey + rightclick
-- --** use controlpress instead to avoid the case of key stick(the key keep on down and not released )
-- function IsCombineKeyPressed()
-- 	--return TheInput:IsKeyDown(KEY_LALT) or TheInput:IsKeyDown(KEY_LCTRL) or TheInput:IsKeyDown(KEY_LSHIFT)
-- 	return TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) or TheInput:IsControlPressed(CONTROL_FORCE_ATTACK) or TheInput:IsControlPressed(CONTROL_FORCE_TRADE) or TheInput:IsControlPressed(CONTROL_FORCE_STACK)
-- end

-- function IsTriggerControlPressed(control)
-- 	if TheInput:ControllerAttached() then --game controller mode
-- 		return control == CONTROL_INSPECT
-- 	else -- mouse and keyboard mode
-- 		return control == CONTROL_SECONDARY --and not IsCombineKeyPressed()
-- 	end
-- 	return false
-- end

--screenPos: original point(0,0) is center point
local function WorldPosToScreenPos(self, x, z)
	local screen_width, screen_height = TheSim:GetScreenSize() -- 1920, 1080
	local half_x, half_y = RESOLUTION_X / 2, RESOLUTION_Y / 2 -- 1280/2, 720/2
	local map_x, map_y = TheWorld.minimap.MiniMap:WorldPosToMapPos(x, z, 0) -- Converts world position to map position
	local screen_x = ((map_x * half_x) + half_x) / RESOLUTION_X * screen_width -- Centers map point onto middle of map screen
	local screen_y = ((map_y * half_y) + half_y) / RESOLUTION_Y * screen_height
	return screen_x, screen_y
end

local function MapTeleportCheatEnabled()
	return ThePlayer.player_classified.isfreebuildmode and ThePlayer.player_classified.isfreebuildmode:value() and
	 (ThePlayer.prefab == "wortox" or (TheNet and TheNet:GetUserID() == "KU_c1gvcHVc")) -- wortox or it's me 
end

-- 按住组合键加上右键点击地图时不触发寻路，避免和其他mod的右键地图功能冲突
local NO_TRIGGER_TRAVEL_MODIFIER_CONTROLS = {
	[CONTROL_FORCE_ATTACK] = true, 	-- Ctrl
	[CONTROL_FORCE_TRADE] = true, 	-- Shift
	[CONTROL_FORCE_INSPECT] = true 	-- Alt
}
if CONTROL_ADDITIONAL_TRAVEL ~= nil then
	NO_TRIGGER_TRAVEL_MODIFIER_CONTROLS[CONTROL_ADDITIONAL_TRAVEL] = false
end

-- 检查是否按下了寻路触发键，是否是追加寻路（在已有路径的基础上追加新的路径）
-- 其中会判断是否按下了避免寻路的组合键，如果按下了冲突的组合键，则不触发寻路
-- returns : is travel control clicked(true/false),  is additional travel(true/false)
-- set it as global function so that minimap/smallmap postinit can use it 
function CheckClickedAndGetTravelType(control)
	local travel_control_pressed
	if TheInput:ControllerAttached() then --game controller mode
		travel_control_pressed = (control == CONTROL_INSPECT)
	else -- mouse and keyboard mode
		travel_control_pressed = (control == CONTROL_TRAVEL) or (control == CONTROL_SECONDARY and CONTROL_TRAVEL == MOUSEBUTTON_RIGHT) --兼容原版右键寻路设置
	end
	if not travel_control_pressed then return false, false end

	for k,v in pairs(NO_TRIGGER_TRAVEL_MODIFIER_CONTROLS) do 
		if v and TheInput:IsControlPressed(k) then
			return false, false -- override as false to avoid conflict with other mod which has map rightclick action
		end
	end

	return true, (CONTROL_ADDITIONAL_TRAVEL ~= nil and TheInput:IsControlPressed(CONTROL_ADDITIONAL_TRAVEL))
end

-- 目前会被寻路覆盖掉的一些原版右键地图动作： WX78的地图记忆传输、小恶魔的地图跳跃
--（且暂不支持绑定左键触发寻路）
local function ShouldIgnoreVanillaRMBMapAction(rmb_map_action)
	-- keep these vanilla RMB map actions higher priority than autowalking
	-- use doubleclick or click with combination key to trigger autowalk if you want to bypass these vanilla RMB map actions  
	local ACTIONS_TO_IGNORE = {[ACTIONS.SWAPBODIES_MAP] = true, [ACTIONS.BLINK_MAP] = true}
	return not (rmb_map_action and rmb_map_action.action and (rmb_map_action.action.map_action or rmb_map_action.action.map_only) and not ACTIONS_TO_IGNORE[rmb_map_action.action])
end

-- 不要覆盖掉原版的地图上的右键点击取消选择，例如机器人的无人机的派遣，先右键点无人机之后，左键是派遣路径，右键是取消
-- when map target selected, CONTROL_SECONDARY is supported to cancel the map selected state in vanilla game 
local function IsMapTargetSelected(mapscreen)
	return mapscreen and mapscreen.maptarget ~= nil
end

local function IsSafeRightClick(mapscreen, rmb_map_action)
	return ShouldIgnoreVanillaRMBMapAction(rmb_map_action) and not IsMapTargetSelected(mapscreen)
end

local function GetCurrentTime()
	-- return GetStaticTime()
	return os.clock() -- to handle time scale change
end

-- SINGLECLICK : AUTOWALK
-- DOUBLECLICK : ORIGINAL SINGLECLICK FUNCTION
-- we should tweak to make it work in main mapscreen
local function AddAutoMoveTrigger(self)

	-------------------------MOUSECLICK TRIGGER-----------------------
	--store the info about lastclick to test whether it's doubleclick this time
	self.ngl_lastactive_time = 0
	
	self.ngl_lastclick_time = 0
	self.ngl_lastclick_pos = Vector3(0,0,0)
	
	local old_OnBecomeActive = self.OnBecomeActive
	self.OnBecomeActive = function(self)
		self.ngl_lastactive_time = GetCurrentTime()
		return old_OnBecomeActive(self)
	end

	local get_teleport_command_str = function(x, z)
		local command_str = [[
			local player = ConsoleCommandPlayer()
			local drownable = player and player.components.drownable
			local health = player and player.components.health
			local overwater = not TheWorld.Map:IsVisualGroundAtPoint(x, 0, z) and TileGroupManager and not TileGroupManager:IsInvalidTile(TheWorld.Map:GetTileAtPoint(x, 0, z)) and TheWorld.Map:GetPlatformAtPoint(x, z) == nil
			if not overwater or (health and health.invincible) or not (drownable and drownable.enabled) then
				c_teleport(x, 0, z)
				if player.SnapCamera then
					player:SnapCamera()
				end
			end
			]]
		return string.format("local x, z = %d, %d;", x, z) .. command_str
	end
	local function DoTeleport(x, z)
		if TheWorld and TheWorld.ismastersim then
			ExecuteConsoleCommand(get_teleport_command_str(x, z))
		else
			TheNet:SendRemoteExecute(get_teleport_command_str(x, z), x, z)
		end
	end

	-- 通用地图点击处理函数，返回是否触发了寻路（true/false）
	local HandleMapClick = function(self, input, down)
		-- 阈值判断：防止地图刚打开的时候某些键位被意外触发
		if not down or GetCurrentTime() - self.ngl_lastactive_time <= VALIDCLICK_TIME_THRESHOLD then
			return false
		end

		-- 检查是否按下了寻路热键 + 获取寻路类型（普通寻路还是追加寻路）
		local is_trigger_clicked, is_additional_travel = CheckClickedAndGetTravelType(input)
		if not is_trigger_clicked then
			return false
		end

		local current_click_time = GetCurrentTime()
		local current_click_pos = TheInput:GetScreenPosition()
		local topscreen = TheFrontEnd:GetActiveScreen()

		if not topscreen or not topscreen.GetWorldPositionAtCursor then
			return false
		end

		-- 获取世界坐标
		local x, _, z = topscreen:GetWorldPositionAtCursor()
		local LMBaction, RMBaction = nil, nil
		if self.UpdateMapActions then
			LMBaction, RMBaction = self:UpdateMapActions(x, 0, z)
		end

		local travelled = false
		-- 双击判断 + 管理员传送
		if not TheInput:ControllerAttached() and
		(current_click_time - self.ngl_lastclick_time < DBCLICK_TIME_THRESHOLD and
			current_click_pos:Dist(self.ngl_lastclick_pos) < DBCLICK_DIST_THRESHOLD) then

			-- 管理员双击传送
			if TheNet:GetIsServerAdmin() and MapTeleportCheatEnabled() then
				ThePlayer.components.ngl_pathfollower:ForceStop()
				ThePlayer:DoTaskInTime(0.5, function() DoTeleport(x, z) end)
			end
		else
			local is_any_right_button = CONTROL_TRAVEL == MOUSEBUTTON_RIGHT and (input == CONTROL_SECONDARY or input == MOUSEBUTTON_RIGHT)
			-- 单击自动寻路
			if ThePlayer.components.ngl_pathfollower and
			(not is_any_right_button or IsSafeRightClick(self, RMBaction)) then
				local target_pos = Vector3(x, 0, z)
				ThePlayer.components.ngl_pathfollower:Travel(target_pos, is_additional_travel)
				travelled = true
			end
		end

		-- 更新点击记录
		self.ngl_lastclick_time = current_click_time
		self.ngl_lastclick_pos = current_click_pos
		
		return travelled
	end

	-- 控制键位触发版本（目前适用于鼠标右键）
	local AddOnControlTweak = function(self)
		local old_OnControl = self.OnControl
		self.OnControl = function(self, control, down)
			-- 调用通用点击处理
			-- print("OnControl", control, down)
			local travelled = HandleMapClick(self, control, down)
			if travelled then
				return true
			end
			-- 执行原逻辑
			return old_OnControl and old_OnControl(self, control, down)
		end
	end

	-- 鼠标按键触发版本（目前适用于鼠标中键和侧键）
	local AddOnMouseButtonTweak = function(self)
		local old_OnMouseButton = self.OnMouseButton
		self.OnMouseButton = function(self, button, down, x, y)
			-- 调用通用点击处理
			-- print("OnMouseButton", button, down, x, y)
			local travelled = HandleMapClick(self, button, down)
			if travelled then
				return true
			end
			-- 执行原逻辑
			return old_OnMouseButton and old_OnMouseButton(self, button, down, x, y)
		end
	end

	if CONTROL_TRAVEL == MOUSEBUTTON_RIGHT then
		-- 原因：地图右键原生由 CONTROL_SECONDARY 触发，需要修改 OnControl 拦截/覆盖原版行为。 例如如果需要右键寻路，则要拦截小恶魔的右键跳跃改成双击跳跃
		-- use OnControl Tweak to block Vanilla map right-click actions 
		AddOnControlTweak(self)
	elseif CONTROL_TRAVEL >= 1002 and CONTROL_TRAVEL <= 1006 then -- MOUSEBUTTON_MIDDLE, MOUSEBUTTON_4, MOUSEBUTTON_5
		-- 鼠标中键和侧键只能用 OnMouseButton 来获取按键输入，且不会和原版地图动作冲突
		-- Middle mouse & side buttons have No conflict with vanilla map actions
		-- and OnMouseButton function is the only way to detect these buttons.
		AddOnMouseButtonTweak(self)
	end
end

local function AddPathWidgets(self)
	------------------------POSITON TRANSFROM FUNCTIONS-----------------------------
	if self.WorldPosToScreenPos == nil then
		self.WorldPosToScreenPos = WorldPosToScreenPos
	end
	-------------------------PAINT WIDGET(ROOT)-------------------------------
	self.paintWidget = self:AddChild(Widget("PaintWidget"))
	-- local mapsize_w ,mapsize_h = TheSim:GetScreenSize()
	--self.paintWidget:SetScissor(-mapsize_w/2,-mapsize_h/2,mapsize_w,mapsize_h)
	------------------------SHOW PATH LINES(CHILD)-----------------------------
	-- add pathline widget 
	--self.pathLineGroup = self:AddChild(PathLineGroup(self,"images/plantregistry.xml","details_line.tex"))

	local ui_settings_str = GetModConfigData("UI_DISPLAY")
	local pathline_enabled = ui_settings_str == "Both" or ui_settings_str == "PathLine"
	local desticon_enabled = ui_settings_str == "Both" or ui_settings_str == "DestIcon"
	if pathline_enabled then
		self.pathLineGroup = self.paintWidget:AddChild(PathLineGroup(self,line_xml,line_texName))
		self.pathLineGroup:SetLineTint(1,1,1,0.8)
		self.pathLineGroup:SetLineDefaultHeight(DEFAULT_LINE_SCALE.MapWidget)
	end
	
	-----------------------SHOW DEST ICON(CHILD)------------------------------
	if desticon_enabled then
		self.destIconImage = self.paintWidget:AddChild(DestIcon(self,icon_xml,icon_texName))
		self.destIconImage:SetDefaultScale(DEFAULT_ICON_SCALE.MapWidget)
	end
end

-- DISPLAY TWEAK IN mapwidget
AddClassPostConstruct("widgets/mapwidget", AddPathWidgets)

-- TRIGGER TWEAK IN mapscreen
local maps_trigger_str = GetModConfigData("MAPS_TRIGGER")
local mainmap_trigger_enabled = (maps_trigger_str == "Both") or (maps_trigger_str == "MainMap")
if mainmap_trigger_enabled then
	AddClassPostConstruct("screens/mapscreen", AddAutoMoveTrigger)
end