-- Native weapon callbacks from Tu Tien 18.1; no character initializers.
local function sly_invalidfreezabletarget(inst,freezable)
    return inst:IsValid()  and  (freezable or inst.components.freezable) and inst.components.combat and not (inst.components.health and inst.components.health:IsDead() )
end
local function sly_circular(pt,p,r,num,s)
    local items = {}
    for k= 1,num do
        local angle = k * 2 * PI / num
        local item = SpawnPrefab(p)
        if item then
            item.Transform:SetPosition(r*math.cos(angle)+pt.x, pt.y, r*math.sin(angle)+pt.z)
            table.insert(items,item)
            if s then
                item.Transform:SetScale(s, s, s)
            end
        end
    end 
    return items
end

local function sly_getmode(inst)
    local current = inst.components.xd_binglingqi and inst.components.xd_binglingqi.current or 0
    if current  > 75 then
        return 4
    elseif current > 50 then
        return 3
    elseif current > 25 then
        return 2
    end
    return 1
end

local sly_moderange = {
    [0] = 0,
    [1] = 0,
    [2] = 2,
    [3] = 3,
    [4] = 4,
}
local function sly_setrange(inst,mode)
    local rang = sly_moderange[mode] or 0
    inst.components.combat:SetRange(TUNING.DEFAULT_ATTACK_RANGE + rang)
end

local function mxrg_isyhlyle(inst)
    return inst.prefab == "xd_sudaji_yhly"
end

local function onuseljsgname_wukong(inst)
    if inst.xd_wukong_currentlj and inst.xd_wukong_currentlj:value() == 2 then
        return  "xd_tttb"
     end
     return "xd_ljattack"
end

local function ljattack_fn_jingwei(inst,weapon)
    SpawnAt("xd_bs_smoke",inst)
end

local function SpawnLuoshenBlinkFx(target)
    local x, y, z = target.Transform:GetWorldPosition()
    local back = SpawnPrefab("xd_luoshen_sand_puff_back")
    if back ~= nil then
        back.Transform:SetPosition(x, y - .1, z)
    end
    local front = SpawnPrefab("xd_luoshen_sand_puff_front")
    if front ~= nil then
        front.Transform:SetPosition(x, y, z)
    end
end

local function DoLuoshenBlink(inst, pos)
    if pos == nil or inst == nil or not inst:IsValid() then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    if not IsTeleportingPermittedFromPointToPoint(x, y, z, pos.x, pos.y, pos.z) then
        return
    end
    if not TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z) or TheWorld.Map:IsGroundTargetBlocked(pos) then
        return
    end

    SpawnLuoshenBlinkFx(inst)
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
    end

    inst:DoTaskInTime(.25, function(inst_)
        if not inst_:IsValid() then
            return
        end
        local plant = SpawnAt("xd_luoshenzhu", inst)
        if plant ~= nil and plant.OnSpawnedBy ~= nil then
            plant:OnSpawnedBy(inst)
        end

        local sx, sy, sz = inst_.Transform:GetWorldPosition()
        if IsTeleportingPermittedFromPointToPoint(sx, sy, sz, pos.x, pos.y, pos.z)
            and TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z)
            and not TheWorld.Map:IsGroundTargetBlocked(pos) then
            if inst_.Physics ~= nil then
                inst_.Physics:Teleport(pos.x, pos.y, pos.z)
            else
                inst_.Transform:SetPosition(pos.x, pos.y, pos.z)
            end
        end

        SpawnLuoshenBlinkFx(inst_)
        if inst_.SoundEmitter ~= nil then
            inst_.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
        end
    end)
end

local CHENPINGAN_SHENTONG_DURATION = 18
local CHENPINGAN_SHENTONG_INTERVAL = 0.1
local CHENPINGAN_SHENTONG_COUNT = math.floor(CHENPINGAN_SHENTONG_DURATION / CHENPINGAN_SHENTONG_INTERVAL + 0.5)
local CHENPINGAN_SHENTONG_BACK_DEPTH = 2
local CHENPINGAN_SHENTONG_WIDTH = 7
local CHENPINGAN_SHENTONG_MIN_HEIGHT = 0.5
local CHENPINGAN_SHENTONG_MAX_HEIGHT = 4
local CHENPINGAN_SHENTONG_SPEED = 22
local CHENPINGAN_SHENTONG_FLY_TIME = 2
local CHENPINGAN_SHENTONG_DAMAGE = 46

local function SpawnChenpinganShentongProjectile(inst)
    if inst == nil or not inst:IsValid() or IsEntityDeadOrGhost(inst, true) then
        return
    end

    local x, _, z = inst.Transform:GetWorldPosition()
    local rotation = inst.Transform:GetRotation()
    local theta = rotation * DEGREES
    local forward_x = math.cos(theta)
    local forward_z = -math.sin(theta)
    local side_x = -forward_z
    local side_z = forward_x
    local back = math.random() * CHENPINGAN_SHENTONG_BACK_DEPTH
    local side = (math.random() - 0.5) * CHENPINGAN_SHENTONG_WIDTH
    local height = GetRandomMinMax(CHENPINGAN_SHENTONG_MIN_HEIGHT, CHENPINGAN_SHENTONG_MAX_HEIGHT)

    local fx = SpawnPrefab("xd_chenpingan_shentong_projectile")
    if fx ~= nil then
        fx.Transform:SetPosition(
            x - forward_x * back + side_x * side,
            height,
            z - forward_z * back + side_z * side
        )
        fx:Setup(inst, rotation, CHENPINGAN_SHENTONG_SPEED, CHENPINGAN_SHENTONG_FLY_TIME, CHENPINGAN_SHENTONG_DAMAGE)
    end
end

local function StartChenpinganShentongProjectiles(inst)
    SpawnChenpinganShentongProjectile(inst)
    inst._xd_chenpingan_shentong_projectile_count = 1

    if inst._xd_chenpingan_shentong_projectile_task ~= nil then
        inst._xd_chenpingan_shentong_projectile_task:Cancel()
    end
    if inst._xd_chenpingan_shentong_sound_task ~= nil then
        inst._xd_chenpingan_shentong_sound_task:Cancel()
    end

    inst._xd_chenpingan_shentong_projectile_task = inst:DoPeriodicTask(CHENPINGAN_SHENTONG_INTERVAL, function(inst)
        if (inst._xd_chenpingan_shentong_projectile_count or 0) >= CHENPINGAN_SHENTONG_COUNT then
            if inst._xd_chenpingan_shentong_projectile_task ~= nil then
                inst._xd_chenpingan_shentong_projectile_task:Cancel()
                inst._xd_chenpingan_shentong_projectile_task = nil
            end
            return
        end

        inst._xd_chenpingan_shentong_projectile_count = (inst._xd_chenpingan_shentong_projectile_count or 0) + 1
        SpawnChenpinganShentongProjectile(inst)
    end, CHENPINGAN_SHENTONG_INTERVAL)

    inst._xd_chenpingan_shentong_sound_task = inst:DoPeriodicTask(0.5, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
    end, 0)

    inst:DoTaskInTime(CHENPINGAN_SHENTONG_DURATION, function()
        if inst._xd_chenpingan_shentong_projectile_task ~= nil then
            inst._xd_chenpingan_shentong_projectile_task:Cancel()
            inst._xd_chenpingan_shentong_projectile_task = nil
        end
        if inst._xd_chenpingan_shentong_sound_task ~= nil then
            inst._xd_chenpingan_shentong_sound_task:Cancel()
            inst._xd_chenpingan_shentong_sound_task = nil
        end
    end)
end


return {
    xd_longtaizi =  function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst.dolingjiskill = function(inst,weapon,pos,target)
            local mode = sly_getmode(inst)
            if mode == 1  then
                XD_TELE_PLAYER(inst,pos)
                sly_circular(pos,"crab_king_waterspout",1.5,6,1.3)
                local ents = XD_GetDamageTargets(pos.x,pos. y, pos.z,4)
                for i,v in pairs(ents) do
                    if v  and inst and inst:IsValid() and v:IsValid() and v ~= inst and XD_CanAttackTrget(inst,v) then
                        if v.components.moisture ~= nil then
                            v.components.moisture:DoDelta(20)
                        end
                        local damage = 400
                        damage = Xd_CalcDamage(inst,damage,v)
                        v.components.combat:GetAttacked(inst,damage)
                        inst:PushEvent("onareaattackother", { target = v})
                    end
                end
            elseif  mode == 2  then
                XD_TELE_PLAYER(inst,pos)
                local fx = SpawnAt("xd_sly_impact_circle_fx", pos,Vector3(0.67,0.67,0.67))
                local ents = XD_GetDamageTargets(pos.x,pos. y, pos.z,4)
                for i,v in pairs(ents) do
                    if v  and inst and inst:IsValid() and v:IsValid() and v ~= inst and XD_CanAttackTrget(inst,v) then
                        local damage = 400
                        damage = Xd_CalcDamage(inst,damage,v)
                        v.components.combat:GetAttacked(inst,damage)
                        inst:PushEvent("onareaattackother", { target = v})
                        if sly_invalidfreezabletarget(v) then
                            v.components.freezable:AddColdness(v.components.freezable:ResolveResistance(), 3)
                        end
                    end
                end
            elseif mode == 3 or mode == 4  then
                XD_TELE_PLAYER(inst,pos)
                local fx = SpawnAt("xd_sly_impact_circle_fx", pos)
                fx:SpawnFx(pos,inst)
                local ents = XD_GetDamageTargets(pos.x,pos. y, pos.z,7)
                for i,v in pairs(ents) do
                    if v  and inst and inst:IsValid() and v:IsValid() and v ~= inst and XD_CanAttackTrget(inst,v) then
                        local damage = 400
                        damage = Xd_CalcDamage(inst,damage,v)
                        v.components.combat:GetAttacked(inst,damage)
                        inst:PushEvent("onareaattackother", { target = v})
                        if sly_invalidfreezabletarget(v) then
                            v.components.freezable:AddColdness(v.components.freezable:ResolveResistance(), 3)
                        end
                    end
                end 
                if mode == 4 then
                    inst:AddXDHuDun_LTZ("_xd_hudun_ltz_one")
                end
            end
            if mode > 1 and inst.components.xd_binglingqi then
                inst.components.xd_binglingqi:DoDelta(-5)
            end
            inst.components.xd_skillcd:Start("灵技",12)
        end
        inst.doshentongskill = function(inst,weapon)
            if inst.lingqi_mode  then
                local mode = sly_getmode(inst)
                inst.lingqi_mode = mode
                inst.ltz_attack_count = 1
                sly_setrange(inst,inst.lingqi_mode)
                inst.components.xd_skillcd:Start("神通",30)
                inst:PushEvent("xd_done_shentong",{weapon = weapon})
                if inst.lingqi_mode_task then
                    inst.lingqi_mode_task:Cancel()
                end
                inst.lingqi_mode_task = inst:DoTaskInTime(13,function()
                    inst.lingqi_mode  = 0
                    local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    sly_setrange(inst,inst.lingqi_mode)
                    inst.lingqi_mode_task = nil
                end)
                if mode > 1 and inst.components.xd_binglingqi then
                    inst.components.xd_binglingqi:DoDelta(-11)
                end
                if mode == 3 or mode == 4 then
                    inst:AddXDHuDun_LTZ("_xd_hudun_ltz_three",3,16)
                end
            end
        end     
    end,
    xd_sudaji = function(inst)

        if not TheWorld.ismastersim then
            return inst
        end
        inst.dolingjiskill = function(inst,weapon,pos,target)
            if not pos then
                inst.sg:GoToState("idle")
                return
            end
            pos.y = 0
            local fx = SpawnAt("xd_sudaji_foxout",pos)
            local facing_angle = inst.Transform:GetRotation() * DEGREES
            fx:ForceFacePoint(pos.x + 1 * math.cos(facing_angle), pos.y, pos.z - 1 * math.sin(facing_angle))
            fx:Start()
            XD_TELE_PLAYER(inst,pos)
            inst:DoTaskInTime(0.25,function()
                inst.sg.statemem._ismxrg_hidded = false
                local fx = SpawnAt("xd_sudaji_mxrg_fire",pos)
                inst:Show()
                inst.DynamicShadow:Enable(true)
                inst.AnimState:SetMultColour(1, 1, 1, 1)
                fx:SetLevel(266.7,1,inst)
                inst.components.health:SetInvincible(false)
            end)
            inst.components.xd_skillcd:Start("灵技",12)
        end
        inst.doshentongskill = function(inst,weapon)
            if inst.components.health:GetPercentWithPenalty() < 0.15 then
                XD_SAY(inst,"Không đủ máu để thi triển.")
                return
            end
            local cost = math.min(inst.components.health.currenthealth-1,inst.components.health:GetMaxWithPenalty() * 0.15)
            inst.components.health:DoDelta(-cost)
            local per = inst.components.health:GetPercentWithPenalty()
            local lys,level = inst.components.inventory:FindItems(mxrg_isyhlyle),1
            local pos = inst:GetPosition()
            local theta = math.random() * 2 * PI
            local radius = 3.5
            local offset = FindWalkableOffset(pos, theta,radius,12, true)
            if offset == nil then
                offset = Vector3(0,0,0)
            end
            local hasly = false
            for i,v in ipairs(lys) do
                level = math.max(level,v.charged and 2 or 1)
                if v.components.finiteuses and v.components.finiteuses:GetPercent() >= 0.1 then
                    hasly = true
                end
            end
            if not hasly then
                per = 0.7 
            end
            if not (per >= 0.7 and level == 1) then
                for i,v in ipairs(lys) do
                    if v.components.finiteuses then
                        v.components.finiteuses:Use(v.components.finiteuses.total* 0.1)
                    end
                end
            end
            if per >= 0.7 then 
                if level == 2 then
                    inst:AddDebuff("xd_sudaji_mxrg_fire5","xd_sudaji_mxrg_fire5")
                else
                    inst:AddDebuff("xd_sudaji_mxrg_fire3","xd_sudaji_mxrg_fire3") 
                end
            elseif per >= 0.4 then 
                SpawnAt("xd_jgb_lightning",pos+offset)
                inst:DoTaskInTime(0.16,function()
                    if inst.components.xd_petleash_mxrg then
                        inst.components.xd_petleash_mxrg:SpawnShadow(pos+offset,level)
                    end
                end)
            else
                inst.components.xd_petleash_mxrg:SpawnShadow(pos+offset,level,"xd_zhouwang")
            end
            inst.components.xd_skillcd:Start("神通",180)
            inst:PushEvent("xd_done_shentong",{weapon = weapon})
        end  
    end,
    xd_wukong = function(inst)
        inst.onuseljsgname = onuseljsgname_wukong
        inst.onuseljsgname_clinet = onuseljsgname_wukong

        if not TheWorld.ismastersim then
            return inst
        end
        inst.dolingjiskill = function(inst,weapon,pos,target)
            if pos and inst then
                local fx = SpawnAt("xd_wukong_phantom",inst)
                local angle =  inst.Transform:GetRotation()
                fx.Transform:SetRotation(angle)
                local bank,anim = inst.AnimState:GetHistoryData()
                if anim then
                    fx.AnimState:PlayAnimation(anim)
                    fx.AnimState:SetTime(inst.AnimState:GetCurrentAnimationTime())
                else
                    fx.AnimState:PlayAnimation("idle_loop")
                end
                fx.SoundEmitter:PlaySound("xd_wukong_sound/xd_wukong_sound/yw")
                local build = not weapon.blade1 and not weapon.skinblade1 and weapon.AnimState:GetBuild() or "xd_wukong_jgb"
                fx:OnSpawnedBy(inst,build)
                XD_TELE_PLAYER(inst,pos)
                inst:AddDebuff("xd_jxsq_buff","xd_jxsq_buff")
            end
            inst.components.xd_skillcd:Start("灵技",20)
        end
        inst.doshentongskill = function(inst,weapon)
            local pos = inst:GetPosition()
            local pets = {}
            inst:StartThread(function()
                for k = 1, 3 do
                    local theta = math.random() * 2 * PI
                    local radius = 3.5
                    local offset = FindWalkableOffset(pos, theta, radius,6, true)
                    if offset == nil then
                        offset = Vector3(0,0,0)
                    end
                    local projectile = SpawnPrefab("xd_wukong_shadow")
                    projectile.Transform:SetPosition((pos+offset):Get())
                    projectile:CopyFromPlayer(inst,nil)
                    table.insert(pets,projectile)
                    projectile.pets = pets
                    Sleep(0.5)
                end
            end)
            inst.components.xd_skillcd:Start("神通",45)
            inst:PushEvent("xd_done_shentong",{weapon = weapon})
        end  
    end,
    xd_jingwei = function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst.ljattack_fn = ljattack_fn_jingwei
        inst.dolingjiskill = function(inst,weapon,pos,target)
            if inst and inst.sg then
                inst.sg:GoToState("xd_jingwei_bird")
            end
            inst.components.xd_skillcd:Start("灵技",20)
        end
        inst.doshentongskill = function(inst,weapon)
            local pet = inst.components.xd_jingwei_pet and inst.components.xd_jingwei_pet:GetPet() or nil
            if pet and not pet.components.health:IsDead() and not pet.doremove then
                inst.components.xd_jingwei_pet:LevelMax()
                inst.components.xd_skillcd:Start("神通",120)
                inst:PushEvent("xd_done_shentong",{weapon = weapon})
            end
        end  
    end,
    xd_yunxiao = function(inst)
        inst.onuseljsgname = "xd_yunxiao_jjj_lungestart"
        inst.onuseljsgname_clinet = "xd_yunxiao_jjj_lungestart"
        if not TheWorld.ismastersim then
            return inst
        end
        inst.dolingjiskill = function(inst,weapon,pos,target)
            inst:PushEvent("xd_yunxiao_jjj_lunge",{targetpos = pos})
            inst.components.xd_skillcd:Start("灵技",15)
        end
        inst.doshentongskill = function(inst,weapon)
            local ix, iy, iz = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("groundpoundring_fx")
            local zone_width = ((TUNING.WURT_TERRAFORMING_TILERANGE + 0.5)*TILE_SCALE)
            local zone_diagonal = math.sqrt(zone_width * zone_width + zone_width * zone_width)
            local fxscale = math.sqrt(zone_diagonal / 12)
            fx.Transform:SetScale(fxscale, fxscale, fxscale)
            fx.Transform:SetPosition(ix, 0, iz)
            local fx = SpawnAt("xd_yunxiao_swamp_terraformer",Vector3(ix, 0, iz))
            fx:DoTerraform()
    
            local ent = SpawnAt("xd_yunxiao_jjj_aoeent",Vector3(ix, 0, iz))
            ent.owner = inst
            inst.components.xd_skillcd:Start("神通",60)
            inst:PushEvent("xd_done_shentong",{weapon = weapon})
        end  
    end,
    xd_hantianzun = function(inst)
        inst.onuseljsgname = "xd_superjump_start"
        inst.onuseljsgname_clinet = "xd_superjump_start"
        if not TheWorld.ismastersim then
            return inst
        end
        inst.dolingjiskill = function(inst,weapon,pos,target)
            inst:PushEvent("xd_superjump",{pos = pos})
            inst.components.xd_skillcd:Start("灵技",15)
        end
        inst.doshentongskill = function(inst,weapon)
            local cost  =inst.components.xd_level and inst.components.xd_level.level >= 9 and 30 or 25
            if inst.components.xd_htz_lq.current < cost then
                XD_SAY(inst,STRINGS.XD_HTZ_NOLQ)
                return true
            end
            inst.components.xd_htz_lq:DoDelta(-cost)
            inst:AddDebuff("xd_qzj_buff","xd_qzj_buff")
            inst.components.xd_skillcd:Start("神通",60)
            inst:PushEvent("xd_done_shentong",{weapon = weapon})
        end  
    end,
    xd_shiji = function(inst)
        inst.onuseljsgname = "xd_superjump_start"
        inst.onuseljsgname_clinet = "xd_superjump_start"
        if not TheWorld.ismastersim then
            return inst
        end
        inst.dolingjiskill = function(inst,weapon,pos,target)
            inst:PushEvent("xd_superjump",{pos = pos})
            inst.components.xd_skillcd:Start("灵技",12)
        end
        inst.doshentongskill = function(inst,weapon)
            local pos = inst:GetPosition()
            local theta = math.random() * 2 * PI
            local radius = math.random(2,5)
            local offset = FindWalkableOffset(pos, theta, radius,12, true)
            if offset == nil then
                offset = Vector3(0,0,0)
            end
            local fx = SpawnAt("xd_shadowmeteor",pos+offset)
            fx.setsize = "large"
            fx.onhitfn = function(_inst)
                if inst and inst:IsValid() then
                    local pet = SpawnAt("xd_sj_pysk",_inst)
                    pet:OnSpawnedBy(inst,nil)
                    pet.sg:GoToState("shield_end")
                    local pt = _inst:GetPosition()
                    SpawnPrefab("groundpoundring_fx").Transform:SetPosition(pt:Get())
                    local points = XD_GetGroundPoints(pt)
                    local map = TheWorld.Map
                    for i, v1 in ipairs(points) do
                        for i,v in ipairs(v1) do
                            if map:IsLandTileAtPoint(v:Get()) and not map:IsDockAtPoint(v:Get()) then
                                SpawnPrefab("groundpound_fx").Transform:SetPosition(v.x, 0, v.z)
                            end
                        end
                    end
                end
            end
            inst.components.xd_skillcd:Start("神通",60)
            inst:PushEvent("xd_done_shentong",{weapon = weapon})
        end  
    end,
    xd_wangmazi = function(inst)
        
        if not TheWorld.ismastersim then
            return inst
        end
        inst.dolingjiskill = function(inst,weapon,pos,target)
            Xd_DsSkill(inst,pos,3,500,true)
            inst.components.xd_skillcd:Start("灵技",20)
        end
        inst.doshentongskill = function(inst,weapon)
            if inst.xd_wmz_forcefieldfx ~= nil then
                inst.xd_wmz_forcefieldfx:kill_fx()
            end
            inst.xd_wmz_forcefieldfx = SpawnPrefab("xd_wmz_forcefieldfx")
            inst.xd_wmz_forcefieldfx.entity:SetParent(inst.entity)
            inst.xd_wmz_forcefieldfx.Transform:SetPosition(0, 0.2, 0)
            inst.xd_wmz_forcefieldfx:SetOwner(inst)
            inst.components.xd_skillcd:Start("神通",60)
            inst:PushEvent("xd_done_shentong",{weapon = weapon})
        end  
    end,

    xd_chenpingan = function(inst)
        inst.onuseljsgname = "xd_chenpingan_lingji_lungestart"
        inst.onuseljsgname_client = "xd_chenpingan_lingji_lungestart"
        if not TheWorld.ismastersim then
            return inst
        end
        inst.dolingjiskill = function(inst,weapon,pos,target)
            if inst.components.xd_chenpingan_ljt_controller ~= nil then
                inst.components.xd_chenpingan_ljt_controller:TryCastLingji()
            end
            
        end
        inst.doshentongskill = function(inst,weapon)
            StartChenpinganShentongProjectiles(inst)
            inst.components.xd_skillcd:Start("神通",60)
            inst:PushEvent("xd_done_shentong",{weapon = weapon})
        end
    end,}
