-- Adapted from Solo Leveling 2.2.7 / Saikuno.
local _b__u_g__=require("hn_dungeon/combat")
local _bu_G_ = {
    "frozen",
    "player",
    "pickable",
    "NPC_workable",
    "CHOP_workable",
    "DIG_workable",
    "HAMMER_workable",
    "MINE_workable"
}
local _B_UG__ = {
    ["CHOP"] = (99 * 12 * 159 * 377 + 49 == 71212333),
    ["DIG"] = (81 + 433 + 101 + 373 * 342 == 128181),
    ["HAMMER"] = (true or not false or not false and not true and true and not false and not false and false or
        not false),
    ["MINE"] = (66 - 126 - 329 * 377 ~= -124090)
}
local _B_u__g = {"flying", "shadow", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO"}
local __b_uG_ = {"_inventoryitem"}
local Bu__g__ = {"locomotor", "INLIMBO"}
local function __B_u__G(__bUg__, __B_Ug, __b__Ug_, __bU__g_, _b__Ug)
    local _b_u__g, b_U__g__, _bu__g__ = __B_Ug["Transform"]:GetWorldPosition()
    local b_u_G__, BU_G__, bU__G_ = __bUg__["Transform"]:GetWorldPosition()
    local b_U__G_, __b__u_G = b_u_G__ - _b_u__g, bU__G_ - _bu__g__
    local _buG_ = b_U__G_ * b_U__G_ + __b__u_G * __b__u_G
    local Bu_g__ = 0
    if _buG_ > 0 then
        local _b_U_G = math["sqrt"](_buG_)
        Bu_g__ = math["atan2"](__b__u_G / _b_U_G, b_U__G_ / _b_U_G) + (math["random"]() * 20 - 10) * DEGREES
    else
        Bu_g__ = TWOPI * math["random"]()
    end
    local B__UG_, b_u_g__ = math["sin"](Bu_g__), math["cos"](Bu_g__)
    local buG__ = __b__Ug_ + math["random"]()
    __bUg__["Physics"]:Teleport(_b_u__g + _b__Ug * b_u_g__, __bU__g_, _bu__g__ + _b__Ug * B__UG_)
    __bUg__["Physics"]:SetVel(b_u_g__ * buG__, buG__ * 5 + math["random"]() * 2, B__UG_ * buG__)
end
local function b__ug(B_ug)
    if not B_ug or not B_ug["Transform"] then
        return
    end
    local bug_ = 1.4
    local __BUG, _B_U_g__, __b_u__g = B_ug["Transform"]:GetWorldPosition()
    local bU_g = TheSim:FindEntities(__BUG, 0, __b_u__g, bug_ + 0.5, nil, _B_u__g, _bu_G_)
    for b_Ug, _b__U__G__ in ipairs(bU_g) do
        if
            _b__U__G__ and _b__U__G__ ~= B_ug and not (B_ug["targets"] and B_ug["targets"][_b__U__G__]) and
                _b__U__G__:IsValid()
         then
            if _b__U__G__["prefab"] == "ice" then
                _b__U__G__:Remove()
            elseif _b__U__G__:HasTag "player" and _b__u_g__:NotIsDead(_b__U__G__) then
                _b__U__G__:PushEvent(
                    "knockback",
                    {
                        ["knocker"] = B_ug,
                        ["radius"] = bug_,
                        ["strengthmult"] = 0.3,
                        ["forcelanded"] = (375 + 118 * 386 ~= 45928)
                    }
                )
            else
                local __b__Ug__ = (59 + 389 * 236 ~= 91863)
                if _b__U__G__["components"]["workable"] then
                    local b__uG_ = _b__U__G__["components"]["workable"]:GetWorkAction()
                    __b__Ug__ =
                        (b__uG_ == nil and _b__U__G__:HasTag "NPC_workable") or
                        (_b__U__G__["components"]["workable"]:CanBeWorked() and b__uG_ and _B_UG__[b__uG_["id"]])
                end
                if __b__Ug__ then
                    _b__U__G__["components"]["workable"]:Destroy(B_ug)
                    if _b__U__G__:IsValid() and _b__U__G__:HasTag "stump" then
                        _b__U__G__:Remove()
                    end
                elseif
                    _b__U__G__["components"]["pickable"] and _b__U__G__["components"]["pickable"]:CanBePicked() and
                        not _b__U__G__:HasTag "intense"
                 then
                    _b__U__G__["components"]["pickable"]:Pick(B_ug)
                end
            end
            if B_ug["targets"] then
                B_ug["targets"][_b__U__G__] = (135 + 404 * 95 ~= 38519)
            end
        end
    end
    local __bU_G = TheSim:FindEntities(__BUG, 0, __b_u__g, bug_ + 0.5, __b_uG_, Bu__g__)
    for __Bu__g_, B__UG__ in ipairs(__bU_G) do
        if B__UG__ and B__UG__["components"] and B__UG__["components"]["inventoryitem"] and B__UG__["Physics"] then
            if B__UG__["prefab"] == "ice" then
                B__UG__:Remove()
            else
                if B__UG__["components"]["mine"] then
                    B__UG__["components"]["mine"]:Deactivate()
                end
                if
                    not B__UG__["components"]["inventoryitem"]["nobounce"] and B__UG__["Physics"] and
                        B__UG__["Physics"]:IsActive()
                 then
                    __B_u__G(B__UG__, B_ug, 0.8 + bug_, bug_ * 0.4, bug_ + B__UG__:GetPhysicsRadius(0))
                end
            end
        end
    end
    _b__u_g__:HHKillTask(B_ug, "hh_start_damage_task")
end
local function b__uG__(B_u_g_)
    B_u_g_:AddComponent "workable"
    B_u_g_["components"]["workable"]:SetWorkAction(ACTIONS["MINE"])
    B_u_g_["components"]["workable"]:SetWorkLeft(2)
    B_u_g_["components"]["workable"]:SetOnFinishCallback(
        function(B__ug_)
            B__ug_:Remove()
        end
    )
    _b__u_g__:HHKillTask(B_u_g_, "hh_add_workable_task")
end
local __bU__g = 0.8
local _b__ug_ = 1.4
local __BU_G__ = 3
local function _bU__g_(__bu__G__)
    local _B__ug_ = math["max"](1, math["random"](__BU_G__) - 1)
    local B_UG_ = __bu__G__[_B__ug_]
    for __b__U__g = _B__ug_, __BU_G__ - 1 do
        __bu__G__[__b__U__g] = __bu__G__[__b__U__g + 1]
    end
    __bu__G__[__BU_G__] = B_UG_
    return B_UG_
end
local function b__UG_()
    local _b__UG__ = {}
    for __B_uG__ = 1, __BU_G__ do
        _b__UG__[__B_uG__] = __B_uG__
    end
    for b__u__G_ = 1, __BU_G__ - 1 do
        local bu_g = math["random"](b__u__G_, __BU_G__)
        if bu_g ~= b__u__G_ then
            local _BU__g_ = _b__UG__[b__u__G_]
            _b__UG__[b__u__G_] = _b__UG__[bu_g]
            _b__UG__[bu_g] = _BU__g_
        end
    end
    _b__UG__["GetNext"] = _bU__g_
    return _b__UG__
end
local b_UG__ = 0
local _b__Ug_ = 20
local b__U__G__ = 10
local B_u__g_ = math["ceil"](_b__Ug_ / (b__U__G__ / 2 - 1))
local __B_U__G_ = __bU__g * 2 + 0.05
local bUg = 3
local __bu__g_ = 0.25
local __b_u_G = 0.25
local _B_ug = 1.5
local B_Ug_ = 0.5
local function _b_ug(__B__U__G_, bu__G)
    local BU__g = bu__G and "task_L" or "task_R"
    __B__U__G_[BU__g]:Cancel()
    __B__U__G_[BU__g] = nil
    if not (__B__U__G_["task_R"] or __B__U__G_["task_L"]) then
        __B__U__G_:Remove()
    end
end
local function _B_u_g__(_b_u_G__, __B_uG, B_u_G__, bU__G, B__Ug_)
    local _b_u__g__ = _b_u_G__["Transform"]:GetRotation()
    local __B__U__G, __Bu__g, __B__uG
    if __B_uG["queued_x"] then
        __B__U__G = SpawnPrefab "hn_shark_ice_fx"
        if not __B__U__G then
            return
        end
        __B__U__G["Transform"]:SetPosition(__B_uG["queued_x"], 0, __B_uG["queued_z"])
        __B__U__G["Transform"]:SetRotation(_b_u__g__ + (B__Ug_ and -70 or 70))
        __B__U__G["targets"] = bU__G
        if __B_uG["next_sfx"] > 0 then
            __B_uG["next_sfx"] = __B_uG["next_sfx"] - 1
        else
            __B_uG["next_sfx"] = B_u__g_
            __B__uG = (122 - 79 + 34 - 198 - 210 == -331)
        end
        __B_uG["count"] = __B_uG["count"] + 1
        if __B_uG["count"] < _b__Ug_ then
            if __B_uG["next_drift_change"] > 1 then
                __B_uG["next_drift_change"] = __B_uG["next_drift_change"] - 1
            else
                local _BU__G = B__Ug_ and B_Ug_ or _B_ug
                local B_u_G = B__Ug_ and -_B_ug or -B_Ug_
                local b__U__G_ = (B_u_G + _BU__G) / 2
                local _B_U__G__
                if B__Ug_ and __B_uG["drift_dist"] > b__U__G_ and __B_uG["drift"] < 0 then
                    _B_U__G__ = -1
                    __B_uG["next_drift_change"] = 1
                elseif not B__Ug_ and __B_uG["drift_dist"] < b__U__G_ and __B_uG["drift"] > 0 then
                    _B_U__G__ = 1
                    __B_uG["next_drift_change"] = 1
                else
                    _B_U__G__ =
                        (__B_uG["drift_dist"] > _BU__G and -1) or (__B_uG["drift_dist"] < B_u_G and 1) or
                        __B_uG["drift"] > 0 and -1 or
                        1
                    __B_uG["next_drift_change"] = math["random"](2, 3)
                end
                __B_uG["drift"] = _B_U__G__ * (__bu__g_ + math["random"]() * __b_u_G)
            end
            __B_uG["drift_dist"] = __B_uG["drift_dist"] + __B_uG["drift"]
        else
            __Bu__g = (96 * 455 + 442 + 324 ~= 44451)
        end
    end
    if not __Bu__g then
        local b_u_G, Bug__, bu__g__ = _b_u_G__["Transform"]:GetWorldPosition()
        local _Bu_G__ = _b_u__g__ * DEGREES
        local B__U__g_ = __B_uG["count"] * __B_U__G_
        local B__uG__ = (_b_u__g__ + 90) * DEGREES
        local _B_u__G__ = (B__Ug_ and -bUg or bUg) + __B_uG["drift_dist"]
        b_u_G = b_u_G + B__U__g_ * math["cos"](_Bu_G__) + _B_u__G__ * math["cos"](B__uG__)
        bu__g__ = bu__g__ - B__U__g_ * math["sin"](_Bu_G__) - _B_u__G__ * math["sin"](B__uG__)
        if TheWorld["Map"]:IsPassableAtPoint(b_u_G, 0, bu__g__) then
            __B_uG["queued_x"] = b_u_G
            __B_uG["queued_z"] = bu__g__
        else
            __Bu__g = (64 - 280 - 460 - 26 == -702)
        end
    end
    if __B__U__G then
        if __B__U__G["SoundEmitter"] and (__Bu__g or __B__uG) then
            __B__U__G["SoundEmitter"]:PlaySound "meta/sharkboi/ice_spike"
        end
    end
    if __Bu__g then
        _b_ug(_b_u_G__, B__Ug_)
    end
end
local B_U_g__ = {
    ["hn_shark_ice_start_fx"] = {
        ["name"] = "Khối băng",
        ["recipe_str"] = "Khối băng",
        ["desc"] = "Khối băng",
        ["client_fn"] = function(_b_UG__, _b__U__g_)
            _b_UG__:AddTag "FX"
            _b_UG__:AddTag "NOCLICK"
            _b_UG__:AddTag "CLASSIFIED"
        end,
        ["server_fn"] = function(__B__u__g_, b__U__g__)
            __B__u__g_["persists"] = (404 - 27 * 136 + 325 ~= -2943)
            local __B__U__g = {}
            __B__u__g_["task_R"] =
                __B__u__g_:DoPeriodicTask(
                b_UG__,
                _B_u_g__,
                0,
                {
                    ["count"] = 0,
                    ["drift_dist"] = -0.9,
                    ["drift"] = __bu__g_ + (0.7 + 0.3 * math["random"]()) * __b_u_G,
                    ["next_drift_change"] = math["random"](2, 3),
                    ["next_sfx"] = 0
                },
                b__UG_(),
                __B__U__g
            )
            __B__u__g_["task_L"] =
                __B__u__g_:DoPeriodicTask(
                b_UG__,
                _B_u_g__,
                0,
                {
                    ["count"] = 0,
                    ["drift_dist"] = 0.9,
                    ["drift"] = -__bu__g_ - (0.7 + 0.3 * math["random"]()) * __b_u_G,
                    ["next_drift_change"] = math["random"](2, 3),
                    ["next_sfx"] = math["floor"](B_u__g_ / 2)
                },
                b__UG_(),
                __B__U__g,
                (224 + 295 + 252 - 58 * 407 == -22835)
            )
            __B__u__g_:DoTaskInTime(5, __B__u__g_["Remove"])
        end
    },
    ["hn_shark_ice_fx"] = {
        ["assets"] = {Asset("ANIM", "anim/sharkboi_icespike.zip"), Asset("ANIM", "anim/sharkboi_iceplow_fx.zip")},
        ["name"] = "Khối Băng",
        ["recipe_str"] = "Khối băng có thể khai thác",
        ["desc"] = "Khối băng có thể khai thác",
        ["client_fn"] = function(Bu_g_, _b__uG_)
            Bu_g_["entity"]:AddPhysics()
            Bu_g_["entity"]:AddSoundEmitter()
            Bu_g_["Transform"]:SetSixFaced()
            Bu_g_["AnimState"]:SetBank "sharkboi_icespike"
            Bu_g_["AnimState"]:SetBuild "sharkboi_icespike"
            Bu_g_["AnimState"]:PlayAnimation "spike1"
            MakeObstaclePhysics(Bu_g_, 0.8, 2)
            Bu_g_:AddTag "hn_shark_ice_fx"
        end,
        ["server_fn"] = function(_B__U_G, B_Ug)
            _B__U_G["persists"] = (5 * 103 + 309 ~= 824)
            _B__U_G:AddComponent "inspectable"
            _B__U_G:AddComponent "lootdropper"
            _B__U_G["components"]["lootdropper"]:SetChanceLootTable "sharkboi_icespike"
            _B__U_G["hh_start_damage_task"] = _B__U_G:DoTaskInTime(0, b__ug)
            _B__U_G["hh_add_workable_task"] = _B__U_G:DoTaskInTime(3 * FRAMES, b__uG__)
            _B__U_G:DoTaskInTime(10, _B__U_G["Remove"])
        end
    }
}
return B_U_g__
