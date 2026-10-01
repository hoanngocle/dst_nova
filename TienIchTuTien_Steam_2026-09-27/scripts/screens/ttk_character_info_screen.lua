local Screen=require("widgets/screen")
local Widget=require("widgets/widget")
local Image=require("widgets/image")
local ImageButton=require("widgets/imagebutton")
local Text=require("widgets/text")
local TextButton=require("widgets/textbutton")
local PAGE_SIZE=12
local TAB_NAMES={"Tổng quan","Tấn công","Phòng thủ","Nguồn buff"}
local GOLD={.94,.79,.49,1}
local WHITE={.90,.94,.94,1}
local MUTED={.60,.69,.72,1}

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
    button:SetTextSize(22)
    button:SetText(text)
    button:SetPosition(x,y,0)
    button:SetOnClick(fn)
    return button
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
    self.black.image:SetTint(0,0,0,.65)
    self.black:SetOnClick(function() self:Close() end)
    self.root=self:AddChild(Widget("CharacterInfoPanel"))
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    -- Consume clicks throughout the panel, including the space between rows.
    local panel=self.root:AddChild(ImageButton("images/global.xml","square.tex"))
    panel:ForceImageSize(900,600)
    panel.image:SetTint(.045,.075,.085,.98)
    panel.scale_on_focus=false
    panel.move_on_click=false
    panel:SetOnClick(function() end)
    Label(self.root,29,"THÔNG TIN NHÂN VẬT",0,254,GOLD)
    self.close_button=Button(self.root,"×",410,254,function() self:Close() end)
    self.tabs={}
    for i,name in ipairs(TAB_NAMES) do
        self.tabs[i]=Button(self.root,name,(i-2.5)*205,204,function() self:SelectTab(i) end)
    end
    self.subtitle=Label(self.root,18,"Đang lấy chỉ số từ server…",0,162,MUTED)
    self.rows={}
    for i=1,PAGE_SIZE do
        local root=self.root:AddChild(Widget("InfoRow"..i))
        root:SetPosition(0,126-(i-1)*29,0)
        local background=root:AddChild(Image("images/global.xml","square.tex"))
        background:SetSize(850,28)
        background:SetTint(.12,.19,.20,i%2==0 and .55 or .15)
        local label=Label(root,19,"",-125,0)
        label:SetRegionSize(560,26);label:SetHAlign(ANCHOR_LEFT)
        local value=Label(root,19,"",290,0,GOLD)
        value:SetRegionSize(235,26);value:SetHAlign(ANCHOR_RIGHT)
        self.rows[i]={root=root,label=label,value=value,background=background}
    end
    Label(self.root,16,"Rê chuột lên dòng để xem đầy đủ • Thay đồ hoặc buff đổi sẽ tự cập nhật",0,-226,MUTED)
    self.status=Label(self.root,16,"",0,-249,MUTED)
    self.previous=Button(self.root,"‹ Trước",-300,-276,function() self:ChangePage(-1) end)
    self.next=Button(self.root,"Sau ›",300,-276,function() self:ChangePage(1) end)
    self.page_label=Label(self.root,19,"",0,-276)
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
    self.info.Request(self.owner)
    self:Refresh()
    -- FrontEnd already updates the active screen; do not register a widget tick.
end)

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
    self.subtitle:SetTruncatedString(snapshot and snapshot.name or "Đang lấy chỉ số từ server…",810,nil,true)
    self.status:SetString(snapshot and (snapshot.ghost and "Hồn ma • Chỉ số chiến đấu không áp dụng"
        or "Số liệu từ server • Làm mới mỗi 0,5 giây") or "Chưa có dữ liệu mới — đang kết nối lại")
    for i,widgets in ipairs(self.rows) do
        local row=entries[(self.page-1)*PAGE_SIZE+i]
        if row then
            widgets.root:Show()
            widgets.label:SetTruncatedString(row[1],560,nil,true)
            widgets.value:SetTruncatedString(row[2],235,nil,true)
            widgets.background:SetHoverText(row[1].."\n"..row[2],
                {font=BODYTEXTFONT,font_size=20,region_w=760,region_h=80,wordwrap=true})
        else widgets.root:Hide() end
    end
    self.page_label:SetString(string.format("%d / %d",self.page,count))
    if self.page>1 then self.previous:Enable() else self.previous:Disable() end
    if self.page<count then self.next:Enable() else self.next:Disable() end
    for i,tab in ipairs(self.tabs) do tab:SetTextColour(unpack(i==self.tab and GOLD or MUTED)) end
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
