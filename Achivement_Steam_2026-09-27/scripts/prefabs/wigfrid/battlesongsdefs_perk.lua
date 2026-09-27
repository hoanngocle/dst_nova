local RECHARGE_PERCENTAGE = chasni_getitemconfig("chasni_battlesong_instant_recharge", "PCTG") or 0.3
local LIGHTNING_DAMAGE_MULT = chasni_getitemconfig("chasni_battlesong_lightning", "LDMG") or 1.6
local LIGHTNING_HUNGER_DRAIN = chasni_getitemconfig("chasni_battlesong_lightning", "LHD") or 2
local song_defs =
{
    chasni_battlesong_instant_recharge =
    {
        ONINSTANT = function(singer, target)
            if target and target.components.inventory then
                local items = target.components.inventory:FindItems(function(i)
                    return i:HasTag("charges_percentage")
                end)
                for _, item in ipairs(items) do
                    if item.components.finiteuses then
                        local total = item.components.finiteuses.total
                        local current = item.components.finiteuses.current
                        if current < total then
                            local increment = math.ceil(total * RECHARGE_PERCENTAGE)
                            item.components.finiteuses:SetUses(math.min(current + increment, total))
                        end
                    end
                end
            end
        end,
        CUSTOMTARGETFN = function(singer)
            if TheNet:GetPVPEnabled() then
                local players = {}
                table.insert(players, singer)
                return players
            end
            local x, y, z = singer.Transform:GetWorldPosition()
            local radius = singer.components.singinginspiration.attach_radius
            return FindPlayersInRange(x, y, z, radius, true) or nil
        end,
        ANIM = "battlesong_instant_revive",
        INSTANT = true,
        COOLDOWN = 60,
        DELTA = TUNING.BATTLESONG_INSTANT_COST,
        ATTACH_FX = "battlesong_instant_recharge_fx",
        SOUND = "dontstarve_DLC001/characters/wathgrithr/quote/electric",
    },
    chasni_battlesong_instant_stopmove =
    {
        ONINSTANT = function(singer, target)
            if not (target.components.health and target.components.health:IsDead()) then
                target:AddDebuff("battlesong_instant_stopmove_debuff", "battlesong_instant_stopmove_debuff")
            end
        end,
        CUSTOMTARGETFN = function(singer)
            local x, y, z = singer.Transform:GetWorldPosition()
            local radius = singer.components.singinginspiration.attach_radius
            return chasni_findentities(x, y, z, radius, {"locomotor"}, chasni_TAG_NOTARGET, singer)
        end,
        ANIM = "battlesong_instant_dropattack",
        COOLDOWN = 60,
        INSTANT = true,
        DELTA = TUNING.BATTLESONG_INSTANT_COST,
        ATTACH_FX = "battlesong_instant_stopmove_fx",
        SOUND = "chasni_song/chasni_song/chasni_battlesong_instant_stopmove",
    },
    chasni_battlesong_channel_lunar =
    {
        ONINSTANT = function(singer, target)
            singer._songchannelingtask = singer:DoPeriodicTask(1.5, function(self)
                local x, y, z = self.Transform:GetWorldPosition()
                local ents = chasni_findentities(x, y, z, TUNING.BATTLESONG_ATTACH_RADIUS, { "_combat", "_health" }, chasni_TAG_NOATTACK, self)

                if #ents > 0 then
                    local lucenttarget = ents[math.random(#ents)]
                    if lucenttarget then
                        local xt, yt, zt = lucenttarget.Transform:GetWorldPosition()
                        local lucent_beam = chasni_spawnprefab("lucentbeam", xt, yt, zt)
                        if lucent_beam then
                            lucent_beam._singer = singer
                        end
                    end
                end
            end)
        end,
        CUSTOMTARGETFN = function(singer)
            if singer then
                local players = {}
                table.insert(players, singer)
                return players
            end
            return nil
        end,
        ANIM = "battlesong_instant_taunt",
        INSTANT = true,
        CHANNEL = true,
        COOLDOWN = 120,
        DELTA = TUNING.BATTLESONG_INSTANT_COST,
        --ATTACH_FX = "battlesong_instant_recharge_fx",
        SOUND = "chasni_song/chasni_song/chasni_battlesong_channel_lunar",
    },
    chasni_battlesong_channel_shadow =
    {
        ONINSTANT = function(singer, target)
            local x, y, z = singer.Transform:GetWorldPosition()
            chasni_spawnprefab("vortex_cloak_fx", x, y, z)
            singer._chasni_battlesong_channel_shadow_charge = (singer._chasni_battlesong_channel_shadow_charge or 0) + 1
            singer._songchannelingtask = singer:DoPeriodicTask(2, function(self)
                local x, y, z = self.Transform:GetWorldPosition()
                chasni_spawnprefab("vortex_cloak_fx", x, y, z)
                self._chasni_battlesong_channel_shadow_charge = (self._chasni_battlesong_channel_shadow_charge or 0) + 1
            end)
            singer._songchannelingendfunction = function(self)
                local x, y, z = self.Transform:GetWorldPosition()
                chasni_spawnprefab("sf_ult2_fx", x, y, z)
                chasni_spawnprefab("sf_ult3_fx", x, y, z)
                chasni_spawnprefab("blackfx_ring", x, y, z)
                local nottargettags = { "playerghost", "INLIMBO", "notarget", "noattack", "invisible", "lunar_aligned" }
                if not TheNet:GetPVPEnabled() then
                    table.insert(nottargettags, "player")
                    table.insert(nottargettags, "companion")
                    table.insert(nottargettags, "ally")
                end
                local targets = TheSim:FindEntities(x, y, z, 12, nil, nottargettags)
                for i, v in ipairs(targets) do
                    if self.components.combat and v:IsValid() and self ~= v then
                        if v.components.combat and v.components.health and not v.components.health:IsDead() then
                            if v.components.combat:CanBeAttacked() and not self.components.combat:IsAlly(v) then
                                local spdmg = {}
                                spdmg["planar"] = math.min((self._chasni_battlesong_channel_shadow_charge or 0) * 15, 200)
                                v.components.combat:GetAttacked(self, 0, nil, nil, spdmg)
                            end
                        end
                    end
                end
                self._chasni_battlesong_channel_shadow_charge = nil
            end
        end,
        CUSTOMTARGETFN = function(singer)
            if singer then
                local players = {}
                table.insert(players, singer)
                return players
            end
            return nil
        end,
        ANIM = "battlesong_instant_panic",
        INSTANT = true,
        CHANNEL = true,
        COOLDOWN = 120,
        DELTA = TUNING.BATTLESONG_INSTANT_COST,
        --ATTACH_FX = "battlesong_instant_recharge_fx",
        SOUND = "chasni_song/chasni_song/chasni_battlesong_channel_shadow",
    },
    chasni_battlesong_sailor =
    {
        ONAPPLY = function(inst, target)
            if target.components.expertsailor == nil then
                target:AddComponent("expertsailor")
            end
            if target.components.moisture then
                target.components.moisture:ForceDry(true, inst)
            end
        end,
        ONDETACH = function(inst, target)
            if target.components.moisture then
                target.components.moisture:ForceDry(false, inst)
            end
        end,
        ANIM = "battlesong_healthgain",
        ATTACH_FX = "battlesong_attach",
        LOOP_FX = "battlesong_sailor_fx",
        DETACH_FX = "battlesong_detach",
        SOUND = "chasni_song/chasni_song/chasni_battlesong_sailor",
    },
    chasni_battlesong_lightning =
    {
        ONAPPLY = function(inst, target)
            if target.components.combat then
                target.components.combat.externaldamagemultipliers:SetModifier("chasni_battlesong_lightning", LIGHTNING_DAMAGE_MULT)
            end

            if target.components.hunger ~= nil then
                target.components.hunger.burnratemodifiers:SetModifier(inst, LIGHTNING_HUNGER_DRAIN)
            end
            if target.wormlight then
                if target.wormlight.prefab == "wormlight_light_lesser" then
                    target.wormlight.components.spell.lifetime = 0
                    target.wormlight.components.spell:ResumeSpell()
                    return
                else
                    target.wormlight.components.spell:OnFinish()
                end
            end

            local light = SpawnPrefab("wormlight_light_lesser")
            light.components.spell:SetTarget(target)
            if light:IsValid() then
                if light.components.spell.target == nil then
                    light:Remove()
                else
                    light.components.spell:StartSpell()
                end
            end
        end,
        ONDETACH = function(inst, target)
            if target.components.combat then
                target.components.combat.externaldamagemultipliers:RemoveModifier("chasni_battlesong_lightning")
            end

            if target.components.hunger ~= nil then
                target.components.hunger.burnratemodifiers:RemoveModifier(inst)
            end

            if target.wormlight then
                if target.wormlight.prefab == "wormlight_light_lesser" then
                    target.wormlight.components.spell:OnFinish()
                end
            end
            inst:Remove()
        end,
        ANIM = "battlesong_sanitygain",
        ATTACH_FX = "battlesong_attach",
        LOOP_FX = "battlesong_lightning_fx",
        DETACH_FX = "battlesong_detach",
        SOUND = "chasni_song/chasni_song/chasni_battlesong_lightning",
    },
}

local Startbattlesong_netid = 30
local battlesong_netid = Startbattlesong_netid
local battlesong_netid_lookup = {}

local function AddNewBattleSongNetID(prefab, song_def)
    song_def.battlesong_netid = battlesong_netid
    table.insert(battlesong_netid_lookup, prefab)
    assert(battlesong_netid < 100, "the max number of battle songs has been passed, you will need to change the netvar for player_classified.inspirationsong1/2/3 to support more")

    battlesong_netid = battlesong_netid + 1
end

for k, v in pairs(song_defs) do
    v.ITEM_NAME  = k
    v.NAME = k.."_buff"
    if not v.INSTANT then
        AddNewBattleSongNetID(k, v)
    end
end

local function GetBattleSongDefFromNetID(netid)
    local def = netid and battlesong_netid_lookup[netid - Startbattlesong_netid + 1] or nil
    return def and song_defs[def] or nil
end

return {song_defs = song_defs, GetBattleSongDefFromNetID = GetBattleSongDefFromNetID, AddNewBattleSongNetID = AddNewBattleSongNetID}