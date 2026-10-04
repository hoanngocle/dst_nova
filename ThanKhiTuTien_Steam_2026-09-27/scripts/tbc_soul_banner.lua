local M = {}
local BASE_DAMAGE = 50
local CRIT_MILESTONES = {3, 5, 7, 9, 11, 13, 16}
local pending_level

function M.IsBanner(prefab)
    return prefab == "xd_wmz_zhf" or prefab == "vanhonphien"
end

function M.Damage(level)
    level = math.max(0, math.min(16, math.floor(tonumber(level) or 0)))
    return BASE_DAMAGE * 1.2 ^ level
end

function M.CritBonus(level)
    level = tonumber(level) or 0
    local milestones = 0
    for _, threshold in ipairs(CRIT_MILESTONES) do
        if level >= threshold then milestones = milestones + 1 end
    end
    return milestones * 10, milestones * 20
end

local function TransferLevel(level, callback, ...)
    local previous = pending_level
    pending_level = level
    local ok, result = pcall(callback, ...)
    pending_level = previous
    if not ok then error(result) end
    return result
end

local function AttachItem(inst)
    inst:AddTag("tbc_upgradeable")
    if not TheWorld.ismastersim then return end
    if inst.components.tbc_upgrade == nil then inst:AddComponent("tbc_upgrade") end
    if pending_level ~= nil then
        inst.components.tbc_upgrade:SetLevel(pending_level)
    end
    local deployable = inst.components.deployable
    if deployable ~= nil and deployable.ondeploy ~= nil then
        local original = deployable.ondeploy
        deployable.ondeploy = function(item, ...)
            return TransferLevel(item.components.tbc_upgrade.level, original, item, ...)
        end
    end
    inst:DoTaskInTime(0, function()
        if inst:IsValid() then inst.components.tbc_upgrade:UpdateDisplay() end
    end)
end

local function AttachGround(inst)
    inst._tbc_banner_level = pending_level or 0
    if not TheWorld.ismastersim then return end
    local save = inst.OnSave
    inst.OnSave = function(item, data, ...)
        if save ~= nil then save(item, data, ...) end
        data.tbc_banner_level = item._tbc_banner_level
    end
    local load = inst.OnLoad
    inst.OnLoad = function(item, data, ...)
        if load ~= nil then load(item, data, ...) end
        item._tbc_banner_level = math.max(0,
            math.min(16, math.floor(tonumber(data and data.tbc_banner_level) or 0)))
    end
    local structure = inst.components.portablestructure
    if structure ~= nil and structure.ondismantlefn ~= nil then
        local original = structure.ondismantlefn
        structure.ondismantlefn = function(item, ...)
            return TransferLevel(item._tbc_banner_level, original, item, ...)
        end
    end
end

local function AttachSoul(inst)
    inst.displaynamefn = function() return "Hồn Linh" end
    if not TheWorld.ismastersim then return end
    local combat = inst.components.combat
    if combat == nil then return end
    local function RefreshDefaultDamage()
        local tracker = inst.components.entitytracker
        local banner = tracker ~= nil and tracker:GetEntity("banner") or nil
        local level = banner ~= nil and banner._tbc_banner_level or 0
        combat:SetDefaultDamage(M.Damage(level))
        return level
    end
    local function WrapCalcDamage()
        if combat.CalcDamage == combat._tbc_banner_calc then return end
        local original = combat.CalcDamage
        combat._tbc_banner_calc = function(self, ...)
            local level = RefreshDefaultDamage()
            local damage, special_damage = original(self, ...)
            if type(damage) ~= "number" then return damage, special_damage end
            local rate, effect = M.CritBonus(level)
            if rate > 0 then
                damage = require("tbc_combat_math").RollCrit(damage,
                    {crit_rate = rate, crit_effect = effect}, math.random)
            end
            return damage, special_damage
        end
        combat.CalcDamage = combat._tbc_banner_calc
    end
    WrapCalcDamage()
    RefreshDefaultDamage()
    local original_spawn = inst.OnSpawnedBy
    if original_spawn ~= nil then
        inst.OnSpawnedBy = function(soul, ...)
            local result = original_spawn(soul, ...)
            WrapCalcDamage()
            RefreshDefaultDamage()
            soul:DoTaskInTime(0, function()
                if soul:IsValid() then RefreshDefaultDamage() end
            end)
            return result
        end
    end
end

function M.Install(add_prefab_post_init)
    for _, prefix in ipairs({"xd_wmz_zhf", "vanhonphien"}) do
        add_prefab_post_init(prefix, AttachItem)
        add_prefab_post_init(prefix .. "_ground", AttachGround)
        add_prefab_post_init(prefix .. "_soul", AttachSoul)
    end
end

return M
