local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"

---------------------------PathLine---------------------------------

local PathLine = Class(Image, function(self, atlas, tex)
    Image._ctor(self, atlas, tex, tex)
    self.default_h = 50

    -- 基准线条（外层半透明，抗锯齿底）
    self:SetVRegPoint(ANCHOR_MIDDLE)
    self:SetHRegPoint(ANCHOR_LEFT)
    self:SetTint(0.9, 0.9, 0.9, 0.5) -- 半透明外层

    -- 内层实心细线（核心视觉） ← 这是抗锯齿关键
    self.centerbar = self:AddChild(Image(atlas, tex, tex))
    self.centerbar:SetVRegPoint(ANCHOR_MIDDLE)
    self.centerbar:SetHRegPoint(ANCHOR_LEFT)
    self.centerbar:SetTint(1, 1, 1, 1) -- 实心内层
    -- self.centerbar:Hide()
end)

function PathLine:AdjustToPoints(startpos_x, startpos_y, endpos_x, endpos_y, zoom)
    local linevec_x, linevec_y = endpos_x - startpos_x, endpos_y - startpos_y
    local length = VecUtil_Length(linevec_x, linevec_y)

    -- 计算高度（外层粗 + 内层细）
	local w,h = self:GetSize()
    local height = zoom and (self.default_h / math.pow(zoom, 0.5)) or h
    local inner_height = height * 0.5 -- 内层更细

    -- 设置外层线条（抗锯齿层）
    self:SetSize(length, height)
    -- 设置内层线条（实心清晰层）
    self.centerbar:SetSize(length, inner_height)

    -- 旋转（保持不变）
    local angle = -VecUtil_GetAngleInDegrees(linevec_x, linevec_y)
    self:SetRotation(angle)
	
    self:SetPosition(startpos_x, startpos_y)
end

function PathLine:SetDefaultHeight(h)
    self.default_h = h
end

-- 设置路线颜色
function PathLine:SetColor(r, g, b, alpha)
    local a = alpha or 1 -- 默认不透明
    self:SetTint(r * 0.85, g * 0.85, b * 0.85, a * 0.5)  -- 外层柔和变暗
    self.centerbar:SetTint(r, g, b, a)                   -- 内层控制主通透
end

--------------------------------PathLineGroup----------------------------
-- 路线线条统一更新逻辑
-- 作用：根据寻路路径，更新主地图/小地图/SmallMap上的路线显示
-- mapwidget: 对应地图控件
-- path: 寻路路径数据
-- zoomScale: 缩放系数（不同地图的 uvscale 修正）
local function UpdatePathLines(self, mapwidget, path, zoomScale)
    -- 无效数据直接返回
    if not path or not self.lineImages or #self.lineImages == 0 then
        return
    end

    -- 基础参数
    local minimap          = mapwidget.minimap
    local baseZoom         = minimap and minimap:GetZoom() or 1
    local finalZoom        = baseZoom * (zoomScale or 1) -- 最终应用的缩放
    local currentStep      = path.currentstep
    local lastScreenX, lastScreenY = nil, nil

    -- 遍历所有路径点，逐段更新线条
    for stepIdx, step in ipairs(path.steps) do
        -- 当前路径点转屏幕坐标
        local screenX, screenY = mapwidget:WorldPosToScreenPos(step.x, step.z)
        local lineIndex        = stepIdx - 1 -- 线条索引 = 点索引 - 1
        local line             = self.lineImages[lineIndex]

        -- 只处理有效线条 & 有效寻路状态
        if lineIndex >= 1 and line and currentStep and ThePlayer then
            if lineIndex == currentStep - 1 then
                -- 【当前行进段】：起点绑定玩家位置，动态跟随
                local playerPos    = ThePlayer:GetPosition()
                local playerX, playerY = mapwidget:WorldPosToScreenPos(playerPos.x, playerPos.z)

                line:AdjustToPoints(playerX, playerY, screenX, screenY, finalZoom)
                line:Show()
            elseif lineIndex <= currentStep - 2 then
                -- 【已走过段】：隐藏
                line:Hide()
            else
                -- 【未行进段】：正常连接上一个点
                if lastScreenX and lastScreenY then
                    line:AdjustToPoints(lastScreenX, lastScreenY, screenX, screenY, finalZoom)
                end
                line:Show()
            end
        end

        -- 记录当前点为下一段的起点
        lastScreenX, lastScreenY = screenX, screenY
    end
end

-- 三大地图的路线更新入口（只保留各自差异逻辑）
local updateFns = {
    -- 主地图
    MapWidget = function(self, path)
        UpdatePathLines(self, self.mapwidget, path, 1)
    end,

    -- Minimap MOD 小地图
    MiniMapWidget = function(self, path)
        local minimapWidget = self.mapwidget
        local mapImg = minimapWidget.img

        -- 小地图需要同步位置偏移
        self:SetPosition(mapImg:GetPosition():Get())
        UpdatePathLines(self, minimapWidget, path, minimapWidget.uvscale)
    end,

    -- SmallMap MOD 小地图
    SmallMap = function(self, path)
        local smallMap = self.mapwidget
        local mapImg = smallMap.img

        self:SetPosition(mapImg:GetPosition():Get())
        UpdatePathLines(self, smallMap, path, smallMap.uvscale.x)
    end,
}


-- 路线组管理控件
local PathLineGroup = Class(Widget, function(self, mapwidget, atlas, tex)
    Widget._ctor(self, "PathLineGroup")

    self.mapwidget = mapwidget
    self.line_atlas = atlas
    self.line_tex = tex

    self.lineImages = {}
    self.line_default_h = 50
    self.tint = {1, 1, 1, 1} -- 存储颜色 R G B A

    -- 绑定地图更新逻辑
    self.UpdateLinesPosition = mapwidget and updateFns[mapwidget.name] or nil

    if self.UpdateLinesPosition then
        self:StartUpdating()
    end
end)

-- 创建线段
function PathLineGroup:InsertLines(amount)
    local r, g, b, a = unpack(self.tint)
    for i = 1, amount do
        local line = self:AddChild(PathLine(self.line_atlas, self.line_tex))
        line:SetDefaultHeight(self.line_default_h)
        line:SetColor(r, g, b, a) -- PathLine 中写的 SetColor
        line:Hide()
        table.insert(self.lineImages, line)
    end
end

-- 设置线条颜色（支持透明度）
function PathLineGroup:SetLineTint(r, g, b, a)
    self.tint = {r, g, b, a or 1}
    if not self:IsEmpty() then
        for _, line in ipairs(self.lineImages) do
            line:SetColor(r, g, b, a)
        end
    end
end

-- 设置线条粗细
function PathLineGroup:SetLineDefaultHeight(h)
    self.line_default_h = h
    if not self:IsEmpty() then
        for _, line in ipairs(self.lineImages) do
            line:SetDefaultHeight(h)
        end
    end
end

-- 清空所有线条
function PathLineGroup:Clear()
    for _, line in ipairs(self.lineImages) do
        line:Kill()
    end
    self.lineImages = {}
end

function PathLineGroup:Count()
    return #self.lineImages
end

function PathLineGroup:IsEmpty()
    return self:Count() == 0
end

-- =========================================
-- ✅ 鼠标聚焦：路线变虚
-- =========================================
function PathLineGroup:OnGainFocus()
    if self:IsEmpty() then return end
    local r, g, b = unpack(self.tint)
    for _, line in ipairs(self.lineImages) do
        line:SetColor(r, g, b, 0.2) -- 聚焦 → 20% 透明度
    end
end

-- =========================================
-- ✅ 失去焦点：恢复原样
-- =========================================
function PathLineGroup:OnLoseFocus()
    if self:IsEmpty() then return end
    local r, g, b, a = unpack(self.tint)
    for _, line in ipairs(self.lineImages) do
        line:SetColor(r, g, b, a) -- 恢复原始颜色
    end
end

-- =========================================
-- 每帧更新路径
-- =========================================
function PathLineGroup:OnUpdate(dt)
    local pathfollower = ThePlayer and ThePlayer.components.ngl_pathfollower
    local path = pathfollower and pathfollower.path

    -- 无路径 → 清空
    if not path then
        if not self:IsEmpty() then
            self:Clear()
        end
        return
    end

    -- 线条数量不匹配 → 重建
    local needLineCount = #path.steps - 1
    if self:Count() ~= needLineCount then
        self:Clear()
        self:InsertLines(needLineCount)
    end

    -- 更新线条位置
    if self.UpdateLinesPosition then
        self:UpdateLinesPosition(path)
    end
end

return PathLineGroup