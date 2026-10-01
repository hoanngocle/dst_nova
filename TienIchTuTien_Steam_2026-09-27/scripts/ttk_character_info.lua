local Stats = require("ttk_character_stats")
local json = require("json")
local M = {}
local api, owner, latest, received, sequence, session_start, last_response
sequence, session_start, last_response = 0, 0, 0
local MAX_BYTES = 48000

local function Valid(snapshot)
    if type(snapshot)~="table" or snapshot.version~=1 or type(snapshot.tabs)~="table" then return false end
    for i=1,4 do
        if type(snapshot.tabs[i])~="table" then return false end
        for _,row in ipairs(snapshot.tabs[i]) do
            if type(row)~="table" or type(row[1])~="string" or type(row[2])~="string" then return false end
        end
    end
    return true
end

function M.Reset(player)
    owner,latest,received=player,nil,nil
    session_start=sequence+1
end

function M.Request(player)
    local G=api and api.GLOBAL
    if G==nil or player~=G.ThePlayer or player~=owner then return end
    sequence=sequence+1
    G.SendModRPCToServer(G.GetModRPC(api.modname,"character_info"),sequence)
end

function M.Read(player)
    if player~=owner or received==nil or api.GLOBAL.GetTime()-received>3 then return nil end
    return latest
end

function M.Install(env)
    api=env
    local G=env.GLOBAL
    env.AddModRPCHandler(env.modname,"character_info",function(player,token)
        if player==nil or not player:IsValid() or player.userid==nil
            or type(token)~="number" or token~=math.floor(token) or token<0 or token>2147483647 then return end
        local now=G.GetTime()
        if player._ttk_info_request_time and now-player._ttk_info_request_time<.45 then return end
        player._ttk_info_request_time=now
        local ok,snapshot=pcall(Stats.Measure,player,G)
        if not ok then
            print("[TienIchTuTien] Character info: "..tostring(snapshot))
            snapshot={version=1,tabs={{{"Trạng thái","Không đọc được chỉ số; thử mở lại bảng."}},{},{},{}}}
        end
        snapshot.values=nil -- internal numeric values are not needed by the UI
        local raw=json.encode(snapshot)
        if #raw>MAX_BYTES then
            local sources=snapshot.tabs[4]
            repeat
                table.remove(sources)
                raw=json.encode(snapshot)
            until #raw<MAX_BYTES-200 or #sources==0
            sources[#sources+1]={"Danh sách quá dài","Một số nguồn buff chưa được hiển thị"}
            raw=json.encode(snapshot)
        end
        G.SendModRPCToClient(G.GetClientModRPC(env.modname,"character_info"),player.userid,raw,token)
    end)
    env.AddClientModRPCHandler(env.modname,"character_info",function(raw,token)
        if owner==nil or owner~=G.ThePlayer or type(token)~="number"
            or token<session_start or token<last_response or token>sequence
            or type(raw)~="string" or #raw>MAX_BYTES then return end
        last_response=token
        local ok,snapshot=pcall(json.decode,raw)
        latest=ok and Valid(snapshot) and snapshot or nil
        received=G.GetTime()
    end)
    if G.TheNet:IsDedicated() then return end
    local Widget=require("widgets/widget")
    local ImageButton=require("widgets/imagebutton")
    env.AddClassPostConstruct("widgets/controls",function(controls)
        local root=controls:AddChild(Widget("CharacterInfoButtonRoot"))
        root:SetScaleMode(G.SCALEMODE_PROPORTIONAL)
        root:SetMaxPropUpscale(G.MAX_HUD_SCALE)
        root:SetHAnchor(G.ANCHOR_LEFT)
        root:SetVAnchor(G.ANCHOR_BOTTOM)
        -- Third medallion beside Nyx's skin and gem-storage buttons.
        root:SetPosition(330,85,0)
        local function Resize()
            local frontend=G.TheFrontEnd
            root:SetScale(frontend and frontend.GetHUDScale and frontend:GetHUDScale() or 1)
        end
        local original=controls.SetHUDSize
        if original then
            local function Pack(...) return {n=select('#',...),...} end
            controls.SetHUDSize=function(self,...)
                local result=Pack(original(self,...))
                Resize()
                return G.unpack(result,1,result.n)
            end
        end
        Resize()
        local button=root:AddChild(ImageButton("images/ttk_character_info_icon.xml","ttk_character_info_icon.tex"))
        button.scale_on_focus=false
        button.move_on_click=false
        -- Match the visible medallion diameter, not the texture's outer bounds.
        button:ForceImageSize(80,80)
        button:SetHoverText("Thông tin nhân vật",{font=G.BODYTEXTFONT,font_size=20,offset_y=42})
        button:SetOnClick(function()
            if controls.owner~=G.ThePlayer or controls._ttk_info_screen then return end
            M.Reset(controls.owner)
            local Screen=require("screens/ttk_character_info_screen")
            local screen=Screen(controls.owner,M,function() controls._ttk_info_screen=nil end)
            controls._ttk_info_screen=screen
            G.TheFrontEnd:PushScreen(screen)
        end)
        controls.ttk_character_info_button=button
        controls.ttk_character_info_root=root
    end)
end

return M
