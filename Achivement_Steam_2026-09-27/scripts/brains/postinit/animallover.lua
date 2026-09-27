local UpvalueHacker = require "functions/upvaluehacker"

-- CC : [BIRDBRAIN] add cz_animallover and upgraded_featherhat tag >> [Reward] Animal Lover || [RoG] upgraded_featherhat
local BirdBrain = require("brains/birdbrain")
local SHOULDFLYAWAY_MUST_TAGS = {"cz_animallover", "upgraded_featherhat"}
local _SHOULDFLYAWAY_MUST_TAGS = UpvalueHacker.GetUpvalue(BirdBrain.OnStart, "ShouldFlyAway", "SHOULDFLYAWAY_MUST_TAGS")

for i,tag in pairs(SHOULDFLYAWAY_MUST_TAGS) do
    table.insert(_SHOULDFLYAWAY_MUST_TAGS, tag)
end

-- CC : [LIGHTNINGGOATBRAIN] add cz_animallover tag >> [Reward] Animal Lover
local LightningGoatBrain = require("brains/lightninggoatbrain")
local GoatShouldRunAway = UpvalueHacker.GetUpvalue(LightningGoatBrain.OnStart, "ShouldRunAway")
local function New_GoatShouldRunAway(guy, ...)
    return GoatShouldRunAway(guy, ...) and not guy:HasTag("cz_animallover")
end

UpvalueHacker.SetUpvalue(LightningGoatBrain.OnStart, New_GoatShouldRunAway, "ShouldRunAway")

-- CC : [KOALEFANTBRAIN] add cz_animallover tag >> [Reward] Animal Lover
local KoalefantBrain = require("brains/koalefantbrain")
local KoalefantShouldRunAway = UpvalueHacker.GetUpvalue(KoalefantBrain.OnStart, "ShouldRunAway")
local function New_KoalefantShouldRunAway(guy, ...)
    return KoalefantShouldRunAway(guy, ...) and not guy:HasTag("cz_animallover")
end

UpvalueHacker.SetUpvalue(KoalefantBrain.OnStart, New_KoalefantShouldRunAway, "ShouldRunAway")


