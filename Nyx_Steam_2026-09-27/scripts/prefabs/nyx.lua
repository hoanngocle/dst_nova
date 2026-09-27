local MakePlayerCharacter=require('prefabs/player_common')
local Net=require('nyx/skillnet')
local U=require('nyx/utility18')
local assets={Asset('ANIM','anim/nyx_purple.zip'),Asset('ANIM','anim/nyx_ghost.zip')}
local function EnsureBook(inst)
    if inst._nyx_skillbook_entity and inst._nyx_skillbook_entity:IsValid() then return end
    local book=SpawnPrefab('nyx_skillbook')
    if book then book:BindToOwner(inst); inst._nyx_skillbook_entity=book; inst._nyx_skillbook:set(book) end
end
local function common(inst)
    inst:AddTag('nyx'); inst:AddTag('nyx_crafter')
    inst.MiniMapEntity:SetIcon('nyx.tex')
    Net.Install(inst)
    if not TheWorld.ismastersim then require('nyx/wings_replica').InstallReplica(inst) end
    inst._nyx_skillbook=net_entity(inst.GUID,'nyx.skillbook')
    inst:ListenForEvent('nyx_eyedirty',U.ApplyEye)
    inst:ListenForEvent('nyx_wingsdirty',U.ApplyWingsReplica)
    inst:ListenForEvent('ms_respawnedfromghost',U.ApplyWingsReplica)
    inst:ListenForEvent('ms_becameghost',U.ApplyWingsReplica)
    inst:DoTaskInTime(0,function() U.ApplyEye(inst); U.ApplyWingsReplica(inst) end)
end
local function master(inst)
    inst.soundsname='wendy'
    inst.base_xdhealth=125; inst.base_xdhunger=125; inst.base_xdsanity=200
    inst.components.health:SetMaxHealth(125); inst.components.hunger:SetMax(125); inst.components.sanity:SetMax(200)
    inst.components.hunger.hungerrate=TUNING.WILSON_HUNGER_RATE
    inst.components.combat.damagemultiplier=1
    inst.components.foodaffinity:AddPrefabAffinity('meatballs',TUNING.AFFINITY_15_CALORIES_HUGE)
    if inst.components.damagetypebonus then
        inst.components.damagetypebonus:AddBonus('shadow_aligned',inst,1.07,'nyx_hanlap')
        inst.components.damagetypebonus:AddBonus('lunar_aligned',inst,1.07,'nyx_hanlap')
    end
    if inst.components.damagetyperesist then
        inst.components.damagetyperesist:AddResist('shadow_aligned',inst,.93,'nyx_hanlap')
        inst.components.damagetyperesist:AddResist('lunar_aligned',inst,.93,'nyx_hanlap')
    end
    inst.AnimState:SetBuild('eva_purple')
    require('nyx/source18').Attach(inst)
    for _,component in ipairs({'nyx_appearance','nyx_domain','nyx_gather','nyx_blink','nyx_skills'}) do inst:AddComponent(component) end
    inst.OnNewSpawn=function()
        inst:DoTaskInTime(0,function()
            for _,prefab in ipairs({'xd_luoshen_krss','xd_wmz_zhf'}) do
                if Prefabs[prefab] then
                    local item=SpawnPrefab(prefab)
                    if item then inst.components.inventory:GiveItem(item) end
                end
            end
        end)
    end
    inst:DoTaskInTime(0,EnsureBook)
    inst:ListenForEvent('onremove',function()
        local book=inst._nyx_skillbook_entity
        if book and book:IsValid() then book:Remove() end
    end)
end
return MakePlayerCharacter('nyx',{
    'nyx_skillbook','spear_wathgrithr_lightning_lunge_fx','lightning','xd_luoshen_krss','xd_wmz_zhf',
    'xd_luoshen_shentong_death_buff','xd_luoshen_shentong_death_circle',
    'groundpoundring_fx','xd_yunxiao_swamp_terraformer','xd_yunxiao_jjj_aoeent',
    'xd_htz_firefx','xd_wmz_butterfly1','xd_wmz_butterfly2','xd_wmz_butterfly3',
    'nyx_gather_controller','nyx_wings_fx','nyx_ice_circle',
    'nyx_wmz_profire','nyx_wmz_beam_fx','nyx_wmz_gestalt',
    'nyx_htz_smallxtj','nyx_htz_trap_spell','nyx_htz_bigxtj','nyx_htz_beam_fx','nyx_htz_laserwire_fx',
},assets,common,master,nil)
