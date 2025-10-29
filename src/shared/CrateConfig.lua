-- CrateConfig.lua: Configuration for crate system
-- Similar to CSGO case opening with this game's theme

local CrateConfig = {}

-- Hardcoded skins that always work
local GUARANTEED_SKINS = {
	"M4-Dragoon", "M4-Cyborg", "M4-Pumpkin", "M4-Leviathan", "M4-Death", 
	"M4-Monster", "M4-Mind", "M4-Blood&Bones", "M4-Default", "M4-Elite",
	"AK-Chaos", "AK-Ice", "AK-Jungle", "AK-Default", "AK-Fire", "AK-Dragon",
	"Luger-Default", "Luger-Gold", "Luger-Elite", "M4-Galaxy", "AK-Void",
	"M4-Neon", "AK-Plasma", "Glock-Basic", "Glock-Steel", "Glock-Neon"
}

-- Generate crate contents with guaranteed skins
local function generateCrateContents()
	local contents = {}
	local chancePerSkin = math.max(1, math.floor(100 / #GUARANTEED_SKINS))
	
	for _, skinName in ipairs(GUARANTEED_SKINS) do
		table.insert(contents, {
			type = "skin",
			name = skinName,
			chance = chancePerSkin,
			rarity = "common"
		})
	end
	
	return contents
end

-- Crate types and their contents (now dynamically populated)
CrateConfig.Crates = {
	BRONZE = {
		name = "Bronze Crate",
		description = "Common weapons and basic skins",
		color = Color3.fromRGB(205, 127, 50), -- Bronze color
		rarity = "uncommon",
		icon = "rbxassetid://0", -- Replace with actual icon
		openCost = 0, -- Free to open
		contents = nil -- Will be populated dynamically
	},
	
	SILVER = {
		name = "Silver Crate",
		description = "Improved weapons with better skins",
		color = Color3.fromRGB(192, 192, 192), -- Silver color
		rarity = "rare",
		icon = "rbxassetid://0",
		openCost = 100, -- Costs 100 credits
		contents = nil -- Will be populated dynamically
	},
	
	GOLD = {
		name = "Gold Crate",
		description = "Premium weapons with rare skins",
		color = Color3.fromRGB(255, 215, 0), -- Gold color
		rarity = "epic",
		icon = "rbxassetid://0",
		openCost = 250,
		contents = nil -- Will be populated dynamically
	},
	
	OMEGA = {
		name = "Omega Crate",
		description = "Ultimate weapons with mythic skins",
		color = Color3.fromRGB(138, 43, 226), -- Purple/Omega color
		rarity = "legendary",
		icon = "rbxassetid://0",
		openCost = 500,
		contents = nil -- Will be populated dynamically
	},
	
	BASIC = {
		name = "Basic Crate",
		description = "Starter weapons and common items",
		color = Color3.fromRGB(139, 69, 19), -- Brown/Basic color
		rarity = "common",
		icon = "rbxassetid://0",
		openCost = 0,
		contents = nil -- Will be populated dynamically
	}
}

-- Animation settings for crate opening
CrateConfig.OpeningAnimation = {
	spinDuration = 3, -- How long the spinning animation lasts
	itemsToShow = 7, -- Number of items shown in the spinning reel
	spinSpeed = 0.1, -- Speed of item transitions during spin
	slowDownFactor = 0.95, -- How much to slow down each frame
	finalSlowSpeed = 0.5, -- Final slow speed before stopping
}

-- Rarity colors (matches your existing system)
CrateConfig.RarityColors = {
	common = Color3.fromRGB(155, 155, 155), -- Gray
	uncommon = Color3.fromRGB(94, 152, 217), -- Light Blue
	rare = Color3.fromRGB(31, 81, 255), -- Blue
	epic = Color3.fromRGB(163, 53, 238), -- Purple
	legendary = Color3.fromRGB(255, 128, 0), -- Orange
	mythic = Color3.fromRGB(235, 75, 75) -- Red
}

-- Get crate configuration
function CrateConfig.GetCrate(crateType)
	return CrateConfig.Crates[crateType]
end

-- Get all available crates
function CrateConfig.GetAllCrates()
	return CrateConfig.Crates
end

-- Roll for an item from a crate
function CrateConfig.RollCrate(crateType)
	local crate = CrateConfig.Crates[crateType]
	if not crate then return nil end
	
	if not crate.contents or #crate.contents == 0 then
		warn("[CrateConfig] No contents in crate:", crateType)
		return nil
	end
	
	-- Calculate total weight
	local totalChance = 0
	for _, item in ipairs(crate.contents) do
		totalChance = totalChance + item.chance
	end
	
	-- Roll random number
	local roll = math.random() * totalChance
	local currentChance = 0
	
	-- Find which item was rolled
	for _, item in ipairs(crate.contents) do
		currentChance = currentChance + item.chance
		if roll <= currentChance then
			return {
				type = item.type,
				name = item.name,
				rarity = item.rarity,
				crateSource = crateType
			}
		end
	end
	
	-- Fallback to first item if something goes wrong
	local firstItem = crate.contents[1]
	return {
		type = firstItem.type,
		name = firstItem.name,
		rarity = firstItem.rarity,
		crateSource = crateType
	}
end

-- Check if player has enough currency to open crate
function CrateConfig.CanAfford(crateType, playerCredits)
	local crate = CrateConfig.GetCrate(crateType)
	if not crate then return false end
	return playerCredits >= crate.openCost
end

-- Get rarity color
function CrateConfig.GetRarityColor(rarity)
	return CrateConfig.RarityColors[rarity] or CrateConfig.RarityColors.common
end

-- Initialize dynamic crate contents
function CrateConfig.initializeDynamicContents()
	-- Populate each crate type with dynamic contents
	for crateType, crateData in pairs(CrateConfig.Crates) do
		crateData.contents = generateCrateContents()
	end
end

-- Call initialization on load
CrateConfig.initializeDynamicContents()

return CrateConfig
