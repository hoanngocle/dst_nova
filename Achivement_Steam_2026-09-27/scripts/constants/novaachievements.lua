-- Imported additions are kept separate from the original Workshop definitions.
-- Regenerate the catalog with tools/import_nova_achievements.py.
local definitions = {}
for _, source in ipairs({"constants/novaachievementcatalog", "constants/elixirachievements"}) do
    for _, achievement in ipairs(require(source)) do
        definitions[#definitions + 1] = achievement
    end
end
return definitions
