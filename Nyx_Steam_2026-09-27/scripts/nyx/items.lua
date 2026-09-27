-- Item permissions are scoped to Nyx. Original linked ownership is preserved.
local M={}
-- Verified restricted equipment from all ten Tu Tien 18.1 characters.
local permissions={
    xd_chenpingan_bd='xd_chenpingan',
    xd_chenpingan_xb='xd_chenpingan',
    xd_chenpingan_cm='xd_chenpingan',
    xd_chenpingan_kcd='xd_chenpingan',
    xd_chenpingan_ygl='xd_chenpingan',
    xd_chenpingan_ygp='xd_chenpingan',
    xd_htz_qzj='xd_hantianzun',
    xd_jingwei_fan='xd_jingwei',
    xd_jingwei_zzql='xd_jingwei',
    xd_sly='xd_longtaizi',
    xd_sj_tej='xd_shiji',
    xd_sj_xsydz='xd_shiji',
    xd_sudaji_mxrg='xd_sudaji',
    xd_sudaji_ywfh='xd_sudaji',
    xd_sudaji_redlantern='xd_sudaji',
    xd_wmz_kjb='xd_wangmazi',
    xd_wmz_xsj='xd_wangmazi',
    xd_wukong_jgb='xd_wukong',
    xd_yunxiao_fgfq='xd_yunxiao',
    xd_yunxiao_fls='xd_yunxiao',
    xd_yunxiao_fysz='xd_yunxiao',
    xd_yunxiao_hyjditem='xd_yunxiao',
    xd_yunxiao_jjj='xd_yunxiao',
    xd_luoshen_krss='xd_luoshen',
    xd_luoshen_dinghunxianglu='xd_luoshen',
}
M.Permissions=permissions
function M.Allows(item,target,tag)
    return target and target.prefab=='nyx' and item and type(item.prefab)=='string'
        and permissions[item.prefab]~=nil and permissions[item.prefab]==tag
end
local function Wrap(self,replica)
    local old=self.IsRestricted
    self.IsRestricted=function(c,target)
        local inv=c.inst.replica and c.inst.replica.inventoryitem
        local tag=replica and inv and inv:GetEquipRestrictedTag() or c.restrictedtag
        if M.Allows(c.inst,target,tag) then
            local linked=c.inst.components and c.inst.components.linkeditem
            if linked and linked:IsEquippableRestrictedToOwner() then
                local userid=linked:GetOwnerUserID()
                if userid and userid~=target.userid then return true end
            end
            return false
        end
        return old(c,target)
    end
end
function M.Install(api)
    api.AddComponentPostInit('equippable',function(c) Wrap(c,false) end)
    api.AddClassPostConstruct('components/equippable_replica',function(c) Wrap(c,true) end)
    api.AddPrefabPostInit('nyx',function(inst)
        if not TheWorld.ismastersim or not XD_CanAttackTrget then return end
        require('nyx/krss').Install(inst)
    end)
    -- Middle-grade spirit stone: preserve the original item and consume one exactly once.
    api.AddPrefabPostInit('xd_lingshi2',function(inst)
        if not TheWorld.ismastersim or not inst.components.xd_use_inventory then return end
        local c=inst.components.xd_use_inventory; local old=c.onusefn
        c.onusefn=function(item,doer,target)
            if doer and doer.prefab=='nyx' and doer.components.xd_htz_lq then
                doer:AddDebuff('xd_lingqiheal_buff','xd_lingqiheal_buff')
                doer.SoundEmitter:PlaySound('dontstarve/common/nightmareAddFuel')
                if item.components.stackable then item.components.stackable:Get():Remove() else item:Remove() end
            elseif old then return old(item,doer,target) end
        end
    end)
    api.AddComponentAction('INVENTORY','xd_use_inventory',function(item,doer,actions)
        if item.prefab=='xd_lingshi2' and doer and doer.prefab=='nyx' and item:HasTag('canuseininv_xd') then
            for _,a in ipairs(actions) do if a==ACTIONS.XD_USE_INVENTORY then return end end
            actions[#actions+1]=ACTIONS.XD_USE_INVENTORY
        end
    end)
end
return M
