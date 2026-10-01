-- Server-only observation. No attack simulation, RNG, buff consumption or mutations.
local PlayerDetail = require("ttk_player_detail")
local M = {}

local function Number(v)
    return type(v) == "number" and v == v and math.abs(v) < math.huge and v or nil
end
local function Call(object, method, ...)
    if object == nil or type(object[method]) ~= "function" then return nil end
    local ok, a, b = pcall(object[method], object, ...)
    if ok then return a, b end
end
local function Format(v)
    if Number(v) == nil then return "—" end
    return string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
end
local function Percent(v) return Format(v) .. "%" end
local function Get(list, default) return Number(Call(list, "Get")) or default end
local function Name(object, G)
    if type(object) == "string" then
        return G.STRINGS and G.STRINGS.NAMES and G.STRINGS.NAMES[object:upper()] or object
    end
    return Call(object, "GetDisplayName") or object and object.prefab or "Không rõ nguồn"
end
local function SortedKeys(t)
    local keys = {}
    for k in pairs(t or {}) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
    return keys
end
local SOURCE_NAMES = {
    damagePerk="Thành tựu: tăng sát thương", damageUpgrade="Cấp độ: tăng sát thương",
    absorbPerk="Thành tựu: giảm sát thương", absorbUpgrade="Cấp độ: giảm sát thương",
    speedUpgrade="Cấp độ: tốc chạy", speedPerk="Thành tựu: tốc chạy",
    greenmooneye="Mắt trăng xanh", tbc_affix="Đá thuộc tính",
    tbc_strengthen_head16="Mũ cường hóa +16", trinket="Trang sức",
    tbc_elixir="Linh dược vĩnh viễn",
}
local EFFECTS = {
    criticalHitRate={"Tỷ lệ bạo kích", "%"}, criticalHitEffect={"ST bạo kích cộng thêm", "%"},
    addComDamage={"ST cộng khi trúng đòn", ""}, addComDamagePercent={"ST cộng khi trúng đòn", "%"},
    trueDamageNum={"ST xuyên giáp cố định", ""}, addSpeedPercent={"Tốc chạy cộng thêm", "%"},
    reduceAttackedDamage={"Chặn ST cố định", ""}, absorbDamage={"Hấp thụ ST (tối đa 80%)", "%"},
    bloodSuck={"Hút máu", "%"}, restoreSpirit={"Hồi tinh thần khi đánh", "%"},
    chanceDodgeAttack={"Né tránh", "%"}, atk_speed={"Tốc đánh cộng thêm", "%"},
    equipMaxMana={"Linh lực tối đa cộng thêm", ""}, equipManaRegen={"Hồi linh lực", "/s"},
    equipHealthRegen={"Hồi máu", "/s"}, equipMaxHealthPercent={"Máu tối đa cộng thêm", "%"},
    sunlightStrike={"ST ban ngày", ""}, afterglowStrike={"ST hoàng hôn", ""},
    nightMenace={"ST ban đêm", ""}, soakStrike={"ST khi ướt ≥ 50%", ""},
    addHitBossDamage={"ST lên boss", ""}, targetPercentDamage={"ST theo máu mục tiêu", "%"},
}
local BUFF_NAMES = {
    add_health="Hồi máu +1/s", buff_10s_1_health="Hồi máu +1/s",
    add_hunger="Hồi đói +1/s", add_sanity="Hồi tinh thần +1/s",
    reduce_speed="Giảm tốc chạy 40%", xd_lingqiheal_buff="Tăng hồi linh lực",
    critter_raptor_buff="Bảo đảm bạo kích đòn kế tiếp",
}
local SKILL_NAMES = {purple_eye="Tử Tiêu Thần Nhãn", moon_wings="Tinh Vũ Nguyệt Dực",
    absolute_domain="Tuyệt Đối Lĩnh Vực", purple_gather="Tử Phong Tụ Linh",
    triflame_fan="Tam Diễm Phiến", yellow_river="Cửu Khúc Hoàng Hà Trận",
    eternal_night="Tàn Dạ – Vĩnh Hằng Lĩnh Vực", spirit_sword="Huyền Thiên Trảm Linh Kiếm"}

function M.Measure(player, G)
    G = G or {}
    local c = player.components or {}
    local v, tabs = {}, {{}, {}, {}, {}}
    local s = {version=1, values=v, tabs=tabs, name=Name(player,G),
        ghost=Call(player,"HasTag","playerghost") == true}
    local function Row(tab,label,value)
        if value ~= nil then tabs[tab][#tabs[tab]+1]={label,tostring(value)} end
    end
    local function Stat(tab,key,label,value,unit)
        value=Number(value)
        if value ~= nil then v[key]=value; Row(tab,label,Format(value)..(unit or "")) end
    end
    local function Resource(key,label,component,current,max,method)
        if component == nil then return end
        v[key]=Number(component[current]); v[key.."_max"]=Number(Call(component,method or "GetMax")) or Number(component[max])
        Row(1,label,Format(v[key]).." / "..Format(v[key.."_max"]))
    end
    Resource("health","Máu",c.health,"currenthealth","maxhealth","GetMaxWithPenalty")
    Resource("hunger","Đói",c.hunger,"current","max")
    Resource("sanity","Tinh thần",c.sanity,"current","max")
    Resource("lingli","Linh lực",c.xd_htz_lq,"current","max")
    Resource("binglingqi","Băng linh khí",c.xd_binglingqi,"current","max")
    Stat(1,"level","Cấp độ",c.levelsystem and c.levelsystem.level)
    Stat(1,"realm","Bậc tu luyện",c.xd_level and c.xd_level.level)
    Stat(1,"temperature","Nhiệt độ",Call(c.temperature,"GetCurrent")," °C")
    Stat(1,"moisture","Độ ướt",Call(c.moisture,"GetMoisture"))
    local nyx = Call(c.nyx_skills and c.nyx_skills.controller,"Snapshot")
    if type(nyx)=="table" and nyx.ready then
        Row(1,"Cảnh giới",nyx.realm_label)
        Stat(1,"lingli_regen","Hồi linh lực (trước tiêu hao)",
            (nyx.regen or 0)+(player._tbc_affix_mana and player._tbc_affix_mana.regen or 0),"/s")
        for _,key in ipairs(SortedKeys(nyx.active)) do
            if nyx.active[key] then Row(4,"Kỹ năng: "..(SKILL_NAMES[key] or key),"Đang bật") end
        end
    end
    if Call(c.nyx_domain,"IsActive") then Row(4,"Kỹ năng: Tuyệt Đối Lĩnh Vực","Đang bật") end
    if s.ghost then
        Row(1,"Trạng thái","Hồn ma — chỉ số chiến đấu không áp dụng")
        return s
    end
    local inventory=c.inventory
    local items,seen,source_items={},{},{}
    for _,item in pairs(inventory and inventory.equipslots or {}) do
        if not seen[item] then
            seen[item]=true; items[#items+1]=item
            if item.GUID then source_items[tostring(item.GUID)]=item end
        end
    end
    table.sort(items,function(a,b) return Name(a,G)<Name(b,G) end)
    local source=G.TTK_EQUIPMENT_DETAIL_SOURCE
    local detail=Call({read=function() return PlayerDetail.Measure(player,source) end},"read") or {}
    local combat=c.combat
    local attack_combat=combat
    local weapon=Call(combat,"GetWeapon")
    if detail.mounted then
        local mount=Call(c.rider,"GetMount")
        attack_combat=mount and mount.components and mount.components.combat or combat
    end
    Row(2,"Vũ khí",weapon and Name(weapon._tbc_source_item or weapon._source_weapon or weapon,G)
        or detail.mounted and "Thú cưỡi" or "Tay không")
    Stat(2,"base_damage","ST nền sau hệ số",detail.damage)
    local preview
    if source and type(source.preview_attack)=="function" and detail.damage then
        local ok,result=pcall(source.preview_attack,player,weapon,detail.damage)
        if ok and type(result)=="table" then preview=result end
    end
    Stat(2,"damage",preview and "ST hiện tại (trước giáp mục tiêu)" or "ST trước hiệu ứng trúng đòn",
        preview and preview.damage or detail.damage)
    Stat(2,"speed","Tốc chạy thực tế",detail.speed)
    Stat(2,"attack_period","Khoảng cách đòn tối thiểu",combat and combat.min_attack_period,"s")
    Stat(2,"damage_multiplier",detail.mounted and "Hệ số ST thú cưỡi" or "Hệ số ST nhân vật",
        attack_combat and attack_combat.damagemultiplier,"×")
    if attack_combat then
        Stat(2,"external_damage_multiplier","Hệ số ST từ buff",Get(attack_combat.externaldamagemultipliers,1),"×")
        Stat(2,"damage_bonus","ST cộng sau hệ số",attack_combat.damagebonus or 0)
    end

    -- Achievement combines independent chances multiplicatively. Its provider
    -- already contains Thần Khí's crit: use it once, never add detail.crit_rate again.
    local crit_rate,crit_damage=detail.crit_rate,detail.crit_damage
    if c.allachivcoin or c.chasnicritchancer then
        local chance,damage=0,1
        local function Chance(amount) chance=1-(1-chance)*(1-(Number(amount) or 0)) end
        local perk,data=c.allachivcoin or {},G.allachiv_coindata or {}
        local perkchance=(data.criticalup or 0)*(perk.criticalupamount or 0)
        local perkdamage=(data.criticaldmgup or 0)*(perk.criticaldmgupamount or 0)
        Chance(perkchance); damage=damage+perkdamage
        if perkchance>0 then Row(4,"Thành tựu: bạo kích",Percent(perkchance*100)) end
        if perkdamage>0 then Row(4,"Thành tựu: ST bạo kích","+"..Percent(perkdamage*100)) end
        for _,item in ipairs(items) do
            Chance(item.chasni_critchancegear); Chance(Call(item,"chasni_critchancegearfn"))
            damage=damage+(item.chasni_critdamagegear or 0)+(Number(Call(item,"chasni_critdamagegearfn")) or 0)
        end
        local added,provider=Call(c.chasnicritchancer,"CalculateCrit")
        Chance(provider); damage=damage+(Number(added) or 0)
        if Call(player,"HasDebuff","critter_raptor_buff") then chance=1 end
        local aura=Call(player,"GetDebuff","chasni_critter_raptor_aura_buff")
        damage=damage+math.max(0,aura and aura.critdamage or 0)/100
        local pet=Call(c.petleash,"GetChasniCritter")
        if pet and G.chasni_ispetname and G.chasni_ispetname(pet,"atops") then
            for _,gem in ipairs({"orangegem","opalpreciousgem"}) do
                local has,count=Call(inventory,"Has",gem,1)
                if has then damage=damage+(Number(count) or 0)*.001 end
            end
        end
        if G.TheWorld and G.TheWorld.state.isfullmoon and G.chasni_checkifgroundedexists
            and G.chasni_checkifgroundedexists("chesspiece_moon_marble") then
            Chance(.3); damage=damage+.3
        end
        crit_rate=damage>1 and math.max(0,math.min(100,chance*100)) or 0
        crit_damage=damage*100
    end
    Stat(2,"crit_rate","Tỷ lệ bạo kích",crit_rate,"%")
    Stat(2,"crit_damage","Sát thương bạo kích",crit_damage,"%")
    Stat(2,"pierce_percent","Xuyên giáp theo ST",detail.pierce_percent,"%")
    Stat(2,"flat_pierce","ST xuyên giáp cố định",detail.flat_pierce)
    if preview and Number(preview.damage) then
        Stat(2,"pierce_damage","ST xuyên giáp dự kiến",preview.damage*(preview.pierce_percent or 0)/100
            +(preview.affix_pierce or 0)+(detail.flat_pierce or 0))
    end
    Row(2,"Phạm vi tính","Chưa tính giáp/kháng, hệ mục tiêu, proc ngẫu nhiên và đòn phụ")
    if c.hh_player then Row(2,"Hiệu ứng Solo gốc","Xem Nguồn buff; chưa gộp vào ST dự kiến") end

    local armor=0
    for _,item in ipairs(items) do
        local ac=item.components and item.components.armor
        if ac and (ac.condition or 0)>0 then armor=math.max(armor,Number(ac.absorb_percent) or 0) end
    end
    Stat(3,"armor","Giáp trang bị (mức cao nhất)",armor*100,"%")
    local h=c.health
    if h then
        local remaining=math.max(0,math.min(1,1-(h.absorb or 0)))*math.max(0,1-Get(h.externalabsorbmodifiers,0))
        Stat(3,"health_absorption","Hấp thụ ST của cơ thể",(1-remaining)*100,"%")
        Stat(3,"flat_reduction","Giảm ST cố định của cơ thể",Get(h.externalreductionmodifiers,0))
    end
    if combat then Stat(3,"damage_taken","ST nhận sau hệ số buff",Get(combat.externaldamagetakenmultipliers,1)*100,"%") end
    local dodge=Number(player.dodgechance) or 0
    local function Dodge(amount) dodge=1-(1-dodge)*(1-(Number(amount) or 0)) end
    Dodge(Call(c.chasnidodgechancer,"CalculateDodge"))
    for _,item in ipairs(items) do
        dodge=1-(1-dodge)*(1-(item.chasni_dodgechancegear or 0))
        dodge=1-(1-dodge)*(1-(Number(Call(item,"chasni_dodgechancegearfn")) or 0))
    end
    if Call(inventory,"EquipHasTag","adventure_hat") and Call(c.rider,"IsRiding") then Dodge(.4) end
    if c.allachivcoin and c.allachivcoin.expertwoodie3 and Call(player,"HasTag","weregoose") then Dodge(.9) end
    if Call(player,"HasDebuff","chasni_kimchibuff") then Dodge(.7) end
    if Call(player,"HasTag","ghostlyelixir_slow") then Dodge(.3) end
    if c.allachivcoin and c.allachivcoin.expertwx2 and Call(player.sg,"HasStateTag","spinning") then
        Dodge(.2*(player.chasni_module_counter_wx78module_spin or 0))
    end
    if Call(player,"HasDebuff","critter_seal_buff") then Dodge((player._sealmisschance or 0)/100) end
    Stat(3,"dodge","Né tránh hiện tại (Achievement)",math.max(0,math.min(100,dodge*100)),"%")
    Row(3,"Lưu ý","Các lớp giảm ST áp dụng nối tiếp; giáp/né còn tùy đòn đánh")
    local passive=player._tbc_passive_state
    if passive then
        Stat(1,"health_regen","Hồi máu từ đá",passive.health_regen,"/s")
        Stat(4,"affix_attack_speed","Đá: tốc đánh đang áp dụng",passive.attack_speed,"%")
        Stat(4,"affix_health_bonus","Đá/cường hóa: máu đã cộng",passive.health_bonus)
    end
    for _,entry in ipairs({{"tbc_player_effects","Thần Khí"},{"hh_player","Solo gốc"}}) do
        local component=c[entry[1]]
        if component then
            for _,key in ipairs({"bloodSuck","restoreSpirit","addComDamage","addComDamagePercent",
                "trueDamageNum","reduceAttackedDamage","absorbDamage","chanceDodgeAttack"}) do
                local amount=Number(Call(component,"GetEffectValueByKey",key))
                if amount and amount~=0 then
                    local def=EFFECTS[key]
                    local tab=(key=="reduceAttackedDamage" or key=="absorbDamage" or key=="chanceDodgeAttack") and 3 or 2
                    Row(tab,entry[2].." · "..def[1],Format(key=="absorbDamage" and math.min(80,amount) or amount)..def[2])
                end
            end
        end
    end

    local function SourceName(key)
        if type(key)=="string" then
            local id=key:match("^[^:]+:([^:]+):")
            if id and source_items[id] then return Name(source_items[id],G).." ["..key:match("([^:]+)$").."]" end
            return SOURCE_NAMES[key] or Name(key,G)
        end
        return Name(key,G)
    end
    local function Modifiers(list,label,unit,speed)
        local entries=list and (speed and list._externalspeedmultipliers or list._modifiers) or {}
        for _,src in ipairs(SortedKeys(entries)) do
            local values=entries[src].modifiers or entries[src].multipliers or {}
            for _,key in ipairs(SortedKeys(values)) do
                if Number(values[key]) then
                    local name=SourceName(src)..(key~="key" and " · "..SourceName(key) or "")
                    Row(4,label.." · "..name,Format(values[key])..unit)
                end
            end
        end
    end
    if attack_combat then
        Modifiers(attack_combat.externaldamagemultipliers,detail.mounted and "ST thú cưỡi" or "Sát thương","×")
    end
    if combat then
        Modifiers(combat.externaldamagetakenmultipliers,"ST nhận vào","×")
    end
    if h then
        Modifiers(h.externalabsorbmodifiers,"Hấp thụ (tỷ lệ)","")
        Modifiers(h.externalreductionmodifiers,"Giảm ST cố định","")
    end
    Modifiers(c.locomotor,"Tốc chạy","×",true)
    for _,item in ipairs(items) do
        local ic=item.components or {}
        Row(4,"Trang bị",Name(item,G))
        if ic.weapon then Row(4,Name(item,G).." · ST vũ khí",Format(ic.weapon.damage)) end
        if ic.armor then Row(4,Name(item,G).." · hấp thụ giáp",Percent((ic.armor.absorb_percent or 0)*100)) end
        local speed=Number(Call(ic.equippable,"GetWalkSpeedMult"))
        if speed and speed~=1 then Row(4,Name(item,G).." · tốc chạy",Format(speed).."×") end
        local upgrade=ic.tbc_upgrade
        if upgrade then
            Row(4,Name(item,G).." · cường hóa","+"..Format(upgrade.level))
            for _,affix in ipairs(upgrade.affixes or {}) do
                local def=source and source.by_code and source.by_code[affix.id]
                local amount=def and (def.fixed and def.fixed_value or (affix.value or 0)/(def.scale or 1)) or affix.value
                Row(4,Name(item,G).." · "..(def and def.name or affix.id),Format(amount)..(def and def.unit or ""))
            end
        end
        for _,affix in ipairs(ic.tbc_equipment and ic.tbc_equipment.affixes or {}) do
            local def=source and source.solo_by_code and source.solo_by_code[affix.id]
            local desc=def and def.desc
            if type(desc)=="string" and desc:find("%%s") then
                local ok,text=pcall(string.format,desc,Format(affix.value))
                desc=ok and text or nil
            end
            Row(4,Name(item,G).." · "..(def and def.name or affix.id),desc or Format(affix.value))
        end
    end
    local function Effects(values,prefix)
        for _,key in ipairs(SortedKeys(values)) do
            if Number(values[key]) and values[key]~=0 then
                local def=EFFECTS[key]
                Row(4,prefix.." · "..(def and def[1] or key),Format(values[key])..(def and def[2] or ""))
            end
        end
    end
    if c.tbc_player_effects then
        for _,key in ipairs(SortedKeys(c.tbc_player_effects.sources)) do
            Effects(c.tbc_player_effects.sources[key],SourceName(key))
        end
    end
    if c.tbc_elixir_progress then
        local names={power="Sức Mạnh",health="Sinh Mệnh",mana="Ma Lực",
            guard="Hộ Thể",speed="Phong Tốc",crit="Bạo Kích"}
        for _,key in ipairs({'power','health','mana','guard','speed','crit'}) do
            local count=Call(c.tbc_elixir_progress,'GetCount',key)
            if Number(count) then Row(4,"Linh dược · "..names[key],Format(count).."/10") end
        end
        Stat(4,"elixir_health","Linh dược · máu tối đa cộng thêm",
            Call(c.tbc_elixir_progress,'GetBonus','health'))
        Stat(4,"elixir_mana","Linh dược · linh lực tối đa cộng thêm",
            Call(c.tbc_elixir_progress,'GetBonus','mana'))
    end
    if c.hh_player then Effects(c.hh_player.hh_effects,"Solo gốc (tổng)") end
    for _,key in ipairs(SortedKeys(c.hh_buff and c.hh_buff.hh_buffs)) do
        local buff=c.hh_buff.hh_buffs[key]
        Row(4,BUFF_NAMES[key] or Name(key,G),Number(buff.time) and math.ceil(math.max(0,buff.time)).."s" or "Đang có hiệu lực")
    end
    for _,key in ipairs(SortedKeys(c.debuffable and c.debuffable.debuffs)) do
        local buff=c.debuffable.debuffs[key].inst
        local timer=buff and buff.components and buff.components.timer
        local clocks={}
        for _,name in ipairs(SortedKeys(timer and timer.timers)) do
            local left=Number(Call(timer,"GetTimeLeft",name))
            if left then clocks[#clocks+1]=name..": "..math.ceil(math.max(0,left)).."s" end
        end
        Row(4,BUFF_NAMES[key] or Name(buff or key,G),#clocks>0 and table.concat(clocks,", ") or "Đang có hiệu lực")
    end
    if #tabs[4]==0 then Row(4,"Nguồn buff","Chưa có nguồn buff được ghi nhận") end
    return s
end

return M
