local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"

local UIData1 = require "constants/uidata"
--local UIData2 = require "constants/uidata_easy"
local UIData = UIData1
local AttributeCaps = require "constants/attributecaps"
local AchievementPages = require "constants/achievementpages"
local FoodAchievementGuide = require "constants/foodachievementguide"

local function CenteredTabX(index, count, spacing)
	return (index - (count + 1) / 2) * spacing
end

local SeasonalCatalog = require "constants/seasonaltaskcatalog"
local SeasonalRewards = require "constants/seasonalrewarddata"
local SeasonalFoodRecipes = require "constants/seasonalfoodrecipes"
local TASK_MILESTONES = {1, 2, 4, 6}
local TASK_ROW_START_Y = -100
local TASK_ROW_STEP_Y = -80
local TASK_TOOLTIP_Y = -635

local function TaskHoverOptions(taskid)
	return { font_size = 18, bg = false, offset_x = 0,
		offset_y = TASK_TOOLTIP_Y - (TASK_ROW_START_Y + TASK_ROW_STEP_Y * taskid),
		colour = {1,1,1,1} }
end

local function MakeSeasonalReceipt(owner, nonce)
	local now = type(GetTime) == "function" and math.floor(GetTime() * 1000) or 0
	return tostring(owner and owner.GUID or "player") .. ":" .. tostring(now) .. ":" .. tostring(nonce or 0)
end

local function GetSeasonalRecipeTooltip(task)
	return task and task.foodprefab
		and SeasonalFoodRecipes.GetTooltip(task.foodprefab, STRINGS.NAMES)
		or nil
end

local function AchievementHoverText(self, achievementindex)
	local hovertext = self:getAchievementProgressString(achievementindex)
	local ach_name = UIData.ach_list[achievementindex]
	local food = FoodAchievementGuide.ById(ach_name)
	if food then
		hovertext = hovertext .. "\n" .. FoodAchievementGuide.Description(food, STRINGS.NAMES)
		local recipe = FoodAchievementGuide.RecipeTooltip(food, STRINGS.NAMES, AllRecipes)
		return recipe and hovertext .. "\n" .. recipe or hovertext
	end
	local taskgroup = STRINGS.ACHIEVEMENTS[ach_name]["description"]
	if type(taskgroup) == "number" then
		local definition = SeasonalCatalog.ById(self.owner["seasonaltaskid"..taskgroup]:value())
		local recipe = GetSeasonalRecipeTooltip(definition)
		if recipe then return hovertext .. "\n" .. recipe end
	end
	return hovertext
end

local function GetSeasonalSlot(achievement_name)
	local slot = type(achievement_name) == "string" and tonumber(string.match(achievement_name, "^task(%d)$")) or nil
	return slot and slot >= 1 and slot <= 6 and slot or nil
end

local uiachievement = Class(Widget, function(self, owner)
	Widget._ctor(self, "uiachievement")
	self.owner = owner
	self.mainui = self:AddChild(Widget("mainui"))
	self.mainui:MoveToFront()

	-- # LEVEL BG
	self.mainui.levelbg = self.mainui:AddChild(Image("images/hud/level/level_bg.xml", "level_bg.tex"))
	self.mainui.levelbg:SetPosition(0, 0, 0)
	self.mainui.levelbg:MoveToFront()
	self.mainui.levelbg:Hide()

	self.mainui.levelbg.title = self.mainui.levelbg:AddChild(Text(NEWFONT_OUTLINE, 55))
	self.mainui.levelbg.title:SetPosition(0, 280, 0)
	self.mainui.levelbg.title:SetString(STRINGS.GUI["levelTitle"])

	-- # PET LEVEL BG
	self.mainui.petlevelbg = self.mainui:AddChild(Image("images/hud/level/level_bg.xml", "level_bg.tex"))
	self.mainui.petlevelbg:SetPosition(0, 0, 0)
	self.mainui.petlevelbg:MoveToFront()
	self.mainui.petlevelbg:Hide()

	self.mainui.petlevelbg.title = self.mainui.petlevelbg:AddChild(Text(NEWFONT_OUTLINE, 55))
	self.mainui.petlevelbg.title:SetPosition(0, 280, 0)
	self.mainui.petlevelbg.title:SetString(STRINGS.GUI["petlevelTitle"])

	-- # MAIN BG
	self.mainui.achievement_bg = self.mainui:AddChild(Image("images/hud/ach/ach_bg.xml", "ach_bg.tex"))
	self.mainui.achievement_bg:SetPosition(0, 0, 0)
	self.mainui.achievement_bg:MoveToFront()
	self.mainui.achievement_bg:Hide()

	self.mainui.achievement_bg.info = self.mainui.achievement_bg:AddChild(Image("images/hud/ach/ach_info_bg.xml", "ach_info_bg.tex"))
	self.mainui.achievement_bg.info:MoveToBack()
	self.mainui.achievement_bg.info:Hide()

	self.mainui.achievement_bg.info.header = self.mainui.achievement_bg.info:AddChild(Text(CHATFONT_OUTLINE, 45))
	self.mainui.achievement_bg.info.header:SetPosition(-20, 300, 0)

	self.mainui.achievement_bg.info.label = self.mainui.achievement_bg.info:AddChild(Text(CHATFONT, 26))
	self.mainui.achievement_bg.info.label:SetPosition(-30, 0, 0)
	self.mainui.achievement_bg.info.label:SetColour(0, 0, 0, 1)
	self.mainui.achievement_bg.info.label:SetVAlign(ANCHOR_TOP)
	self.mainui.achievement_bg.info.label:SetHAlign(ANCHOR_LEFT)

	self.mainui.achievement_bg.titlebox = self.mainui.achievement_bg:AddChild(Widget("titlebox"))
	self.mainui.achievement_bg.titlebox:SetPosition(0, 400, 0)

	self.mainui.achievement_bg.titlebox.title = self.mainui.achievement_bg.titlebox:AddChild(Text(NEWFONT_OUTLINE, 55))
	self.mainui.achievement_bg.titlebox.title:SetPosition(0, 0, 0)
	self.mainui.achievement_bg.titlebox.title:SetString(STRINGS.GUI["achievementTitle"])

	self.mainui.achievement_bg.titlebox.icon = self.mainui.achievement_bg.titlebox:AddChild(Image("images/hud/guide_button.xml", "guide_button.tex"))
	self.mainui.achievement_bg.titlebox.icon:SetPosition(self.mainui.achievement_bg.titlebox.title:GetRegionSize() / 2 + 40, -8, 0)

	self.mainui.achievement_bg.coinamount = self.mainui.achievement_bg.titlebox.title:AddChild(Text(NUMBERFONT, 35, self.owner.currentcoinamount:value()))
	self.mainui.achievement_bg.coinamount:SetPosition(0, -38, 0)

	self.mainui.achievement_bg.star = self.mainui.achievement_bg.titlebox.title:AddChild(Image("images/hud/star.xml", "star.tex"))
	self.mainui.achievement_bg.star:SetPosition(50, -38, 0)

	self.mainui.achievement_bg.close = self.mainui.achievement_bg:AddChild(ImageButton("images/hud/close_button.xml", "close_button.tex"))
	self.mainui.achievement_bg.close:SetPosition(550, 450, 0)
	self.mainui.achievement_bg.close:SetOnClick(function()
		self:hideAll()
	end)

	self.mainui.achievement_bg.reset = self.mainui.achievement_bg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.achievement_bg.reset:SetPosition(450, 385, 0)
	self.mainui.achievement_bg.reset:SetOnClick(function()
		self.mainui.resetperk_bg:Show()
		self.mainui.resetperk_bg:MoveToFront()
	end)
	self.mainui.achievement_bg.reset.label = self.mainui.achievement_bg.reset:AddChild(Text(BUTTONFONT, 35))
	self.mainui.achievement_bg.reset.label:SetMultilineTruncatedString(STRINGS.GUI["resetR"], 1, 100, 50, "", true)
	self.mainui.achievement_bg.reset.label:SetColour(0,0,0,1)

	self.achpage = 1
	self.mainui.achievement_bg.achnav = self.mainui:AddChild(Widget("achnav"))
	self.mainui.achievement_bg.achnav:SetPosition(0, 370, 0)
	local nav = self.mainui.achievement_bg.achnav
	nav.previous = nav:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	nav.previous:SetPosition(-445, 0, 0)
	nav.previous:SetOnClick(function()
		self.achpage = math.max(1, self.achpage - 1)
		self:build()
	end)
	nav.previous.label = nav.previous:AddChild(Text(BUTTONFONT, 28, "<"))
	nav.previous.label:SetColour(0, 0, 0, 1)
	nav.next = nav:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	nav.next:SetPosition(445, 0, 0)
	nav.next:SetOnClick(function()
		self.achpage = math.min(AchievementPages.PageCount(UIData.ach_tab[self.numpage]), self.achpage + 1)
		self:build()
	end)
	nav.next.label = nav.next:AddChild(Text(BUTTONFONT, 28, ">"))
	nav.next.label:SetColour(0, 0, 0, 1)
	nav.page = nav:AddChild(Text(BUTTONFONT, 28))
	nav.page:SetPosition(-280, 0, 0)
	nav:Hide()

	--self.mainui.achievement_bg.sort = self.mainui.achievement_bg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	--self.mainui.achievement_bg.sort:SetPosition(450, 385, 0)
	--self.mainui.achievement_bg.sort:SetOnClick(function()
	--	if UIData == UIData1 then
	--		UIData = UIData2
	--	else
	--		UIData = UIData1
	--	end
	--	self:hideAll()
	--	self.mainui.allachiv:Show()
	--	self.mainui.achievement_bg:Show()
	--	self.mainui.achievement_bg.sort:Show()
	--	self.mainui.ach_cat:Show()
	--	self.mainui.achievement_bg.titlebox.title:SetString(STRINGS.GUI["achievementTitle"])
	--	self.mainui.achievement_bg.titlebox.icon:SetPosition(self.mainui.achievement_bg.titlebox.title:GetRegionSize() / 2 + 20, 0, 0)
	--	self.mainui.achievement_bg.titlebox.icon:SetHoverText(STRINGS.GUI["achievementInfo"],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
	--	self:setAllAchivCategoriesActive()
	--	local _numpage = tostring(self.numpage)
	--	self.mainui.ach_cat["cat".._numpage]:Disable()
	--	self.mainui.ach_cat["cat".._numpage].image:SetScale(1,1,1)
	--end)
	--self.mainui.achievement_bg.sort.label = self.mainui.achievement_bg.sort:AddChild(Text(BUTTONFONT, 35))
	--self.mainui.achievement_bg.sort.label:SetMultilineTruncatedString(STRINGS.GUI["sort"], 1, 100, 50, "", true)
	--self.mainui.achievement_bg.sort.label:SetColour(0,0,0,1)

	-- # window items
	self.mainui.allachiv = self.mainui:AddChild(Widget("allachiv"))
	self.mainui.allachiv:SetPosition(0, 460, 0)
	self.mainui.allachiv:Hide()

	self.mainui.allcoin = self.mainui:AddChild(Widget("allcoin"))
	self.mainui.allcoin:SetPosition(0, 460, 0)
	self.mainui.allcoin:Hide()

	self.mainui.alltask = self.mainui:AddChild(Widget("alltask"))
	self.mainui.alltask:SetPosition(0, 460, 0)
	self.mainui.alltask:Hide()

	-- # reset functionality
	self.mainui.resetperk_bg = self.mainui:AddChild(Image("images/hud/small_bg.xml", "small_bg.tex"))
	self.mainui.resetperk_bg:SetPosition(445, -180, 0)
	self.mainui.resetperk_bg:Hide()
	self.mainui.resetperk_bg.label = self.mainui.resetperk_bg:AddChild(Text(CHATFONT, 28))
	self.mainui.resetperk_bg.label:SetPosition(0, 40, 0)
	self.mainui.resetperk_bg.label:SetColour(0,0,0,1)
	self.mainui.resetperk_bg.label:SetMultilineTruncatedString(STRINGS.GUI["resetinfo"], 5, 380, 500, "", true)

	self.mainui.resetperk_bg.removeyes = self.mainui.resetperk_bg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.resetperk_bg.removeyes:SetPosition(-130, -90, 0)
	self.mainui.resetperk_bg.removeyes:SetOnClick(function()
		self:hideAll()
		SendModRPCToServer(MOD_RPC["AchievementUI"]["removecoin"])
		self.owner:DoTaskInTime(.35, function()
			self:perk_build()
		end)
	end)
	self.mainui.resetperk_bg.removeyes.label = self.mainui.resetperk_bg.removeyes:AddChild(Text(BUTTONFONT, 27))
	self.mainui.resetperk_bg.removeyes.label:SetMultilineTruncatedString(STRINGS.GUI["reset"], 1, 70, 50, "", true)
	self.mainui.resetperk_bg.removeyes.label:SetColour(0,0,0,1)

	self.mainui.resetperk_bg.removeno = self.mainui.resetperk_bg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.resetperk_bg.removeno:SetPosition(130, -90, 0)
	self.mainui.resetperk_bg.removeno:SetNormalScale(1,1,1)
	self.mainui.resetperk_bg.removeno:SetOnClick(function()
		self.mainui.resetperk_bg:Hide()
	end)
	self.mainui.resetperk_bg.removeno.label = self.mainui.resetperk_bg.removeno:AddChild(Text(BUTTONFONT, 27))
	self.mainui.resetperk_bg.removeno.label:SetMultilineTruncatedString(STRINGS.GUI["close"], 1, 70, 50, "", true)
	self.mainui.resetperk_bg.removeno.label:SetColour(0,0,0,1)

	-- # Main UI Components
	self.mainbutton = self:AddChild(Widget("mainbutton"))
	self.mainbutton:SetHAnchor(ANCHOR_LEFT)
	self.mainbutton:SetVAnchor(ANCHOR_TOP)
	self.mainbutton:MoveToBack()
	self.mainbutton:SetPosition(0, 5, 0)

	local dragging = false
	self.mainbutton.OnMouseButton = function(inst, button, down, x, y)
		if button == 1001 then
			if down then
				dragging = true
				local mousepos = TheInput:GetScreenPosition()
				self.dragPosDiff = self.mainbutton:GetPosition() - mousepos
			else
				dragging = false
			end
		end
	end
	self.followhandler = TheInput:AddMoveHandler(function(x,y)
		if dragging then
			local _,h = self.mainbutton.bg:GetSize()
			local margin = 20
			local threshold = h*self.mainbutton.bg:GetScale().y
			local _, screenh_full = _G.unpack({_G.TheSim:GetScreenSize()})
			if y < screenh_full-threshold-margin then dragging = false end
			local pos
			if type(x) == "number" then
				pos = Vector3(x, y, 1)
			else
				pos = x
			end
			SendModRPCToServer(MOD_RPC["AchievementUI"]["saveWidgetXPos"],pos.x + self.dragPosDiff.x)
		end
	end)

	-- # MAIN UI BG
	self.mainbutton.bg = self.mainbutton:AddChild(Image("images/hud/main/main_bg.xml", "main_bg.tex"))
	self.mainbutton.bg:MoveToFront()
	self.mainbutton.bg:SetClickable(true)
	self.mainbutton.bg:SetHRegPoint(ANCHOR_LEFT)
	self.mainbutton.bg:SetVRegPoint(ANCHOR_TOP)

	-- # XP BAR
	self.mainbutton.xpbar_filled = self.mainbutton:AddChild(Image("images/hud/main/main_bar_fill.xml", "main_bar_fill.tex"))
	self.mainbutton.xpbar_filled:MoveToFront()
	self.mainbutton.xpbar_filled:SetHRegPoint(ANCHOR_LEFT)
	self.mainbutton.xpbar_filled:SetPosition(23, -100, 0)
	self.mainbutton.xpbar_filled:MoveToBack()

	-- # LEVEL BUTTON
	self.mainbutton.levelbutton = self.mainbutton:AddChild(ImageButton("images/hud/main/main_level_button.xml", "main_level_button.tex"))
	self.mainbutton.levelbutton:MoveToFront()
	self.mainbutton.levelbutton:SetPosition(118, -125, 0)
	self.mainbutton.levelbutton:SetHoverText(STRINGS.GUI["viewL"],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
	self.mainbutton.levelbutton:SetOnClick(function()
		if self.mainui.levelbg.shown then
			self:hideAll()
		else
			self:hideAll()
			self.mainui.levelbg:Show()
		end
	end)

	-- # ACHIEVEMENT BUTTON
	self.mainbutton.achievementbutton = self.mainbutton:AddChild(ImageButton("images/hud/main/main_ach_button.xml", "main_ach_button.tex"))
	self.mainbutton.achievementbutton:MoveToFront()
	self.mainbutton.achievementbutton:SetHoverText(STRINGS.GUI["viewA"],{ size = 9, offset_x = 90, offset_y = -55, colour = {1,1,1,1}})
	self.mainbutton.achievementbutton:SetPosition(49, -50, 0)
	self.mainbutton.achievementbutton:SetOnClick(function()
		if self.mainui.allachiv.shown then
			self:hideAll()
		else
			self:hideAll()
			self.mainui.allachiv:Show()
			self.mainui.achievement_bg:Show()
			self:build()
			--self.mainui.achievement_bg.sort:Show()
			self.mainui.ach_cat:Show()
			self.mainui.achievement_bg.titlebox.title:SetString(STRINGS.GUI["achievementTitle"])
			self.mainui.achievement_bg.titlebox.icon:SetPosition(self.mainui.achievement_bg.titlebox.title:GetRegionSize() / 2 + 20, 0, 0)
			self.mainui.achievement_bg.titlebox.icon:SetHoverText(STRINGS.GUI["achievementInfo"],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
		end
		self:setAllAchivCategoriesActive()
		local _numpage = tostring(self.numpage)
		self.mainui.ach_cat["cat".._numpage]:Disable()
		self.mainui.ach_cat["cat".._numpage].image:SetScale(1,1,1)
	end)

	-- # REWARD BUTTON
	self.mainbutton.perkbutton = self.mainbutton:AddChild(ImageButton("images/hud/main/main_perk_button.xml", "main_perk_button.tex"))
	self.mainbutton.perkbutton:MoveToFront()
	self.mainbutton.perkbutton:SetPosition(118, -50, 0)
	self.mainbutton.perkbutton:SetHoverText(STRINGS.GUI["viewR"],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
	self.mainbutton.perkbutton:SetOnClick(function()
		if self.mainui.allcoin.shown then
			self:hideAll()
		else
			self:hideAll()
			self.mainui.allcoin:Show()
			self.mainui.achievement_bg:Show()
			self.mainui.achievement_bg.reset:Show()
			self.mainui.perk_cat:Show()
			local name = UIData.perk_tab[self.perkpage].name
			self.mainui.achievement_bg.titlebox.title:SetString("Đặc quyền: " .. STRINGS.GUI[name])
			self.mainui.achievement_bg.titlebox.icon:SetPosition(self.mainui.achievement_bg.titlebox.title:GetRegionSize() / 2 + 20, 0, 0)
			self.mainui.achievement_bg.titlebox.icon:SetHoverText(STRINGS.GUI["perkInfo-"..name],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
		end
		self:setAllPerkCategoriesActive()
		local _perkpage = tostring(self.perkpage)
		self.mainui.perk_cat["perkcat".._perkpage]:Disable()
		self.mainui.perk_cat["perkcat".._perkpage].image:SetScale(1,1,1)
	end)

	-- # TASK BUTTON
	self.mainbutton.taskbutton = self.mainbutton:AddChild(ImageButton("images/hud/main/main_task_button.xml", "main_task_button.tex"))
	self.mainbutton.taskbutton:MoveToFront()
	self.mainbutton.taskbutton:SetPosition(187, -50, 0)
	self.mainbutton.taskbutton:SetHoverText(STRINGS.GUI["viewT"],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
	self.mainbutton.taskbutton:SetOnClick(function()
		if self.mainui.alltask.shown then
			self:hideAll()
		else
			self:hideAll()
			self.mainui.alltask:Show()
			self.mainui.achievement_bg:Show()
			local round = self.owner.seasonalround and self.owner.seasonalround:value() or 1
			self.mainui.achievement_bg.titlebox.title:SetString(STRINGS.GUI["taskTitle"] .. " - " .. string.format(STRINGS.GUI["taskRound"], round))
			self.mainui.achievement_bg.titlebox.icon:SetPosition(self.mainui.achievement_bg.titlebox.title:GetRegionSize() / 2 + 20, 0, 0)
			self.mainui.achievement_bg.titlebox.icon:SetHoverText(STRINGS.GUI["taskInfo"],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
		end
	end)

	-- # Config button
	self.mainbutton.configact = self.mainbutton:AddChild(ImageButton("images/hud/main/main_setting_button.xml", "main_setting_button.tex"))
	self.mainbutton.configact:SetPosition(249, -21, 0)
	self.mainbutton.configact:SetFocusScale(1.05,1.05,1)
	self.mainbutton.configact:SetHoverText(STRINGS.GUI["set"],{ size = 9, offset_x = 0, offset_y = -55, colour = {1,1,1,1}})
	self.mainbutton.configact:SetOnClick(function()
		if self.mainbutton.configs.shown then
			self.mainbutton.configs:Hide()
			if self.mainbutton.guidebutton then
				local startingpos = self.mainbutton.guidebutton:GetPosition()
				self.mainbutton.guidebutton:SetPosition(startingpos.x, -40, 0)
			end
		else
			self.mainbutton.configs:Show()
			if self.mainbutton.guidebutton then
				local startingpos = self.mainbutton.guidebutton:GetPosition()
				self.mainbutton.guidebutton:SetPosition(startingpos.x, -75, 0)
			end
		end
		self.mainui.resetperk_bg:Hide()
		self.mainui.resetlevel_bg:Hide()
	end)

	self.mainbutton.configs = self.mainbutton:AddChild(Widget("configs"))
	self.mainbutton.configs:SetPosition(272, -20, 0)
	self.mainbutton.configs:MoveToBack()
	self.mainbutton.configs:Hide()

	self.mainbutton.configs.bg = self.mainbutton.configs:AddChild(Image("images/hud/main/main_zoom_bg.xml", "main_zoom_bg.tex"))
	self.mainbutton.configs.bg:SetPosition(0, 0, 0)
	self.mainbutton.configs.bg:SetHRegPoint(ANCHOR_LEFT)
	self.mainbutton.configs.bg:SetClickable(false)

	self.size = self.owner.currentzoomlevel:value() or 0.5
	self.mainui:SetScale(self.size - 0.1, self.size - 0.1, 1)
	self.mainbutton.configbigger = self.mainbutton.configs:AddChild(ImageButton("images/hud/main/main_zoom_button_2.xml", "main_zoom_button_2.tex"))
	self.mainbutton.configbigger:SetPosition(17, 0, 0)
	self.mainbutton.configbigger:SetFocusScale(1.05,1.05,1)
	self.mainbutton.configbigger:SetHoverText(STRINGS.GUI["zoomI"],{ size = 9, offset_x = 0, offset_y = -55, colour = {1,1,1,1}})
	self.mainbutton.configbigger:SetOnClick(function()
		if not self.mainui.achievement_bg.shown and not self.mainui.levelbg.shown then
			self.mainui.allachiv:Show()
			self.mainui.achievement_bg:Show()
			self.mainui.ach_cat:Show()
			self.mainui.achievement_bg.titlebox.title:SetString(STRINGS.GUI["achievementTitle"])
			self.mainui.achievement_bg.titlebox.icon:SetPosition(self.mainui.achievement_bg.titlebox.title:GetRegionSize() / 2 + 20, 0, 0)
			self.mainui.achievement_bg.titlebox.icon:SetHoverText(STRINGS.GUI["achievementInfo"],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
		end
		self.size = self.size + .02
		SendModRPCToServer(MOD_RPC["AchievementUI"]["saveZoomlevel"],self.size)
	end)

	self.mainbutton.configsmaller = self.mainbutton.configs:AddChild(ImageButton("images/hud/main/main_zoom_button_1.xml", "main_zoom_button_1.tex"))
	self.mainbutton.configsmaller:SetPosition(46, 0, 0)
	self.mainbutton.configsmaller:SetFocusScale(1.05,1.05,1)
	self.mainbutton.configsmaller:SetHoverText(STRINGS.GUI["zoomO"],{ size = 9, offset_x = 0, offset_y = -55, colour = {1,1,1,1}})
	self.mainbutton.configsmaller:SetOnClick(function()
		if not self.mainui.achievement_bg.shown and not self.mainui.levelbg.shown then
			self.mainui.allachiv:Show()
			self.mainui.achievement_bg:Show()
			self.mainui.ach_cat:Show()
			self.mainui.achievement_bg.titlebox.title:SetString(STRINGS.GUI["achievementTitle"])
			self.mainui.achievement_bg.titlebox.icon:SetPosition(self.mainui.achievement_bg.titlebox.title:GetRegionSize() / 2 + 20, 0, 0)
			self.mainui.achievement_bg.titlebox.icon:SetHoverText(STRINGS.GUI["achievementInfo"],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
		end
		if self.size > .02 then
			self.size = self.size - .02
		end
		SendModRPCToServer(MOD_RPC["AchievementUI"]["saveZoomlevel"],self.size)
	end)

	self.mainbutton.configminimize = self.mainbutton.configs:AddChild(ImageButton("images/hud/main/main_minimize_button.xml", "main_minimize_button.tex"))
	self.mainbutton.configminimize:SetPosition(75, 0, 0)
	self.mainbutton.configminimize:SetFocusScale(1.05,1.05,1)
	self.mainbutton.configminimize:SetHoverText(STRINGS.GUI["minim"],{ size = 9, offset_x = 0, offset_y = -55, colour = {1,1,1,1}})
	self.mainbutton.configminimize:SetOnClick(function()
		SendModRPCToServer(MOD_RPC["AchievementUI"]["saveMainHudType"])
	end)

	-- Trinket slot
	if not UIData.ui_hidden_list.trinketowner then
		self.mainbutton.trinket = self.mainbutton:AddChild(Image("images/hud/main/main_trinket_2.xml", "main_trinket_2.tex"))
		self.mainbutton.trinket:SetPosition(-20, -40, 0)
		self.mainbutton.trinket:MoveToBack()
		self.mainbutton.trinket:Hide()
	end

	-- Active Skill
	self.mainbutton.activeskills = self.mainbutton:AddChild(Widget("activeskills"))
	self.mainbutton.activeskills:SetPosition(118, -158, 0)
	self.mainbutton.activeskills:MoveToBack()

	self.mainbutton.activeskills.activeskillbutton = self.mainbutton.activeskills:AddChild(ImageButton("images/hud/main/main_bg_down_2.xml", "main_bg_down_2.tex"))
	self.mainbutton.activeskills.activeskillbutton:SetPosition(0, 0, 0)
	self.mainbutton.activeskills.activeskillbutton:SetFocusScale(1,1.1,1)
	self.mainbutton.activeskills.activeskillbutton:MoveToFront()
	self.mainbutton.activeskills.activeskillbutton:SetOnClick(function()
		local startingpos = self.mainbutton.activeskills:GetPosition()
		local isminimalist = self.owner.currentmainhudtype:value() == true
		local closey = -158 + (isminimalist and 78 or 0)
		local openy = (-170  + (isminimalist and 78 or 0)) - self.activeskillcount * 70
		if startingpos.y > closey - 5 then
			self.mainbutton.activeskills:MoveTo(Vector3(startingpos.x, startingpos.y, 0), Vector3(startingpos.x, openy, 0), 1)
		else
			self.mainbutton.activeskills:MoveTo(Vector3(startingpos.x, startingpos.y, 0), Vector3(startingpos.x, closey, 0), 1)
		end
	end)

	self.mainbutton.activeskills.bg = self.mainbutton.activeskills:AddChild(Image("images/hud/main/main_bg_down_1.xml", "main_bg_down_1.tex"))
	self.mainbutton.activeskills.bg:SetPosition(0, 90, 0)
	self.mainbutton.activeskills.bg:MoveToBack()

	self.mainbutton.activeskills.bg2 = self.mainbutton.activeskills:AddChild(Image("images/hud/main/main_bg_down_1.xml", "main_bg_down_1.tex"))
	self.mainbutton.activeskills.bg2:SetPosition(0, 180, 0)
	self.mainbutton.activeskills.bg2:MoveToBack()

	-- Woodie UI
	if not UIData.ui_hidden_list.expertwoodie1 then
		local woodieskills = {
			{ child = "goose", atlas = "images/hud/goose_button.xml", tex = "goose_button.tex", scale = 0.3, fn = function() SendModRPCToServer(MOD_RPC["Woodie_Mod"]["goose_button"]) end },
			{ child = "beaver", atlas = "images/hud/beaver_button.xml", tex = "beaver_button.tex", scale = 0.3, fn = function() SendModRPCToServer(MOD_RPC["Woodie_Mod"]["beaver_button"]) end},
			{ child = "moose", atlas = "images/hud/moose_button.xml", tex = "moose_button.tex", scale = 0.3, fn = function() SendModRPCToServer(MOD_RPC["Woodie_Mod"]["moose_button"]) end },
		}
		self.mainbutton.activeskills.werehud = self.mainbutton.activeskills:AddChild(Widget("werehud"))
		self.mainbutton.activeskills.werehud:Hide()
		self:build_activeskills(self.mainbutton.activeskills.werehud, woodieskills, 10)

		self.mainbutton.activeskills.werehud.goose.cd = self.mainbutton.activeskills.werehud.goose:AddChild(UIAnim())
		self.mainbutton.activeskills.werehud.goose.cd:GetAnimState():SetBank("recharge_meter")
		self.mainbutton.activeskills.werehud.goose.cd:GetAnimState():SetBuild("recharge_meter")
		self.mainbutton.activeskills.werehud.goose.cd:GetAnimState():SetMultColour(0, 0, 0, 0.5)
		self.mainbutton.activeskills.werehud.goose.cd:GetAnimState():AnimateWhilePaused(false)
		self.mainbutton.activeskills.werehud.goose.cd:SetScale(3,3)
		self.mainbutton.activeskills.werehud.goose.cd:SetClickable(false)
		self.mainbutton.activeskills.werehud.goose.cd:Hide()

		self.mainbutton.activeskills.werehud.beaver.cd = self.mainbutton.activeskills.werehud.beaver:AddChild(UIAnim())
		self.mainbutton.activeskills.werehud.beaver.cd:GetAnimState():SetBank("recharge_meter")
		self.mainbutton.activeskills.werehud.beaver.cd:GetAnimState():SetBuild("recharge_meter")
		self.mainbutton.activeskills.werehud.beaver.cd:GetAnimState():SetMultColour(0, 0, 0, 0.5)
		self.mainbutton.activeskills.werehud.beaver.cd:GetAnimState():AnimateWhilePaused(false)
		self.mainbutton.activeskills.werehud.beaver.cd:SetScale(3,3)
		self.mainbutton.activeskills.werehud.beaver.cd:SetClickable(false)
		self.mainbutton.activeskills.werehud.beaver.cd:Hide()

		self.mainbutton.activeskills.werehud.moose.cd = self.mainbutton.activeskills.werehud.moose:AddChild(UIAnim())
		self.mainbutton.activeskills.werehud.moose.cd:GetAnimState():SetBank("recharge_meter")
		self.mainbutton.activeskills.werehud.moose.cd:GetAnimState():SetBuild("recharge_meter")
		self.mainbutton.activeskills.werehud.moose.cd:GetAnimState():SetMultColour(0, 0, 0, 0.5)
		self.mainbutton.activeskills.werehud.moose.cd:GetAnimState():AnimateWhilePaused(false)
		self.mainbutton.activeskills.werehud.moose.cd:SetScale(3,3)
		self.mainbutton.activeskills.werehud.moose.cd:SetClickable(false)
		self.mainbutton.activeskills.werehud.moose.cd:Hide()

		self.werecd = {}
		self.werecd["goose"] = self.owner.net_goosecd and (1 - self.owner.net_goosecd:value()) * TUNING.EXPERT_WOODIE1_COOLDOWN.goose or 0
		self.werecd["beaver"] = self.owner.net_beavercd and (1 - self.owner.net_beavercd:value()) * TUNING.EXPERT_WOODIE1_COOLDOWN.beaver or 0
		self.werecd["moose"] = self.owner.net_moosecd and (1 - self.owner.net_moosecd:value()) * TUNING.EXPERT_WOODIE1_COOLDOWN.moose or 0
		self.owner:ListenForEvent("goosecddirty", function(inst)
			self.werecd["goose"] = (1 - self.owner.net_goosecd:value()) * TUNING.EXPERT_WOODIE1_COOLDOWN.goose
		end)
		self.owner:ListenForEvent("beavercddirty", function(inst)
			self.werecd["beaver"] = (1 - self.owner.net_beavercd:value()) * TUNING.EXPERT_WOODIE1_COOLDOWN.beaver
		end)
		self.owner:ListenForEvent("moosecddirty", function(inst)
			self.werecd["moose"] = (1 - self.owner.net_moosecd:value()) * TUNING.EXPERT_WOODIE1_COOLDOWN.moose
		end)
	end
	-- Woodie UI END

	-- Wendy UI
	if not UIData.ui_hidden_list.expertwendy3 then
		local wendyskills = {
			{ child = "near", atlas = "images/hud/sisturn_button1.xml", tex = "sisturn_button1.tex", scale = .5, fn = function() SendModRPCToServer(MOD_RPC["Wendy_Mod"]["sisturn_button"]) end },
			{ child = "far", atlas = "images/hud/sisturn_button2.xml", tex = "sisturn_button2.tex", scale = .5, fn = function() SendModRPCToServer(MOD_RPC["Wendy_Mod"]["sisturn_buttonfar"]) end },
		}
		self.mainbutton.activeskills.wendyhud = self.mainbutton.activeskills:AddChild(Widget("wendyhud"))
		self.mainbutton.activeskills.wendyhud:Hide()
		self:build_activeskills(self.mainbutton.activeskills.wendyhud, wendyskills, 15, true)
	end
	-- Wendy UI END

	-- EXTRA ACTIVE SKILL UI
	local extraskills = {
		{ child = "sharemap", atlas = "images/hud/activeskill/perk_map.xml", tex = "perk_map.tex", scale = .6, fn = function() SendModRPCToServer(MOD_RPC["Active_Perk"]["sharemap"]) end },
	}
	self.mainbutton.activeskills.extraskills = self.mainbutton.activeskills:AddChild(Widget("extraskills"))
	self.mainbutton.activeskills.extraskills:Show()
	self:build_activeskills(self.mainbutton.activeskills.extraskills, extraskills, 15)
	-- EXTRA END

	-- GUIDE START
	local guideimage = softresolvefilepath("images/chasniclient/guide/guide-button.xml")
	if guideimage and TheSim:AtlasContains(guideimage, "guide-button.tex") then
		self.mainbutton.guidebutton = self.mainbutton:AddChild(ImageButton("images/chasniclient/guide/guide-button.xml", "guide-button.tex"))
		self.mainbutton.guidebutton:SetPosition(330, -40, 0)
		self.mainbutton.guidebutton:SetScale(0.7, 0.7)
		self.mainbutton.guidebutton:MoveToFront()
		self.mainbutton.guidebutton:SetOnClick(function()
			local guide_main_page = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls
					and ThePlayer.HUD.controls.chasni_guide
					and ThePlayer.HUD.controls.chasni_guide.main_guide
					and ThePlayer.HUD.controls.chasni_guide.main_guide.main_page
			if guide_main_page then
				if guide_main_page.shown then
					guide_main_page:Hide()
				else
					guide_main_page:Show()
				end
			end
		end)
	end
	-- GUIDE END

	self.mainui.ach_cat = self.mainui:AddChild(Widget("ach_cat"))
	self.mainui.ach_cat:SetPosition(0, 85, 0)
	self.mainui.ach_cat:Hide()

	self.mainui.perk_cat = self.mainui:AddChild(Widget("perk_cat"))
	self.mainui.perk_cat:SetPosition(0, 85, 0)
	self.mainui.perk_cat:Hide()

	--Main Tab Buttons
	local first_row_count = math.min(8, #UIData.ach_tab)
	local second_row_count = #UIData.ach_tab - first_row_count
	for i = 1, #UIData.ach_tab do
		local first_row = i <= first_row_count
		local index = first_row and i or i - first_row_count
		local count = first_row and first_row_count or second_row_count
		self:initAchCategory(i, UIData.ach_tab[i].name, CenteredTabX(index, count, 135), first_row and -453 or -510)
	end

	for i = 1, #UIData.perk_tab  do
		self:initPerkCategory(i, UIData.perk_tab[i].name, CenteredTabX(i, #UIData.perk_tab, 140), -515)
	end

	-- Level MainPage
	self.mainui.levelbg.xpbar_filled = self.mainui.levelbg:AddChild(Image("images/hud/level/level_bar_fill.xml", "level_bar_fill.tex"))
	self.mainui.levelbg.xpbar_filled:SetHRegPoint(ANCHOR_LEFT)
	self.mainui.levelbg.xpbar_filled:SetPosition(-218, 157, 0)

	self.mainui.levelbg.levelxp = self.mainui.levelbg:AddChild(Text(CHATFONT, 33))
	self.mainui.levelbg.levelxp:SetPosition(10, 154, 0)
	self.mainui.levelbg.levelxp:SetHAlign(ANCHOR_MIDDLE)

	self.mainui.levelbg.overallxp = self.mainui.levelbg:AddChild(Text(CHATFONT, 29))
	self.mainui.levelbg.overallxp:SetPosition(200, 207, 0)
	self.mainui.levelbg.overallxp:SetHAlign(ANCHOR_RIGHT)

	self.mainui.levelbg.freepoints = self.mainui.levelbg:AddChild(Text(CHATFONT, 29))
	self.mainui.levelbg.freepoints:SetPosition(-85, 207, 0)
	self.mainui.levelbg.freepoints:SetHAlign(ANCHOR_LEFT)

	self.mainui.levelbg.levelbutton = self.mainui.levelbg:AddChild(Image("images/hud/level/level_bar.xml", "level_bar.tex"))
	self.mainui.levelbg.levelbutton:SetPosition(0, 155, 0)
	self.mainui.levelbg.level = self.mainui.levelbg.levelbutton:AddChild(Text(CHATFONT_OUTLINE, 65))
	self.mainui.levelbg.level:SetPosition(-250, -3, 0)
	self.mainui.levelbg.level:SetHAlign(ANCHOR_MIDDLE)

	self.mainui.levelbg.costheader = self.mainui.levelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.levelbg.costheader:SetPosition(200, 80, 0)
	self.mainui.levelbg.costheader:SetHAlign(ANCHOR_MIDDLE)
	self.mainui.levelbg.costheader:SetString(STRINGS.GUI["attributecost"])

	self.mainui.levelbg.costs = self.mainui.levelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.levelbg.costs:SetPosition(200, -58, 0)
	self.mainui.levelbg.costs:SetHAlign(ANCHOR_MIDDLE)

	self.mainui.levelbg.currentheader = self.mainui.levelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.levelbg.currentheader:SetPosition(295, 80, 0)
	self.mainui.levelbg.currentheader:SetHAlign(ANCHOR_MIDDLE)
	self.mainui.levelbg.currentheader:SetString(STRINGS.GUI["attributecurrent"])

	self.mainui.levelbg.currents = self.mainui.levelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.levelbg.currents:SetPosition(295, -58, 0)
	self.mainui.levelbg.currents:SetHAlign(ANCHOR_MIDDLE)

	self.mainui.levelbg.attributelabels = self.mainui.levelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.levelbg.attributelabels:SetPosition(-280, -58, 0)
	self.mainui.levelbg.attributelabels:SetHAlign(ANCHOR_RIGHT)
	self.mainui.levelbg.attributelabels:SetString(STRINGS.GUI["attributelabels"])

	self.mainui.levelbg.attributelevels = self.mainui.levelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.levelbg.attributelevels:SetPosition(-155, -58, 0)
	self.mainui.levelbg.attributelevels:SetHAlign(ANCHOR_RIGHT)

	self.mainui.levelbg.attributeunits = self.mainui.levelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.levelbg.attributeunits:SetPosition(-115, -58, 0)
	self.mainui.levelbg.attributeunits:SetHAlign(ANCHOR_RIGHT)
	self.mainui.levelbg.attributeunits:SetString(STRINGS.GUI["attributeunits"])

	self.mainui.levelbg.reset = self.mainui.levelbg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.levelbg.reset:SetPosition(240, 280, 0)
	self.mainui.levelbg.reset:SetOnClick(function()
		self.mainui.resetlevel_bg:Show()
		self.mainui.resetlevel_bg:MoveToFront()
	end)
	self.mainui.levelbg.reset.label = self.mainui.levelbg.reset:AddChild(Text(BUTTONFONT, 35))
	self.mainui.levelbg.reset.label:SetMultilineTruncatedString(STRINGS.GUI["resetL"], 1, 100, 50, "", true)
	self.mainui.levelbg.reset.label:SetColour(0,0,0,1)

	self.mainui.levelbg.levelswitch = self.mainui.levelbg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.levelbg.levelswitch:SetPosition(240, -310, 0)
	self.mainui.levelbg.levelswitch:SetOnClick(function()
		self:hideAll()
		self.mainui.petlevelbg:Show()
	end)
	self.mainui.levelbg.levelswitch.label = self.mainui.levelbg.levelswitch:AddChild(Text(BUTTONFONT, 35))
	self.mainui.levelbg.levelswitch.label:SetMultilineTruncatedString(STRINGS.GUI["levelPet"], 1, 100, 50, "", true)
	self.mainui.levelbg.levelswitch.label:SetColour(0,0,0,1)

	self.mainui.resetlevel_bg = self.mainui:AddChild(Image("images/hud/small_bg.xml", "small_bg.tex"))
	self.mainui.resetlevel_bg:SetPosition(445, -180, 0)
	self.mainui.resetlevel_bg:Hide()
	self.mainui.resetlevel_bg.label = self.mainui.resetlevel_bg:AddChild(Text(CHATFONT, 28))
	self.mainui.resetlevel_bg.label:SetPosition(0, 40, 0)
	self.mainui.resetlevel_bg.label:SetColour(0,0,0,1)
	self.mainui.resetlevel_bg.label:SetMultilineTruncatedString(STRINGS.GUI["resetinfo"], 5, 380, 500, "", true)

	self.mainui.resetlevel_bg.removeyes = self.mainui.resetlevel_bg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.resetlevel_bg.removeyes:SetPosition(-130, -90, 0)
	self.mainui.resetlevel_bg.removeyes:SetOnClick(function()
		SendModRPCToServer(MOD_RPC["AchievementUI"]["removeattribute"])
		self.mainui.resetlevel_bg:Hide()
		self.mainui.levelbg:Hide()
	end)
	self.mainui.resetlevel_bg.removeyes.label = self.mainui.resetlevel_bg.removeyes:AddChild(Text(BUTTONFONT, 28))
	self.mainui.resetlevel_bg.removeyes.label:SetMultilineTruncatedString(STRINGS.GUI["reset"], 1, 70, 50, "", true)
	self.mainui.resetlevel_bg.removeyes.label:SetColour(0,0,0,1)

	self.mainui.resetlevel_bg.removeno = self.mainui.resetlevel_bg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.resetlevel_bg.removeno:SetPosition(130, -90, 0)
	self.mainui.resetlevel_bg.removeno:SetOnClick(function()
		self.mainui.resetlevel_bg:Hide()
	end)

	self.mainui.resetlevel_bg.removeno.label = self.mainui.resetlevel_bg.removeno:AddChild(Text(BUTTONFONT, 28))
	self.mainui.resetlevel_bg.removeno.label:SetMultilineTruncatedString(STRINGS.GUI["close"], 1, 70, 50, "", true)
	self.mainui.resetlevel_bg.removeno.label:SetColour(0,0,0,1)

	self.mainui.levelbg.close = self.mainui.levelbg:AddChild(ImageButton("images/hud/close_button.xml", "close_button.tex"))
	self.mainui.levelbg.close:SetPosition(370, 350, 0)
	self.mainui.levelbg.close:SetOnClick(function()
		self:hideAll()
	end)

	self.mainui.levelbg.description = self.mainui.levelbg:AddChild(Text(CHATFONT, 24))
	self.mainui.levelbg.description:SetPosition(0, -245, 0)
	self.mainui.levelbg.description:SetHAlign(ANCHOR_MIDDLE)
	self.mainui.levelbg.description:SetMultilineTruncatedString(STRINGS.GUI["levelinfo"], 2, 900, 500, "", true)

	self.mainui.levelbg.levelupbuttons = self.mainui.levelbg:AddChild(Widget("levelupbuttons"))
	self.mainui.levelbg.levelupbuttons:SetPosition(180, 82, 0)

	self:initlevelupButton("hunger", "x1", "hungerlevel", -210, -48, "+"..hungerGain)
	self:initlevelupButton("sanity", "x1", "sanitylevel", -210, -83, "+"..sanityGain)
	self:initlevelupButton("health", "x1", "healthlevel", -210, -118, "+"..healthGain, self.owner.prefab == "wanda")
	self:initlevelupButton("damage", "x1", "damagelevel", -210, -153, "+"..damageGain*100 .."%")
	self:initlevelupButton("absorb", "x1", "absorblevel", -210, -188, "+"..absorbGain*100 .."%")
	self:initlevelupButton("speed", "x1", "speedlevel", -210, -223, "+"..speedGain*100 .."%")

	self:initlevelupButton("hunger10", "x10", "hungerlevel10", -135, -48, "+"..hungerGain*10)
	self:initlevelupButton("sanity10", "x10", "sanitylevel10", -135, -83, "+"..sanityGain*10)
	self:initlevelupButton("health10", "x10", "healthlevel10", -135, -118, "+"..healthGain*10, self.owner.prefab == "wanda")
	self:initlevelupButton("damage10", "x10", "damagelevel10", -135, -153, "+"..damageGain*1000 .."%")
	self:initlevelupButton("absorb10", "x10", "absorblevel10", -135, -188, "+"..absorbGain*1000 .."%")
	self:initlevelupButton("speed10", "x10", "speedlevel10", -135, -223, "+"..speedGain*1000 .."%")

	self:initlevelupButton("hungermax", "MAX", "hungerlevelmax", -60, -48)
	self:initlevelupButton("sanitymax", "MAX", "sanitylevelmax", -60, -83)
	self:initlevelupButton("healthmax", "MAX", "healthlevelmax", -60, -118, nil, self.owner.prefab == "wanda")
	self:initlevelupButton("damagemax", "MAX", "damagelevelmax", -60, -153)
	self:initlevelupButton("absorbmax", "MAX", "absorblevelmax", -60, -188)
	self:initlevelupButton("speedmax", "MAX", "speedlevelmax", -60, -223)

	-- PetLevel MainPage
	self.mainui.petlevelbg.xpbar_filled = self.mainui.petlevelbg:AddChild(Image("images/hud/level/level_bar_fill.xml", "level_bar_fill.tex"))
	self.mainui.petlevelbg.xpbar_filled:SetHRegPoint(ANCHOR_LEFT)
	self.mainui.petlevelbg.xpbar_filled:SetPosition(-218, 157, 0)
	self.mainui.petlevelbg.xpbar_filled:SetTint(0.2, 0.8, 0.2, 1)
	

	self.mainui.petlevelbg.levelxp = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 33))
	self.mainui.petlevelbg.levelxp:SetPosition(10, 154, 0)
	self.mainui.petlevelbg.levelxp:SetHAlign(ANCHOR_MIDDLE)

	self.mainui.petlevelbg.overallxp = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 29))
	self.mainui.petlevelbg.overallxp:SetPosition(200, 207, 0)
	self.mainui.petlevelbg.overallxp:SetHAlign(ANCHOR_RIGHT)

	self.mainui.petlevelbg.freepoints = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 29))
	self.mainui.petlevelbg.freepoints:SetPosition(-85, 207, 0)
	self.mainui.petlevelbg.freepoints:SetHAlign(ANCHOR_LEFT)

	self.mainui.petlevelbg.levelbutton = self.mainui.petlevelbg:AddChild(Image("images/hud/level/level_bar.xml", "level_bar.tex"))
	self.mainui.petlevelbg.levelbutton:SetPosition(0, 155, 0)
	self.mainui.petlevelbg.levelbutton:SetTint(0.2, 0.8, 0.2, 1)
	self.mainui.petlevelbg.level = self.mainui.petlevelbg.levelbutton:AddChild(Text(CHATFONT_OUTLINE, 65))
	self.mainui.petlevelbg.level:SetPosition(-250, -3, 0)
	self.mainui.petlevelbg.level:SetHAlign(ANCHOR_MIDDLE)

	self.mainui.petlevelbg.costheader = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.petlevelbg.costheader:SetPosition(200, 80, 0)
	self.mainui.petlevelbg.costheader:SetHAlign(ANCHOR_MIDDLE)
	self.mainui.petlevelbg.costheader:SetString(STRINGS.GUI["attributecost"])

	self.mainui.petlevelbg.costs = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.petlevelbg.costs:SetPosition(200, -58, 0)
	self.mainui.petlevelbg.costs:SetHAlign(ANCHOR_MIDDLE)

	self.mainui.petlevelbg.currentheader = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.petlevelbg.currentheader:SetPosition(295, 80, 0)
	self.mainui.petlevelbg.currentheader:SetHAlign(ANCHOR_MIDDLE)
	self.mainui.petlevelbg.currentheader:SetString(STRINGS.GUI["attributecurrent"])

	self.mainui.petlevelbg.currents = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.petlevelbg.currents:SetPosition(295, -58, 0)
	self.mainui.petlevelbg.currents:SetHAlign(ANCHOR_MIDDLE)

	self.mainui.petlevelbg.attributelabels = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.petlevelbg.attributelabels:SetPosition(-280, -58, 0)
	self.mainui.petlevelbg.attributelabels:SetHAlign(ANCHOR_RIGHT)
	self.mainui.petlevelbg.attributelabels:SetString(STRINGS.GUI["petattributelabels"])

	self.mainui.petlevelbg.attributelevels = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.petlevelbg.attributelevels:SetPosition(-155, -58, 0)
	self.mainui.petlevelbg.attributelevels:SetHAlign(ANCHOR_RIGHT)

	self.mainui.petlevelbg.attributeunits = self.mainui.petlevelbg:AddChild(Text(CHATFONT, 35))
	self.mainui.petlevelbg.attributeunits:SetPosition(-115, -58, 0)
	self.mainui.petlevelbg.attributeunits:SetHAlign(ANCHOR_RIGHT)
	self.mainui.petlevelbg.attributeunits:SetString(STRINGS.GUI["petattributeunits"])

	self.mainui.petlevelbg.levelswitch = self.mainui.petlevelbg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.petlevelbg.levelswitch:SetPosition(240, -310, 0)
	self.mainui.petlevelbg.levelswitch:SetOnClick(function()
		self:hideAll()
		self.mainui.levelbg:Show()
	end)
	self.mainui.petlevelbg.levelswitch.label = self.mainui.petlevelbg.levelswitch:AddChild(Text(BUTTONFONT, 35))
	self.mainui.petlevelbg.levelswitch.label:SetMultilineTruncatedString(STRINGS.GUI["levelPlayer"], 1, 100, 50, "", true)
	self.mainui.petlevelbg.levelswitch.label:SetColour(0,0,0,1)

	self.mainui.petlevelbg.evolve = self.mainui.petlevelbg:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.petlevelbg.evolve:SetPosition(-240, -310, 0)
	self.mainui.petlevelbg.evolve:SetOnClick(function()
		SendModRPCToServer(MOD_RPC["AchievementUI"]["evolvePet"])
		self:hideAll()
	end)
	self.mainui.petlevelbg.evolve.label = self.mainui.petlevelbg.evolve:AddChild(Text(BUTTONFONT, 35))
	self.mainui.petlevelbg.evolve.label:SetMultilineTruncatedString(STRINGS.GUI["petEvolve"], 1, 100, 50, "", true)
	self.mainui.petlevelbg.evolve.label:SetColour(0,0,0,1)

	self.mainui.petlevelbg.close = self.mainui.petlevelbg:AddChild(ImageButton("images/hud/close_button.xml", "close_button.tex"))
	self.mainui.petlevelbg.close:SetPosition(370, 350, 0)
	self.mainui.petlevelbg.close:SetOnClick(function()
		self:hideAll()
	end)

	self.mainui.petlevelbg.levelupbuttons = self.mainui.petlevelbg:AddChild(Widget("levelupbuttons"))
	self.mainui.petlevelbg.levelupbuttons:SetPosition(180, 82, 0)

	self:initpetlevelupButton("petspeed", "x1", "petspeedlevel", -210, -48)
	self:initpetlevelupButton("petdamage", "x1", "petdamagelevel", -210, -83)
	self:initpetlevelupButton("petattackspeed", "x1", "petattackspeedlevel", -210, -118)
	self:initpetlevelupButton("petcooldown", "x1", "petcooldownlevel", -210, -153)
	self:initpetlevelupButton("petspell", "x1", "petspelllevel", -210, -188)
	self:initpetlevelupButton("petpassive", "x1", "petpassivelevel", -210, -223)

	self:initpetlevelupButton("petspeed10", "x10", "petspeedlevel10", -135, -48)
	self:initpetlevelupButton("petdamage10", "x10", "petdamagelevel10", -135, -83)
	self:initpetlevelupButton("petattackspeed10", "x10", "petattackspeedlevel10", -135, -118)
	self:initpetlevelupButton("petcooldown10", "x10", "petcooldownlevel10", -135, -153)
	self:initpetlevelupButton("petspell10", "x10", "petspelllevel10", -135, -188)
	self:initpetlevelupButton("petpassive10", "x10", "petpassivelevel10", -135, -223)

	self:initpetlevelupButton("petspeedmax", "MAX", "petspeedlevelmax", -60, -48)
	self:initpetlevelupButton("petdamagemax", "MAX", "petdamagelevelmax", -60, -83)
	self:initpetlevelupButton("petattackspeedmax", "MAX", "petattackspeedlevelmax", -60, -118)
	self:initpetlevelupButton("petcooldownmax", "MAX", "petcooldownlevelmax", -60, -153)
	self:initpetlevelupButton("petspellmax", "MAX", "petspelllevelmax", -60, -188)
	self:initpetlevelupButton("petpassivemax", "MAX", "petpassivelevelmax", -60, -223)

	self.inst:DoTaskInTime(.2, function()
		self.numpage = 1
		self.perkpage = 1
		self:loadtasklist()
		self.achivlisttile = {}
		self.tasklisttile = {}
		self.coinlistbutton = {}
		self.activeskilllist = {}
		self.activeskillcount = 0
		self.pinnedachievements = {"", "", ""}
		self.pinnedui = {}
		self:build()
		self:perk_build()
		self:task_build()
		self:build_pinned()
		self:StartUpdating()
	end)
end)

function uiachievement:initAchCategory(id, name, posx, posy)
	local _id = tostring(id)
	self.mainui.ach_cat["cat".._id] = self.mainui.ach_cat:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.ach_cat["cat".._id]:SetPosition(posx, posy, 0)
	self.mainui.ach_cat["cat".._id]:SetOnClick(function()
		if self.mainui.allachiv.shown then
			self.numpage = id
			self.achpage = 1
			self:build()
			self:setAllAchivCategoriesActive()
			self.mainui.ach_cat["cat".._id]:Disable()
			self.mainui.ach_cat["cat".._id].image:SetScale(1,1,1)
		end
	end)
	self.mainui.ach_cat["cat".._id].label = self.mainui.ach_cat["cat".._id]:AddChild(Text(BUTTONFONT, 35))
	self.mainui.ach_cat["cat".._id].label:SetColour(0,0,0,1)
	self.mainui.ach_cat["cat".._id].label:SetMultilineTruncatedString(STRINGS.GUI[name], 1, 120, 50, "", true)
end

function uiachievement:initPerkCategory(id, name, posx, posy)
	local _id = tostring(id)
	self.mainui.perk_cat["perkcat".._id] = self.mainui.perk_cat:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.perk_cat["perkcat".._id]:SetPosition(posx, posy, 0)
	self.mainui.perk_cat["perkcat".._id]:SetOnClick(function()
		if self.mainui.allcoin.shown then
			self.perkpage = id
			self:perk_build()
			self:setAllPerkCategoriesActive()
			self.mainui.perk_cat["perkcat".._id]:Disable()
			self.mainui.perk_cat["perkcat".._id].image:SetScale(1,1,1)
		end
	end)
	self.mainui.perk_cat["perkcat".._id].label = self.mainui.perk_cat["perkcat".._id]:AddChild(Text(BUTTONFONT, 35))
	self.mainui.perk_cat["perkcat".._id].label:SetMultilineTruncatedString(STRINGS.GUI[name], 1, 150, 50, "", true)
	self.mainui.perk_cat["perkcat".._id].label:SetColour(0,0,0,1)
end

function uiachievement:initlevelupButton(name, desc, rpc, posx, posy, hover, hide)
	self.mainui.levelbg.levelupbuttons[name] = self.mainui.levelbg.levelupbuttons:AddChild(ImageButton("images/hud/level/level_attr_button.xml", "level_attr_button_active.tex", nil, "level_attr_button_disable.tex"))
	self.mainui.levelbg.levelupbuttons[name]:SetPosition(posx, posy, 0)
	if hover then
		self.mainui.levelbg.levelupbuttons[name]:SetHoverText(hover)
	end
	self.mainui.levelbg.levelupbuttons[name].label = self.mainui.levelbg.levelupbuttons[name]:AddChild(Text(CHATFONT, 23))
	self.mainui.levelbg.levelupbuttons[name].label:SetHAlign(ANCHOR_MIDDLE)
	self.mainui.levelbg.levelupbuttons[name].label:SetPosition(0, -0.5, 0)
	self.mainui.levelbg.levelupbuttons[name].label:SetString(desc)
	self.mainui.levelbg.levelupbuttons[name].label:SetColour(0,0,0,1)
	self.mainui.levelbg.levelupbuttons[name]:SetOnClick(function()
		SendModRPCToServer(MOD_RPC["ChasniLevelRPC"][rpc])
	end)
	if hide then
		self.mainui.levelbg.levelupbuttons[name]:Hide()
	end
end

function uiachievement:initpetlevelupButton(name, desc, rpc, posx, posy, hover, hide)
	self.mainui.petlevelbg.levelupbuttons[name] = self.mainui.petlevelbg.levelupbuttons:AddChild(ImageButton("images/hud/level/level_attr_button.xml", "level_attr_button_active.tex", nil, "level_attr_button_disable.tex"))
	self.mainui.petlevelbg.levelupbuttons[name]:SetPosition(posx, posy, 0)
	if hover then
		self.mainui.petlevelbg.levelupbuttons[name]:SetHoverText(hover)
	end
	self.mainui.petlevelbg.levelupbuttons[name].label = self.mainui.petlevelbg.levelupbuttons[name]:AddChild(Text(CHATFONT, 23))
	self.mainui.petlevelbg.levelupbuttons[name].label:SetHAlign(ANCHOR_MIDDLE)
	self.mainui.petlevelbg.levelupbuttons[name].label:SetPosition(0, -0.5, 0)
	self.mainui.petlevelbg.levelupbuttons[name].label:SetString(desc)
	self.mainui.petlevelbg.levelupbuttons[name].label:SetColour(0,0,0,1)
	self.mainui.petlevelbg.levelupbuttons[name]:SetOnClick(function()
		SendModRPCToServer(MOD_RPC["ChasniPetLevelRPC"][rpc])
	end)
	if hide then
		self.mainui.petlevelbg.levelupbuttons[name]:Hide()
	end
end

function uiachievement:hideAll()
	self.mainbutton.configs:Hide()
	self.mainui.resetperk_bg:Hide()
	self.mainui.allcoin:Hide()
	self.mainui.achievement_bg:Hide()
	self.mainui.ach_cat:Hide()
	self.mainui.allachiv:Hide()
	self.mainui.perk_cat:Hide()
	self.mainui.levelbg:Hide()
	self.mainui.petlevelbg:Hide()
	self.mainui.achievement_bg.reset:Hide()
	self.mainui.achievement_bg.achnav:Hide()
	--self.mainui.achievement_bg.sort:Hide()
	self.mainui.achievement_bg.info:Hide()
	self.mainui.alltask:Hide()
	if self.mainbutton.guidebutton then
		local startingpos = self.mainbutton.guidebutton:GetPosition()
		self.mainbutton.guidebutton:SetPosition(startingpos.x, -40, 0)
	end
	SendModRPCToServer(MOD_RPC["AchievementUI"]["movetrinketslot"])
end

function uiachievement:setAllAchivCategoriesActive()
	for i=1, #UIData.ach_tab do
		local _i = tostring(i)
		self.mainui.ach_cat["cat".._i]:Enable()
	end

	self.mainui.achievement_bg.info:Hide()
	self.mainui.achievement_bg.info:SetPosition(331, -150, 0)
end

function uiachievement:setAllPerkCategoriesActive()
	for i=1, #UIData.perk_tab do
		local _i = tostring(i)
		self.mainui.perk_cat["perkcat".._i]:Enable()
	end
end

-- ACHIEVEMENT
function uiachievement:updateachievepage(i)
	local ach_name = UIData.ach_list[i] or nil
	if ach_name then
		local task_slot = GetSeasonalSlot(ach_name)
		local completed = task_slot and self.owner["seasonaltaskdone"..task_slot]:value()
			or (not task_slot and self.owner["check"..ach_name]:value() == 1)
		local active = completed and "1" or "2"
		self.achivlisttile[i]:SetTexture("images/hud/ach/ach_text_bg_"..active..".xml", "ach_text_bg_"..active..".tex")

		self.achivlisttile[i]:SetHoverText(AchievementHoverText(self, i))

		if ach_list_lists[ach_name] then
			if self["infoopen"..ach_name] then
				self.mainui.achievement_bg.info.header:SetMultilineTruncatedString(STRINGS.GUI[ach_name], 40, 300, 38, "...", true)
				self.mainui.achievement_bg.info.label:SetMultilineTruncatedString(self.owner["current"..ach_name.."list"]:value(), 40, 300, 38, "...", true)
			end
		end
	end
end

function uiachievement:updatetaskpage()
	local taskdone = 0
	for i=1,6 do
		local task = self.tasklist[i]
		if task.done then
			taskdone = taskdone + 1
			self.tasklisttile[i].checkmark:Show()
		else
			self.tasklisttile[i].checkmark:Hide()
		end
		self.tasklisttile[i].count:SetColour(task.done and 0.5 or 0, task.done and 1 or 0, task.done and 0.8 or 0, 1)
		self.tasklisttile[i].count:SetString(tostring(task.progress).."/"..tostring(task.target))
		self.tasklisttile[i].name:SetString(task.definition and task.definition.name or STRINGS.GUI["unknowntask"])
		local recipe = GetSeasonalRecipeTooltip(task.definition)
		local hovertext = task.definition and task.definition.description or STRINGS.GUI["unknowntask"]
		if recipe then hovertext = hovertext .. "\n" .. recipe end
		self.tasklisttile[i]:SetHoverText(hovertext, TaskHoverOptions(i))
	end
	self.mainui.alltask.barfill:SetScale(math.min(1, taskdone / 6),1,1)
	for i=1,4 do
		local state = self.owner["taskprize"..i]:value() == true and "open" or "close"
		if self.mainui.alltask.taskbar.chest[i].atlas ~= "images/hud/task/task_chest_"..state..".xml" then
			self.mainui.alltask.taskbar.chest[i]:SetTextures("images/hud/task/task_chest_"..state..".xml", "task_chest_"..state..".tex")
		end
		local reward_id = self.owner["seasonalreward"..i]:value()
		local season = self.tasklist[1] and self.tasklist[1].definition and self.tasklist[1].definition.season or "autumn"
		local reward_text = reward_id ~= "" and SeasonalRewards.Describe(reward_id, season) or STRINGS.GUI["taskRewardPending"]
		self.mainui.alltask.taskbar.chest[i]:SetHoverText(reward_text,{ size = 9, offset_x = 90, offset_y = -55, colour = {1,1,1,1}})
	end
	if self.mainui.alltask.shown then
		local round = self.owner.seasonalround:value()
		self.mainui.achievement_bg.titlebox.title:SetString(STRINGS.GUI["taskTitle"] .. " - " .. string.format(STRINGS.GUI["taskRound"], round))
	end
	local info = self.owner.seasonalfinished:value() and STRINGS.GUI["taskSeasonFinished"] or STRINGS.GUI["taskinfo"]
	self.mainui.alltask.info:SetMultilineTruncatedString(info, 2, 900, 500, "", true)
end

-- PINNED UI
function uiachievement:UpdatePinnedUI()
	for i = 1, #self.pinnedachievements do
		local achievementindex = self.pinnedachievements[i]
		if achievementindex ~= "" then
			self.pinnedui[i]:Show()
			self.pinnedui[i].bg.name:SetTruncatedString(self:getAchievementDescriptionString(achievementindex), 335, 500, "")
			self.pinnedui[i].bg.desc:SetString(self:getAchievementProgressString(achievementindex, true))
		else
			self.pinnedui[i]:Hide()
		end
	end
end

-- WOODIE CD UI
function uiachievement:UpdateWereChargePercent(wereform, cd)
	local prev_precent = self.werecd[wereform] and 1 - (self.werecd[wereform] / TUNING.EXPERT_WOODIE1_COOLDOWN[wereform]) or 1
	local cur_precent = 1 - (cd / TUNING.EXPERT_WOODIE1_COOLDOWN[wereform])
	self.werecd[wereform] = cd
	if self.werecd[wereform] > 0 then
		self.mainbutton.activeskills.werehud[wereform].cd:Show()
		self.mainbutton.activeskills.werehud[wereform].cd:GetAnimState():SetPercent("recharge", cur_precent)
		self.mainbutton.activeskills.werehud[wereform]:SetImageNormalColour(0.4, 0.4, 0.4, 1)
	else
		if prev_precent < 1 and not self.mainbutton.activeskills.werehud[wereform].cd:GetAnimState():IsCurrentAnimation("frame_pst") then
			self.mainbutton.activeskills.werehud[wereform].cd:GetAnimState():PlayAnimation("frame_pst")
		end
		self.mainbutton.activeskills.werehud[wereform].cd:Hide()
		self.mainbutton.activeskills.werehud[wereform]:SetImageNormalColour(1, 1, 1, 1)
	end
end

-- Achievements Categories number of entries
function uiachievement:OnUpdate(dt)
	local zoomlevel = self.owner.currentzoomlevel:value()
	if zoomlevel ~= self.size then
		self.size = zoomlevel
		self.mainui:SetScale(zoomlevel - 0.1, zoomlevel - 0.1, 1)
	end
	local savedxpos = self.owner.currentwidgetxpos:value()
	local pos = self.mainbutton:GetPosition()
	if savedxpos ~= -1 and pos.x ~= savedxpos then
		self.mainbutton:SetPosition(savedxpos, pos.y, pos.z)
		SendModRPCToServer(MOD_RPC["AchievementUI"]["movetrinketslot"])
	end

	-- HUD type Logic
	local HUDtoggled = self.minimalistHUD ~= self.owner.currentmainhudtype:value()
	if HUDtoggled then
		self.minimalistHUD = self.owner.currentmainhudtype:value() == true
		local mainbg = "main_bg".. (self.minimalistHUD and "_minimalist" or "")
		self.mainbutton.bg:SetTexture("images/hud/main/"..mainbg..".xml", mainbg..".tex")
		self.mainbutton.activeskills.activeskillbutton:SetTextures("images/hud/main/"..mainbg.."_down_2.xml", mainbg.."_down_2.tex")
		if self.minimalistHUD then
			self.mainbutton.achievementbutton:SetPosition(30, -30, 0)
			self.mainbutton.perkbutton:SetPosition(70, -30, 0)
			self.mainbutton.taskbutton:SetPosition(110, -30, 0)
			self.mainbutton.levelbutton:SetPosition(150, -30, 0)
			self.mainbutton.levelbutton:SetScale(1.4,1.4,1.4)
			self.mainbutton.configact:SetPosition(200, -30, 0)
			self.mainbutton.configs:SetPosition(220, -30, 0)
			if self.mainbutton.guidebutton then
				local startingpos = self.mainbutton.guidebutton:GetPosition()
				self.mainbutton.guidebutton:SetPosition(285, startingpos.y, 0)
			end

			self.mainbutton.activeskills:SetPosition(113, -80, 0)
			self.mainbutton.activeskills.bg:SetPosition(0, 70, 0)
			self.mainbutton.activeskills.bg2:SetPosition(0, 160, 0)

			self.mainbutton.xpbar_filled:Hide()
		else
			self.mainbutton.achievementbutton:SetPosition(49, -50, 0)
			self.mainbutton.perkbutton:SetPosition(118, -50, 0)
			self.mainbutton.taskbutton:SetPosition(187, -50, 0)
			self.mainbutton.levelbutton:SetPosition(118, -125, 0)
			self.mainbutton.levelbutton.image:SetScale(1,1,1)
			self.mainbutton.configact:SetPosition(249, -21, 0)
			self.mainbutton.configs:SetPosition(272, -20, 0)
			if self.mainbutton.guidebutton then
				local startingpos = self.mainbutton.guidebutton:GetPosition()
				self.mainbutton.guidebutton:SetPosition(330, startingpos.y, 0)
			end

			self.mainbutton.activeskills:SetPosition(118, -158, 0)
			self.mainbutton.activeskills.bg:SetPosition(0, 90, 0)
			self.mainbutton.activeskills.bg2:SetPosition(0, 180, 0)

			self.mainbutton.xpbar_filled:Show()
		end
	end

	if not self.mainui.allcoin.shown then
		self.mainui.resetperk_bg:Hide()
	end
	if not self.mainui.levelbg.shown then
		self.mainui.resetlevel_bg:Hide()
	end

	self.mainui.achievement_bg.coinamount:SetString(self.owner.currentcoinamount:value())

	-- LEVEL attribute cost checking
	local attributes = {
		"hunger", "sanity", "health", "damage", "absorb", "speed"
	}
	local coststring = ""
	self.availableattributepoints = self.owner.currentattributepoints:value()
	if self.availableattributepoints > 0 then
		self.mainui.levelbg.freepoints:Show()
		self.mainui.levelbg.freepoints:SetString(STRINGS.GUI["availablePoints"]..self.availableattributepoints)
	else
		self.mainui.levelbg.freepoints:Hide()
	end
	for _, attr in ipairs(attributes) do
		local cost = self.owner["current" .. attr .. "levelcost"]:value()
		if self.availableattributepoints >= cost then
			if not self.mainui.levelbg.levelupbuttons[attr]:IsEnabled() then
				self.mainui.levelbg.levelupbuttons[attr]:Enable()
			end
			if not self.mainui.levelbg.levelupbuttons[attr.."max"]:IsEnabled() then
				self.mainui.levelbg.levelupbuttons[attr.."max"]:Enable()
			end
		else
			if self.mainui.levelbg.levelupbuttons[attr]:IsEnabled() then
				self.mainui.levelbg.levelupbuttons[attr]:Disable()
				self.mainui.levelbg.levelupbuttons[attr].image:SetScale(1,1,1)
			end
			if self.mainui.levelbg.levelupbuttons[attr.."max"]:IsEnabled() then
				self.mainui.levelbg.levelupbuttons[attr.."max"]:Disable()
				self.mainui.levelbg.levelupbuttons[attr.."max"].image:SetScale(1,1,1)
			end
		end

		if self.availableattributepoints >= 10 * cost then
			if not self.mainui.levelbg.levelupbuttons[attr.."10"]:IsEnabled() then
				self.mainui.levelbg.levelupbuttons[attr.."10"]:Enable()
			end
		else
			if self.mainui.levelbg.levelupbuttons[attr.."10"]:IsEnabled() then
				self.mainui.levelbg.levelupbuttons[attr.."10"]:Disable()
				self.mainui.levelbg.levelupbuttons[attr.."10"].image:SetScale(1,1,1)
			end
		end
		coststring = coststring .. self.owner["current" .. attr .. "levelcost"]:value() .. "\n"
	end
	self.mainui.levelbg.costs:SetString(coststring)
	local currentstring =
	self.owner.currenthungerlevel:value().."\n"
			..self.owner.currentsanitylevel:value().."\n"
			..self.owner.currenthealthlevel:value().."\n"
			..self.owner.currentdamagelevel:value().."\n"
			..self.owner.currentabsorblevel:value().."\n"
			..self.owner.currentspeedlevel:value().."\n"
	self.mainui.levelbg.currents:SetString(currentstring)
	self.mainui.levelbg.levelxp:SetString(self.owner.currentlevelxp:value().."/"..chasni_getxpgoals(self.owner.currentlevel:value()))
	self.mainui.levelbg.overallxp:SetString(STRINGS.GUI["overallxp"]..self.owner.currentoverallxp:value())
	self.mainui.levelbg.level:SetString(self.owner.currentlevel:value())

	local percent = self.owner.currentlevelxp:value() / chasni_getxpgoals(self.owner.currentlevel:value())
	self.mainbutton.xpbar_filled:SetScale(1*percent,1,1)
	self.mainui.levelbg.xpbar_filled:SetScale(1*percent,1,1)

	local hunger = math.floor(self.owner.currenthungerlevelmax:value()+0.5)
	local sanity = math.floor(self.owner.currentsanitylevelmax:value()+0.5)
	local health = math.floor(self.owner.currenthealthlevelmax:value()+0.5)
	local damage = math.floor(self.owner.currentdamagelevelmax:value()+0.5)
	local defence = math.floor(self.owner.currentabsorblevelmax:value()+0.5)
	local speed = math.floor(self.owner.currentspeedlevelmax:value()+0.5)
	self.mainui.levelbg.attributelevels:SetString(hunger.."\n"..sanity.."\n"..health.."\n"..damage.."\n"..defence.."\n"..speed)

	if self.mainui.levelbg.levelswitch then
		if self.owner.currentduppercritter:value() == 1 then
			self.mainui.levelbg.levelswitch:Show()
		else
			self.mainui.levelbg.levelswitch:Hide()
		end
	end
	-- PETLEVEL attribute cost checking
	local petattributes = {
		"petspeed", "petdamage", "petattackspeed", "petcooldown", "petspell", "petpassive",
	}
	local petcoststring = ""
	self.petavailableattributepoints = self.owner.currentpetattributepoints:value()
	if self.petavailableattributepoints > 0 then
		self.mainui.petlevelbg.freepoints:Show()
		self.mainui.petlevelbg.freepoints:SetString(STRINGS.GUI["availablePoints"]..self.petavailableattributepoints)
	else
		self.mainui.petlevelbg.freepoints:Hide()
	end
	for _, attr in ipairs(petattributes) do
		local cost = self.owner["current" .. attr .. "levelcost"]:value()
		if self.petavailableattributepoints >= cost then
			if not self.mainui.petlevelbg.levelupbuttons[attr]:IsEnabled() then
				self.mainui.petlevelbg.levelupbuttons[attr]:Enable()
			end
			if not self.mainui.petlevelbg.levelupbuttons[attr.."max"]:IsEnabled() then
				self.mainui.petlevelbg.levelupbuttons[attr.."max"]:Enable()
			end
		else
			if self.mainui.petlevelbg.levelupbuttons[attr]:IsEnabled() then
				self.mainui.petlevelbg.levelupbuttons[attr]:Disable()
				self.mainui.petlevelbg.levelupbuttons[attr].image:SetScale(1,1,1)
			end
			if self.mainui.petlevelbg.levelupbuttons[attr.."max"]:IsEnabled() then
				self.mainui.petlevelbg.levelupbuttons[attr.."max"]:Disable()
				self.mainui.petlevelbg.levelupbuttons[attr.."max"].image:SetScale(1,1,1)
			end
		end

		if self.petavailableattributepoints >= 10 * cost then
			if not self.mainui.petlevelbg.levelupbuttons[attr.."10"]:IsEnabled() then
				self.mainui.petlevelbg.levelupbuttons[attr.."10"]:Enable()
			end
		else
			if self.mainui.petlevelbg.levelupbuttons[attr.."10"]:IsEnabled() then
				self.mainui.petlevelbg.levelupbuttons[attr.."10"]:Disable()
				self.mainui.petlevelbg.levelupbuttons[attr.."10"].image:SetScale(1,1,1)
			end
		end
		petcoststring = petcoststring .. self.owner["current" .. attr .. "levelcost"]:value() .. "\n"
	end
	self.mainui.petlevelbg.costs:SetString(petcoststring)
	local petcurrentstring =
	self.owner.currentpetspeedlevel:value().."\n"
			..self.owner.currentpetdamagelevel:value().."\n"
			..self.owner.currentpetattackspeedlevel:value().."\n"
			..self.owner.currentpetcooldownlevel:value().."\n"
			..self.owner.currentpetspelllevel:value().."\n"
			..self.owner.currentpetpassivelevel:value().."\n"
	self.mainui.petlevelbg.currents:SetString(petcurrentstring)
	self.mainui.petlevelbg.levelxp:SetString(self.owner.currentpetlevelxp:value().."/"..chasni_getxpgoals(self.owner.currentpetlevel:value()))
	self.mainui.petlevelbg.overallxp:SetString(STRINGS.GUI["overallxp"]..self.owner.currentpetoverallxp:value())
	self.mainui.petlevelbg.level:SetString(self.owner.currentpetlevel:value())

	local petpercent = self.owner.currentpetlevelxp:value() / chasni_getxpgoals(self.owner.currentpetlevel:value())
	self.mainui.petlevelbg.xpbar_filled:SetScale(1*petpercent,1,1)
	local function FormatFloat(num)
		return string.format("%.2f", num):gsub("%.?0+$", "")
	end
	local petspeed = FormatFloat(self.owner.currentpetspeedlevelmax:value())
	local petdamage = FormatFloat(self.owner.currentpetdamagelevelmax:value())
	local petattackspeed = FormatFloat(self.owner.currentpetattackspeedlevelmax:value())
	local petcooldown = FormatFloat(self.owner.currentpetcooldownlevelmax:value())
	local petspell = FormatFloat(self.owner.currentpetspelllevelmax:value())
	local petpassive = FormatFloat(self.owner.currentpetpassivelevelmax:value())
	self.mainui.petlevelbg.attributelevels:SetString(petspeed.."\n"..petdamage.."\n"..petattackspeed.."\n"..petcooldown.."\n"..petspell.."\n"..petpassive)
	-- Pet evolve checking
	if self.owner.currentpetcanevolve:value() == true then
		self.mainui.petlevelbg.evolve:Show()
	else
		self.mainui.petlevelbg.evolve:Hide()
	end
	-- ACH
	local start, count = self:getVisibleAchievementRange()
	for i = start, start + count - 1 do
		self:updateachievepage(i)
	end
	self:loadtasklist()
	self:updatetaskpage()

	-- Pinned Achievement UI
	self:UpdatePinnedUI()

	-- trinketowner
	if self.mainbutton.trinket then
		if self.owner.currenttrinketowner and self.owner.currenttrinketowner:value() == 1 then
			self.mainbutton.trinket:Show()
		else
			self.mainbutton.trinket:Hide()
		end
	end

	-- Woodie UI
	if self.mainbutton.activeskills.werehud then
		if self.owner.prefab == "woodie" and self.owner.currentexpertwoodie1:value() == 1 then
			self.mainbutton.activeskills.werehud:Show()
			if not self.activeskilllist["werehud"] then
				self.activeskilllist["werehud"] = true
				self.activeskillcount = self.activeskillcount + 1
				self.mainbutton.activeskills.werehud:SetPosition(0, -25 + self.activeskillcount * 70, 0)
			end
			if not TheNet:IsServerPaused() then
				self:UpdateWereChargePercent("goose", self.werecd["goose"] > 0 and self.werecd["goose"] - dt or 0)
				self:UpdateWereChargePercent("beaver", self.werecd["beaver"] > 0 and self.werecd["beaver"] - dt or 0)
				self:UpdateWereChargePercent("moose", self.werecd["moose"] > 0 and self.werecd["moose"] - dt or 0)
			end
		else
			self.mainbutton.activeskills.werehud:Hide()
			if self.activeskilllist["werehud"] then
				self.activeskilllist["werehud"] = false
				self.activeskillcount = self.activeskillcount - 1
			end
		end
	end

	-- Wendy UI
	if self.mainbutton.activeskills.wendyhud then
		if self.owner.prefab == "wendy" and self.owner.currentexpertwendy3:value() == 1 then
			self.mainbutton.activeskills.wendyhud:Show()
			if not self.activeskilllist["wendyhud"] then
				self.activeskilllist["wendyhud"] = true
				self.activeskillcount = self.activeskillcount + 1
				self.mainbutton.activeskills.wendyhud:SetPosition(0, -25 + self.activeskillcount * 70, 0)
			end
		else
			self.mainbutton.activeskills.wendyhud:Hide()
			if self.activeskilllist["wendyhud"] then
				self.activeskilllist["wendyhud"] = false
				self.activeskillcount = self.activeskillcount - 1
			end
		end
	end

	-- Extra UI
	if self.owner.currentsharemap:value() == 1 then
		self:showactiveskill(self.mainbutton.activeskills.extraskills, "extraskills", "sharemap")
	else
		self:hideactiveskill(self.mainbutton.activeskills.extraskills, "extraskills", "sharemap")
	end
	if self.activeskillcount > 0 then
		self.mainbutton.activeskills:Show()
	else
		self.mainbutton.activeskills:Hide()
	end

	if self.owner:HasTag("chasni_forcerefreshui") then
		self:hideAll()
		self.owner:DoTaskInTime(.35, function()
			self:perk_build()
		end)
		SendModRPCToServer(MOD_RPC["AchievementUI"]["donerefreshui"])
	end
end

function uiachievement:disableinfoopen(active)
	for index,_ in pairs(ach_list_lists) do
		self["infoopen"..index] = index == active
	end
end

function uiachievement:getAchievementDescriptionString(achievementindex)
	local desc = STRINGS.ACHIEVEMENTS[UIData.ach_list[achievementindex]]["description"]
	if type(desc) == "number" then
		local task_id = self.owner["seasonaltaskid"..desc]:value()
		local definition = SeasonalCatalog.ById(task_id)
		return definition and definition.name or STRINGS.GUI["unknowntask"]
	end
	return desc
end

function uiachievement:getAchievementProgressString(achievementindex, withoutcomp)
	local ach_name = UIData.ach_list[achievementindex] or nil
	if ach_name then
		local compstring = withoutcomp and "" or STRINGS.GUI["comp"]
		if ach_name == "shadowpieche" then
			return compstring
					..STRINGS.GUI["sknig"]..self.owner.checkshadowknight:value().."  "
					..STRINGS.GUI["sbish"]..self.owner.checkshadowbishop:value().."  "
					..STRINGS.GUI["srook"]..self.owner.checkshadowrook:value()
		elseif ach_name == "twinterror" then
			return compstring
					..STRINGS.GUI["twin1"]..self.owner.checktwinterror1:value().."  "
					..STRINGS.GUI["twin2"]..self.owner.checktwinterror2:value()
		elseif ach_name == "werepigs" then
			return compstring
					..STRINGS.GUI["werep1"]..self.owner.checkwerepigs1:value().."  "
					..STRINGS.GUI["werep2"]..self.owner.checkwerepigs2:value()
		elseif ach_name == "dragonflybeequeen" then
			return compstring
					..STRINGS.GUI["dgnfly"]..self.owner.checkdragonflybeequeen1:value().."  "
					..STRINGS.GUI["bqueen"]..self.owner.checkdragonflybeequeen2:value()
		elseif ach_name == "malbatrosscrabking" then
			return compstring
					..STRINGS.GUI["mallbt"]..self.owner.checkmalbatrosscrabking1:value().."  "
					..STRINGS.GUI["crabkg"]..self.owner.checkmalbatrosscrabking2:value()
		elseif ach_name == "ancientguardianancientfuelweaver" then
			return compstring
					..STRINGS.GUI["ancgua"]..self.owner.checkancientguardianancientfuelweaver1:value().."  "
					..STRINGS.GUI["ancfue"]..self.owner.checkancientguardianancientfuelweaver2:value()
		elseif ach_name == "seasonboss" then
			return compstring
					..STRINGS.GUI["season1"]..self.owner.checkbossspring:value().."  "
					..STRINGS.GUI["season2"]..self.owner.checkbosssummer:value().."  "
					..STRINGS.GUI["season3"]..self.owner.checkbossautumn:value().."  "
					..STRINGS.GUI["season4"]..self.owner.checkbosswinter:value()
		elseif ach_name == "mutationboss" then
			return compstring
					..STRINGS.GUI["mutated1"]..self.owner.checkmutatedwarg:value().."  "
					..STRINGS.GUI["mutated2"]..self.owner.checkmutatedbearger:value().."  "
					..STRINGS.GUI["mutated3"]..self.owner.checkmutateddeerclops:value()
		elseif ach_name == "complete" then
			local achivvalue = 0
			for i=1, #UIData.ach_list do
				local name = UIData.ach_list[i] or nil
				if name and name ~= "complete" and string.sub(name, 1, 4) ~= "task" then
					achivvalue = (achivvalue + self.owner["check"..name]:value())
				end
			end
			return compstring..achivvalue.."/"..(#UIData.ach_list - 1)
		elseif GetSeasonalSlot(ach_name) then
			local slot = GetSeasonalSlot(ach_name)
			return compstring..self.owner["seasonaltaskprogress"..slot]:value().."/"..self.owner["seasonaltasktarget"..slot]:value()
		elseif ach_lists[ach_name].current then
			return compstring..self.owner["current"..ach_name]:value().."/"..ach_lists[ach_name].current
		else
			return compstring..self.owner["check"..ach_name]:value().."/1"
		end
	end
end

function uiachievement:getVisibleAchievementRange()
	local category = UIData.ach_tab[self.numpage]
	return AchievementPages.Range(category, self.achpage)
end

function uiachievement:build()
	self.mainui.allachiv:KillAllChildren()
	local start, count, page, total = self:getVisibleAchievementRange()
	self.achpage = page
	local nav = self.mainui.achievement_bg.achnav
	if total > 1 and self.mainui.allachiv.shown then
		nav:Show()
		nav:MoveToFront()
		nav.page:SetString(page .. " / " .. total)
		if page == 1 then nav.previous:Disable() else nav.previous:Enable() end
		if page == total then nav.next:Disable() else nav.next:Enable() end
	else
		nav:Hide()
	end
	for i = 1, count do
		self:build_achievpage(i, start + i - 1)
	end
end

function uiachievement:perk_build()
	self.mainui.allcoin:KillAllChildren()
	local name = UIData.perk_tab[self.perkpage].name
	local start = UIData.perk_tab[self.perkpage].start
	local count = UIData.perk_tab[self.perkpage].count
	local _adaptivecost = self.perkpage == 1
	local place = 1;
	for i = 1, count do
		if self:build_perkpage(place, start + i - 1, _adaptivecost, name) then
			place = place + 1
		end
	end
	self.mainui.achievement_bg.titlebox.title:SetString("Đặc quyền: " .. STRINGS.GUI[name])
	self.mainui.achievement_bg.titlebox.icon:SetPosition(self.mainui.achievement_bg.titlebox.title:GetRegionSize() / 2 + 20, 0, 0)
	self.mainui.achievement_bg.titlebox.icon:SetHoverText(STRINGS.GUI["perkInfo-"..name],{ size = 9, offset_x = 15, offset_y = -55, colour = {1,1,1,1}})
end

function uiachievement:task_build()
	self.mainui.alltask:KillAllChildren()
	self:build_taskpage()
end

function uiachievement:build_achievpage(j,i)
	local ach_name = UIData.ach_list[i] or nil
	local ach_data = ach_name and ach_lists[ach_name] or nil
	if ach_data == nil then return end

	local task_slot = GetSeasonalSlot(ach_name)
	local completed = task_slot and self.owner["seasonaltaskdone"..task_slot]:value()
		or (not task_slot and self.owner["check"..ach_name]:value() == 1)
	local active = completed and "1" or "2"

	local x = (j % 2 == 0) and 285 or -265
	local y = 22 - (93 * (math.ceil(j / 2) + 1))
	local button = self.mainui.allachiv:AddChild(Image("images/hud/ach/ach_text_bg_" .. active .. ".xml", "ach_text_bg_" .. active .. ".tex"))
	button:SetPosition(x - 9.5, y, 0)
	local hovertext = AchievementHoverText(self, i)
	button:SetHoverText(hovertext,{ size = 9, offset_y = y > -500 and 0 or -35, colour = {1,1,1,1}})

	button.name = button:AddChild(Text(HEADERFONT, 30))
	button.name:SetPosition(-45, 18, 0)
	button.name:SetHAlign(ANCHOR_LEFT)
	button.name:SetColour(0, 0, 0, 1)
	button.name:SetTruncatedString(STRINGS.ACHIEVEMENTS[ach_name]["name"] .. (ach_name == "complete" and " " .. (self.owner.currentcomplete:value() + 1) or ""), 400, 500, "")
	button.name:SetRegionSize(430, 60)

	button.desc = button:AddChild(Text(NEWFONT, 27))
	button.desc:SetPosition(-10, -19, 0)
	button.desc:SetHAlign(ANCHOR_LEFT)
	button.desc:SetColour(0, 0, 0, 1)
	button.desc:SetTruncatedString(self:getAchievementDescriptionString(i), 400, 500, "", true, 5)
	button.desc:SetRegionSize(500, 65)

	button.cost = button:AddChild(Text(NUMBERFONT, 28))
	button.cost:SetPosition(213, 22, 0)
	button.cost:SetHAlign(ANCHOR_RIGHT)
	button.cost:SetRegionSize(60, 60)
	button.cost:SetString("+" .. ach_lists[ach_name].coinget)
	button.star = button:AddChild(Image("images/hud/small_star.xml", "small_star.tex"))
	button.star:SetPosition(253, 22, 0)

	local actionbuttonx = 243
	button.pinbutton = button:AddChild(ImageButton("images/hud/ach/ach_pin_button.xml", "ach_pin_button.tex"))
	button.pinbutton:SetPosition(actionbuttonx, -13, 0)
	button.pinbutton:SetOnClick(function()
		for pinid = 1, #self.pinnedachievements do
			if self.pinnedachievements[pinid] == i then
				self.pinnedachievements[pinid] = ""
				break
			elseif self.pinnedachievements[pinid] == "" then
				self.pinnedachievements[pinid] = i
				break
			end
		end
	end)
	actionbuttonx = actionbuttonx - 43
	if ach_list_lists[ach_name] then
		button.infobutton = button:AddChild(ImageButton("images/hud/ach/ach_info_button.xml", "ach_info_button.tex"))
		button.infobutton:SetPosition(actionbuttonx, -13, 0)
		button.infobutton:SetOnClick(function()
			if self["infoopen" .. ach_name] then
				self.mainui.achievement_bg.info:MoveTo(Vector3(755, -10, 1), Vector3(231, -10, 1), 1)

				self.owner:DoTaskInTime(0.5, function() self.mainui.achievement_bg.info:Hide() end)
				self:disableinfoopen("false")
			else
				self.mainui.achievement_bg.info:Show()
				self.mainui.achievement_bg.info.header:SetMultilineTruncatedString(STRINGS.GUI[ach_name], 40, 300, 38, "...", true)
				self.mainui.achievement_bg.info.label:SetMultilineTruncatedString(self.owner["current"..ach_name.."list"]:value(), 40, 300, 38, "...", true)
				self.mainui.achievement_bg.info:MoveTo(Vector3(331, -10, 0), Vector3(755, -10, 1), 1)
				self:disableinfoopen(ach_name)
			end
		end)
		actionbuttonx = actionbuttonx - 43
	end
	local hint = chasni_getachievementhint(ach_name)
	if hint then
		button.hintbutton = button:AddChild(ImageButton("images/hud/ach/ach_hint_button.xml", "ach_hint_button.tex"))
		button.hintbutton:SetPosition(actionbuttonx, -13, 0)

		button.hintbutton.bg = button.hintbutton:AddChild(Widget("hint_popup"))
		button.hintbutton.bg:Hide()
		button.hintbutton.bg.bgimage = button.hintbutton.bg:AddChild(Image("images/hud/hint_bg.xml", "hint_bg.tex"))
		button.hintbutton.bg.bgimage:SetPosition(0, 0, 0)
		button.hintbutton.bg.bgimage:MoveToFront()
		button.hintbutton.bg.bgimage:SetOnLoseFocus(function(enabled)
			button.hintbutton.bg:Hide()
		end)
		button.hintbutton.bg.label = button.hintbutton.bg:AddChild(Text(CHATFONT, 28))
		button.hintbutton.bg.label:SetPosition(0, 0, 0)
		button.hintbutton.bg.label:SetColour(0,0,0,1)
		button.hintbutton.bg.label:SetMultilineTruncatedString(hint, 5, 380, 500, "", true)
		button.hintbutton.bg.label:MoveToFront()
		local w, h = button.hintbutton.bg.label:GetRegionSize()
		local padding_x = 30
		local padding_y = 20
		button.hintbutton.bg.bgimage:ScaleToSize(w + padding_x, h + padding_y)
		local hinty = y > -500 and -((h*0.5) + padding_y) or ((h*0.5) + padding_y)
		button.hintbutton.bg:SetPosition(0, hinty, 0)

		button.hintbutton:SetOnClick(function(enabled)
			if button.hintbutton.bg.shown then
				button.hintbutton.bg:Hide()
			else
				button:MoveToFront()
				button.hintbutton.bg:Show()
			end
		end)
		button.hintbutton:SetOnLoseFocus(function(enabled)
			button.hintbutton.bg:Hide()
		end)
	end

	self.achivlisttile[i] = button
end

function uiachievement:build_perkpage(j,i, adaptivecost, name)
	local perk = UIData.perk_list[i] or nil
	local perk_name = perk and perk.name or nil
	local perk_data = perk_name and perk_lists[perk_name] or nil
	if perk_data == nil or (perk.exception and (perk.exception[self.owner.prefab] or perk.exception.all)) then return false end

	local perk_current = self.owner["current"..perk_name] and self.owner["current"..perk_name]:value() or 0
	local perk_cost = adaptivecost and self.owner[perk_name.."cost"] and self.owner[perk_name.."cost"]:value() or perk_data.cost or 0
	local at_cap = adaptivecost and AttributeCaps[perk_name] and perk_current >= AttributeCaps[perk_name]
	local active = perk_current == 0 and "1" or "2"

	local x = -372 + ((j-1)%3) * 368
	local y = 29 - (103 * (math.ceil(j/3) + 1))
	local button = self.mainui.allcoin:AddChild(Widget("perkbutton"..i))
	button:SetPosition(x, y, 0)

	button.bg = button:AddChild(ImageButton("images/hud/perk/perk_text_bg_" .. active .. ".xml", "perk_text_bg_" .. active .. ".tex"))
	button.bg:SetPosition(0, 0, 0)
	button.bg:SetScale(1, 1.15, 1)
	button.bg:SetFocusScale(1.05, 1.05, 1)
	button.bg:SetOnClick(function()
		if at_cap then return end
		SendModRPCToServer(MOD_RPC["DSTAchievement"][perk_name])
		self.owner:DoTaskInTime(.3, function()
			if ThePlayer and ThePlayer.PushEvent then
				ThePlayer:PushEvent("refreshcrafting")
			end
			self:perk_build()
		end)
	end)

	local char = perk.only
	if char then
		button.expertise = button:AddChild(Image("images/button/playerimg/" .. char .. ".xml", char .. ".tex"))
		button.expertise:SetPosition(140, -15, 0)
		button.expertise:SetTint(1, 1, 1, 0.5)
		button.expertise:SetScale(0.75, 0.75, 1)
	end

	if perk_current ~= 0 or (name == "attributes" and AttributeCaps[perk_name]) then
		if name == "global" and toggleableglobalperk[perk_name] then
			button.globalswitch = button:AddChild(Text(HEADERFONT, 24))
			button.globalswitch:SetPosition(157, -17, 0)
			button.globalswitch:SetHAlign(ANCHOR_RIGHT)
			button.globalswitch:SetString(perk_current == -1 and "TẮT" or "BẬT")
			button.globalswitch:SetColour(perk_current == -1 and 0.8 or 0.5, perk_current == -1 and 0.1 or 1, perk_current == -1 and 0.1 or 0.8, 1)
		elseif name == "attributes" then
			button.attributecounter = button:AddChild(Text(HEADERFONT, 24))
			button.attributecounter:SetPosition(157, -17, 0)
			button.attributecounter:SetHAlign(ANCHOR_RIGHT)
			button.attributecounter:SetString(AttributeCaps[perk_name] and (perk_current.."/"..AttributeCaps[perk_name]) or (perk_current.." X"))
			button.attributecounter:SetColour(0, 0, 0, 1)
		end
	end

	button.name = button:AddChild(Text(HEADERFONT, 30))
	button.name:SetPosition(0, 25, 0)
	button.name:SetHAlign(ANCHOR_LEFT)
	button.name:SetTruncatedString(STRINGS.PERKS[perk_name]["name"], 300, 500, "")
	button.name:SetRegionSize(350, 60)
	button.name:SetColour(0, 0, 0, 1)

	button.desc = button:AddChild(Text(NEWFONT, 27))
	button.desc:SetPosition(0, -15, 0)
	button.desc:SetHAlign(ANCHOR_LEFT)
	button.desc:SetMultilineTruncatedString(STRINGS.PERKS[perk_name]["description"], 2, 260, 500, "", true, 5)
	button.desc:SetColour(0, 0, 0, 1)
	button.desc:SetRegionSize(350, 60)

	button.cost = button:AddChild(Text(NUMBERFONT, 28))
	button.cost:SetPosition(127, 25, 0)
	button.cost:SetHAlign(ANCHOR_RIGHT)
	button.cost:SetRegionSize(50, 30)
	button.cost:SetString(at_cap and "MAX" or "-" .. perk_cost)
	button.star = button:AddChild(Image("images/hud/small_star.xml", "small_star.tex"))
	button.star:SetPosition(162, 25, 0)
	if at_cap then button.star:Hide() end

	self.coinlistbutton[i] = button
	return true
end

function uiachievement:build_taskpage()
	for taskid=1,6 do
		self.tasklisttile[taskid] = self.mainui.alltask:AddChild(Image("images/hud/task/task_text_bg.xml", "task_text_bg.tex"))
		self.tasklisttile[taskid].checkmark = self.tasklisttile[taskid]:AddChild(Image("images/hud/task/task_check.xml", "task_check.tex"))
		self.tasklisttile[taskid].checkmark:SetPosition(455, 1, 0)
		self.tasklisttile[taskid].checkmark:SetClickable(false)
		self.tasklisttile[taskid].checkmark:Hide()
		self.tasklisttile[taskid].count = self.tasklisttile[taskid]:AddChild(Text(NUMBERFONT, 34))
		self.tasklisttile[taskid].count:SetPosition(405, 0, 0)
		self.tasklisttile[taskid].count:SetHAlign(ANCHOR_RIGHT)
		self.tasklisttile[taskid].count:SetClickable(false)
		self.tasklisttile[taskid]:SetPosition(0, TASK_ROW_START_Y + TASK_ROW_STEP_Y * taskid, 0)

		local definition = self.tasklist[taskid].definition
		local desctext = definition and definition.name or STRINGS.GUI["unknowntask"]
		self.tasklisttile[taskid].name = self.tasklisttile[taskid]:AddChild(Text(CHATFONT, 36))
		self.tasklisttile[taskid].name:SetPosition(25, 0, 0)
		self.tasklisttile[taskid].name:SetHAlign(ANCHOR_LEFT)
		self.tasklisttile[taskid].name:SetVAlign(ANCHOR_MIDDLE)
		self.tasklisttile[taskid].name:SetString(desctext)
		self.tasklisttile[taskid].name:SetRegionSize(850,60)
		self.tasklisttile[taskid].name:SetColour(0,0,0,1)
		self.tasklisttile[taskid].name:SetClickable(false)
		local recipe = GetSeasonalRecipeTooltip(definition)
		local hovertext = definition and definition.description or STRINGS.GUI["unknowntask"]
		if recipe then hovertext = hovertext .. "\n" .. recipe end
		self.tasklisttile[taskid]:SetHoverText(hovertext, TaskHoverOptions(taskid))
	end

	self.mainui.alltask.barfill = self.mainui.alltask:AddChild(Image("images/hud/task/task_bar_fill.xml", "task_bar_fill.tex"))
	self.mainui.alltask.barfill:SetPosition(-481, -788, 0)
	self.mainui.alltask.barfill:SetHRegPoint(ANCHOR_LEFT)
	self.mainui.alltask.taskbar = self.mainui.alltask:AddChild(Image("images/hud/task/task_bar.xml", "task_bar.tex"))
	self.mainui.alltask.taskbar:SetPosition(-100, -790, 0)
	self.mainui.alltask.taskbar:MoveToFront()
	self.mainui.alltask.taskbar.barpoint = {}
	self.mainui.alltask.taskbar.chest = {}
	for i = 1, 4 do
		local milestone = TASK_MILESTONES[i]
		local marker_x = -450 + (856 * milestone / 6)
		self.mainui.alltask.taskbar.barpoint[i] = self.mainui.alltask.taskbar:AddChild(Image("images/hud/task/task_bar_acc.xml", "task_bar_acc.tex"))
		self.mainui.alltask.taskbar.barpoint[i]:SetPosition(marker_x, 15, 0)
		self.mainui.alltask.taskbar.chest[i] = self.mainui.alltask.taskbar:AddChild(ImageButton("images/hud/task/task_chest_close.xml", "task_chest_close.tex"))
		self.mainui.alltask.taskbar.chest[i]:SetPosition(marker_x, 100, 0)
		self.mainui.alltask.taskbar.chest[i]:SetHoverText(STRINGS.GUI["taskRewardPending"],{ size = 9, offset_x = 90, offset_y = -55, colour = {1,1,1,1}})
		self.mainui.alltask.taskbar.chest[i]:SetOnClick(function()
			if not self.owner["taskprize"..i]:value() then
				self:hideAll()
			end
			self._seasonal_receipt_nonce = (self._seasonal_receipt_nonce or 0) + 1
			SendModRPCToServer(MOD_RPC["AchievementUI"]["claimtaskprize"], milestone, MakeSeasonalReceipt(self.owner, self._seasonal_receipt_nonce))
		end)
	end

	self.mainui.alltask.taskbar.claimtask = self.mainui.alltask.taskbar:AddChild(ImageButton("images/hud/main_button.xml", "main_button_active.tex", nil, "main_button_disable.tex"))
	self.mainui.alltask.taskbar.claimtask:SetPosition(540, 0, 0)
	self.mainui.alltask.taskbar.claimtask:SetOnClick(function()
		local taskdone = 0
		for i=1,6 do
			if self.tasklist[i].done then taskdone = taskdone + 1 end
		end
		local has_claimable = false
		for i, milestone in ipairs(TASK_MILESTONES) do
			if taskdone >= milestone and not self.owner["taskprize"..i]:value() then has_claimable = true end
		end
		if has_claimable then self:hideAll() end
		self._seasonal_receipt_nonce = (self._seasonal_receipt_nonce or 0) + 1
		SendModRPCToServer(MOD_RPC["AchievementUI"]["claimtaskprizes"], MakeSeasonalReceipt(self.owner, self._seasonal_receipt_nonce))
	end)
	self.mainui.alltask.taskbar.claimtask.label = self.mainui.alltask.taskbar.claimtask:AddChild(Text(BUTTONFONT, 35))
	self.mainui.alltask.taskbar.claimtask.label:SetMultilineTruncatedString(STRINGS.GUI["claimtask"], 1, 100, 50, "", true)
	self.mainui.alltask.taskbar.claimtask.label:SetColour(0,0,0,1)

	self.mainui.alltask.info = self.mainui.alltask:AddChild(Text(CHATFONT, 24))
	self.mainui.alltask.info:SetPosition(0, -855, 0)
	self.mainui.alltask.info:SetHAlign(ANCHOR_MIDDLE)
	self.mainui.alltask.info:SetMultilineTruncatedString(STRINGS.GUI["taskinfo"], 2, 900, 500, "", true)
end

function uiachievement:build_activeskills(parent, skills, spacing, isblacken)
	local imageWidgets = {}
	local totalWidth = 0

	for _, skill in ipairs(skills) do
		parent[skill.child] = parent:AddChild(ImageButton(skill.atlas, skill.tex))
		parent[skill.child]:SetScale(skill.scale, skill.scale)
		parent[skill.child]:SetOnClick(skill.fn)
		if isblacken then
			parent[skill.child]:SetImageNormalColour(0.4, 0.4, 0.4, 1)
		end

		local width, _ = parent[skill.child].image:GetSize()
		totalWidth = totalWidth + (width * skill.scale) + spacing
		imageWidgets[#imageWidgets + 1] = { widget = parent[skill.child], width = width * skill.scale }
	end
	totalWidth = totalWidth - spacing

	local currentX = -totalWidth / 2
	for _, data in ipairs(imageWidgets) do
		data.widget:SetPosition(currentX + data.width / 2, 0)
		currentX = currentX + data.width + spacing
	end

	parent:SetPosition(0, 0, 0)
end

function uiachievement:hideactiveskill(parent, parentname, childname)
	if parent[childname] then
		parent[childname]:Hide()
		self:recenterimages(parent, parentname, "hide")
	end
end

function uiachievement:showactiveskill(parent, parentname, childname)
	if parent[childname] then
		parent[childname]:Show()
		self:recenterimages(parent, parentname, "show")
	end
end
function uiachievement:recenterimages(parent, parentname, action)
	local imageWidgets = {}
	local totalWidth = 0
	local visibleCount = 0

	if action == "show" then
		self.mainbutton.activeskills:Show()
	end

	for _, widget in pairs(parent) do
		if widget and type(widget) == "table" and widget.IsVisible and widget:IsVisible() and widget.image then
			local scaled_width = 55.35
			totalWidth = totalWidth + scaled_width
			table.insert(imageWidgets, { widget = widget, width = 55.35 })
			visibleCount = visibleCount + 1
		end
	end

	local spacing = 5
	if visibleCount > 1 then
		totalWidth = totalWidth + (visibleCount - 1) * spacing
	end

	local currentX = -totalWidth / 2
	for _, data in ipairs(imageWidgets) do
		data.widget:SetPosition(currentX + data.width / 2, 0)
		currentX = currentX + data.width + spacing
	end

	if action == "show" and not self.activeskilllist[parentname] then
		self.activeskilllist[parentname] = true
		self.activeskillcount = self.activeskillcount + 1
		parent:SetPosition(0, -25 + self.activeskillcount * 70, 0)
	elseif action == "hide" and visibleCount == 0 and self.activeskilllist[parentname] then
		self.activeskilllist[parentname] = false
		self.activeskillcount = self.activeskillcount - 1
	end
end

function uiachievement:build_pinned()
	for i = 1, #self.pinnedachievements do
		self.pinnedui[i] = self:AddChild(Widget("pinnedui"..i))
		self.pinnedui[i]:SetHAnchor(ANCHOR_LEFT)
		self.pinnedui[i]:SetVAnchor(ANCHOR_BOTTOM)
		self.pinnedui[i]:SetPosition(350, 0, 0)

		self.pinnedui[i].bg = self.pinnedui[i]:AddChild(Image("images/hud/ach/ach_text_bg_1.xml", "ach_text_bg_1.tex"))
		self.pinnedui[i].bg:MoveToFront()
		self.pinnedui[i].bg:SetPosition(-60, 0, 0)
		self.pinnedui[i].bg:SetTint(1,1,1,0)
		self.pinnedui[i].bg:SetScale(1.4, 1.4, 1)
		self.pinnedui[i].bg.name = self.pinnedui[i].bg:AddChild(Text(CHATFONT, 20))
		self.pinnedui[i].bg.name:SetPosition(0, 50*i, 0)
		self.pinnedui[i].bg.name:SetHAlign(ANCHOR_LEFT)
		self.pinnedui[i].bg.name:SetRegionSize(300,60)

		self.pinnedui[i].bg.desc = self.pinnedui[i].bg:AddChild(Text(CHATFONT, 20))
		self.pinnedui[i].bg.desc:SetPosition(0, 50*i - 20, 0)
		self.pinnedui[i].bg.desc:SetHAlign(ANCHOR_LEFT)
		self.pinnedui[i].bg.desc:SetRegionSize(300,60)

		self.pinnedui[i].bg.close = self.pinnedui[i].bg:AddChild(ImageButton("images/hud/close_button.xml", "close_button.tex"))
		self.pinnedui[i].bg.close:SetPosition(-180, 50*i - 10, 0)
		self.pinnedui[i].bg.close:SetScale(0.4, 0.4, 1)
		self.pinnedui[i].bg.close:SetOnClick(function()
			self.pinnedachievements[i] = ""
		end)
	end
end

function uiachievement:loadtasklist()
	self.tasklist = {}
	for index = 1, 6 do
		local task_id = self.owner["seasonaltaskid"..index]:value()
		self.tasklist[index] = {
			id = task_id,
			definition = SeasonalCatalog.ById(task_id),
			progress = self.owner["seasonaltaskprogress"..index]:value(),
			target = self.owner["seasonaltasktarget"..index]:value(),
			done = self.owner["seasonaltaskdone"..index]:value(),
		}
	end
end

function uiachievement:rebuild()
	self:build()
	self:perk_build()
	self:task_build()
end

return uiachievement
