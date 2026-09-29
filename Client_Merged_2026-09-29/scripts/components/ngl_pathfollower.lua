-- 发送左键点击RPC的最远距离，超出会发送RPC失败
local SERVER_LEFTCLICK_DIST_SQ = 4096 --64*64
local CLIENT_ENTITY_LOADING_RANGE = 64
-- 为了让子路径搜索时能够加载到下一个节点附近是否有寻路墙，让最大的节点距离更接近屏幕加载距离
--make it closer to the entities loading range to make the subsearch can check all the obstacles
local MAX_STEP_DIST = 40
local MAX_STEP_DIST_SQ = MAX_STEP_DIST * MAX_STEP_DIST
-- 路径搜索的状态
-- the status of pathsearch
local STATUS_CALCULATING = 0
local STATUS_FOUNDPATH = 1
local STATUS_NOPATH = 2

-- 提前一小段距离视为到达，关闭延迟补偿会有大于1帧的延迟
-- 并且距离理应和速度有关，但速度似乎很难获取，特别是关闭延迟补偿时 locomotor被移除
--should adjust them according to the player's speed, increase them when high speed
local FORCESTOP_OFFSET = 2
local ARRIVESTEP_MOVEMENTPREDICT_ENABLED = .5
local ARRIVESTEP_MOVEMENTPREDICT_DISABLED = 1.25 --主要是提前切换到下一个点防止一段一段走的视觉上卡顿

local function IsSailingMoveMode(movemode)
	return movemode and movemode.is_boat_movement
end

local function StepToVector3(step)
	return Vector3(step.x, step.y, step.z)
end

local function Vector3ToStep(point)
	return {y = point.y, x = point.x, z = point.z}
end

-- 有效的路径，至少要有两个step，起点和终点
local function IsValidPath(path)
	return path ~= nil and path.steps and #path.steps >= 2
end

-- by 老王天天写bug
local function BitAND(a, b)
    local p, c = 1, 0
    while a > 0 and b > 0 do
        local ra, rb = a % 2, b % 2
        if ra + rb > 1 then
            c = c + p
        end
        a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
    end
    return c
end

local PathFollower = Class(function(self, inst)
    self.inst = inst

	--self.movemode = MOVEMODES.DIRECTWALK
	self.debugmode = false
	self.debug_signs = {}

	self.dest = nil
	self.path = nil
	self.atdestfn = nil
	self.search_queue = {}

	self.pathfinder = self.inst.components.fusedpathfinder

	self.subsearch_pathfinder = require("components/ngl_pathfinder") -- actually self.inst is not used 
	-- self.subsearch_pathfinder = self.inst.components.fusedpathfinder
	self.subsearch_enabled = true
	self.subsearch_info = {startstep = nil, endstep = nil} -- subsearch index of step
	
	self.allow_pathfinding_fog_of_war = false

end)

-- 确保路径里面两个step之间的距离在发送RPC的有效范围内（distsq < 4096），否则截断成两部分
-- make the distance between adjacent pathsteps in range of sendLeftClickRPC
-- it's unnecessary in DIRECTWALK Mode, but still should do that to handle the case when holding something over the cursor so that toggle to the LEFTCLICK Mode during the path following
local function SplitPathInRange(self, path, range, start_index, end_index)
	local start_index = math.max(1, start_index or 1)
	local end_index = math.min(#(path.steps), end_index or #(path.steps))
	local index = start_index+1
	while(index <= math.min(end_index, #(path.steps))) do
		local pre = StepToVector3(path.steps[index-1])
		local cur = StepToVector3(path.steps[index])
		if pre:DistSq(cur) > range*range + 4 then -- out of range, 4 is a small tolerance
			local inrange_pos = (cur - pre):GetNormalized()* (range)+pre
			table.insert(path.steps, index, Vector3ToStep(inrange_pos))
			end_index = end_index + 1
			--print("after split",StepToVector3(path.steps[index-1]):Dist(StepToVector3(path.steps[index])))
		else
			index = index + 1
		end
	end
	return path
end

local function CheckNotFogOfWar(self, path)
	if self.inst and self.inst.CanSeePointOnMiniMap then
		for _, step in ipairs(path.steps) do
			if not self.inst:CanSeePointOnMiniMap(step.x, step.y, step.z) then
				return false
			end
		end
	end
	return true
end

local function CheckAndGetSearchResult(self, is_subsearch)
	local pathfinder = is_subsearch and self.subsearch_pathfinder or self.pathfinder
	local search_over, validpath = false, nil
	local status = pathfinder and pathfinder:GetSearchStatus()
	if status ~= STATUS_CALCULATING then
		search_over = true
		-- local time = GetStaticTime()
		if status == STATUS_FOUNDPATH then
			-- GET PATH RESULT
			local foundpath = pathfinder:GetSearchResult()
			if foundpath and IsValidPath(foundpath) then  --[[and (self.allow_pathfinding_fog_of_war or CheckNotFogOfWar(self, foundpath))]]
				validpath = SplitPathInRange(self, foundpath, MAX_STEP_DIST)
				--print("get path, pathfinder ", pathfinder_str, " ,cost ", time - self.search_start_time)
			else
				--print("invalid path, pathfinder ", pathfinder_str, " ,cost ", time - self.search_start_time)
			end
			
		else
			if status == nil then
				-- LOST PATH SEARCH
				--print("lost search, pathfinder ", pathfinder_str, " ,cost ", time - self.search_start_time)
			else
				-- NO PATH
				--print("no path, pathfinder ", pathfinder_str, " ,cost ", time - self.search_start_time)
			end
		end
	end
	return search_over, validpath
end

-- see utils/astar_util:calcGroundSpeedMulti
local function IsFasterAtPoint(pathfinder, point, groundcaps)
	if pathfinder and pathfinder.IsFasterAtPoint then
		return pathfinder:IsFasterAtPoint(point, groundcaps)
	end
	return false
end

-- 子路径拼接完后进行路径平滑
local function SmoothPath(self, path, is_subsearch, start_index, end_index)
	local start_index = math.max(1, start_index or 1)
	local end_index = math.min(#(path.steps), end_index or #(path.steps))
	local check_pathcaps = self.avoidcreep_pathcaps --self:GetPathCaps(true)
	local check_groundcaps = self:GetGroundCaps(true)
	local check_pathfinder = self.pathfinder --is_subsearch and self.subsearch_pathfinder and self.pathfinder
	local boat = self.inst:GetCurrentPlatform()
	local boat_radius = boat and boat:GetPhysicsRadius() + 2 -- make it larger to make sure not collision happens
	-- should use LUA pathfinder to check point on faster ground

	local index = start_index+1 -- startindex的后一个step才是有可能会删除的
	while(index < math.min(end_index, #(path.steps))) do --endindex的前一个step才是有可能会删除的
		local pre = StepToVector3(path.steps[index-1])
		local post = StepToVector3(path.steps[index+1])
		local cur = StepToVector3(path.steps[index])
		-- delete the unnecessary points
		if (check_pathfinder:IsClear(pre, post, check_pathcaps, boat_radius)) and -- hasLOS
				not IsFasterAtPoint(check_pathfinder, cur, check_groundcaps) then -- not on faster ground  --[[or is_subsearch]] enable this if we use pathfinder that can follow road
					table.remove(path.steps, index)
					end_index = end_index -1

		else
			index = index + 1
		end
		--print("index:",index)
	end
	path = SplitPathInRange(self, path, MAX_STEP_DIST, start_index, end_index)
	return path
end

-- 用于寻路完成后的动态调整，将子路径拼接进原路径
-- when we get a subpath, next is to combine the subpath to the path
-- start_index and end_index is neccessary !!!
local function InsertSubPathToMainPath(self, path, subpath, start_index, end_index, without_smooth)
	-- 掐头去尾，中间部分插入
	-- remove the first and last step, insert the the internal part
	local sub_maxsteps = #(subpath.steps)
	if sub_maxsteps > 2 then
		local steps = deepcopy(path.steps)
		--删除原来路径的中间节点 {a(start_index), b, c, d(end_index)} --> {a,d}
		-- delete original internal step
		if (end_index - start_index) > 1 then
			for i= end_index-1, start_index+1, -1 do
				table.remove(steps, i)
				end_index = end_index - 1
			end
		end
		-- 将中间的节点加入到原路径 path.steps{a, d} + subpath.steps{d(firststep),e,f,h(laststep)} --> {a,e,f,d}
		-- merge internal steps of subpath(ignore the firststep and laststep because they're perhaps at overhang area) to pathsteps
		for i = 2, sub_maxsteps - 1 do
			local step = subpath.steps[i]
			table.insert(steps, start_index+i-1, step)
			end_index = end_index + 1
			if self.debugmode and self.debug_signs then
				local sign = SpawnPrefab("minisign")
				sign.Transform:SetPosition(step.x, step.y, step.z)

				table.insert(self.debug_signs, sign)
			end
		end
		path.steps = steps
		if not without_smooth then
			local smooth_iter = 2
			for i=1, smooth_iter do --need a total smooth method can work out at only once
				path = SmoothPath(self, path, true, start_index, #(path.steps)) --math.min(end_index + 2, #(path.steps))
			end
		end
		--print("merge subpath to path")
	end
	return path
end

-- Find the next path step that is fully walkable, no walls (pathfinding cell), no spider webs (creep)
-- 寻找下一个无阻挡、无蜘蛛网的可走路径点
local function GetIndexOfNextWalkableStep(self, path, start_index, end_index)
	local steps = path and path.steps
	if steps ~= nil then
		local pathfinder = self.subsearch_pathfinder
		local pathcaps = self.avoidcreep_pathcaps
		for i=start_index, (end_index or #(steps)) do
			local step = steps[i]
			if pathfinder:IsPassableAtPoint(StepToVector3(step), pathcaps) then
				return i
			end

		end
	end
end

-- Find the farthest step within the client's entity loading range
-- 寻找客户端加载范围内最远的路径点
local function GetIndexOfLastInRangeStep(self, path, range, start_index, end_index)
	local steps = path and path.steps
	if steps ~= nil then
		local start_step = steps[start_index]
		for i=(end_index or #(steps)), start_index, -1 do
			local step = steps[i]
			if VecUtil_DistSq(step.x, step.z, start_step.x, start_step.z) <= range*range then
				return i
			end
		end
	end
end

-- Find the next step that is IN FRONT of the player, WALKABLE, and within RPC range
-- 寻找角色【前方、可通行、在RPC范围内】的下一个路径点
local function GetIndexOfNextForewardWalkableInRangeStep(self, path, range, start_index, end_index)
	local max_steps = #(path.steps)
	if max_steps <=2 then return end

	start_index = math.max(2, start_index or 2)
	end_index = math.min(end_index or max_steps, max_steps)
	local my_pos = self.inst:GetPosition()
	local my_angle = self.inst:GetRotation()
	local pathfinder = self.pathfinder
	local pathcaps = self.avoidcreep_pathcaps
	for i=start_index, end_index do
		local check_pt = StepToVector3(path.steps[i])
		local pt_angle = self.inst:GetAngleToPoint(check_pt:Get())
		-- get next in foreward, walkable, in-rpc-range step
		if math.abs(my_angle - pt_angle) <= 90 and 
			pathfinder:IsClear(my_pos, check_pt, pathcaps) and
				VecUtil_DistSq(my_pos.x, my_pos.z, check_pt.x, check_pt.z) <= range*range then
					return i
		end
	end
end

-- sometimes first step is in backward, FIXME 
local function PathSetNewFirstStep(self, path)

	-- 需要考虑一个情况：当寻路得到结果时，人物当前的位置可能和起始点因为移动存在一些偏差
	-- 可能会导致当前位置不再与第二个step连通,也可能不再在RPC发送范围内
	-- 这时需要把原点设置为角色位置，检查是否再连通，不连通则多一步为原来的起点
	-- to handle the case of this:
	-- https://forums.kleientertainment.com/klei-bug-tracker/dont-starve-together/a-rare-pathfind-bug-r40745/
	-- in that case, we may have shifted the position which is the startpos of pathsearch since maintaining the previous movement
	-- should recheck the LOS between second step and player's position and recheck the range of steps

	local MAX_CHECK_PASSED_STEPS = 5
	-- make this step became the second step
	local new_secondstep = GetIndexOfNextForewardWalkableInRangeStep(self, path, MAX_STEP_DIST, 2, MAX_CHECK_PASSED_STEPS) or 2

	-- delete the steps before that
	for i=1, new_secondstep-1 do
		table.remove(path.steps, 1)
	end
	-- insert my position to first step
	table.insert(path.steps, 1, Vector3ToStep(self:GetCurrentPos()))
	path = SplitPathInRange(self, path, MAX_STEP_DIST, 1, 2)
	return path
end

-- 有点像这样：http://theory.stanford.edu/~amitp/GameProgramming/MovingObstacles.html#recalculating-paths
-- 但我是为了处理在移动过程中新进入加载范围的障碍物
-- 由于客户端存在玩家一定范围加载实体，范围外实体无法检测，因此第一次寻路可能检测不到范围外的墙体和蜘蛛网，当每次到达下一步时再次进行子路径寻路来动态调整
-- we are not able to check all the entities(walls, spidernet) about ground condition, because the game is only load the entities in a player range
-- so we should check the LOS and adjust the following steps when we arrive next step during the pathfollow
-- it works just like this: http://theory.stanford.edu/~amitp/GameProgramming/MovingObstacles.html#recalculating-paths
-- but to handle the obstacles which are new into the loading range when pathfollowing
local function DoSubpathSearch(self)
	-- clear the previous work
	self:KillSubpathSearch()
	self:KillPendingSubpathSearches()
	self.subsearch_info = {startstep = nil, endstep = nil}
	-- update the pathfinding walls
	local boat = self.inst:GetCurrentPlatform()
	TheWorld.ngl_pathfinding_settings = {enabled = true, boat = boat}
	TheWorld:PushEvent("ngl_pathfinding_change",{enabled = true, boat = boat})
	-- clear the previous subpath search task
	if self.subsearch_task ~= nil then
		self.subsearch_task:Cancel()
	end
	-- delay 1 frame to make sure all obstacles has received the event and finished update the pathfinding walls
	self.subsearch_task = self.inst:DoTaskInTime(0, function()
		if not self.in_subpathsearching and self.path ~= nil then
			local check_pathfinder = self.subsearch_pathfinder
			local check_pathcaps = self.avoidcreep_pathcaps or self:GetPathCaps(true)
			local check_groundcaps = self:GetGroundCaps(true)
			local path = self.path
			-- actually it means index
			local currentstep = self.path.currentstep
			local maxstep = #(path.steps)
			local check_startindex, check_endindex = currentstep, GetIndexOfLastInRangeStep(self, path, CLIENT_ENTITY_LOADING_RANGE, currentstep, maxstep) or maxstep
			local subsearch_startindex, subsearch_endindex = nil, nil
			for i= check_endindex, check_startindex, -1 do
				if not check_pathfinder:IsClear(StepToVector3(path.steps[i-1]), StepToVector3(path.steps[i]), check_pathcaps) then
					subsearch_startindex = currentstep - 1
					subsearch_endindex = GetIndexOfNextWalkableStep(self, path, i) or maxstep
					break
				end
			end
			-- if has not LOS we should do subpath search to adjust the follow-up steps
			if subsearch_startindex and subsearch_endindex then --check LOS(line of sight)
				self.subsearch_info = {startstep = subsearch_startindex, endstep = subsearch_endindex}
				-- if we use fused pathfinder or lua pathfinder, should add to pathsearch queue to avoid the resource grabbing of a single LUA pathfinder
				local startpos = StepToVector3(path.steps[subsearch_startindex])
				local endpos = StepToVector3(path.steps[subsearch_endindex])
				self:AddToPathSearchQueue(startpos, endpos, check_pathcaps, check_groundcaps, true)
				-- print("start a subpath search at index of ", subsearch_startindex,"~", subsearch_endindex, "total step:", maxstep)
			end
		end
		self.subsearch_task = nil
	end)
end

-- 得到路径后保证人物跟随，检查与下一步的位置，到达后切换下一步，直至到达终点
-- when we get a path ,just make the character following it
local function FollowPath(self)
	local path = self.path
	local inst = self.inst
	if path == nil then return end

	self:UpdateMoveMode()
	-- local can_move = self:CanMove()
	-- if not can_move then
	-- 	return
	-- end

	local cur_pos = self:GetCurrentPos()
	cur_pos.y = 0

	local currentstep_pos = StepToVector3(path.steps[path.currentstep]) -- {x,y,z} --> Vector3

	local step_distsq = cur_pos:DistSq(currentstep_pos)

	-- Add tolerance to step points.
	local boat = self.inst:GetCurrentPlatform()
	local physdiameter = IsSailingMoveMode(self:GetMoveMode(true)) and boat
							and boat:GetPhysicsRadius(0)*2
							or self.inst:GetPhysicsRadius(0)*2
	step_distsq = step_distsq - physdiameter * physdiameter

	local arrive_step_dist = self:GetArriveStep()
	if step_distsq <= (arrive_step_dist)*(arrive_step_dist) then -- arrive currentstep_pos, move to nextstep
		local maxsteps = #self.path.steps
		if self.path.currentstep < maxsteps then
			self.path.currentstep = self.path.currentstep + 1
			self.inst:PushEvent("ngl_startnextstep", {currentstep = self.path.currentstep})
			local step = self.path.steps[self.path.currentstep]
			self:MoveTo(StepToVector3(step))
			--print("switch to nextstep")
			if self.subsearch_enabled then
				DoSubpathSearch(self)
			end
		else
			self.inst:PushEvent("ngl_onreachdestination",{ pos = self.dest })
			if self.atdestfn ~= nil then
				self.atdestfn(self.inst)
			end
			--print("arrive the dest")

			self:ForceStop()
		end
	else -- no need to send move action, but we should handle some bad case here
		if step_distsq > SERVER_LEFTCLICK_DIST_SQ - 100 then -- for some reason, we're out of rpc range
			local inrange_pos = (cur_pos - currentstep_pos):GetNormalized()* (MAX_STEP_DIST)+currentstep_pos
			table.insert(path.steps, path.currentstep, Vector3ToStep(inrange_pos))
		end

		-- resume the following if we stopped or we are offtrace for some reason
		if self:ShouldResumeMoving() or self:IsOffTrack() then
			self:MoveTo(StepToVector3(path.steps[path.currentstep]))
			--print("re-moveto")
		end
	end
end

local function DirectWalkWithNoPath(self)
	local cur_pos = self:GetCurrentPos()
	cur_pos.y = 0
	local dest_distsq = cur_pos:DistSq(self.dest)
	self:UpdateMoveMode()
	local should_resume = self:ShouldResumeMoving()

	local arrive_step_dist = 2 --set larger tolerance because we have not set redirectfn in this case so far
	if dest_distsq <= (arrive_step_dist)*(arrive_step_dist) then
		self.inst:PushEvent("ngl_onreachdestination",{ pos = self.dest })
		if self.atdestfn ~= nil then
			self.atdestfn(self.inst)
		end
		self:ForceStop()
	elseif should_resume then
		self:MoveTo(self.dest)
	end
end

-- ######################################################################
-- 【WallUpdate】= 寻路结果查询 + 设置路径（不受暂停影响）
-- ######################################################################
function PathFollower:OnWallUpdate(dt)
	-- 1.启动寻路
	self:TryToDoPathSearch()

	-- 2.主路径结果
	if self.in_mainpathsearching then
		local search_over, foundpath = CheckAndGetSearchResult(self)
		-- Search Over: path search finished, stop and clean the search, Setup the final path
		-- Otherwise  ：still in calculating, waiting for next update to check again

		-- 寻路完成		: 处理结果，设置路径
		-- 寻路未完成	：继续等待下一帧更新来检查结果
		if search_over then
			-- clean the main search and set in_mainpathsearching to false
			self:KillMainpathSearch()
			
			local final_path = foundpath
			local prev_path_not_existed = self.path == nil
			if final_path ~= nil then
				-- self.search_over_time = GetStaticTime()
				if prev_path_not_existed then -- 原来没有路径，设置为新路径
					--set up path
					-- fix firststep
					final_path = PathSetNewFirstStep(self, final_path)
					-- final_path = SmoothPath(self, final_path)
					self.path = {}
					self.path.steps = final_path.steps
					self.path.currentstep = 2
				else -- concatenate with existed path -- 原来有路径，是追加寻路，将新路径拼接到原路径的后面（去掉原路径的终点因为和新路径的起点重合)
					local existed_steps = deepcopy(self.path.steps)
					local currrentstep = self.path.currentstep
					table.remove(existed_steps) -- remove the endpos
					for _, step in pairs(final_path.steps) do
						table.insert(existed_steps, step)
					end
					self.path.steps = existed_steps
					-- SmoothPath(self, self.path, false, currrentstep, #(self.path.steps))
					self:MoveTo(StepToVector3(self.path.steps[currrentstep]))
				end
			else -- no path or invalid path -- 寻路失败，直走
				-- direct walk
				prev_path_not_existed = true
				self.path = nil
				self.search_queue = {}
			end

			---- 开始出发 some special settings when first time to move
			if prev_path_not_existed then
				if self.path ~= nil then -- first time get the path, setup path following
					-- for debug
					if self.debugmode then
						self:VisualizePath()
					end

					-- start pathfollow
					self:UpdateMoveMode()
					self:MoveTo(StepToVector3(self.path.steps[self.path.currentstep]))
					self.inst:PushEvent("ngl_startpathfollow", {path = self.path})

					-- subpath search
					if self.subsearch_enabled then
						-- 动态路径调整中 设置为蜘蛛网不可走，来实现绕路
						-- 这样就算没有找到路，顶多也就是维持原路 不进行这段的动态调整
						local groundcaps = self:GetGroundCaps(true)
						local avoidcreep_pathcaps = shallowcopy(self:GetPathCaps(true))
						avoidcreep_pathcaps.ignorecreep = not (groundcaps.speed_on_creep and groundcaps.speed_on_creep < 0)
						-- avoidcreep_pathcaps.ignoreflood = not (groundcaps.speed_on_flood and groundcaps.speed_on_flood < 0) -- DEPRECATED see bypass prefab defs
						self.avoidcreep_pathcaps = avoidcreep_pathcaps
						DoSubpathSearch(self)
					end
				else -- get no path, setup direct walking
					if self.dest then
						-- start direct walk with no path
						--self:SetMoveModeOverrideInternal(MOVEMODES.DIRECTWALK) -- now it should also adapted to sailing move mode
						self:UpdateMoveMode()
						self:MoveTo(self.dest)
						self.inst:PushEvent("ngl_startdirectwalkwithnopath", {dest = self.dest})
					end
				end
			end
		end
	end -- in_mainpathsearching end

    -- 3. 子路径结果
    if self.in_subpathsearching then
        local over, subpath = CheckAndGetSearchResult(self, true)
        if over then
            self:KillSubpathSearch()
            if subpath and self.subsearch_info and self.subsearch_info.startstep then
                self.path = InsertSubPathToMainPath(self, self.path, subpath,
                    self.subsearch_info.startstep, self.subsearch_info.endstep,
                    IsSailingMoveMode(self:GetMoveMode(true)))
				self:MoveTo(StepToVector3(self.path.steps[self.path.currentstep]))
                self.subsearch_info = {startstep = nil, endstep = nil}
            end
        end
    end
end

-- ######################################################################
-- 【OnUpdate】= 仅路径跟随（游戏帧，暂停不执行）
-- ######################################################################
function PathFollower:OnUpdate()
    -- 有路径：跟随
    if self.path ~= nil and IsValidPath(self.path) then
        FollowPath(self)
    -- 无路径：直接走
	elseif self.dest ~= nil then
        DirectWalkWithNoPath(self)
    end
end

function PathFollower:GetCurrentPos()
	if IsSailingMoveMode(self:GetMoveMode(true)) and self.inst:GetCurrentPlatform() then
		return self.inst:GetCurrentPlatform():GetPosition()
	else
		return self.inst:GetPosition()
	end
end

function PathFollower:CanMove()
	local movemode = self:GetMoveMode(true)
	return movemode and movemode.check_canmove_fn and movemode.check_canmove_fn(self)
end

function PathFollower:ShouldResumeMoving()
	local movemode = self:GetMoveMode(true)
	return movemode and movemode.check_shouldresume_fn and movemode.check_shouldresume_fn(self)
end

-- 根据不同移动模式来执行移动
-- select GoToPoint or MoveInDirection by self:GetMoveMode()
function PathFollower:MoveTo(pos)
	if not self:CanMove() then return end
	local movemode = self:GetMoveMode()
	if movemode and movemode.on_move_fn then
		movemode.on_move_fn(self, pos)
	end
end

-- 在DIRECTWALK模式可能因为碰撞或其他原因偏移路径（LEFTCLICK模式下本身会寻路且紧跟路径），需要检测是否偏移，重新矫正方向
-- only beyond this distance should we correct direction in DIRECTWALK movemode
local REDIRECT_DIST = 1

-- 点与直线的距离
-- the distance between point and line of two points
local function getDistFromPointToLine(point, linePoint1, linePoint2)
	local x0,y0 = point.x, point.z
	local x1,y1 = linePoint1.x, linePoint1.z
	local x2,y2 = linePoint2.x, linePoint2.z
	return math.abs( (x2-x1)*(y0-y1) - (y2-y1)*(x0-x1) ) / math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))
end

-- 检查玩家与路径的距离，距离路径超出REDIRECT_DIST时 矫正方向
-- we should correct the direction if we are far from the path
function PathFollower:IsOffTrack()
	if self.path == nil or not self:FollowingPath() then return false end
	local movemode = self:GetMoveMode(true)
	if movemode and movemode.check_offtrack then
		local path = self.path
		local cur_pos = self:GetCurrentPos()
		cur_pos.y = 0
		local curstep_pos = StepToVector3(path.steps[path.currentstep])
		local prestep_pos = StepToVector3(path.steps[math.min(path.currentstep - 1, 1)])
		if curstep_pos == prestep_pos then return false end -- will result in a denominator of 0 when caculating the distance

		local dist = getDistFromPointToLine(cur_pos, prestep_pos, curstep_pos)
		--print("TRAVEL: DIST - ",dist)
		return dist > REDIRECT_DIST
	end
	return false
end

-- 强制停止，清除所有任务，停止人物移动
-- stop and reset all the record
function PathFollower:ForceStop()
	self.inst:StopUpdatingComponent(self)
	self.inst:StopWallUpdatingComponent(self)
	self.in_updating = false

	self:Clear()
	local movemode = self:GetMoveMode(true)
	if movemode and movemode.on_stop_fn then
		movemode.on_stop_fn(self)
	end

	self.inst:PushEvent("ngl_stoppathfollow")
	TheWorld.ngl_pathfinding_settings = {enabled = false}
	TheWorld:PushEvent("ngl_pathfinding_change",{enabled = false})
end

-- 清除所有任务和数据
function PathFollower:Clear()
	self:KillAllSearches()

	self.path = nil
	self.dest = nil
	self.search_queue = {}

	if self.debug_signs ~= nil then
		for _, sign in pairs (self.debug_signs) do
			sign:Remove()
		end
		self.debug_signs = nil
	end
end

local function StopOtherAutoRowingTask(inst)
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=2836299735
	local pc = inst.components.playercontroller
	local script = pc and pc.automation_tasks and pc.automation_tasks.paddle
	if script and script.Interrupt then
		script:Interrupt()
	end
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=3116915877
	if inst.detect_interrupt_task ~= nil then
        TheInput.oncontrol:RemoveHandler(inst.detect_interrupt_task)
        inst.detect_interrupt_task = nil
    end
    if inst.auto_row_task ~= nil then
        inst.auto_row_task:Cancel()
        inst.auto_row_task = nil
    end
end

-- 触发自动走路，输入可以是1. Vector3（触发寻路）； 2. Steps； 3. Path
-- OVERLOAD:
-- 1. Vector3 as input(Vector3)
-- 2. steps as input {{x = x1,y = y1,z = z1},....}
-- 3. path as input {steps = {...}}
function PathFollower:Travel(destPos, additional)
	if destPos == nil then return end
	if not additional then
		self:Clear()
		StopOtherAutoRowingTask(self.inst)
	end

	if destPos.IsVector3 and destPos:IsVector3() then -- is a Vector3
		local destpos_pathfindable = self.allow_pathfinding_fog_of_war or
				(self.inst and self.inst.CanSeePointOnMiniMap and self.inst:CanSeePointOnMiniMap(destPos:Get()))

		local pathfinder = self.pathfinder
		if pathfinder and destpos_pathfindable then
			-- has move it to start following, which means add more obstacles' pathfinding walls only for subsearch
			---- for feature of avoid obstacle , see components/ngl_pfwalls_clientonly.lua
			--TheWorld.ngl_pathfinding_settings = {enabled = true, boat = boat}
			--TheWorld:PushEvent("ngl_pathfinding_change",{enabled = true, boat = boat})
			local prev_dest = self.dest
			self.dest = destPos
			local boat = self.inst:GetCurrentPlatform()
			-- 客户端只加载一定范围的实体，因此最开始的寻路无法检测到范围外的墙体和蜘蛛网
			-- 走路过程中，每次到达当前步，再次对下一小段(范围见DoSubpathSearch 的 startstep endstep)进行寻路来重新检测墙体和蜘蛛网进行动态调整
			-- when client-side, the game only loads the entity in a range, so we recheck the obstacles when arrive current step
			-- do subpath search while pathfollow to adjust the follow-up steps
			local pathcaps = self:GetPathCaps()
			local groundcaps = self:GetGroundCaps()
			-- 忽略寻路墙和蜘蛛网的话没必要做动态调整
			-- it's unnecessary to do path adjustment when ignore pathfinding walls and spider-web
			self.subsearch_enabled = not (false or --TheWorld.ismastersim
					(pathcaps.ignorewalls and not (groundcaps.speed_on_creep and groundcaps.speed_on_creep == ASTAR_SPEED_SLOWER)))
			-- not the case of ignore walls and no speed down on creep meanwhile, subpathsearch is just for rechecking the walls and creep that are out of loading range
			self.inst:PushEvent("ngl_newdest", {dest = self.dest})
			if not additional then -- 否则可能影响路径动态调整，导致检测不到那些注册额外寻路墙的障碍物
				TheWorld:PushEvent("ngl_pathfinding_change",{enabled = false}) -- cancel the pathfinding cell at main path search and apply it at sub path search
			end
			-- params of self:FindPath
			self:AddToPathSearchQueue((not self:DirectWalkingWithNoPath()) and prev_dest or self:GetCurrentPos(), destPos, pathcaps, groundcaps, false)
		else
			self.dest = destPos
			self.path = nil
			-- start direct walk with no path
			--self:SetMoveModeOverrideInternal(MOVEMODES.DIRECTWALK) -- now it should adapted to sailing move mode
			self:MoveTo(self.dest)
			self.inst:PushEvent("ngl_startdirectwalkwithnopath", {dest = self.dest})
		end

	elseif type(destPos) == "table" then
		local steps
		if IsValidPath(destPos) then					-- is a path
			steps = destPos.steps
		elseif #destPos >= 2 then						-- is a steps
			steps = destPos
		end

		if steps ~= nil then
			self.dest = StepToVector3(steps[#steps])
			self.path = {steps = steps, currentstep = 2}
			self.subsearch_enabled = false -- a preset-path, dont change the path
			self.inst:PushEvent("ngl_startpathfollow", {path = self.path})
		else
			print("invalid travel input")
			return
		end
	end

	self.inst:StartUpdatingComponent(self)
	self.inst:StartWallUpdatingComponent(self)
	self.in_updating = true

end

--队列依次进行主路径搜索
function PathFollower:AddToPathSearchQueue(startpos, endpos, pathcaps, groundcaps, is_subsearch)
	if self.search_queue == nil then self.search_queue = {} end
	table.insert(self.search_queue, {startpos = startpos, endpos = endpos, pathcaps = pathcaps, groundcaps = groundcaps, is_subsearch = is_subsearch or false})
end

-- 搜索空闲时执行路径搜索
function PathFollower:TryToDoPathSearch()
	-- if not self.in_mainpathsearching and self.search_queue and next(self.search_queue) ~= nil then
	if not self.in_mainpathsearching and not self.in_subpathsearching and self.search_queue and next(self.search_queue) ~= nil then
		local params = table.remove(self.search_queue, 1)
		self:FindPath(params.startpos, params.endpos, params.pathcaps, params.groundcaps, params.is_subsearch) --false
	end
end

-- pathfind via one pathfinder at once
function PathFollower:FindPath(startpos, endpos, pathcaps, groundcaps, is_subsearch)
	--print("pathfinding with" , self.using_lua_pathfinder and "Lua-side" or "C-side" , "pathfinder" )

	local pathfinder = is_subsearch and self.subsearch_pathfinder or self.pathfinder
	if pathfinder == nil then return end

	local p0 = startpos or Vector3(self:GetCurrentPos():Get())
	local p1 = endpos or Vector3(self.dest:Get())

	p0.y = 0
	p1.y = 0

	local pathcaps = pathcaps or self:GetPathCaps()
	local groundcaps = groundcaps or self:GetGroundCaps()
	-- self:SetPathCapsOverrideInternal(pathcaps) --if pathcaps nil, then set override as nil, which means cancel the override
	-- self:SetGroundCapsOverrideInternal(groundcaps)

	-- add boat_radius for boat pathfinding(extra avoid collision with shore)
	local boat = self.inst:GetCurrentPlatform()
	local boat_radius = boat and boat:GetPhysicsRadius() + 2
	pathfinder:SubmitSearch(p0, p1, pathcaps, groundcaps, boat_radius)

	if is_subsearch then
		self.in_subpathsearching = true
	else
		self.in_mainpathsearching = true
	end
	-- self.search_start_time = GetStaticTime()
	--self.waitsearchresult_task = self.inst:DoPeriodicTask(FRAMES, check_search_status, FRAMES)
end

function PathFollower:KillAllSearches()
	self:KillMainpathSearch()
	self:KillSubpathSearch()
end

function PathFollower:KillMainpathSearch()
	self.in_mainpathsearching = false
	if self.pathfinder ~= nil then
		self.pathfinder:KillSearch()
	end
end

function PathFollower:KillSubpathSearch()
	self.in_subpathsearching = false
	if self.subsearch_pathfinder ~= nil then
		self.subsearch_pathfinder:KillSearch()
	end
end

function PathFollower:KillPendingSubpathSearches()
	if self.search_queue == nil or next(self.search_queue) == nil then return end
	for i=#(self.search_queue), 1, -1 do
		local search_params = self.search_queue[i]
		if search_params and search_params.is_subsearch then
			table.remove(self.search_queue, i)
		end
	end
end

function PathFollower:HasDest()
	return self.dest ~= nil
end

function PathFollower:GetLocomotor()
	return self.inst.components.locomotor or nil
end

function PathFollower:WaitingForPathSearch()
	-- return self.waitsearchresult_task ~= nil
	return self.in_updating and self.path == nil and (self.in_mainpathsearching or next(self.search_queue) ~= nil)
end

function PathFollower:FollowingPath()
	-- return self.followpath_task ~= nil
	return self.in_updating and self.path ~= nil
end

function PathFollower:DirectWalkingWithNoPath()
	-- return self.check_arrival_for_directwalk_task ~= nil
	return self.in_updating and self.path == nil and not (self.in_mainpathsearching or next(self.search_queue) ~= nil)
end

function PathFollower:GetPathfinder()
	return self.pathfinder
end

local function is_implemented_required_interfaces(pathfinder_cmp)
	return (pathfinder_cmp.SubmitSearch and pathfinder_cmp.GetSearchStatus and pathfinder_cmp.GetSearchResult and pathfinder_cmp.KillSearch and pathfinder_cmp.SetMaxTime) ~= nil
end

local function get_pathfinder_component(pathfinder, self)
	local pathfinder_cmp = nil
	if type(pathfinder) == "string" and self.inst.components[pathfinder] then
		pathfinder_cmp = self.inst.components[pathfinder]
	elseif type(pathfinder) == "table" then
		pathfinder_cmp = pathfinder
	end
	return pathfinder_cmp
end

-- set C-side Pathfinder, higher efficiency with inherent time limits
-- FindPath via C pathfinder first
function PathFollower:SetPathfinder(pathfinder)
	if pathfinder then
		local pathfinder_cmp = get_pathfinder_component(pathfinder, self)
		if pathfinder_cmp == nil then
			print("Pathfinder not exists")
			return
		end
		if is_implemented_required_interfaces(pathfinder_cmp) then
			self.pathfinder = pathfinder_cmp
		else
			print("Pathfinder has not implemented all requested interfaces")
		end
	end
end

function PathFollower:GetArriveStep()
	local movemode = self:GetMoveMode(true)
	if movemode and movemode.is_boat_movement then return 0 end
	return self:GetLocomotor() and ARRIVESTEP_MOVEMENTPREDICT_ENABLED or ARRIVESTEP_MOVEMENTPREDICT_DISABLED
end

--- MOVE MODE

-- Deprecated, self-adapte by default and use SetMoveModeOverrideInternal to override it
--function PathFollower:SetMoveMode(movemode)
--	self.movemode = movemode
--end

-- use for component internal toggle movemode
function PathFollower:SetMoveModeOverrideInternal(movemode)
	self._movemode_override = movemode
end

-- outer interface and with higher priority, note that setmovemodeoverride before the Travel
function PathFollower:SetMoveModeOverride(movemode)
	self.movemode_override = movemode
end

local MOVEMODES = require("ngl_movemodes")
local MOVEMODES_ARRAY = {}
for k,v in pairs(MOVEMODES) do
	table.insert(MOVEMODES_ARRAY, {mode = k, fn = v.pick_movemode_fn, priority = v.priority})
end
table.sort(MOVEMODES_ARRAY, function(a,b)  return a.priority > b.priority end)

-- should update the movemode after call Self:Move
function PathFollower:UpdateMoveMode()
	local prev_movemode = self.movemode
	for k,v in ipairs(MOVEMODES_ARRAY) do
		if type(v.fn) == "function" and v.fn(self) then
			self.movemode = MOVEMODES[v.mode]
			break
		end
	end
	-- quick fix directwalk issue
	if prev_movemode == MOVEMODES.DIRECTWALK and self.movemode ~= MOVEMODES.DIRECTWALK and self:GetLocomotor() == nil then
		SendRPCToServer(RPC.StopWalking)
	end
end

-- without_update means you will get the previous movemode
-- Match the movemode when Move and Stop, otherwise it may cause some issue
function PathFollower:GetMoveMode(without_update)
	if not without_update then
		self:UpdateMoveMode()
	end
	return self.movemode_override or self._movemode_override or self.movemode
end

--- PATH CAPS
function PathFollower:SetPathCapsOverrideInternal(pathcaps)
	self._pathcaps_override = pathcaps
end

function PathFollower:SetPathCapsOverride(pathcaps)
	self.pathcaps_override = pathcaps
end

-- a function return can player collide with other
-- for example: if we can cross the ocean and land ,then it return false with COLLISION.LAND_OCEAN_LIMITS
function PathFollower:CanCollideWith(COLLISION_TYPE)
-- | COLLISION_TYPE    | MASK_VALUE | BIN_VALUE           |
-- | ----------------- | ---------- | ------------------- |
-- | GROUND            | 32         | 0000 0000 0010 0000 |
-- | BOAT_LIMITS       | 64         | 0000 0000 0100 0000 |
-- | LAND_OCEAN_LIMITS | 128        | 0000 0000 1000 0000 |
-- | LIMITS            | 192        | 0000 0000 1100 0000 |
-- | WORLD             | 224        | 0000 0000 1110 0000 |
-- | ITEMS             | 256        | 0000 0001 0000 0000 |
-- | OBSTACLES         | 512        | 0000 0010 0000 0000 |
-- | CHARACTERS        | 1024       | 0000 0100 0000 0000 |
-- | FLYERS            | 2048       | 0000 1000 0000 0000 |
-- | SANITY            | 4096       | 0001 0000 0000 0000 |
-- | SMALLOBSTACLES    | 8192       | 0010 0000 0000 0000 |
-- | GIANTS            | 16384      | 0100 0000 0000 0000 |

--GROUND            = 32,
--BOAT_LIMITS       = 64,
--LAND_OCEAN_LIMITS = 128,             -- physics wall between water and land
--LIMITS            = 128 + 64,        -- BOAT_LIMITS + LAND_OCEAN_LIMITS
--WORLD             = 128 + 64 + 32,   -- BOAT_LIMITS + LAND_OCEAN_LIMITS + GROUND
--ITEMS             = 256,
--OBSTACLES         = 512,
--CHARACTERS        = 1024,
--FLYERS            = 2048,
--SANITY            = 4096,
--SMALLOBSTACLES    = 8192,		-- collide with characters but not giants
--GIANTS            = 16384,	-- collide with obstacles but not small obstacles
    local collision_mask = self.inst.Physics:GetCollisionMask()
    return BitAND(collision_mask, COLLISION_TYPE) == COLLISION_TYPE
end

function PathFollower:UpdatePathCaps()
	local isplayer = self.inst:HasTag("player")
	local iswebber = self.inst:HasTag("spiderwhisperer")
	local is_onland = self.inst:IsOnValidGround() -- is standing on land at this moment

    -- get result from Physics component(C++ side) and use bit operate function
	local no_land_ocean_limits = not self:CanCollideWith(COLLISION.LAND_OCEAN_LIMITS)
	local no_obstacle_collision = not self:CanCollideWith(COLLISION.OBSTACLES)
	self.pathcaps = {
						player = isplayer, ignorecreep = true, ignorewalls = no_obstacle_collision,
						allowocean = not is_onland or no_land_ocean_limits,
						ignoreLand = not is_onland and not no_land_ocean_limits,
						-- ignoreflood = true, -- DEPRECATED, see ngl_floodpfwalls component
					}
	-- ignorecreep = false means you will failed to find a way if all areas are on creep
	-- speed down on creep means you will prior to find a way without creep, but in worst casea it will get the way on the creep
end


function PathFollower:GetPathCaps(without_update)
	if not without_update then
		self:UpdatePathCaps()
	end
	return self.pathcaps_override or self._pathcaps_override or self.pathcaps
end

--- FASTER GROUND TILES
--this may be very expensive
local function search_faster_on_tiles(inst)
    local faster_on_tiles = {}
    for tile_name, tile_id in pairs(WORLD_TILES) do
        if TileGroupManager:IsLandTile(tile_id) then
            if inst:HasTag("turfrunner_"..tostring(tile_id)) then
                faster_on_tiles[tostring(tile_id)] = true
            end
        end
    end
    --print("call faster tiles search")
    return faster_on_tiles
end

function PathFollower:UpdateCachedFasterGroundTiles(mount)
    local inst = mount or self.inst
    if self.cached_faster_on_tiles == nil then
        self.cached_faster_on_tiles = {}
    end
    self.cached_faster_on_tiles[inst] = search_faster_on_tiles(inst)
end


function PathFollower:GetFasterGroundTiles(mount, without_update)
    local inst = mount or self.inst
    if self.cached_faster_on_tiles == nil or self.cached_faster_on_tiles[inst] == nil and not without_update then
        -- update only has no corresponding record
        self:UpdateCachedFasterGroundTiles(inst)
    end
    return self.cached_faster_on_tiles[inst]
end

--- GROUND CAPS
function PathFollower:SetGroundCapsOverrideInternal(groundcaps)
	self._groundcaps_override = groundcaps
end

function PathFollower:SetGroundCapsOverride(groundcaps)
	self.groundcaps_override = groundcaps
end

-- for astar pathfinder
function PathFollower:UpdateGroundCaps()
	self.groundcaps = {speed_on_road = nil, speed_on_creep = nil, faster_on_tiles = nil}
	-- i'm not sure the groundcaps when you pick a mod character who can fly
	-- at least we can exclude the ghost, we can sure ghost is no speed change for ground
	local can_cross_limits = not self:CanCollideWith(COLLISION.LAND_OCEAN_LIMITS)
	local isghost = self.inst:HasTag("player") and
					(self.inst.player_classified ~= nil and self.inst.player_classified.isghostmode:value()) or
					(self.inst.player_classified == nil and self.inst:HasTag("playerghost"))

	if isghost then return end

	local iswebber = self.inst:HasTag("spiderwhisperer")
-- 	local isriding =(self.inst.replica and self.inst.replica.rider and self.inst.replica.rider._isriding:value()) or
-- 					(self.inst.components and self.inst.components.rider and self.inst.components.rider:IsRiding())
	local mount = (self.inst.player_classified ~= nil and self.inst.player_classified.ridermount:value()) or
	              (self.inst.components and self.inst.components.rider and self.inst.components.rider:GetMount()) or
	              nil
	local locomotor = self:GetLocomotor()

	-- DEPRECATED
	-- --FLOOD (island adventure Mod)
	-- local world_has_flood_cmp = TheWorld.components.flooding ~= nil
	-- local has_flood_immune_tags = self.inst:HasTag("flying") or self.inst:HasTag("flood_immune") or self.inst:HasTag("playerghost")
	-- self.groundcaps.speed_on_flood = world_has_flood_cmp and not has_flood_immune_tags and ASTAR_SPEED_SLOWER or ASTAR_SPEED_NORMAL


	--ROAD
	if mount ~= nil then
		local mount_faster_on_road = (self.inst.player_classified ~= nil and self.inst.player_classified.riderfasteronroad:value()) or
									 (mount.components.locomotor ~= nil and mount.components.locomotor.fasteronroad)
		self.groundcaps.speed_on_road = mount_faster_on_road and ASTAR_SPEED_FASTER or ASTAR_SPEED_NORMAL
	else
		if locomotor then
			self.groundcaps.speed_on_road = locomotor.fasteronroad and ASTAR_SPEED_FASTER or ASTAR_SPEED_NORMAL
		else -- we can't get locomotor:FasterOnRoad() when lag compensation OFF ,but player always fasteronroad i think
			self.groundcaps.speed_on_road = ASTAR_SPEED_FASTER
		end
	end


	--CREEP(spidernet)
	--ghost not trigger the creep
	if mount ~= nil then
		-- webber riding the mount will not trigger the creep either
		self.groundcaps.speed_on_creep = (not iswebber) and ASTAR_SPEED_SLOWER or ASTAR_SPEED_NORMAL
	else
		if locomotor then
			self.groundcaps.speed_on_creep = locomotor.fasteroncreep and ASTAR_SPEED_FASTER or (locomotor.triggerscreep and ASTAR_SPEED_SLOWER or ASTAR_SPEED_NORMAL)
		else
			self.groundcaps.speed_on_creep = iswebber and ASTAR_SPEED_FASTER or ASTAR_SPEED_SLOWER
		end
	end

	--FASTER TILES
    --it 's corresponding to the locomotor.faster_on_tiles
    -- such as wurt --> MARSH

	if mount ~= nil then
		self.groundcaps.faster_on_tiles = self:GetFasterGroundTiles(mount)
	else
		self.groundcaps.faster_on_tiles = self:GetFasterGroundTiles(self.inst)
	end

end

function PathFollower:GetGroundCaps(without_update)
	if not without_update then
		self:UpdateGroundCaps()
	end
	return self.groundcaps_override or self._groundcaps_override or self.groundcaps
end

--- DEBUG FNS
function PathFollower:GetDebugString()

	if self.dest == nil then
		return "no dest"
	else
		local status
		if self:DirectWalkingWithNoPath() then
			status = "no path and reset to directwalk"
		elseif self:WaitingForPathSearch() then
			status = "waiting for search result"
		elseif self:FollowingPath() then
			status = "following the path"
		end

		return "DEST:" .. tostring(self.dest) .. " STATUS:" .. status
	end
end

function PathFollower:VisualizePath()
	if not IsValidPath(self.path) then return end
	self.debug_signs = {}
	for _,step in pairs (self.path.steps) do
		local sign = SpawnPrefab("minisign")
		sign.Transform:SetPosition(step.x, step.y, step.z)

		table.insert(self.debug_signs, sign)
	end
end

function PathFollower:SetDebugMode(enabled)
	self.debugmode = (enabled == true)
	if self:FollowingPath() then
		self:VisualizePath()
	end
end

function PathFollower:SendAction(act, rightclick, doubleclick)
	local function sendrpc(act, rightclick, doubleclick)
		local pos = act:GetActionPoint()
		local controlmods = act.controlmods or 10 --force stack and force attack
		if doubleclick then
			SendRPCToServer(RPC.DoubleTapAction, act.action.code, pos.x, pos.z, act.action.canforce, act.action.mod_name)
        elseif rightclick then
            SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, act.target, act.rotation, true, nil, act.action.canforce, act.action.mod_name)
        else
            SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, act.target, true, controlmods, act.action.canforce, act.action.mod_name)
        end
	end

    local playercontroller = self.inst.components.playercontroller
    if playercontroller == nil or act == nil then return end
    if playercontroller.locomotor == nil then
		if act.action and act.action.pre_action_cb then
			act.action.pre_action_cb(act)
		end
    	sendrpc(act, rightclick, doubleclick)
    elseif playercontroller:CanLocomote() then
		act.preview_cb = function()
			sendrpc(act, rightclick, doubleclick)
        end
        playercontroller:DoAction(act)
    end
end

return PathFollower