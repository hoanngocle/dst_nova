-- Smart Minisign by mamjun1, integrated without replacing chest prefabs.
local G = GLOBAL

G.TUNING.TTK_SMARTSIGN_BUNDLE = GetModConfigData("BundleItems")
G.TUNING.TTK_SMARTSIGN_DIG = GetModConfigData("Digornot")
G.TUNING.TTK_SMARTSIGN_SKIN = GetModConfigData("ChangeSkin")
-- The source option stores false for "only players may dig".
G.TUNING.TTK_SMARTSIGN_ALLOW_NONPLAYER_DIG = GetModConfigData("OnlyPlayer")

AddClassPostConstruct("components/inventoryitem_replica", function(self)
    local old_set_atlas = self.SetAtlas
    function self:SetAtlas(atlasname)
        if old_set_atlas ~= nil then
            old_set_atlas(self, atlasname)
        end
        self._ttk_smart_sign_atlas = atlasname ~= nil and G.resolvefilepath(atlasname) or nil
    end
    function self:GetHuaAtlas()
        return self._ttk_smart_sign_atlas or self:GetAtlas()
    end
end)

-- Remove detached signs left by an older version of the source mod.
AddPrefabPostInit("minisign", function(inst)
    if not G.TheWorld.ismastersim then return end
    local old_load_post_pass = inst.OnLoadPostPass
    inst.OnLoadPostPass = function(sign, newents, savedata)
        if old_load_post_pass ~= nil then
            old_load_post_pass(sign, newents, savedata)
        end
        if savedata ~= nil and savedata.huachest ~= nil
            and newents ~= nil and newents[savedata.huachest] ~= nil then
            sign:DoTaskInTime(0, sign.Remove)
        end
    end
end)

local function add_smart_sign(inst)
    if G.TheWorld.ismastersim and inst.components.smart_minisign == nil then
        inst:AddComponent("smart_minisign")
    end
end

AddPrefabPostInit("treasurechest", add_smart_sign)
if GetModConfigData("DragonflyChest") then
    AddPrefabPostInit("dragonflychest", add_smart_sign)
end
if GetModConfigData("Icebox") then
    AddPrefabPostInit("icebox", add_smart_sign)
end
if GetModConfigData("SaltBox") then
    AddPrefabPostInit("saltbox", add_smart_sign)
end

-- Keep the source mod's public API for other mods that call it.
G.TUNING.SMART_SIGN_DRAW_ENABLE = true
G.SMART_SIGN_DRAW = add_smart_sign

-- AnimState needs an ATLAS_BUILD for inventory icons from other mods.
-- Collect those atlases after every enabled mod has registered its prefabs.
local manager = G.ModManager
if manager ~= nil and manager.RegisterPrefabs ~= nil then
    local old_register_prefabs = manager.RegisterPrefabs
    local registered = false
    manager.RegisterPrefabs = function(self, ...)
        local result = old_register_prefabs(self, ...)
        if registered then return result end
        registered = true

        local atlases = {}
        local atlas_builds = {}
        local function normalize(path)
            return path:gsub("^%.%./mods/[^/]+/", "")
        end
        local function scan(assets)
            if assets == nil then return end
            for _, asset in pairs(assets) do
                if type(asset.file) == "string" then
                    local file = normalize(asset.file)
                    if asset.type == "ATLAS" and
                        (file:find("images/", 1, true) == 1 or file:find("/images/", 1, true) ~= nil) then
                        atlases[file] = true
                    elseif asset.type == "ATLAS_BUILD" then
                        atlas_builds[file] = true
                    end
                end
            end
        end

        for _, modname in ipairs(self.enabledmods or {}) do
            local mod = self:GetMod(modname)
            if mod ~= nil then
                scan(mod.Assets)
                for _, prefab in pairs(mod.Prefabs or {}) do
                    scan(prefab.assets)
                end
            end
        end

        local builds = {}
        for file in pairs(atlases) do
            if not atlas_builds[file] then
                builds[#builds + 1] = Asset("ATLAS_BUILD", file, 256)
            end
        end
        if #builds > 0 then
            local name = "TTK_SMARTSIGN_ATLASES"
            G.RegisterPrefabs(G.Prefab(name, nil, builds, nil, true))
            G.TheSim:LoadPrefabs({name})
            self.loadedprefabs[#self.loadedprefabs + 1] = name
        end
        return result
    end
end
