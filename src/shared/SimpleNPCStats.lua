--[[
	SimpleNPCStats.lua
	Centralized configuration for all NPC stats (health, damage, drops, etc.)
	
	USAGE:
	local NPCStats = require(game.ReplicatedStorage.Shared.SimpleNPCStats)
	local config = NPCStats.Spidy
	print(config.HEALTH) -- 100
	print(config.DROPS) -- { {item = "Coin", chance = 1, amount = {5, 10}} }
	
	To disable an NPC from spawning, set NPC_COUNT = 0
]]

local SimpleNPCStats = {}

-- ============================================================
-- DEFAULT VALUES (inherited if not specified)
-- ============================================================
local DEFAULTS = {
	NPC_COUNT = 2,
	HEALTH = 100,
	WALK_SPEED = 16,
	ATTACK_DISTANCE = 50,
	DAMAGE = 10,
	IDLE_TIME = {1, 2},
	WALK_TIME = {3, 6},
	WALK_RADIUS = 300,
	DROPS = {}, -- Default no drops
}

-- Helper to apply defaults
local function withDefaults(config)
	local result = {}
	for key, value in pairs(DEFAULTS) do
		result[key] = value
	end
	for key, value in pairs(config) do
		result[key] = value
	end
	return result
end

-- ============================================================
-- SIMPLE NPCs (Basic AI - Spidy, Ghosts, etc.)
-- ============================================================

-- SPIDY
SimpleNPCStats.Spidy = withDefaults({
	MODEL_NAME = "Spidy",
	NPC_COUNT = 2,
	HEALTH = 100,
	WALK_SPEED = 16,
	ATTACK_DISTANCE = 50,
	DAMAGE = 10,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {5, 10} },
		{ item = "Bronze", chance = 0.08, amount = {1, 1} },
		{ item = "Silver", chance = 0.03, amount = {1, 1} },
		{ item = "Sapphire", chance = 0.01, amount = {1, 1} },
		{ item = "Omega", chance = 0.005, amount = {1, 1} },
		{ item = "Ruby", chance = 0.001, amount = {1, 1} },
	},
})

-- TORSO GHOST
SimpleNPCStats.TorsoGhost = withDefaults({
	MODEL_NAME = "TorsoGhost",
	NPC_COUNT = 2,
	HEALTH = 80,
	WALK_SPEED = 18,
	ATTACK_DISTANCE = 50,
	DAMAGE = 8,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {3, 8} },
		{ item = "Bronze", chance = 0.06, amount = {1, 1} },
		{ item = "Silver", chance = 0.02, amount = {1, 1} },
		{ item = "Sapphire", chance = 0.008, amount = {1, 1} },
		{ item = "Omega", chance = 0.003, amount = {1, 1} },
		{ item = "Ruby", chance = 0.0005, amount = {1, 1} },
	},
})

-- SKELLY
SimpleNPCStats.Skelly = withDefaults({
	MODEL_NAME = "Skelly",
	NPC_COUNT = 2,
	HEALTH = 120,
	WALK_SPEED = 14,
	ATTACK_DISTANCE = 50,
	DAMAGE = 12,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {8, 15} },
		{ item = "Bronze", chance = 0.12, amount = {1, 1} },
		{ item = "Silver", chance = 0.05, amount = {1, 1} },
		{ item = "Sapphire", chance = 0.02, amount = {1, 1} },
		{ item = "Omega", chance = 0.008, amount = {1, 1} },
		{ item = "Ruby", chance = 0.002, amount = {1, 1} },
	},
})

-- ROBO
SimpleNPCStats.Robo = withDefaults({
	MODEL_NAME = "Robo",
	NPC_COUNT = 2,
	HEALTH = 150,
	WALK_SPEED = 12,
	ATTACK_DISTANCE = 50,
	DAMAGE = 15,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {10, 20} },
		{ item = "Bronze", chance = 0.15, amount = {1, 1} },
		{ item = "Silver", chance = 0.08, amount = {1, 1} },
		{ item = "Sapphire", chance = 0.03, amount = {1, 1} },
		{ item = "Omega", chance = 0.01, amount = {1, 1} },
		{ item = "Ruby", chance = 0.003, amount = {1, 1} },
	},
})

-- RED PIGGY
SimpleNPCStats.RedPiggy = withDefaults({
	MODEL_NAME = "RedPiggy",
	NPC_COUNT = 2,
	HEALTH = 90,
	WALK_SPEED = 20,
	ATTACK_DISTANCE = 50,
	DAMAGE = 10,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {5, 12} },
		{ item = "Bronze", chance = 0.08, amount = {1, 1} },
		{ item = "Silver", chance = 0.03, amount = {1, 1} },
		{ item = "Sapphire", chance = 0.01, amount = {1, 1} },
		{ item = "Omega", chance = 0.005, amount = {1, 1} },
		{ item = "Ruby", chance = 0.001, amount = {1, 1} },
	},
})

-- MAMA GHOST
SimpleNPCStats.MamaGhost = withDefaults({
	MODEL_NAME = "MamaGhost",
	NPC_COUNT = 2,
	HEALTH = 200,
	WALK_SPEED = 14,
	ATTACK_DISTANCE = 60,
	DAMAGE = 18,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {15, 25} },
		{ item = "Bronze", chance = 0.20, amount = {1, 1} },
		{ item = "Silver", chance = 0.10, amount = {1, 1} },
		{ item = "Sapphire", chance = 0.04, amount = {1, 1} },
		{ item = "Omega", chance = 0.015, amount = {1, 1} },
		{ item = "Ruby", chance = 0.005, amount = {1, 1} },
	},
})

-- BABY GHOST
SimpleNPCStats.BabyGhost = withDefaults({
	MODEL_NAME = "BabyGhost",
	NPC_COUNT = 2,
	HEALTH = 50,
	WALK_SPEED = 22,
	ATTACK_DISTANCE = 40,
	DAMAGE = 5,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {2, 5} },
		{ item = "Bronze", chance = 0.05, amount = {1, 1} },
		{ item = "Silver", chance = 0.015, amount = {1, 1} },
		{ item = "Sapphire", chance = 0.005, amount = {1, 1} },
		{ item = "Omega", chance = 0.002, amount = {1, 1} },
		{ item = "Ruby", chance = 0.0003, amount = {1, 1} },
	},
})

-- FISH TANK
SimpleNPCStats.FishTank = withDefaults({
	MODEL_NAME = "FishTank",
	NPC_COUNT = 2,
	HEALTH = 100,
	WALK_SPEED = 16,
	ATTACK_DISTANCE = 50,
	DAMAGE = 10,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {5, 10} },
		{ item = "Bronze", chance = 0.08, amount = {1, 1} },
		{ item = "Silver", chance = 0.03, amount = {1, 1} },
		{ item = "Sapphire", chance = 0.01, amount = {1, 1} },
		{ item = "Omega", chance = 0.005, amount = {1, 1} },
		{ item = "Ruby", chance = 0.001, amount = {1, 1} },
	},
})

-- ============================================================
-- BOSS NPCs (Advanced AI from NPCConfig)
-- ============================================================

-- END
SimpleNPCStats.End = withDefaults({
	MODEL_NAME = "End",
	NPC_COUNT = 1,
	HEALTH = 1000,
	WALK_SPEED = 16,
	ATTACK_DISTANCE = 100,
	DAMAGE = 25,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {100, 200} },
		{ item = "Bronze", chance = 0.50, amount = {1, 2} },
		{ item = "Silver", chance = 0.30, amount = {1, 2} },
		{ item = "Sapphire", chance = 0.15, amount = {1, 1} },
		{ item = "Omega", chance = 0.08, amount = {1, 1} },
		{ item = "Ruby", chance = 0.03, amount = {1, 1} },
	},
})

-- THE BEGINNING
SimpleNPCStats.Beginning = withDefaults({
	MODEL_NAME = "Thebeginning",
	NPC_COUNT = 1,
	HEALTH = 1000,
	WALK_SPEED = 16,
	ATTACK_DISTANCE = 100,
	DAMAGE = 25,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {100, 200} },
		{ item = "Bronze", chance = 0.50, amount = {1, 2} },
		{ item = "Silver", chance = 0.30, amount = {1, 2} },
		{ item = "Sapphire", chance = 0.15, amount = {1, 1} },
		{ item = "Omega", chance = 0.08, amount = {1, 1} },
		{ item = "Ruby", chance = 0.03, amount = {1, 1} },
	},
})

-- WORLD BREAKER
SimpleNPCStats.WorldBreaker = withDefaults({
	MODEL_NAME = "World Breaker",
	NPC_COUNT = 1,
	HEALTH = 1500,
	WALK_SPEED = 16,
	ATTACK_DISTANCE = 100,
	DAMAGE = 30,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {150, 300} },
		{ item = "Bronze", chance = 0.60, amount = {1, 2} },
		{ item = "Silver", chance = 0.40, amount = {1, 2} },
		{ item = "Sapphire", chance = 0.20, amount = {1, 1} },
		{ item = "Omega", chance = 0.10, amount = {1, 1} },
		{ item = "Ruby", chance = 0.04, amount = {1, 1} },
	},
})

-- THE WEEPING KING
SimpleNPCStats.TheWeepingKing = withDefaults({
	MODEL_NAME = "The Weeping King",
	NPC_COUNT = 1,
	HEALTH = 2000,
	WALK_SPEED = 16,
	ATTACK_DISTANCE = 100,
	DAMAGE = 35,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {200, 400} },
		{ item = "Bronze", chance = 0.70, amount = {1, 3} },
		{ item = "Silver", chance = 0.50, amount = {1, 2} },
		{ item = "Sapphire", chance = 0.25, amount = {1, 2} },
		{ item = "Omega", chance = 0.12, amount = {1, 1} },
		{ item = "Ruby", chance = 0.05, amount = {1, 1} },
	},
})

-- TWO FACE
SimpleNPCStats.TwoFace = withDefaults({
	MODEL_NAME = "TwoFace",
	NPC_COUNT = 1,
	HEALTH = 1200,
	WALK_SPEED = 16,
	ATTACK_DISTANCE = 100,
	DAMAGE = 28,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {120, 250} },
		{ item = "Bronze", chance = 0.55, amount = {1, 2} },
		{ item = "Silver", chance = 0.35, amount = {1, 2} },
		{ item = "Sapphire", chance = 0.18, amount = {1, 1} },
		{ item = "Omega", chance = 0.09, amount = {1, 1} },
		{ item = "Ruby", chance = 0.035, amount = {1, 1} },
	},
})

-- DICE
SimpleNPCStats.Dice = withDefaults({
	MODEL_NAME = "Dice",
	NPC_COUNT = 1,
	HEALTH = 800,
	WALK_SPEED = 18,
	ATTACK_DISTANCE = 100,
	DAMAGE = 20,
	DROPS = {
		{ item = "Gold", chance = 1, amount = {80, 160} },
		{ item = "Bronze", chance = 0.45, amount = {1, 2} },
		{ item = "Silver", chance = 0.25, amount = {1, 1} },
		{ item = "Sapphire", chance = 0.12, amount = {1, 1} },
		{ item = "Omega", chance = 0.06, amount = {1, 1} },
		{ item = "Ruby", chance = 0.02, amount = {1, 1} },
	},
})

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Get all NPC names
function SimpleNPCStats.GetAllNames()
	local names = {}
	for name, config in pairs(SimpleNPCStats) do
		if type(config) == "table" and config.MODEL_NAME then
			table.insert(names, name)
		end
	end
	return names
end

-- Get config by model name
function SimpleNPCStats.GetByModelName(modelName)
	for _, config in pairs(SimpleNPCStats) do
		if type(config) == "table" and config.MODEL_NAME == modelName then
			return config
		end
	end
	return nil
end

-- Disable all NPCs (set count to 0)
function SimpleNPCStats.DisableAll()
	for name, config in pairs(SimpleNPCStats) do
		if type(config) == "table" and config.NPC_COUNT then
			config.NPC_COUNT = 0
		end
	end
end

-- Enable all NPCs (set count to default)
function SimpleNPCStats.EnableAll(count)
	count = count or DEFAULTS.NPC_COUNT
	for name, config in pairs(SimpleNPCStats) do
		if type(config) == "table" and config.NPC_COUNT ~= nil then
			config.NPC_COUNT = count
		end
	end
end

return SimpleNPCStats
