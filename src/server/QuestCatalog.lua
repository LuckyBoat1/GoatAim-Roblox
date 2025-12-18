-- QuestCatalog.lua (ModuleScript)
-- Central registry for quests.

local QuestCatalog = {}

QuestCatalog.Definitions = {}

local function addTieredQuest(category, baseName, descTemplate, stat, baseGoal, baseMoney, baseXp)
	local multipliers = {1, 2, 5, 10, 25, 50, 100, 250, 500, 1000}
	local roman = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"}
	
	for i = 1, 10 do
		local id = category .. "_" .. i
		local goal = baseGoal * multipliers[i]
		local money = baseMoney * multipliers[i]
		local xp = baseXp * multipliers[i]
		
		-- Special skin reward for Tier 10
		local reward = {money = money, xp = xp}
		if i == 10 then
			reward.skin = baseName .. " Elite"
		end
		
		QuestCatalog.Definitions[id] = {
			category = category,
			name = baseName .. " " .. roman[i],
			desc = descTemplate:format(goal),
			goal = goal,
			stat = stat,
			reward = reward
		}
	end
end

-- WARLORD: PvP Fights
addTieredQuest("warlord", "Warlord", "Win %s PvP Fights", "pvp_wins", 6, 200, 100)

-- MARKSMAN: Shots Landed
addTieredQuest("marksman", "Marksman", "Land %s Shots", "shots_landed", 100, 200, 100)

-- INFERNO: Kills
addTieredQuest("inferno", "Inferno", "Get %s Kills", "kills", 20, 300, 150)

-- APOCALYPSE: Loot Boxes from Abyss
addTieredQuest("apocalypse", "Apocalypse", "Find %s Abyss Loot Boxes", "abyss_loot", 2, 400, 200)

-- VENDETTA: Time spent in PvE (minutes)
addTieredQuest("vendetta", "Vendetta", "Spend %s minutes in PvE", "pve_time_min", 10, 200, 100)

-- MAYHEM: Shots Fired
addTieredQuest("mayhem", "Mayhem", "Fire %s Shots", "shots_fired", 200, 100, 50)

-- RAMBO: Headshots
addTieredQuest("rambo", "Rambo", "Get %s Headshots", "headshots", 10, 300, 150)

-- ANNIHILATOR: Kills in Abyss
addTieredQuest("annihilator", "Annihilator", "Get %s Kills in Abyss", "abyss_kills", 10, 400, 200)

-- THE VOID: Time spent in Abyss (minutes)
addTieredQuest("the_void", "The Void", "Spend %s minutes in Abyss", "abyss_time_min", 10, 300, 150)

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
