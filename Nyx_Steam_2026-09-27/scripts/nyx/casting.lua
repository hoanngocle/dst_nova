local P=require('nyx/progression')
local Defs=require('nyx/skilldefs')
local C={}; C.__index=C
function C.New(port) return setmetatable({port=port,ends={},active={},handles={},seen={},busy=false},C) end
function C:Remaining(id) return math.max(0,(self.ends[id] or 0)-self.port.clock()) end
function C:Stop(id,reason)
    local h=self.active[id]; self.active[id]=nil
    if h then pcall(h.Cancel,h,reason) end
end
function C:StopAll(reason)
    for id in pairs(self.active) do self:Stop(id,reason) end
    for h in pairs(self.handles) do pcall(h.Cancel,h,reason) end
    self.handles={}
end
function C:Request(id,payload,request_id)
    if self.busy then return false,'Đang thi triển.' end
    local def=type(id)=='string' and Defs.Get(id) or nil
    if not def or not P.Finite(request_id) or request_id<1 or request_id>2147483647 or request_id%1~=0 then return false,'Yêu cầu không hợp lệ.' end
    local now=self.port.clock()
    for i=#self.seen,1,-1 do if now-self.seen[i].time>10 then table.remove(self.seen,i) end end
    for _,v in ipairs(self.seen) do if v.id==request_id then return false,'Yêu cầu trùng.' end end
    self.seen[#self.seen+1]={id=request_id,time=now}
    if #self.seen>32 then table.remove(self.seen,1) end
    if self.active[id] then self:Stop(id,'manual'); return true end
    local s=self.port.read()
    if not s.ready then return false,s.reason end
    if not P.Unlocked(def,s) then return false,'Chưa đạt mốc mở khóa.' end
    if not self.port.alive() then return false,'Không thể dùng lúc này.' end
    if self:Remaining(id)>0 then return false,'Kỹ năng đang hồi.' end
    payload=type(payload)=='table' and payload or {}
    if def.target=='point' and (not P.Finite(payload.x) or not P.Finite(payload.z)) then return false,'Điểm chọn không hợp lệ.' end
    local valid,why=self.port.valid(def,payload)
    if not valid then return false,why end
    local minimum=def.target=='toggle' and (id=='purple_eye' and P.EyeDrain(s.level) or P.WingDrain(s.level)) or def.cost
    if s.current<minimum then return false,'Không đủ Linh Lực.' end
    self.busy=true
    local ok,h,reason=pcall(self.port.prepare,id,payload)
    if not ok or not h then self.busy=false; return false,ok and reason or 'Không thể chuẩn bị kỹ năng.' end
    if not self.port.spend(def.cost) then self.busy=false; pcall(h.Cancel,h,'no_resource'); return false,'Không đủ Linh Lực.' end
    local started,result=pcall(h.Start,h)
    if not started or result~=true then
        pcall(h.Cancel,h,'failed'); self.port.refund(def.cost); self.busy=false
        return false,'Thi triển thất bại; Linh Lực đã hoàn lại.'
    end
    self.ends[id]=now+def.cooldown
    if def.target=='toggle' then self.active[id]=h end
    self.handles[h]=true
    self.busy=false
    return true
end
function C:Tick()
    local s=self.port.read()
    if not s.ready or not self.port.alive() then self:StopAll('invalid_owner'); return end
    for _,id in ipairs({'purple_eye','moon_wings'}) do
        local h=self.active[id]
        if h then
            if (h.IsDone and h:IsDone()) or (h.CanContinue and not h:CanContinue()) then self:Stop(id,'invalid_state')
            else
                local n=id=='purple_eye' and P.EyeDrain(s.level) or P.WingDrain(s.level)
                if not self.port.spend(n) or self.port.read().current<=0 then self:Stop(id,'no_resource') end
            end
        end
    end
    for h in pairs(self.handles) do
        if h.IsDone and h:IsDone() then self.handles[h]=nil end
    end
end
function C:Snapshot()
    local s=self.port.read(); s.cooldowns={}; s.active={}; s.unlocked={}
    for _,id in ipairs(Defs.Order()) do
        s.cooldowns[id]=math.ceil(self:Remaining(id)*10)/10
        s.active[id]=self.active[id]~=nil
        s.unlocked[id]=P.Unlocked(Defs.Get(id),s)
    end
    return s
end
function C:Save()
    local data={cooldowns={}}
    for _,id in ipairs(Defs.Order()) do local n=self:Remaining(id); if n>0 then data.cooldowns[id]=n end end
    return data
end
function C:Load(data)
    self:StopAll('load'); self.ends={}; self.seen={}
    local cds=type(data)=='table' and type(data.cooldowns)=='table' and data.cooldowns or {}
    for _,id in ipairs(Defs.Order()) do
        local n=cds[id]
        self.ends[id]=self.port.clock()+(P.Finite(n) and math.max(0,math.min(Defs.Get(id).cooldown,n)) or 0)
    end
end
return C
