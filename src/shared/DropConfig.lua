--[[
	DropConfig - Define NPC drop tables here
	
	Each NPC can drop multiple items on death with customizable drop rates.
	
	STRUCTURE:
	NPCName = {
		drops = {
			{ itemName = "ItemName", chance = 0.5 },  -- 50% chance to drop
			{ itemName = "ItemName2", chance = 0.25 }, -- 25% chance to drop
		}
	}
	
	CHANCE VALUES:
	- 1 or 100 = 100% guaranteed drop
	- 0.5 or 50 = 50% chance
	- 0.1 or 10 = 10% chance
	- values > 1 are treated as percentages (0-100)
	- values 0-1 are treated as decimal (0-1)
	
	Each item has independent chance - multiple items can drop from same kill!
]]

local DropConfig = {}

-- ============================================================
-- END NPC DROPS
-- ============================================================
DropConfig.End = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.4 },
		{ itemName = "Bronze", chance = 0.3 },
		{ itemName = "Sapphire", chance = 0.15 },
		{ itemName = "Omega", chance = 0.08 },
		{ itemName = "Ruby", chance = 0.02 },
		{ itemName = "EXP", chance = 1 },
	}
}

-- ============================================================
-- BEGINNING NPC DROPS
-- ============================================================
DropConfig.Beginning = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.35 },
		{ itemName = "Bronze", chance = 0.25 },
		{ itemName = "Sapphire", chance = 0.12 },
		{ itemName = "Omega", chance = 0.05 },
		{ itemName = "Ruby", chance = 0.01 },
		{ itemName = "EXP", chance = 1 },
	}
}

-- ============================================================
-- WORLD BREAKER NPC DROPS
-- ============================================================
DropConfig.WorldBreaker = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.42 },
		{ itemName = "Bronze", chance = 0.32 },
		{ itemName = "Sapphire", chance = 0.18 },
		{ itemName = "Omega", chance = 0.1 },
		{ itemName = "Ruby", chance = 0.03 },
		{ itemName = "EXP", chance = 1 },
	}
}

-- ============================================================
-- THE WEEPING KING NPC DROPS
-- ============================================================
DropConfig.TheWeepingKing = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.45 },
		{ itemName = "Bronze", chance = 0.35 },
		{ itemName = "Sapphire", chance = 0.2 },
		{ itemName = "Omega", chance = 0.12 },
		{ itemName = "Ruby", chance = 0.05 },
		{ itemName = "EXP", chance = 1 },
	}
}

-- ============================================================
-- TWO FACE NPC DROPS
-- ============================================================
DropConfig.TwoFace = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.44 },
		{ itemName = "Bronze", chance = 0.34 },
		{ itemName = "Sapphire", chance = 0.19 },
		{ itemName = "Omega", chance = 0.11 },
		{ itemName = "Ruby", chance = 0.04 },
		{ itemName = "EXP", chance = 1 },
	}
}

-- ============================================================
-- DICE NPC DROPS
-- ============================================================
DropConfig.Dice = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.38 },
		{ itemName = "Bronze", chance = 0.28 },
		{ itemName = "Sapphire", chance = 0.14 },
		{ itemName = "Omega", chance = 0.07 },
		{ itemName = "Ruby", chance = 0.01 },
		{ itemName = "EXP", chance = 1 },
	}
}

-- ============================================================
-- OTHER NPCS (Skelly, BabyGhost, MamaGhost, TorsoGhost, Spidy, Robo)
-- ============================================================
DropConfig.Skelly = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.25 },
		{ itemName = "Bronze", chance = 0.18 },
		{ itemName = "Sapphire", chance = 0.08 },
		{ itemName = "Omega", chance = 0.03 },
		{ itemName = "Ruby", chance = 0.005 },
		{ itemName = "EXP", chance = 1 },
	}
}

DropConfig.BabyGhost = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.2 },
		{ itemName = "Bronze", chance = 0.14 },
		{ itemName = "Sapphire", chance = 0.06 },
		{ itemName = "Omega", chance = 0.02 },
		{ itemName = "Ruby", chance = 0.003 },
		{ itemName = "EXP", chance = 1 },
	}
}

DropConfig.MamaGhost = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.32 },
		{ itemName = "Bronze", chance = 0.23 },
		{ itemName = "Sapphire", chance = 0.11 },
		{ itemName = "Omega", chance = 0.05 },
		{ itemName = "Ruby", chance = 0.01 },
		{ itemName = "EXP", chance = 1 },
	}
}

DropConfig.TorsoGhost = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.28 },
		{ itemName = "Bronze", chance = 0.2 },
		{ itemName = "Sapphire", chance = 0.09 },
		{ itemName = "Omega", chance = 0.04 },
		{ itemName = "Ruby", chance = 0.008 },
		{ itemName = "EXP", chance = 1 },
	}
}

DropConfig.Spidy = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.3 },
		{ itemName = "Bronze", chance = 0.22 },
		{ itemName = "Sapphire", chance = 0.1 },
		{ itemName = "Omega", chance = 0.04 },
		{ itemName = "Ruby", chance = 0.008 },
		{ itemName = "EXP", chance = 1 },
	}
}

DropConfig.Robo = {
	drops = {
		{ itemName = "Gold", chance = 1 },
		{ itemName = "Silver", chance = 0.3 },
		{ itemName = "Bronze", chance = 0.22 },
		{ itemName = "Sapphire", chance = 0.1 },
		{ itemName = "Omega", chance = 0.05 },
		{ itemName = "Ruby", chance = 0.009 },
		{ itemName = "EXP", chance = 1 },
	}
}

-- ============================================================
-- Helper function to process drops
-- ============================================================
--[[
	Usage in death script:
	
	local DropConfig = require(ReplicatedStorage.Shared.DropConfig)
	local npcDrops = DropConfig.End  -- Get drop table for End NPC
	
	for _, dropData in ipairs(npcDrops.drops) do
		local chance = dropData.chance
		
		-- Normalize chance (if > 1, treat as percentage)
		if chance > 1 then
			chance = chance / 100
		end
		
		-- Roll for this item
		if math.random() < chance then
			-- Drop the item!
			spawnDropItem(dropData.itemName, npcDeathPosition)
		end
	end
]]

return DropConfig
