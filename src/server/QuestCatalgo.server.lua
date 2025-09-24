-- QuestCatalog.lua (ModuleScript)
-- Central registry for quests. Replace stubs with real data/logic.

local QuestCatalog = {}

-- Example quest structure (adjust to your project):
-- QuestCatalog.Definitions = {
--   Headshot10 = { name = "Sharpshooter", goal = 10, stat = "headshots", reward = { money = 100 } },
-- }

QuestCatalog.Definitions = {}

-- Register a quest programmatically (optional helper):
function QuestCatalog.register(id: string, def)
    QuestCatalog.Definitions[id] = def
end

-- Fetch quest definition
function QuestCatalog.get(id: string)
    return QuestCatalog.Definitions[id]
end

-- List all quests
function QuestCatalog.list()
    local list = {}
    for id, def in pairs(QuestCatalog.Definitions) do
        list[#list+1] = { id = id, def = def }
    end
    table.sort(list, function(a,b) return a.id < b.id end)
    return list
end

return QuestCatalog

