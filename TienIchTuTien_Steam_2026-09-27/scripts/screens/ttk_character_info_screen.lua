local Screen=require("widgets/screen")
local Widget=require("widgets/widget")
local Image=require("widgets/image")
local ImageButton=require("widgets/imagebutton")
local Text=require("widgets/text")
local TextButton=require("widgets/textbutton")
local PAGE_SIZE=10
local TAB_NAMES={"Tổng quan","Tấn công","Phòng thủ","Nguồn buff"}
local GOLD={.36,.21,.48,1}
local WHITE={.18,.16,.20,1}
local MUTED={.40,.35,.39,1}
local DEFAULT_ZOOM=1.25
local MIN_ZOOM=1
local MAX_ZOOM=1.8
local ZOOM_STEP=.1
local last_zoom=DEFAULT_ZOOM

local function Label(parent,size,text,x,y,colour)
    local label=parent:AddChild(Text(BODYTEXTFONT,size,text))
    label:SetPosition(x,y,0)
    label:SetColour(unpack(colour or WHITE))
    label:SetClickable(false)
    return label
end
local function Button(parent,text,x,y,fn)
    local button=parent:AddChild(TextButton())
    button:SetFont(BODYTEXTFONT)
    button:SetTextSize(24)
    button:SetText(text)
    button:SetTextColour(unpack(WHITE))
    button:SetTextFocusColour(.55,.26,.67,1)
    button:SetPosition(x,y,0)
    button:SetOnClick(fn)
    return button
end
local function CompactHover(widget,text,parent)
    widget:SetHoverText(text,{attach_to_parent=parent,font=BODYTEXTFONT,font_size=20,
        bg_atlas="images/global.xml",bg_texture="square.tex",colour=WHITE,offset_y=65})
    -- Native SetHoverText inflates its backdrop by 1.5x/2x on every refresh.
    -- Measure bounded multiline text and size the backdrop to its actual contents.
    widget.hovertext:SetScale(1)
    widget.hovertext:SetMultilineTruncatedString(text,5,300,nil,true)
    local w,h=widget.hovertext:GetRegionSize()
    widget.hovertext_bg:SetSize(w+24,h+18)
    widget.hovertext_bg:SetTint(.98,.96,.90,1)
end

local CharacterInfo=Class(Screen,function(self,owner,info,onclose)
    Screen._ctor(self,"CharacterInfo")
    self.owner,self.info,self.onclose=owner,info,onclose
    self.tab,self.page,self.elapsed=1,1,0
    self.black=self:AddChild(ImageButton("images/global.xml","square.tex"))
    self.black.scale_on_focus=false
    self.black.move_on_click=false
    self.black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black.image:SetHAnchor(ANCHOR_MIDDLE)
    self.black.image:SetVAnchor(ANCHOR_MIDDLE)
    self.black.image:SetTint(0,0,0,.35)
    self.black:SetOnClick(function() self:Close() end)
    self.root=self:AddChild(Widget("CharacterInfoPanel"))
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetMaxPropUpscale(2)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.zoom=last_zoom
    self:ApplyZoom()
    -- Consume clicks throughout the panel, including the space between rows.
    local border=self.root:AddChild(Image("images/global.xml","square.tex"))
    border:SetSize(688,508)
    border:SetTint(.39,.29,.43,1)
    border:SetClickable(false)
    local panel=self.root:AddChild(ImageButton("images/global.xml","square.tex"))
    panel:ForceImageSize(680,500)
    panel.image:SetTint(.91,.88,.81,1)
    panel.scale_on_focus=false
    panel.move_on_click=false
    panel:SetOnClick(function() end)
    Label(self.root,29,"THÔNG TIN NHÂN VẬT",0,210,GOLD)
    self.close_button=Button(self.root,"×",310,210,function() self:Close() end)
    self.zoom_out=Button(self.root,"-",230,210,function() self:ChangeZoom(-ZOOM_STEP) end)
    self.zoom_in=Button(self.root,"+",270,210,function() self:ChangeZoom(ZOOM_STEP) end)
    self.zoom_out:SetHoverText("Thu nhỏ",{font=BODYTEXTFONT,font_size=20})
    self.zoom_in:SetHoverText("Phóng to",{font=BODYTEXTFONT,font_size=20})
    self.tabs={}
    self.tab_backgrounds={}
    for i,name in ipairs(TAB_NAMES) do
        local background=self.root:AddChild(Image("images/global.xml","square.tex"))
        background:SetPosition((i-2.5)*165,168,0)
        background:SetSize(155,32)
        background:SetClickable(false)
        self.tab_backgrounds[i]=background
        self.tabs[i]=Button(self.root,name,(i-2.5)*165,168,function() self:SelectTab(i) end)
    end
    self.subtitle=Label(self.root,20,"Đang lấy chỉ số từ server…",0,135,MUTED)
    self.rows={}
    for i=1,PAGE_SIZE do
        local root=self.root:AddChild(Widget("InfoRow"..i))
        root:SetPosition(0,108-(i-1)*27,0)
        local background=root:AddChild(Image("images/global.xml","square.tex"))
        background:SetSize(630,27)
        background:SetTint(.67,.61,.71,i%2==0 and .32 or .08)
        local label=Label(root,22,"",-115,0)
        label:SetRegionSize(390,27);label:SetHAlign(ANCHOR_LEFT)
        local value=Label(root,22,"",210,0,GOLD)
        value:SetRegionSize(200,27);value:SetHAlign(ANCHOR_RIGHT)
        self.rows[i]={root=root,label=label,value=value,background=background}
    end
    Label(self.root,18,"Rê chuột trên dòng bị rút gọn để xem chi tiết",0,-172,MUTED)
    self.status=Label(self.root,18,"",0,-194,MUTED)
    self.previous=Button(self.root,"‹ Trước",-235,-222,function() self:ChangePage(-1) end)
    self.next=Button(self.root,"Sau ›",235,-222,function() self:ChangePage(1) end)
    self.page_label=Label(self.root,22,"",0,-222)
    self.default_focus=self.tabs[1]
    for i,tab in ipairs(self.tabs) do
        tab:SetFocusChangeDir(MOVE_LEFT,self.tabs[i-1] or self.close_button)
        tab:SetFocusChangeDir(MOVE_RIGHT,self.tabs[i+1] or self.close_button)
        tab:SetFocusChangeDir(MOVE_DOWN,self.previous)
    end
    self.previous:SetFocusChangeDir(MOVE_RIGHT,self.next)
    self.next:SetFocusChangeDir(MOVE_LEFT,self.previous)
    self.previous:SetFocusChangeDir(MOVE_UP,self.tabs[1])
    self.next:SetFocusChangeDir(MOVE_UP,self.tabs[4])
    self.close_button:SetFocusChangeDir(MOVE_DOWN,self.tabs[4])
    self.close_button:SetFocusChangeDir(MOVE_LEFT,self.zoom_in)
    self.zoom_in:SetFocusChangeDir(MOVE_LEFT,self.zoom_out)
    self.zoom_in:SetFocusChangeDir(MOVE_RIGHT,self.close_button)
    self.zoom_out:SetFocusChangeDir(MOVE_RIGHT,self.zoom_in)
    self.info.Request(self.owner)
    self:Refresh()
    -- FrontEnd already updates the active screen; do not register a widget tick.
end)

function CharacterInfo:ApplyZoom()
    self.zoom=math.max(MIN_ZOOM,math.min(self.zoom,MAX_ZOOM))
    self.root:SetScale(self.zoom)
end

function CharacterInfo:ChangeZoom(delta)
    self.zoom=math.max(MIN_ZOOM,math.min(MAX_ZOOM,self.zoom+delta))
    self:ApplyZoom()
    last_zoom=self.zoom
end

function CharacterInfo:SelectTab(index)
    self.tab,self.page=index,1
    self:Refresh()
end
function CharacterInfo:ChangePage(delta)
    self.page=self.page+delta
    self:Refresh()
end
function CharacterInfo:Refresh()
    local snapshot=self.info.Read(self.owner)
    local entries=snapshot and snapshot.tabs[self.tab] or {}
    local count=math.max(1,math.ceil(#entries/PAGE_SIZE))
    self.page=math.max(1,math.min(count,self.page))
    self.subtitle:SetTruncatedString(snapshot and snapshot.name or "Đang lấy chỉ số từ server…",620,nil,true)
    self.status:SetString(snapshot and (snapshot.ghost and "Hồn ma • Chỉ số chiến đấu không áp dụng"
        or "Số liệu từ server • Làm mới mỗi 0,5 giây") or "Chưa có dữ liệu mới — đang kết nối lại")
    for i,widgets in ipairs(self.rows) do
        local row=entries[(self.page-1)*PAGE_SIZE+i]
        if row then
            widgets.root:Show()
            local label_fits=widgets.label:SetTruncatedString(row[1],390,nil,true)
            local value_fits=widgets.value:SetTruncatedString(row[2],200,nil,true)
            if not label_fits or not value_fits then
                CompactHover(widgets.background,row[1].."\n"..row[2],self.root)
            else widgets.background:ClearHoverText() end
        else
            widgets.background:ClearHoverText()
            widgets.root:Hide()
        end
    end
    self.page_label:SetString(string.format("%d / %d",self.page,count))
    if self.page>1 then self.previous:Enable() else self.previous:Disable() end
    if self.page<count then self.next:Enable() else self.next:Disable() end
    for i,tab in ipairs(self.tabs) do
        tab:SetTextColour(unpack(i==self.tab and GOLD or MUTED))
        self.tab_backgrounds[i]:SetTint(.72,.64,.79,i==self.tab and .8 or .2)
    end
end
function CharacterInfo:OnUpdate(dt)
    if self.closed then return end
    if not self.owner:IsValid() then self:Close();return end
    if TheFrontEnd:GetActiveScreen()~=self then return end
    self.elapsed=self.elapsed+dt
    if self.elapsed>=.5 then
        self.elapsed=0
        self.info.Request(self.owner)
        self:Refresh()
    end
end
function CharacterInfo:Close()
    if self.closed then return end
    self.closed=true
    if self.onclose then self.onclose() end
    TheFrontEnd:PopScreen(self)
end
function CharacterInfo:OnDestroy()
    if not self.closed then
        self.closed=true
        if self.onclose then self.onclose() end
    end
    Screen.OnDestroy(self)
end
function CharacterInfo:OnControl(control,down)
    if Screen.OnControl(self,control,down) then return true end
    if not down then
        if control==CONTROL_CANCEL then self:Close();return true end
        if control==CONTROL_SCROLLBACK then self:ChangePage(-1);return true end
        if control==CONTROL_SCROLLFWD then self:ChangePage(1);return true end
    end
    return false
end

return CharacterInfo
