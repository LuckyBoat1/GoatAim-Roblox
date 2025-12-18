-- SkinConfig.lua: Skins + rarity + icons + ADS settings
-- 5-tier rarity: common < rare < epic < legendary < mythic

local SkinConfig = {}

SkinConfig.RARITY_ORDER = { common=1, rare=2, epic=3, legendary=4, mythic=5 }

-- Default icons per base weapon
local DEFAULT_ICONS = {
	M4        = "rbxassetid://6047992706",
	AK        = "rbxassetid://6048009712",
	Luger     = "rbxassetid://6764432243",
	BattleAxe = "rbxassetid://6764432243",
}

-- Base-weapon ADS defaults
local DEFAULT_ADS = {
	FOV = {
		M4    = 50,
		AK    = 55,
		Luger = 60,
	},
	Grip = {
		M4    = CFrame.new(0, -0.5, -1.2),
		AK    = CFrame.new(0, -0.3, -1.0),
		Luger = CFrame.new(0, -0.2, -0.8),
	},
}

-- Canonical skins list
-- weapon, rarity, icon, adsAllowed, adsGrip, adsFov
local SKINS = {
	-- M4 family
	["M4-Dragoon"]     = { weapon="M4", rarity="rare",      icon="rbxassetid://6047992706", adsAllowed=true,  adsFov=45 },
	["M4-Pumpkin"]     = { weapon="M4", rarity="common",    icon="rbxassetid://6047995673", adsAllowed=true },
	["M4-Leviathan"]   = { weapon="M4", rarity="mythic",    icon="rbxassetid://6047997840", adsAllowed=true },
	["M4-Death"]       = { weapon="M4", rarity="mythic",    icon="rbxassetid://6047999933", adsAllowed=true,  adsGrip=CFrame.new(0,-0.6,-1.3) },
	["M4-Monster"]     = { weapon="M4", rarity="epic",      icon="rbxassetid://6048002208", adsAllowed=false },
	["M4-Mind"]        = { weapon="M4", rarity="epic",      icon="rbxassetid://6048004397", adsAllowed=true },
	["M4-Blood&Bones"] = { weapon="M4", rarity="rare",      icon="rbxassetid://6048006454", adsAllowed=true },

	-- AK family (normalize names to "AK")
	["AK-Chaos"]       = { weapon="AK", rarity="legendary", icon="rbxassetid://6048009712", adsAllowed=false },
	["AK-Ice"]         = { weapon="AK", rarity="rare",      icon="rbxassetid://6048012215", adsAllowed=true },
	["AK-Jungle"]      = { weapon="AK", rarity="common",    icon="rbxassetid://6048014433", adsAllowed=true },
}

-- Name normalization convenience
local function normalizeWeaponName(w)
	if not w then return nil end
	local lw = w:lower()
	if lw == "ak" or lw == "ak47" then return "AK" end
	return w
end

-- Pools cache
local _poolsByRarity = nil
local function buildPools()
	local pools = { common={}, rare={}, epic={}, legendary={}, mythic={} }
	for skinId, meta in pairs(SKINS) do
		local r = (meta.rarity or "common"):lower()
		if not pools[r] then r = "common" end
		table.insert(pools[r], skinId)
	end
	_poolsByRarity = pools
end

-- Public API
function SkinConfig.GetSkinMeta(skinId) return SKINS[skinId] end
function SkinConfig.GetWeaponForSkin(skinId) local m=SKINS[skinId]; return m and m.weapon or nil end
function SkinConfig.GetRarity(skinId) local m=SKINS[skinId]; return m and m.rarity or "common" end

function SkinConfig.GetPoolsByRarity()
	if not _poolsByRarity then buildPools() end
	return _poolsByRarity
end

function SkinConfig.GetAllSkinsForWeapon(weaponName)
	weaponName = normalizeWeaponName(weaponName)
	local out = {}
	for id, m in pairs(SKINS) do
		if m.weapon == weaponName then table.insert(out, id) end
	end
	table.sort(out)
	return out
end

function SkinConfig.HasSkin(playerDataTable, skinId)
	return playerDataTable and playerDataTable.skins and playerDataTable.skins[skinId] == true
end

-- Icons
function SkinConfig.GetSkinIcon(skinId, toolName)
	local meta = SKINS[skinId]
	if meta and meta.icon then return meta.icon end
	local weapon = meta and meta.weapon or normalizeWeaponName(toolName)
	return (weapon and DEFAULT_ICONS[weapon]) or "rbxassetid://6764432243"
end

function SkinConfig.GetAllIconContentIds()
	local ids = {}
	for _, id in pairs(DEFAULT_ICONS) do table.insert(ids, id) end
	for _, m in pairs(SKINS) do if m.icon then table.insert(ids, m.icon) end end
	return ids
end

-- ADS
function SkinConfig.IsADSAllowed(toolName, skinId)
	local meta = SKINS[skinId]
	if meta and meta.adsAllowed ~= nil then return meta.adsAllowed end
	return true
end

function SkinConfig.GetADSGripForSkin(skinId, toolName)
	local meta = SKINS[skinId]
	if meta and meta.adsGrip then return meta.adsGrip end
	local weapon = meta and meta.weapon or normalizeWeaponName(toolName)
	return (weapon and DEFAULT_ADS.Grip[weapon]) or CFrame.new(0, -0.4, -1.0)
end

function SkinConfig.GetADSFOVForSkin(skinId, toolName)
	local meta = SKINS[skinId]
	if meta and meta.adsFov then return meta.adsFov end
	local weapon = meta and meta.weapon or normalizeWeaponName(toolName)
	return (weapon and DEFAULT_ADS.FOV[weapon]) or 55
end

function SkinConfig.GetAllSkins()
	local out = {}
	for id, meta in pairs(SKINS) do
		out[#out+1] = {id=id, weapon=meta.weapon, rarity=meta.rarity, icon=meta.icon}
	end
	table.sort(out, function(a,b)
		if a.weapon == b.weapon then
			local ra = SkinConfig.RARITY_ORDER[a.rarity] or 1
			local rb = SkinConfig.RARITY_ORDER[b.rarity] or 1
			if ra == rb then return a.id < b.id end
			return ra < rb
		end
		return a.weapon < b.weapon
	end)
	return out
end

return SkinConfig
