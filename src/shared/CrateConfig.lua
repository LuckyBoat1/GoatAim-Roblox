-- CrateConfig.lua: Configuration for crate system
-- Similar to CSGO case opening with this game's theme

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CrateConfig = {}

-- Each crate type maps to EXACTLY one skin rarity
CrateConfig.CRATE_RARITY = {
	BRONZE   = "common",
	SILVER   = "rare",
	SAPPHIRE = "epic",
	OMEGA    = "legendary",
	RUBY     = "mythic",
}

-- Crate types and their contents (now dynamically populated)
CrateConfig.Crates = {
	BRONZE = {
		name = "Bronze Crate",
		modelName = "Bronze",
		description = "Common weapons and basic skins",
		color = Color3.fromRGB(205, 127, 50), -- Bronze color
		rarity = "uncommon",
		icon = "rbxassetid://0", -- Replace with actual icon
		openCost = 1000,
	},
	
	SILVER = {
		name = "Silver Crate",
		modelName = "Silver",
		description = "Improved weapons with better skins",
		color = Color3.fromRGB(192, 192, 192), -- Silver color
		rarity = "rare",
		icon = "rbxassetid://0",
		openCost = 3000,
	},
	
	SAPPHIRE = {
		name = "Sapphire Crate",
		modelName = "Sapphire",
		description = "Premium weapons with rare skins",
		color = Color3.fromRGB(65, 105, 225), -- Royal Blue
		rarity = "epic",
		icon = "rbxassetid://0",
		openCost = 5000,
	},
	
	OMEGA = {
		name = "Omega Crate",
		modelName = "Omega",
		description = "Elite weapons with legendary skins",
		color = Color3.fromRGB(255, 128, 0), -- Orange
		rarity = "legendary",
		icon = "rbxassetid://0",
		openCost = 10000,
	},

	RUBY = {
		name = "Ruby Crate",
		modelName = "Ruby",
		description = "The ultimate collection",
		color = Color3.fromRGB(220, 20, 60), -- Ruby Red
		rarity = "mythic",
		icon = "rbxassetid://0",
		openCost = 1000,
	},
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

-- Get the exact rarity a crate type drops
function CrateConfig.GetCrateRarity(crateType)
	return CrateConfig.CRATE_RARITY[crateType] or "common"
end

-- Get all skins that match a specific rarity.
-- Uses SkinConfig.GetPoolsByRarity() as the source of truth (the SKINS table),
-- so ALL configured skins are available regardless of whether a model exists in SkinLibrary.
-- SkinLibrary is only used for 3D visuals — missing models show as empty reel slots.
function CrateConfig.GetSkinsForRarity(targetRarity)
	local skins = {}
	local SkinConfig = nil
	pcall(function()
		SkinConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkinConfig"))
	end)

	-- Primary: pull from SkinConfig's SKINS table (all configured/active skins)
	if SkinConfig and SkinConfig.GetPoolsByRarity then
		local pools = SkinConfig.GetPoolsByRarity()
		local pool = pools[targetRarity] or {}
		for _, skinId in ipairs(pool) do
			table.insert(skins, {
				type = "skin",
				name = skinId,
				rarity = targetRarity,
			})
		end
		warn(string.format("[CrateConfig] GetSkinsForRarity('%s'): found %d skins from SkinConfig pool", targetRarity, #skins))
		if #skins > 0 then return skins end
	end

	-- Fallback: scan SkinLibrary models if SkinConfig unavailable
	local skinLib = ReplicatedStorage:FindFirstChild("SkinLibrary")
	if not skinLib then return skins end
	for _, skinModel in pairs(skinLib:GetChildren()) do
		if skinModel:IsA("Model") or skinModel:IsA("BasePart") then
			table.insert(skins, {
				type = "skin",
				name = skinModel.Name,
				rarity = targetRarity,
			})
		end
	end
	return skins
end

-- Roll for an item from a crate (picks only from the crate's rarity)
function CrateConfig.RollCrate(crateType)
	local targetRarity = CrateConfig.GetCrateRarity(crateType)
	local pool = CrateConfig.GetSkinsForRarity(targetRarity)
	if #pool == 0 then
		warn("[CrateConfig] No skins found for rarity:", targetRarity, "in crate:", crateType)
		return nil
	end
	return pool[math.random(1, #pool)]
end

return CrateConfig
