local Format = require "tbc_equipment/format"
local B__uG__ = require "tbc_equipment/compat"
local __b_uG__ = {}
local B__uG__ = require "tbc_equipment/compat"
local __b_uG__ = {}
local B__uG__ = require "tbc_equipment/compat"
local __b_uG__ = {}
local a = require "tbc_equipment/compat"
local b = Format["EQUIP_EFFECT"]
local c = string["format"]("", 0)
local function d(e, f, g)
    if a:HasComponents(e, "tbc_player_effects") and a:IsHHType(f, "table") then
        for h, i in pairs(f) do
            if a:IsHHType(i, "number") and i > 0 then
                if g then
                    e["components"]["tbc_player_effects"]:AddEffectValueByKey(h, i)
                else
                    e["components"]["tbc_player_effects"]:ReduceEffectValueByKey(h, i)
                end
            end
        end
    end
end
local j = {
    ["gem_jd"] = {
        "Extraordinary",
        "Generous",
        "Extraordinary",
        "Superb technology",
        "Climbing the pole",
        "Integrate",
        "Exquisite",
        "Wise super",
        "Technical first -class",
        "Bogu tongjin",
        "Talented",
        "Five cars in learning",
        "Excellent technology",
        "Taka -high dou",
        "Talented",
        "Talented",
        "Taishan beidou",
        "Skilled",
        "Talented",
        "Superb skills",
        "Extraordinary technology",
        "Wise",
        "Exquisite",
        "Smart",
        "Talent",
        "Profound",
        "Profound",
        "Technology",
        "Superb skills",
        "Talented",
        "Technical unique",
        "Shenlong sees the head",
        "技",
        "Exquisite technique",
        "Talent",
        "Fascinating",
        "Amazing",
        "Outstanding",
        "One skill",
        "Excessive technology",
        "Acute",
        "Talented",
        "Superb skills",
        "Profound",
        "Technical",
        "Superb skills",
        "Technically",
        "Outstanding skills",
        "Excessive technology",
        "Superpopy"
    },
    ["gem_ph"] = {
        "Stars fall",
        "I dance alone in the endless void",
        "Crushed darkness",
        "Welcome to the birth of light!",
        "Sword refers to the sky",
        "Cherish thorns",
        "Bloody burning",
        "Just to protect the pure land in my heart!",
        "Gorgeous",
        "Thunderous",
        "I am proud alone",
        "Staring at the end of this chaotic world!",
        "Dark coming",
        "Mourning",
        "I use the hot heart",
        "Burning life",
        "Light the road to move forward!",
        "Broken dream",
        "Reorganization",
        "I use unyielding will",
        "Challenge the shackles of fate!",
        "Stormy",
        "Move forward",
        "I write the legend with enthusiasm",
        "It is brilliant with courage!",
        "Under the sky",
        "Beings to look up",
        "I stand alone",
        "Let the world witness my existence!",
        "Bloody",
        "Sword",
        "I use unyielding spirit",
        "Challenge the limits of the world!",
        "Dark",
        "Light flashing",
        "I use faith to ignite hope",
        "Light the direction of moving forward!",
        "Starry",
        "Time 荏苒",
        "I use life to guard the faith",
        "Let your dreams come into reality!"
    },
    ["eight_pig"] = {"Handsome"},
    ["gem_spl"] = {
        string["format"]("%s into%s, can i not enter?", 13, 5),
        "It hurts, it hurts!intersectionintersection",
        "Lost my love forever",
        "Gang",
        "Heaven",
        "Why do you want to hide from me!intersectionintersection",
        "The corner of its length",
        "Looking forward to a future that makes me peaceful and happy",
        "Its passes also took away the killing wolf",
        "Wolf comes here",
        "Since i am tired of pursuing",
        "I have learned to lie directly",
        "Since an anti -wind strike",
        "I can move with the wind",
        "Unwilling",
        "Liver",
        "It's just a momentary achievement",
        "Only swinging is eternal",
        "And it will never be tired"
    },
    ["gem_xm"] = {"Send"},
    ["gem_xl"] = {"Zi li cute"},
    ["gem_ls"] = {"Lu sheng is unparalleled in the world"},
    ["gem_nk"] = {"Zhijiang cake hand"}
}
local function k(e, l, m)
    a:HHKillTask(e, l)
    if j[m] then
        local n = j[m]
        local o = #n
        e[l] =
            e:DoPeriodicTask(
            0.3,
            function()
                if not a:IsHHType(e["hh_str_index"], "number") or not n[e["hh_str_index"]] or e["hh_str_index"] > o then
                    e["hh_str_index"] = 1
                end
                local p = j[m]
                local q = math["random"](1, #j[m])
                a:SpawnClientStrFx(e, p[q])
                e["hh_str_index"] = e["hh_str_index"] + 1
            end
        )
    end
end
local function r(s, t)
    if not a:HasComponents(s, "equippable") or not (s["components"]["equippable"]["equipslot"] == t) then
        return false, "vui lòng hợp thành trang bị phù hợp"
    end
    return true, "đáp ứng các điều kiện"
end
local function u(v, w, x, y, z, A, B, C)
    local D = {
        ["name"] = tostring(v),
        ["client_text"] = tostring(w),
        ["desc"] = tostring(x),
        ["only_one"] = true,
        ["is_suit"] = true,
        ["client_color"] = B or {94 / 255, 38 / 255, 18 / 255, 1},
        ["suit_str"] = tostring(y),
        ["check_equip_can_add"] = function(s)
            return r(s, EQUIPSLOTS[tostring(z)])
        end,
        ["id"] = C or 9999
    }
    if A then
        D["person_one"] = true
    end
    return D
end
local function E(s)
    if s:IsValid() and a:HasComponents(s, "health") and not s["components"]["health"]:IsDead() then
        return true
    end
    return false
end
local function F(s, G)
    if
        a:HasComponents(s, "armor") and not s["components"]["armor"]["indestructible"] or
            a:HasComponents(s, "finiteuses") or
            a:HasComponents(s, "fueled") or
            a:HasComponents(s, "perishable")
     then
        if not G then
            if
                s["prefab"] == "greenstaff" or s["prefab"] == "greenamulet" or s["prefab"] == "yellowstaff" or
                    s["prefab"] == "yellowamulet" or
                    s["prefab"] == "orangeamulet" or
                    s["prefab"] == "telestaff" or
                    s["prefab"] == "purpleamulet" or
                    s["prefab"] == "icestaff" or
                    s["prefab"] == "blueamulet" or
                    s["prefab"] == "firestaff" or
                    s["prefab"] == "amulet" or
                    s["prefab"] == "opalstaff"
             then
                return false
            end
        end
        return true
    end
    return false
end
local function H(e, I)
    if e:IsValid() and a:HasComponents(e, "health") and a:IsHHType(I, "number") then
        local J = e["components"]["health"]:GetPercent()
        local K = e["components"]["health"]["maxhealth"]
        if I > 0 then
            e["components"]["health"]["maxhealth"] = math["min"](K + I, 60000)
            e["components"]["health"]:SetPercent(J)
        else
            e["components"]["health"]["maxhealth"] = math["max"](K + I, 1)
            e["components"]["health"]:SetPercent(J)
        end
    end
end
local function L(M)
    if a:HasComponents(M, "tbc_player_effects") then
        M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneFreeze", 1)
        M["components"]["tbc_player_effects"]:AddEffectValueByKey("immunePoison", 1)
        M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneCold", 1)
        M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneHot", 1)
        M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneBramble", 1)
        M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneReduceSpeed", 1)
        M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneSuppressNum", 1)
    end
    if a:HasComponents(M, "hh_buff") then
        M["components"]["hh_buff"]:RemoveBuff "poison"
    end
end
local function N(M)
    if a:HasComponents(M, "tbc_player_effects") then
        M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneFreeze", 1)
        M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immunePoison", 1)
        M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneCold", 1)
        M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneHot", 1)
        M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneBramble", 1)
        M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneReduceSpeed", 1)
        M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneSuppressNum", 1)
    end
end
local O = "tbc_equipment"
local function P(s)
    if not a:HasComponents(s, "equippable") then
        return
    end
    local Q = s["components"]["equippable"]["onequipfn"]
    s["components"]["equippable"]["onequipfn"] = function(R, M, ...)
        if a:HasComponents(R, O) and M:IsValid() and M:HasTag "player" then
            R["components"][O]:HandleEquipBuffToPlayer(M, true)
        end
        if Q then
            Q(R, M, ...)
        end
    end
    local S = s["components"]["equippable"]["onunequipfn"]
    s["components"]["equippable"]["onunequipfn"] = function(R, M, ...)
        if a:HasComponents(R, O) and M:IsValid() and M:HasTag "player" then
            R["components"][O]:HandleEquipBuffToPlayer(M, false)
        end
        if S then
            S(R, M, ...)
        end
    end
end
local function T(s)
    if a:HasComponents(s, "forgerepairable") and s:HasTag "broken" then
        if a:IsHHType(s["components"]["forgerepairable"]["onrepaired"], "function") then
            s["components"]["forgerepairable"]["onrepaired"](s)
        end
    end
end
local function U(s, V)
    if not a:IsHHType(V, "number") or V < 0 then
        return
    end
    if a:HasComponents(s, "armor") and not s["components"]["armor"]["indestructible"] then
        local W = s["components"]["armor"]:GetPercent()
        if W < 1 then
            local X = s["components"]["armor"]["condition"]
            s["components"]["armor"]:SetCondition(X + V)
        end
    end
    if a:HasComponents(s, "finiteuses") then
        local Y = s["components"]["finiteuses"]:GetPercent()
        if Y < 1 then
            local Z = s["components"]["finiteuses"]["total"]
            local X = s["components"]["finiteuses"]:GetUses()
            s["components"]["finiteuses"]:SetUses(math["min"](Z, X + V))
        end
    end
    if a:HasComponents(s, "fueled") then
        local _ = s["components"]["fueled"]:GetPercent()
        if _ < 1 then
            s["components"]["fueled"]:DoDelta(V)
        end
    end
    if a:HasComponents(s, "perishable") then
        local a0 = s["components"]["perishable"]:GetPercent()
        if a0 < 1 then
            local a1 = s["components"]["perishable"]["perishremainingtime"]
            local Z = s["components"]["perishable"]["perishtime"]
            if a1 and Z and Z > 0 then
                a1 = a1 + V
                local a2 = a1 / Z
                s["components"]["perishable"]:SetPercent(a2)
            end
        end
    end
    local a3, a4 = pcall(T, s)
end
local function a5(s, a6)
    if not a:IsHHType(a6, "number") or a6 < 0 then
        return
    end
    if a:HasComponents(s, "armor") and not s["components"]["armor"]["indestructible"] then
        local W = s["components"]["armor"]:GetPercent()
        if W < 1 then
            local a7 = math["min"](W + a6, 1)
            s["components"]["armor"]:SetPercent(a7)
        end
    end
    if a:HasComponents(s, "finiteuses") then
        local Y = s["components"]["finiteuses"]:GetPercent()
        if Y < 1 then
            local a7 = math["min"](Y + a6, 1)
            s["components"]["finiteuses"]:SetPercent(a7)
        end
    end
    if a:HasComponents(s, "fueled") then
        local _ = s["components"]["fueled"]:GetPercent()
        if _ < 1 then
            local a7 = math["min"](_ + a6, 1)
            s["components"]["fueled"]:SetPercent(a7)
        end
    end
    if a:HasComponents(s, "perishable") then
        local a0 = s["components"]["perishable"]:GetPercent()
        if a0 < 1 then
            local a7 = math["min"](a0 + a6, 1)
            s["components"]["perishable"]:SetPercent(a7)
        end
    end
    local a3, a4 = pcall(T, s)
end
local function a8(s, a9, aa)
    if not a:IsHHType(a9, "number") then
        return
    end
    if a:HasComponents(s, "armor") and not s["components"]["armor"]["indestructible"] then
        local W = s["components"]["armor"]:GetPercent()
        local ab = s["components"]["armor"]["maxcondition"]
        s["components"]["armor"]["maxcondition"] = math["max"](ab + a9)
        s["components"]["armor"]:SetPercent(W)
    end
    if a:HasComponents(s, "finiteuses") then
        local Y = s["components"]["finiteuses"]:GetPercent()
        local ac = s["components"]["finiteuses"]["total"]
        s["components"]["finiteuses"]["total"] = math["max"](ac + a9, 1)
        s["components"]["finiteuses"]:SetPercent(Y)
    end
    if a:HasComponents(s, "fueled") then
        local _ = s["components"]["fueled"]:GetPercent()
        local ad = s["components"]["fueled"]["maxfuel"]
        s["components"]["fueled"]["maxfuel"] = math["max"](ad + a9, 1)
        s["components"]["fueled"]:SetPercent(_)
    end
    if a:HasComponents(s, "perishable") then
        local a0 = s["components"]["perishable"]:GetPercent()
        local ae = s["components"]["perishable"]["perishtime"]
        if ae and ae > 0 then
            s["components"]["perishable"]["perishtime"] = math["max"](ae + a9, 1)
            s["components"]["perishable"]:SetPercent(a0)
        end
    end
end
local af = {
    ["follow_reduce_damage"] = {
        ["id"] = 96,
        ["name"] = "Trợ Thủ-PT",
        ["only_one"] = true,
        ["client_text"] = "TT\nThủ",
        ["desc"] = b["follow_reduce_damage"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 5, ["max"] = 10},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addFollowReduceDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addFollowReduceDamage", I)
        end
    },
    ["follow_add_damage"] = {
        ["id"] = 95,
        ["name"] = "Trợ Thủ-TC",
        ["client_text"] = "TT\nCông",
        ["desc"] = b["follow_damage"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 10, ["max"] = 20},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addFollowDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addFollowDamage", I)
        end
    },
    ["fast_act"] = {
        ["id"] = 94,
        ["name"] = "Tháo Vát-TH",
        ["client_text"] = "TV\nTH",
        ["desc"] = b["fast_act"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["on_equip_fn"] = function(s, e, I)
            if a:HasComponents(e, "tbc_player_effects") then
                e["components"]["tbc_player_effects"]:AddEffectValueByKey("fast_act", 1)
            end
            a:HHClientRpc(e, "hh_fast_act", true)
        end,
        ["un_equip_fn"] = function(s, e, I)
            if a:HasComponents(e, "tbc_player_effects") then
                e["components"]["tbc_player_effects"]:ReduceEffectValueByKey("fast_act", 1)
                if e["components"]["tbc_player_effects"]:HasSpecialEffect "fast_act" then
                    a:HHClientRpc(e, "hh_fast_act", true)
                else
                    a:HHClientRpc(e, "hh_fast_act", false)
                end
            end
        end
    },
    ["work_speed"] = {
        ["id"] = 93,
        ["name"] = "Tháo Vát-KT",
        ["client_text"] = "TV\nKT",
        ["desc"] = b["work_speed"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("workAddSpeed", 1)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("workAddSpeed", 1)
            end
        end
    },
    ["shadow_camp"] = {
        ["id"] = 92,
        ["name"] = "Phục Ma-BT",
        ["client_text"] = "PM\nBT",
        ["desc"] = b["shadow_camp"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("shadowCamp", 1)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("shadowCamp", 1)
            end
        end
    },
    ["moon_camp"] = {
        ["id"] = 91,
        ["name"] = "Phục Ma-VĐ",
        ["client_text"] = "PM\nVĐ",
        ["desc"] = b["moon_camp"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("moonCamp", 1)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("moonCamp", 1)
            end
        end
    },
    ["add_speed"] = {
        ["id"] = 89,
        ["name"] = "Nhanh Nhẹn",
        ["client_text"] = "NN",
        ["desc"] = b["add_speed"],
        ["check_desc"] = "trang bị tay",
        ["only_one"] = true,
        ["can_add"] = true,
        ["value_range"] = {["min"] = 1, ["max"] = 25},
        ["star_rating"] = 8,
        ["check_equip_can_add"] = function(s)
            if r(s, EQUIPSLOTS["HANDS"]) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addSpeedPercent", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addSpeedPercent", I)
        end
    },
    ["add_light"] = {
        ["id"] = 90,
        ["name"] = "☆Phổ Độ",
        ["client_text"] = "PĐ",
        ["desc"] = b["add_light"],
        ["check_desc"] = "tất cả",
        ["can_add"] = false,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["on_equip_fn"] = function(s, M, I)
            a:HHRemoveFx(M, "hh_add_light_fx")
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("add_light", 1)
                M["hh_add_light_fx"] = SpawnPrefab "hh_light_fx"
                if M["hh_add_light_fx"] then
                    M["hh_add_light_fx"]["entity"]:SetParent(M["entity"])
                end
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            a:HHRemoveFx(M, "hh_add_light_fx")
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("add_light", 1)
                if M["components"]["tbc_player_effects"]:HasSpecialEffect "add_light" then
                    M["hh_add_light_fx"] = SpawnPrefab "hh_light_fx"
                    if M["hh_add_light_fx"] then
                        M["hh_add_light_fx"]["entity"]:SetParent(M["entity"])
                    end
                end
            end
        end
    },
    ["add_max_use_small"] = {
        ["id"] = 87,
        ["name"] = "Bền Bỉ I",
        ["desc"] = b["add_max_use"],
        ["can_add"] = true,
        ["only_one"] = true,
        ["client_text"] = "BB\nI",
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 20, ["max"] = 80},
        ["check_equip_can_add"] = function(s)
            if F(s) and a:HasComponents(s, "tbc_equipment") then
                if s["components"]["tbc_equipment"]:HasEffectByName "add_max_use_big" then
                    return false, "chỉ được ép tối đa 1 viên Bền Bỉ"
                end
                return true, "đáp ứng các điều kiện"
            end
            return false, "trang bị ko phù hợp"
        end,
        ["check_desc"] = "trang bị có độ tươi, độ bền",
        ["start_fn"] = function(s, I)
            a8(s, I)
        end,
        ["end_fn"] = function(s, I)
            a8(s, -I)
        end
    },
    ["add_max_use_big"] = {
        ["id"] = 88,
        ["name"] = "Bền Bỉ II",
        ["desc"] = b["add_max_use"],
        ["can_add"] = true,
        ["only_one"] = true,
        ["client_text"] = "BB\nII",
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 40, ["max"] = 160},
        ["check_equip_can_add"] = function(s)
            if F(s) and a:HasComponents(s, "tbc_equipment") then
                if s["components"]["tbc_equipment"]:HasEffectByName "add_max_use_small" then
                    return false, "chỉ được ép tối đa 1 viên Bền Bỉ"
                end
                return true, "đáp ứng các điều kiện"
            end
            return false, "trang bị ko phù hợp"
        end,
        ["check_desc"] = "trang bị có độ tươi, độ bền",
        ["start_fn"] = function(s, I)
            a8(s, I)
        end,
        ["end_fn"] = function(s, I)
            a8(s, -I)
        end
    },
    ["san_replace_damage_small"] = {
        ["id"] = 85,
        ["name"] = "Lá Chắn I",
        ["client_text"] = "LC\nI",
        ["desc"] = b["san_replace_damage"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 1, ["max"] = 10},
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("sanReplaceDamageChance", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("sanReplaceDamageChance", I)
            end
        end
    },
    ["san_replace_damage_big"] = {
        ["id"] = 86,
        ["name"] = "Lá Chắn II",
        ["client_text"] = "LC\nII",
        ["desc"] = b["san_replace_damage"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 1, ["max"] = 20},
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("sanReplaceDamageChance", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("sanReplaceDamageChance", I)
            end
        end
    },
    ["reflexive_injury_small"] = {
        ["id"] = 83,
        ["name"] = "Phản Kích I",
        ["client_text"] = "PK\nI",
        ["desc"] = b["reflexive_injury"],
        ["check_desc"] = "ngoại trừ vũ khí",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 1, ["max"] = 10},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return false, "ko ép được vũ khí"
            end
            return true, "đáp ứng các điều kiện"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("reflexiveInjury", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("reflexiveInjury", I)
        end
    },
    ["reflexive_injury_med"] = {
        ["id"] = 84,
        ["name"] = "Phản Kích II",
        ["client_text"] = "PK\nII",
        ["desc"] = b["reflexive_injury"],
        ["check_desc"] = "ngoại trừ vũ khí",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 5, ["max"] = 15},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return false, "ko ép được vũ khí"
            end
            return true, "đáp ứng các điều kiện"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("reflexiveInjury", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("reflexiveInjury", I)
        end
    },
    ["reflexive_injury_big"] = {
        ["id"] = 81,
        ["name"] = "☆Phản Kích III",
        ["client_text"] = "PK\nIII",
        ["desc"] = b["reflexive_injury"],
        ["check_desc"] = "ngoại trừ vũ khí",
        ["can_add"] = false,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 10, ["max"] = 20},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return false, "ko ép được vũ khí"
            end
            return true, "đáp ứng các điều kiện"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("reflexiveInjury", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("reflexiveInjury", I)
        end
    },
    ["reflexive_injury_special"] = {
        ["id"] = 82,
        ["name"] = "★Phản Kích IV",
        ["client_text"] = "PK\nIV",
        ["desc"] = b["reflexive_injury"],
        ["check_desc"] = "ngoại trừ vũ khí",
        ["can_add"] = false,
        ["only_one"] = true,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 15, ["max"] = 30},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return false, "ko ép được vũ khí"
            end
            return true, "đáp ứng các điều kiện"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("reflexiveInjury", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("reflexiveInjury", I)
        end
    },
    ["add_critical_hit_rate_small"] = {
        ["id"] = 79,
        ["name"] = "Bạo Kích I",
        ["client_text"] = "CK\nI",
        ["desc"] = b["add_critical_hit_rate"],
        ["check_desc"] = "ngoại trừ giáp",
        ["can_add"] = true,
        ["only_one"] = false,
        ["value_range"] = {["min"] = 1, ["max"] = 10},
        ["star_rating"] = 4,
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "armor") then
                return false, "ko ép được giáp"
            end
            return true, "đáp ứng các điều kiện"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("criticalHitRate", I)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("criticalHitEffect", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("criticalHitRate", I)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("criticalHitEffect", I)
            end
        end
    },
    ["add_critical_hit_rate_med"] = {
        ["id"] = 80,
        ["name"] = "Bạo Kích II",
        ["client_text"] = "CK\nII",
        ["desc"] = b["add_critical_hit_rate"],
        ["check_desc"] = "ngoại trừ giáp",
        ["can_add"] = true,
        ["only_one"] = false,
        ["value_range"] = {["min"] = 1, ["max"] = 20},
        ["star_rating"] = 6,
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "armor") then
                return false, "ko ép được giáp"
            end
            return true, "đáp ứng các điều kiện"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("criticalHitRate", I)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("criticalHitEffect", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("criticalHitRate", I)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("criticalHitEffect", I)
            end
        end
    },
    ["add_critical_hit_rate_big"] = {
        ["id"] = 77,
        ["name"] = "☆Bạo Kích III",
        ["client_text"] = "CK\nIII",
        ["desc"] = b["add_critical_hit_rate"],
        ["check_desc"] = "ngoại trừ giáp",
        ["can_add"] = false,
        ["only_one"] = false,
        ["value_range"] = {["min"] = 1, ["max"] = 30},
        ["star_rating"] = 8,
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "armor") then
                return false, "ko ép được giáp"
            end
            return true, "đáp ứng các điều kiện"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("criticalHitRate", I)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("criticalHitEffect", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("criticalHitRate", I)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("criticalHitEffect", I)
            end
        end
    },
    ["add_critical_hit_rate_special"] = {
        ["id"] = 78,
        ["name"] = "★Bạo Kích IV",
        ["client_text"] = "CK\nIV",
        ["desc"] = b["add_critical_hit_rate"],
        ["check_desc"] = "ngoại trừ giáp",
        ["can_add"] = false,
        ["only_one"] = false,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["only_compound"] = true,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 1, ["max"] = 50},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "armor") then
                return false, "ko ép được giáp"
            end
            return true, "đáp ứng các điều kiện"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("criticalHitRate", I)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("criticalHitEffect", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("criticalHitRate", I)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("criticalHitEffect", I)
            end
        end
    },
    ["atk_speed_small"] = {
        ["id"] = 75,
        ["name"] = "Liên Kích I",
        ["client_text"] = "LK\nI",
        ["desc"] = b["atk_speed"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 1, ["max"] = 10},
        ["check_equip_can_add"] = function(s)
            if r(s, EQUIPSLOTS["HANDS"]) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào trang bị ở vị trí tay"
        end,
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["atk_speed"] = I}, true)
            if a:HasComponents(M, "tbc_player_effects") then
                local ag = M["components"]["tbc_player_effects"]:GetEffectValueByKey "atk_speed"
                a:HHClientRpc(M, "hh_atk_speed", ag)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["atk_speed"] = I}, false)
            if a:HasComponents(M, "tbc_player_effects") then
                local ag = M["components"]["tbc_player_effects"]:GetEffectValueByKey "atk_speed"
                a:HHClientRpc(M, "hh_atk_speed", ag)
            end
        end
    },
    ["atk_speed_med"] = {
        ["id"] = 76,
        ["name"] = "Liên Kích II",
        ["client_text"] = "LK\nII",
        ["desc"] = b["atk_speed"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 5, ["max"] = 20},
        ["check_equip_can_add"] = function(s)
            if r(s, EQUIPSLOTS["HANDS"]) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào trang bị ở vị trí tay"
        end,
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["atk_speed"] = I}, true)
            if a:HasComponents(M, "tbc_player_effects") then
                local ag = M["components"]["tbc_player_effects"]:GetEffectValueByKey "atk_speed"
                a:HHClientRpc(M, "hh_atk_speed", ag)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["atk_speed"] = I}, false)
            if a:HasComponents(M, "tbc_player_effects") then
                local ag = M["components"]["tbc_player_effects"]:GetEffectValueByKey "atk_speed"
                a:HHClientRpc(M, "hh_atk_speed", ag)
            end
        end
    },
    ["atk_speed_big"] = {
        ["id"] = 73,
        ["name"] = "☆Liên Kích III",
        ["client_text"] = "LK\nIII",
        ["desc"] = b["atk_speed"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = false,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 10, ["max"] = 35},
        ["check_equip_can_add"] = function(s)
            if r(s, EQUIPSLOTS["HANDS"]) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào trang bị ở vị trí tay"
        end,
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["atk_speed"] = I}, true)
            if a:HasComponents(M, "tbc_player_effects") then
                local ag = M["components"]["tbc_player_effects"]:GetEffectValueByKey "atk_speed"
                a:HHClientRpc(M, "hh_atk_speed", ag)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["atk_speed"] = I}, false)
            if a:HasComponents(M, "tbc_player_effects") then
                local ag = M["components"]["tbc_player_effects"]:GetEffectValueByKey "atk_speed"
                a:HHClientRpc(M, "hh_atk_speed", ag)
            end
        end
    },
    ["atk_speed_special"] = {
        ["id"] = 74,
        ["name"] = "★Liên Kích IV",
        ["client_text"] = "LK\nIV",
        ["desc"] = b["atk_speed"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = false,
        ["only_one"] = true,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["only_compound"] = true,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 20, ["max"] = 70},
        ["check_equip_can_add"] = function(s)
            if r(s, EQUIPSLOTS["HANDS"]) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào trang bị ở vị trí tay"
        end,
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["atk_speed"] = I}, true)
            if a:HasComponents(M, "tbc_player_effects") then
                local ag = M["components"]["tbc_player_effects"]:GetEffectValueByKey "atk_speed"
                a:HHClientRpc(M, "hh_atk_speed", ag)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["atk_speed"] = I}, false)
            if a:HasComponents(M, "tbc_player_effects") then
                local ag = M["components"]["tbc_player_effects"]:GetEffectValueByKey "atk_speed"
                a:HHClientRpc(M, "hh_atk_speed", ag)
            end
        end
    },
    ["restore_use_10s_1use"] = {
        ["id"] = 71,
        ["name"] = "Gia Trì I",
        ["client_text"] = "GT\nI",
        ["desc"] = b["restore_use_10s_1use"],
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 4,
        ["xml"] = "images/inventoryimages2.xml",
        ["tex"] = "sewing_kit.tex",
        ["check_equip_can_add"] = function(s)
            if F(s) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "trang bị ko phù hợp"
        end,
        ["check_desc"] = "trang bị có độ tươi, độ bền",
        ["start_fn"] = function(s)
            a:HHKillTask(s, "restore_use_10s_1use_task")
            s["restore_use_10s_1use_task"] =
                s:DoPeriodicTask(
                10,
                function()
                    U(s, 1)
                end
            )
        end,
        ["end_fn"] = function(s)
            a:HHKillTask(s, "restore_use_10s_1use_task")
        end
    },
    ["restore_use_5s_1use"] = {
        ["id"] = 72,
        ["name"] = "Gia Trì II",
        ["client_text"] = "GT\nII",
        ["desc"] = b["restore_use_5s_1use"],
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["check_equip_can_add"] = function(s)
            if F(s) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "trang bị ko phù hợp"
        end,
        ["check_desc"] = "trang bị có độ tươi, độ bền",
        ["start_fn"] = function(s)
            a:HHKillTask(s, "restore_use_5s_1use_task")
            s["restore_use_5s_1use_task"] =
                s:DoPeriodicTask(
                5,
                function()
                    U(s, 1)
                end
            )
        end,
        ["end_fn"] = function(s)
            a:HHKillTask(s, "restore_use_5s_1use_task")
        end
    },
    ["restore_use_3s_1use"] = {
        ["id"] = 69,
        ["name"] = "☆Gia Trì III",
        ["client_text"] = "GT\nIII",
        ["desc"] = b["restore_use_3s_1use"],
        ["can_add"] = false,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["check_desc"] = "trang bị có độ tươi, độ bền",
        ["check_equip_can_add"] = function(s)
            if F(s) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "trang bị ko phù hợp"
        end,
        ["start_fn"] = function(s)
            a:HHKillTask(s, "restore_use_3s_1use_task")
            s["restore_use_3s_1use_task"] =
                s:DoPeriodicTask(
                1,
                function()
                    U(s, 1)
                end
            )
        end,
        ["end_fn"] = function(s)
            a:HHKillTask(s, "restore_use_3s_1use_task")
        end
    },
    ["restore_use_1s_2_percent"] = {
        ["id"] = 70,
        ["name"] = "★Gia Trì IV",
        ["client_text"] = "GT\nIV",
        ["desc"] = b["restore_use_1s_2_percent"],
        ["can_add"] = false,
        ["only_one"] = true,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["only_compound"] = true,
        ["star_rating"] = 10,
        ["check_equip_can_add"] = function(s)
            if F(s) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "trang bị ko phù hợp"
        end,
        ["check_desc"] = "trang bị có độ tươi, độ bền",
        ["start_fn"] = function(s)
            a:HHKillTask(s, "restore_use_1s_2_percent_task")
            s["restore_use_1s_2_percent_task"] =
                s:DoPeriodicTask(
                1,
                function()
                    a5(s, 0.02)
                end
            )
        end,
        ["end_fn"] = function(s)
            a:HHKillTask(s, "restore_use_1s_2_percent_task")
        end
    },
    ["add_max_use_armor_01"] = {
        ["id"] = 67,
        ["name"] = "Hộ Giáp I",
        ["desc"] = b["add_max_use_armor_01"],
        ["can_add"] = true,
        ["only_one"] = false,
        ["client_text"] = "HG\nI",
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 200, ["max"] = 500},
        ["check_equip_can_add"] = function(s)
            if F(s) and a:HasComponents(s, "tbc_equipment") then
                if
                    s["components"]["tbc_equipment"]:HasEffectByName "add_max_use_armor_02" or
                        s["components"]["tbc_equipment"]:HasEffectByName "add_max_use_armor_03"
                 then
                    return false, "chỉ được ép tối đa 1 viên Hộ Giáp"
                end
                if a:HasComponents(s, "armor") then
                    return true, "đáp ứng các điều kiện"
                end
                return false, "chỉ ép được vào giáp"
            end
            return false, "chỉ ép được vào giáp"
        end,
        ["check_desc"] = "giáp",
        ["start_fn"] = function(s, I)
            a8(s, I)
        end,
        ["end_fn"] = function(s, I)
            a8(s, -I)
        end
    },
    ["add_max_use_armor_02"] = {
        ["id"] = 68,
        ["name"] = "Hộ Giáp II",
        ["desc"] = b["add_max_use_armor_02"],
        ["can_add"] = true,
        ["only_one"] = false,
        ["client_text"] = "HG\nII",
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 500, ["max"] = 1000},
        ["check_equip_can_add"] = function(s)
            if F(s) and a:HasComponents(s, "tbc_equipment") then
                if
                    s["components"]["tbc_equipment"]:HasEffectByName "add_max_use_armor_01" or
                        s["components"]["tbc_equipment"]:HasEffectByName "add_max_use_armor_03"
                 then
                    return false, "chỉ được ép tối đa 1 viên Hộ Giáp"
                end
                if a:HasComponents(s, "armor") then
                    return true, "đáp ứng các điều kiện"
                end
                return false, "chỉ ép được vào giáp"
            end
            return false, "chỉ ép được vào giáp"
        end,
        ["check_desc"] = "giáp",
        ["start_fn"] = function(s, I)
            a8(s, I)
        end,
        ["end_fn"] = function(s, I)
            a8(s, -I)
        end
    },
    ["add_max_use_armor_03"] = {
        ["id"] = 65,
        ["name"] = "☆Hộ Giáp III",
        ["desc"] = b["add_max_use_armor_03"],
        ["can_add"] = false,
        ["only_one"] = true,
        ["client_text"] = "HG\nIII",
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 1000, ["max"] = 3000},
        ["check_equip_can_add"] = function(s)
            if F(s) and a:HasComponents(s, "tbc_equipment") then
                if
                    s["components"]["tbc_equipment"]:HasEffectByName "add_max_use_armor_01" or
                        s["components"]["tbc_equipment"]:HasEffectByName "add_max_use_armor_02"
                 then
                    return false, "chỉ được ép tối đa 1 viên Hộ Giáp"
                end
                if a:HasComponents(s, "armor") then
                    return true, "đáp ứng các điều kiện"
                end
                return false, "chỉ ép được vào giáp"
            end
            return false, "chỉ ép được vào giáp"
        end,
        ["check_desc"] = "giáp",
        ["start_fn"] = function(s, I)
            a8(s, I)
        end,
        ["end_fn"] = function(s, I)
            a8(s, -I)
        end
    },
    ["armor_immune_amount"] = {
        ["id"] = 66,
        ["name"] = "★Hộ Giáp IV",
        ["client_text"] = "HG\nIV",
        ["desc"] = b["armor_immune_amount"],
        ["can_add"] = false,
        ["only_one"] = true,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["only_compound"] = true,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 10, ["max"] = 80},
        ["check_desc"] = "giáp hấp thụ dưới 100% ST",
        ["check_equip_can_add"] = function(s)
            if not a:HasComponents(s, "armor") then
                return false, "chỉ ép được vào giáp"
            end
            if not s["components"]["armor"]["indestructible"] then
                return true, "đáp ứng các điều kiện"
            end
            local ah = s["components"]["armor"]["absorb_percent"] or 0
            if not a:IsHHType(ah, "number") then
                return false, "lỗi thông số gi"
            end
            if ah >= 1 then
                return false, "chỉ ép được vào giáp block dưới 100%"
            end
            return false, "chỉ ép được vào giáp"
        end,
        ["on_equip_fn"] = function(s, M, I)
        end,
        ["un_equip_fn"] = function(s, M, I)
        end
    },
    ["true_damage_small"] = {
        ["id"] = 63,
        ["name"] = "Xuyên Giáp I",
        ["client_text"] = "XG\nI",
        ["desc"] = b["true_damage"],
        ["check_desc"] = "vũ khí" .. c,
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 30},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("trueDamageNum", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("trueDamageNum", I)
            end
        end
    },
    ["true_damage_med"] = {
        ["id"] = 64,
        ["name"] = "Xuyên Giáp II",
        ["client_text"] = "XG\nII",
        ["desc"] = b["true_damage"],
        ["check_desc"] = "vũ khí" .. c,
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 20, ["max"] = 60},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("trueDamageNum", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("trueDamageNum", I)
            end
        end
    },
    ["true_damage_big"] = {
        ["id"] = 61,
        ["name"] = "☆Xuyên Giáp III",
        ["client_text"] = "XG\nIII",
        ["desc"] = b["true_damage"],
        ["check_desc"] = "vũ khí" .. c,
        ["can_add"] = false,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 40, ["max"] = 120},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("trueDamageNum", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("trueDamageNum", I)
            end
        end
    },
    ["true_damage_special"] = {
        ["id"] = 62,
        ["name"] = "★Xuyên Giáp IV",
        ["client_text"] = "XG\nIV",
        ["desc"] = b["true_damage"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = false,
        ["only_one"] = true,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["only_compound"] = true,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 80, ["max"] = 240},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["trueDamageNum"] = I}, true)
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["trueDamageNum"] = I}, false)
        end
    },
    ["add_day_damage"] = {
        ["id"] = 51,
        ["name"] = "Thanh Long-Sáng",
        ["client_text"] = "TL\nSáng",
        ["desc"] = b["add_day_damage"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 20, ["max"] = 80},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("sunlightStrike", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("sunlightStrike", I)
        end
    },
    ["add_dusk_damage"] = {
        ["id"] = 52,
        ["name"] = "Thanh Long-Chiều",
        ["client_text"] = "TL\nChiều",
        ["desc"] = b["add_dusk_damage"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 20, ["max"] = 80},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("afterglowStrike", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("afterglowStrike", I)
        end
    },
    ["add_night_damage"] = {
        ["id"] = 49,
        ["name"] = "Thanh Long-Tối",
        ["client_text"] = "TL\nTối",
        ["desc"] = b["add_night_damage"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 20, ["max"] = 80},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("nightMenace", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("nightMenace", I)
        end
    },
    ["blood_outburst"] = {
        ["id"] = 50,
        ["name"] = "Thanh Long-Máu",
        ["client_text"] = "TL\nMáu",
        ["desc"] = b["blood_outburst"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("bloodOutburst", 1)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("bloodOutburst", 1)
        end
    },
    ["spirit_fade"] = {
        ["id"] = 48,
        ["name"] = "Thanh Long-Não",
        ["client_text"] = "TL\nNão",
        ["desc"] = b["spirit_fade"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("spiritFade", 1)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("spiritFade", 1)
        end
    },
    ["hunger_assault"] = {
        ["id"] = 47,
        ["name"] = "Thanh Long-Đói",
        ["client_text"] = "TL\nĐói",
        ["desc"] = b["hunger_assault"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("hungerAssault", 1)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("hungerAssault", 1)
        end
    },
    ["add_hit_damage_monkey"] = {
        ["id"] = 46,
        ["name"] = "Thanh Long-Khỉ",
        ["client_text"] = "TL\nKhỉ",
        ["desc"] = b["add_hit_damage_monkey"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitMonkeyDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitMonkeyDamage", I)
        end
    },
    ["add_hit_damage_boss"] = {
        ["id"] = 45,
        ["name"] = "Thanh Long-Trùm",
        ["client_text"] = "TL\nTrùm",
        ["desc"] = b["add_hit_damage_boss"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitBossDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitBossDamage", I)
        end
    },
    ["add_hit_damage_pig"] = {
        ["id"] = 44,
        ["name"] = "Thanh Long-Heo",
        ["client_text"] = "TL\nHeo",
        ["desc"] = b["add_hit_damage_pig"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitPigDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitPigDamage", I)
        end
    },
    ["add_hit_damage_frog"] = {
        ["id"] = 41,
        ["name"] = "Thanh Long-Ếch",
        ["client_text"] = "TL\nẾch",
        ["desc"] = b["add_hit_damage_frog"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitFrogDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitFrogDamage", I)
        end
    },
    ["add_hit_damage_spider"] = {
        ["id"] = 40,
        ["name"] = "Thanh Long-Nhện",
        ["client_text"] = "TL\nNhện",
        ["desc"] = b["add_hit_damage_spider"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitSpiderDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitSpiderDamage", I)
        end
    },
    ["add_hit_damage_dog"] = {
        ["id"] = 39,
        ["name"] = "Thanh Long-Sói",
        ["client_text"] = "TL\nSói",
        ["desc"] = b["add_hit_damage_dog"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitDogDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitDogDamage", I)
        end
    },
    ["add_hit_damage_gear"] = {
        ["id"] = 38,
        ["name"] = "Thanh Long-ĐH",
        ["client_text"] = "TL\nĐH",
        ["desc"] = b["add_hit_damage_gear"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitGearDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitGearDamage", I)
        end
    },
    ["add_hit_damage_insect"] = {
        ["id"] = 37,
        ["name"] = "Thanh Long-CT",
        ["client_text"] = "TL\nCT",
        ["desc"] = b["add_hit_damage_insect"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitInsectDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitInsectDamage", I)
        end
    },
    ["add_hit_damage_shadow"] = {
        ["id"] = 36,
        ["name"] = "Thanh Long-BT",
        ["client_text"] = "TL\nBT",
        ["desc"] = b["add_hit_damage_shadow"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitShadowDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitShadowDamage", I)
        end
    },
    ["add_hit_damage_plant"] = {
        ["id"] = 35,
        ["name"] = "Thanh Long-TV",
        ["client_text"] = "TL\nTV",
        ["desc"] = b["add_hit_damage_plant"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addHitPlantDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addHitPlantDamage", I)
        end
    },
    ["add_damage_small"] = {
        ["id"] = 33,
        ["name"] = "Thanh Long I",
        ["client_text"] = "TL\nI",
        ["desc"] = b["add_damage_small"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = true,
        ["only_one"] = false,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 5, ["max"] = 20},
        ["check_equip_can_add"] = function(s)
            if r(s, EQUIPSLOTS["HANDS"]) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addComDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addComDamage", I)
        end
    },
    ["add_damage_med"] = {
        ["id"] = 34,
        ["name"] = "Thanh Long II",
        ["client_text"] = "TL\nII",
        ["desc"] = b["add_damage_med"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = true,
        ["only_one"] = false,
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 10, ["max"] = 40},
        ["check_equip_can_add"] = function(s)
            if r(s, EQUIPSLOTS["HANDS"]) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addComDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addComDamage", I)
        end
    },
    ["add_damage_big"] = {
        ["id"] = 31,
        ["name"] = "☆Thanh Long III",
        ["client_text"] = "TL\nIII",
        ["desc"] = b["add_damage_big"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = false,
        ["only_one"] = false,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 20, ["max"] = 80},
        ["check_equip_can_add"] = function(s)
            if r(s, EQUIPSLOTS["HANDS"]) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addComDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addComDamage", I)
        end
    },
    ["special_bhtg"] = {
        ["id"] = 32,
        ["name"] = "★Thanh Long IV",
        ["client_text"] = "TL\nIV",
        ["desc"] = b["special_bhtg"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = false,
        ["only_one"] = false,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["only_compound"] = true,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 1, ["max"] = 3},
        ["check_equip_can_add"] = function(s)
            if r(s, EQUIPSLOTS["HANDS"]) then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("addComDamage", 160)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("targetPercentDamage", I)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addComDamage", 160)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("targetPercentDamage", I)
            end
        end
    },
    ["absorb_small"] = {
        ["id"] = 27,
        ["name"] = "Bạch Hổ-G1",
        ["client_text"] = "BH\nG1",
        ["desc"] = b["absorb_small"],
        ["check_desc"] = "tất cả (giảm tối đa 80%)",
        ["can_add"] = true,
        ["only_one"] = false,
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 1, ["max"] = 5},
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["absorbDamage"] = I}, true)
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["absorbDamage"] = I}, false)
        end
    },
    ["absorb_mid"] = {
        ["id"] = 28,
        ["name"] = "Bạch Hổ-G2",
        ["client_text"] = "BH\nG2",
        ["desc"] = b["absorb_small"],
        ["check_desc"] = "tất cả (giảm tối đa 80%)",
        ["can_add"] = true,
        ["only_one"] = false,
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 1, ["max"] = 15},
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["absorbDamage"] = I}, true)
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["absorbDamage"] = I}, false)
        end
    },
    ["absorb_big"] = {
        ["id"] = 25,
        ["name"] = "Bạch Hổ-G3",
        ["client_text"] = "BH\nG3",
        ["desc"] = b["absorb_small"],
        ["check_desc"] = "tất cả (giảm tối đa 80%)",
        ["can_add"] = true,
        ["only_one"] = false,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 1, ["max"] = 25},
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["absorbDamage"] = I}, true)
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["absorbDamage"] = I}, false)
        end
    },
    ["absorb_special"] = {
        ["id"] = 26,
        ["name"] = "☆Bạch Hổ-G4",
        ["client_text"] = "BH\nG4",
        ["desc"] = b["absorb_small"],
        ["check_desc"] = "tất cả (giảm tối đa 80%)",
        ["can_add"] = false,
        ["only_one"] = false,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 1, ["max"] = 35},
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["absorbDamage"] = I}, true)
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["absorbDamage"] = I}, false)
        end
    },
    ["reduce_damage_small"] = {
        ["id"] = 23,
        ["name"] = "Bạch Hổ I",
        ["desc"] = b["reduce_damage"],
        ["can_add"] = true,
        ["only_one"] = true,
        ["client_text"] = "BH\nI",
        ["star_rating"] = 4,
        ["value_range"] = {["min"] = 1, ["max"] = 5},
        ["check_equip_can_add"] = function(s)
            if
                s["components"]["tbc_equipment"]:HasEffectByName "special_sgsy" or
                    s["components"]["tbc_equipment"]:HasEffectByName "reduce_damage_mid" or
                    s["components"]["tbc_equipment"]:HasEffectByName "reduce_damage_big"
             then
                return false, "chỉ được ép tối đa 1 viên Bạch Hổ"
            end
            if a:HasComponents(s, "armor") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào giáp"
        end,
        ["check_desc"] = "giáp",
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("reduceAttackedDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("reduceAttackedDamage", I)
        end
    },
    ["reduce_damage_mid"] = {
        ["id"] = 24,
        ["name"] = "Bạch Hổ II",
        ["client_text"] = "BH\nII",
        ["desc"] = b["reduce_damage"],
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 5, ["max"] = 15},
        ["check_equip_can_add"] = function(s)
            if
                s["components"]["tbc_equipment"]:HasEffectByName "reduce_damage_small" or
                    s["components"]["tbc_equipment"]:HasEffectByName "special_sgsy" or
                    s["components"]["tbc_equipment"]:HasEffectByName "reduce_damage_big"
             then
                return false, "chỉ được ép tối đa 1 viên Bạch Hổ"
            end
            if a:HasComponents(s, "armor") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào giáp"
        end,
        ["check_desc"] = "giáp",
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("reduceAttackedDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("reduceAttackedDamage", I)
        end
    },
    ["reduce_damage_big"] = {
        ["id"] = 21,
        ["name"] = "☆Bạch Hổ III",
        ["client_text"] = "BH\nIII",
        ["desc"] = b["reduce_damage"],
        ["can_add"] = false,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 10, ["max"] = 25},
        ["check_equip_can_add"] = function(s)
            if
                s["components"]["tbc_equipment"]:HasEffectByName "reduce_damage_small" or
                    s["components"]["tbc_equipment"]:HasEffectByName "reduce_damage_mid" or
                    s["components"]["tbc_equipment"]:HasEffectByName "special_sgsy"
             then
                return false, "chỉ được ép tối đa 1 viên Bạch Hổ"
            end
            if a:HasComponents(s, "armor") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào giáp"
        end,
        ["check_desc"] = "giáp",
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("reduceAttackedDamage", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("reduceAttackedDamage", I)
        end
    },
    ["special_sgsy"] = {
        ["id"] = 22,
        ["name"] = "★Bạch Hổ IV",
        ["client_text"] = "BH\nIV",
        ["desc"] = b["special_sgsy"],
        ["check_equip_can_add"] = function(s)
            if
                s["components"]["tbc_equipment"]:HasEffectByName "reduce_damage_small" or
                    s["components"]["tbc_equipment"]:HasEffectByName "reduce_damage_mid" or
                    s["components"]["tbc_equipment"]:HasEffectByName "reduce_damage_big"
             then
                return false, "chỉ được ép tối đa 1 viên Bạch Hổ"
            end
            if a:HasComponents(s, "armor") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào giáp"
        end,
        ["check_desc"] = "giáp",
        ["can_add"] = false,
        ["only_one"] = true,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["only_compound"] = true,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 1, ["max"] = 1000},
        ["on_equip_fn"] = function(s, M, I)
            d(
                M,
                {["absorbDamage"] = 45, ["reduceAttackedDamage"] = 35, ["immuneBramble"] = 1, ["immuneSuppressNum"] = 1},
                true
            )
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(
                M,
                {["absorbDamage"] = 45, ["reduceAttackedDamage"] = 35, ["immuneBramble"] = 1, ["immuneSuppressNum"] = 1},
                false
            )
        end
    },
    ["add_immune_cold"] = {
        ["id"] = 20,
        ["name"] = "Huyền Vũ-Lạnh",
        ["client_text"] = "HV\nLạnh",
        ["desc"] = b["add_immune_cold"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneCold", 1)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneCold", 1)
        end
    },
    ["add_immune_hot"] = {
        ["id"] = 19,
        ["name"] = "Huyền Vũ-Nóng",
        ["client_text"] = "HV\nNóng",
        ["desc"] = b["add_immune_hot"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneHot", 1)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneHot", 1)
        end
    },
    ["add_immune_poison"] = {
        ["id"] = 18,
        ["name"] = "Huyền Vũ-Độc",
        ["client_text"] = "HV\nĐộc",
        ["desc"] = b["add_immune_poison"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immunePoison", 1)
            end
            if a:HasComponents(M, "hh_buff") then
                M["components"]["hh_buff"]:RemoveBuff "poison"
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immunePoison", 1)
            end
        end
    },
    ["add_immune_freeze"] = {
        ["id"] = 17,
        ["name"] = "Huyền Vũ-Băng",
        ["client_text"] = "HV\nBăng",
        ["desc"] = b["add_immune_freeze"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneFreeze", 1)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneFreeze", 1)
            end
        end
    },
    ["immunity_moisture"] = {
        ["id"] = 16,
        ["name"] = "Huyền Vũ-Ướt",
        ["client_text"] = "HV\nƯớt",
        ["desc"] = b["immunity_moisture"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immunityMoisture", 1)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immunityMoisture", 1)
            end
        end
    },
    ["immunity_reduce_speed"] = {
        ["id"] = 15,
        ["name"] = "Huyền Vũ-Chậm",
        ["client_text"] = "HV\nChậm",
        ["desc"] = b["porter"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 6,
        ["value_range"] = {["min"] = 10, ["max"] = 80},
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["porter"] = 1, ["immuneReduceSpeed"] = 1}, true)
            if a:HasComponents(M, "hh_buff") then
                M["components"]["hh_buff"]:RemoveBuff "reduce_speed"
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["porter"] = 1, ["immuneReduceSpeed"] = 1}, false)
        end
    },
    ["immune_sleep"] = {
        ["id"] = 13,
        ["name"] = "Huyền Vũ-Ngủ",
        ["client_text"] = "HV\nNgủ",
        ["desc"] = b["immune_sleep"],
        ["can_add"] = true,
        ["only_one"] = true,
        ["check_desc"] = "tất cả",
        ["star_rating"] = 6,
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["immunitySleep"] = 1}, true)
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["immunitySleep"] = 1}, false)
        end
    },
    ["immune_bramble"] = {
        ["id"] = 14,
        ["name"] = "Huyền Vũ-PĐ",
        ["client_text"] = "HV\nPĐ",
        ["desc"] = b["immune_bramble"],
        ["check_desc"] = "tất cả",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneBramble", 1)
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneBramble", 1)
            end
        end
    },
    ["immune_suppress"] = {
        ["id"] = 11,
        ["name"] = "Huyền Vũ-TĐ",
        ["client_text"] = "HV\nTĐ",
        ["desc"] = b["immune_suppress"],
        ["can_add"] = true,
        ["only_one"] = true,
        ["check_desc"] = "tất cả",
        ["star_rating"] = 8,
        ["on_equip_fn"] = function(s, M, I)
            d(M, {["immuneSuppressNum"] = 1}, true)
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(M, {["immuneSuppressNum"] = 1}, false)
        end
    },
    ["immune_debuff"] = {
        ["id"] = 12,
        ["name"] = "☆Huyền Vũ-TT",
        ["client_text"] = "HV\nTT",
        ["desc"] = b["immune_debuff"],
        ["check_desc"] = "tất cả",
        ["can_add"] = false,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immunityMoisture", 1)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneCold", 1)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneHot", 1)
            end
            if a:HasComponents(M, "hh_buff") then
                M["components"]["hh_buff"]:RemoveBuff "add_cold"
                M["components"]["hh_buff"]:RemoveBuff "add_hot"
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immunityMoisture", 1)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneCold", 1)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneHot", 1)
            end
        end
    },
    ["immune_debuff_2"] = {
        ["id"] = 9,
        ["name"] = "☆Huyền Vũ-KC",
        ["client_text"] = "HV\nKC",
        ["desc"] = b["immune_debuff_2"],
        ["check_desc"] = "tất cả",
        ["can_add"] = false,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["on_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneFreeze", 1)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immunePoison", 1)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immuneReduceSpeed", 1)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("porter", 1)
                M["components"]["tbc_player_effects"]:AddEffectValueByKey("immunitySleep", 1)
            end
            if a:HasComponents(M, "hh_buff") then
                M["components"]["hh_buff"]:RemoveBuff "poison"
                M["components"]["hh_buff"]:RemoveBuff "reduce_speed"
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            if a:HasComponents(M, "tbc_player_effects") then
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneFreeze", 1)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immunePoison", 1)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immuneReduceSpeed", 1)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("porter", 1)
                M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("immunitySleep", 1)
            end
        end
    },
    ["special_zqrf"] = {
        ["id"] = 10,
        ["name"] = "★Huyền Vũ-BX",
        ["client_text"] = "HV\nBX",
        ["desc"] = b["special_zqrf"],
        ["check_desc"] = "tất cả",
        ["can_add"] = false,
        ["only_one"] = true,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["only_compound"] = true,
        ["star_rating"] = 10,
        ["on_equip_fn"] = function(s, M, I)
            d(
                M,
                {
                    ["immunitySleep"] = 1,
                    ["immuneReduceSpeed"] = 1,
                    ["porter"] = 1,
                    ["immuneFreeze"] = 1,
                    ["immunePoison"] = 1,
                    ["immuneCold"] = 1,
                    ["immuneHot"] = 1,
                    ["immunityMoisture"] = 1
                },
                true
            )
            if a:HasComponents(M, "hh_buff") then
                M["components"]["hh_buff"]:RemoveBuff "poison"
                M["components"]["hh_buff"]:RemoveBuff "reduce_speed"
                M["components"]["hh_buff"]:RemoveBuff "add_cold"
                M["components"]["hh_buff"]:RemoveBuff "add_hot"
            end
        end,
        ["un_equip_fn"] = function(s, M, I)
            d(
                M,
                {
                    ["immuneReduceSpeed"] = 1,
                    ["porter"] = 1,
                    ["immuneFreeze"] = 1,
                    ["immunePoison"] = 1,
                    ["immuneCold"] = 1,
                    ["immuneHot"] = 1,
                    ["immunityMoisture"] = 1,
                    ["immunitySleep"] = 1
                },
                false
            )
        end
    },
    ["health_suppress_num"] = {
        ["id"] = 3,
        ["name"] = "Chu Tước-TĐ",
        ["only_one"] = true,
        ["client_text"] = "CT\nTĐ",
        ["desc"] = b["health_suppress_num"],
        ["check_desc"] = "vũ khí",
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 5,
        ["value_range"] = {["min"] = 10, ["max"] = 50},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addSuppressAddHealth", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addSuppressAddHealth", I)
        end
    },
    ["atk_add_san"] = {
        ["id"] = 4,
        ["name"] = "Chu Tước-HN",
        ["client_text"] = "CT\nHN",
        ["desc"] = b["atk_add_san"],
        ["check_desc"] = "vũ khí" .. c,
        ["can_add"] = true,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 1, ["max"] = 3},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("restoreSpirit", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("restoreSpirit", I)
        end
    },
    ["atk_blood_suck"] = {
        ["id"] = 1,
        ["name"] = "☆Chu Tước-HM",
        ["client_text"] = "CT\nHM",
        ["desc"] = b["atk_blood_suck"],
        ["check_desc"] = "vũ khí" .. c,
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["can_add"] = false,
        ["only_one"] = true,
        ["star_rating"] = 8,
        ["value_range"] = {["min"] = 1, ["max"] = 3},
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("bloodSuck", I)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("bloodSuck", I)
        end
    },
    ["special_xwsh"] = {
        ["id"] = 2,
        ["name"] = "★Chu Tước-TM",
        ["client_text"] = "CT\nTM",
        ["desc"] = b["special_xwsh"],
        ["check_desc"] = "vũ khí" .. c,
        ["can_add"] = false,
        ["only_one"] = true,
        ["client_color"] = {255 / 255, 0 / 255, 0 / 255, 1},
        ["only_compound"] = true,
        ["star_rating"] = 10,
        ["value_range"] = {["min"] = 2, ["max"] = 5},
        ["check_equip_can_add"] = function(s)
            if a:HasComponents(s, "weapon") then
                return true, "đáp ứng các điều kiện"
            end
            return false, "chỉ ép vào vũ khí"
        end,
        ["on_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("bloodSuck", I)
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("restoreSpirit", I)
            M["components"]["tbc_player_effects"]:AddEffectValueByKey("addSuppressAddHealth", 100)
        end,
        ["un_equip_fn"] = function(s, M, I)
            if not a:HasComponents(M, "tbc_player_effects") then
                return
            end
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("bloodSuck", I)
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("restoreSpirit", I)
            M["components"]["tbc_player_effects"]:ReduceEffectValueByKey("addSuppressAddHealth", 100)
        end
    }
}
local function ai(aj)
    if a:IsHHType(aj, "number") then
        return aj
    end
    return 0
end
local function ak(M, al, am, an, ao, ap, aq)
    if not M or not a:IsHHType(al, "string") or not a:IsHHType(am, "string") then
        return
    end
    a:HHRemoveFx(M, al)
    M[al] = SpawnPrefab(am)
    if M[al] then
        if a:IsHHType(an, "string") and M[al]["AnimState"] then
            M[al]["AnimState"]:PlayAnimation(an, true)
        end
        M[al]["entity"]:AddFollower()
        M[al]["entity"]:SetParent(M["entity"])
        local ar = ai(ao)
        local as = ai(ap)
        local at = ai(aq)
        M[al]["Follower"]:FollowSymbol(M["GUID"], "swap_body", ar, as, at)
    end
end
local function au(e)
    if not e or not e["sg"] or e:HasTag "playerghost" then
        return
    end
    local av = e["sg"]:HasStateTag "moving"
    local aw = e["sg"]:HasStateTag "running"
    if (av or aw) and e["Transform"] then
        local ax = SpawnPrefab "hh_footprint_fz_fx"
        if ax and ax["Transform"] then
            local ay, az, aA = e["Transform"]:GetWorldPosition()
            local aB = e["Transform"]:GetRotation()
            local aC, aD = 0, 0
            local aE = 0.3
            if not e["hh_foot_to_change"] then
                e["hh_foot_to_change"] = true
            else
                aE = -0.3
                e["hh_foot_to_change"] = false
            end
            aC = ay + aE * math["cos"]((-aB + 90) * DEGREES)
            aD = aA + aE * math["sin"]((-aB + 90) * DEGREES)
            ax["Transform"]:SetPosition(aC, 0, aD)
            ax["Transform"]:SetRotation(aB)
        end
    end
end
local ELEMENTBEAD_GOGGLES_SOURCE_TAG = "hh_elementbead_goggles_source"
local function aG(e, f)
    if not a:HasComponents(e, "tbc_player_effects") or not a:IsHHType(f, "table") then
        return false
    end
    local aH = false
    for h, i in ipairs(f) do
        if not e["components"]["tbc_player_effects"]:HasSpecialEffect(i) then
            aH = true
            break
        end
    end
    if aH then
        return false
    end
    return true
end
local function aI(e, aJ)
    if a:HasComponents(e, "hh_buff") then
        return e["components"]["hh_buff"]:HasBuff(aJ)
    end
    return false
end
local function aK(M, aL)
    if
        not a:NotIsDead(M) or not a:HasComponents(M, "hh_buff") or aI(M, "suit_basalt_cd") or not aL or
            not a:IsHHType(aL["damageresolved"], "number") or
            aL["damageresolved"] <= 0
     then
        return
    end
    M["components"]["health"]:DoDelta(10)
    a:HandleSuitBuff(M, "suit_basalt")
    a:HandleSuitBuff(M, "suit_basalt_cd", 20, true)
end
local function aM(M, aL)
    if not a:NotIsDead(M) then
        return
    end
    if aI(M, "suit_yhby_cd") then
        return
    end
    local ay, az, aA = M["Transform"]:GetWorldPosition()
    local aN = TheSim:FindEntities(ay, az, aA, 10, {"player"})
    if aN then
        for h, i in ipairs(aN) do
            if a:NotIsDead(i) and a:HasComponents(i, "tbc_player_effects") and a:HasComponents(i, "hh_buff") then
                if not aI(M, "suit_yhby_cd") then
                    a:HandleSuitBuff(i, "add_health", 10, true)
                end
            end
        end
    end
    a:SpawnClientStrFx(M, "Eternal blessing trigger")
    a:HandleSuitBuff(M, "suit_yhby_cd", 20, true)
end
local aO = {
    ["suit_yhby"] = {
        ["check_fn"] = aG,
        ["effect_list"] = {"z_suit_yhby_hand", "z_suit_yhby_body", "z_suit_yhby_hat"},
        ["start_fn"] = function(e, R)
            d(
                e,
                {
                    ["immuneSuppressNum"] = 1,
                    ["immunityMoisture"] = 1,
                    ["immunePoison"] = 1,
                    ["reduceAttackedDamage"] = 10
                },
                true
            )
            a:HandleSuitBuff(e, "player_healthSuppressNum")
            a:HandleSuitBuff(e, "poison")
            a:HandleSuitBuff(e, "suit_yhby", nil, true)
            e:ListenForEvent("attacked", aM)
        end,
        ["stop_fn"] = function(e, R)
            d(
                e,
                {
                    ["immuneSuppressNum"] = 1,
                    ["immunityMoisture"] = 1,
                    ["immunePoison"] = 1,
                    ["reduceAttackedDamage"] = 10
                },
                false
            )
            a:HandleSuitBuff(e, "suit_yhby")
            e:RemoveEventCallback("attacked", aM)
        end
    },
    ["suit_bhtg"] = {
        ["check_fn"] = aG,
        ["effect_list"] = {"z_suit_bhtg_hand", "z_suit_bhtg_body", "z_suit_bhtg_hat"},
        ["start_fn"] = function(e, R)
            d(
                e,
                {
                    ["targetPercentDamage"] = 2,
                    ["restoreSpirit"] = 3,
                    ["addComDamage"] = 50,
                    ["addComDamagePercent"] = 10,
                    ["addSuppressAddHealth"] = 100
                },
                true
            )
        end,
        ["stop_fn"] = function(e, R)
            d(
                e,
                {
                    ["targetPercentDamage"] = 2,
                    ["restoreSpirit"] = 3,
                    ["addComDamage"] = 50,
                    ["addComDamagePercent"] = 10,
                    ["addSuppressAddHealth"] = 100
                },
                false
            )
        end
    },
    ["suit_zqrf"] = {
        ["check_fn"] = aG,
        ["effect_list"] = {"z_suit_zqrf_hand", "z_suit_zqrf_body", "z_suit_zqrf_hat"},
        ["start_fn"] = function(e, R)
            d(
                e,
                {["trueDamageNum"] = 50, ["bloodSuck"] = 3, ["immuneSuppressNum"] = 1, ["immuneReduceSpeed"] = 1},
                true
            )
        end,
        ["stop_fn"] = function(e, R)
            d(
                e,
                {["trueDamageNum"] = 50, ["bloodSuck"] = 3, ["immuneSuppressNum"] = 1, ["immuneReduceSpeed"] = 1},
                false
            )
        end
    }
}
local aP, aQ = "images/dyc_gem_enc.xml", "dyc_gem_enc.tex"
local aR = "images/inventoryimages.xml"
local aS = {
    {
        ["id"] = "z_suit_yhby_hand",
        ["recipe"] = {
            {["id"] = "hh_essence", ["num"] = 10, ["xml"] = aP, ["tex"] = "dyc_gem_enc.tex"},
            {["id"] = "rocks", ["num"] = 20, ["xml"] = aR, ["tex"] = "rocks.tex"},
            {["id"] = "blue_cap", ["num"] = 10, ["xml"] = aR, ["tex"] = "blue_cap.tex"},
            {["id"] = "beefalowool", ["num"] = 5, ["xml"] = aR, ["tex"] = "beefalowool.tex"}
        }
    },
    {
        ["id"] = "z_suit_yhby_body",
        ["recipe"] = {
            {["id"] = "hh_essence", ["num"] = 10, ["xml"] = aP, ["tex"] = "dyc_gem_enc.tex"},
            {["id"] = "rocks", ["num"] = 20, ["xml"] = aR, ["tex"] = "rocks.tex"},
            {["id"] = "bandage", ["num"] = 3, ["xml"] = aR, ["tex"] = "bandage.tex"},
            {["id"] = "red_cap", ["num"] = 10, ["xml"] = aR, ["tex"] = "red_cap.tex"}
        }
    },
    {
        ["id"] = "z_suit_yhby_hat",
        ["recipe"] = {
            {["id"] = "hh_essence", ["num"] = 10, ["xml"] = aP, ["tex"] = "dyc_gem_enc.tex"},
            {["id"] = "rocks", ["num"] = 20, ["xml"] = aR, ["tex"] = "rocks.tex"},
            {["id"] = "jellybean", ["num"] = 3, ["xml"] = aR, ["tex"] = "jellybean.tex"},
            {["id"] = "green_cap", ["num"] = 10, ["xml"] = aR, ["tex"] = "green_cap.tex"}
        }
    },
    {
        ["id"] = "z_suit_bhtg_hand",
        ["recipe"] = {
            {["id"] = "hh_essence", ["num"] = 10, ["xml"] = aP, ["tex"] = "dyc_gem_enc.tex"},
            {["id"] = "coontail", ["num"] = 10, ["xml"] = aR, ["tex"] = "coontail.tex"},
            {["id"] = "thulecite", ["num"] = 5, ["xml"] = aR, ["tex"] = "thulecite.tex"},
            {["id"] = "goldnugget", ["num"] = 20, ["xml"] = aR, ["tex"] = "goldnugget.tex"}
        }
    },
    {
        ["id"] = "z_suit_bhtg_body",
        ["recipe"] = {
            {["id"] = "hh_essence", ["num"] = 10, ["xml"] = aP, ["tex"] = "dyc_gem_enc.tex"},
            {["id"] = "horn", ["num"] = 1, ["xml"] = aR, ["tex"] = "horn.tex"},
            {["id"] = "steelwool", ["num"] = 5, ["xml"] = aR, ["tex"] = "steelwool.tex"},
            {["id"] = "stinger", ["num"] = 40, ["xml"] = aR, ["tex"] = "stinger.tex"}
        }
    },
    {
        ["id"] = "z_suit_bhtg_hat",
        ["recipe"] = {
            {["id"] = "hh_essence", ["num"] = 10, ["xml"] = aP, ["tex"] = "dyc_gem_enc.tex"},
            {["id"] = "pigskin", ["num"] = 10, ["xml"] = aR, ["tex"] = "pigskin.tex"},
            {["id"] = "tentaclespots", ["num"] = 10, ["xml"] = aR, ["tex"] = "tentaclespots.tex"},
            {["id"] = "slurper_pelt", ["num"] = 10, ["xml"] = aR, ["tex"] = "slurper_pelt.tex"}
        }
    },
    {
        ["id"] = "z_suit_zqrf_hand",
        ["recipe"] = {
            {["id"] = "hh_essence", ["num"] = 10, ["xml"] = aP, ["tex"] = "dyc_gem_enc.tex"},
            {["id"] = "feather_canary", ["num"] = 10, ["xml"] = aR, ["tex"] = "feather_canary.tex"},
            {["id"] = "thulecite", ["num"] = 5, ["xml"] = aR, ["tex"] = "thulecite.tex"},
            {["id"] = "goldnugget", ["num"] = 20, ["xml"] = aR, ["tex"] = "goldnugget.tex"}
        }
    },
    {
        ["id"] = "z_suit_zqrf_body",
        ["recipe"] = {
            {["id"] = "hh_essence", ["num"] = 10, ["xml"] = aP, ["tex"] = "dyc_gem_enc.tex"},
            {["id"] = "feather_crow", ["num"] = 10, ["xml"] = aR, ["tex"] = "feather_crow.tex"},
            {["id"] = "steelwool", ["num"] = 5, ["xml"] = aR, ["tex"] = "steelwool.tex"},
            {["id"] = "beefalowool", ["num"] = 20, ["xml"] = aR, ["tex"] = "beefalowool.tex"}
        }
    },
    {
        ["id"] = "z_suit_zqrf_hat",
        ["recipe"] = {
            {["id"] = "hh_essence", ["num"] = 10, ["xml"] = aP, ["tex"] = "dyc_gem_enc.tex"},
            {["id"] = "feather_robin", ["num"] = 10, ["xml"] = aR, ["tex"] = "feather_robin.tex"},
            {["id"] = "feather_robin_winter", ["num"] = 10, ["xml"] = aR, ["tex"] = "feather_robin_winter.tex"},
            {["id"] = "silk", ["num"] = 40, ["xml"] = aR, ["tex"] = "silk.tex"}
        }
    }
}
return {["Affixes"] = af, ["Suits"] = aO, ["SuitRecipes"] = aS}
