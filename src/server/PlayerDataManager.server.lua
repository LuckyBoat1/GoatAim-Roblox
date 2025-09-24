-- PlayerDataManager: Simple player data + skins + boxes + equip glue
-- Compatible with MatrixVault Inventory client (GetPlayerData RF, EquipSkin RE).
-- Seeds some AK/M4 skins as owned by default so they appear in the Inventory grid.
-- Provides _G helpers used by Quests (money/coins, box grant/open, skin grant, stats).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- RemoteEvents folder (match project mapping EXACTLY so clients find it)
local RemoteEvents = RS:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = RS
end

-- Inventory remotes
local GetPlayerDataRF = RemoteEvents:FindFirstChild("GetPlayerData") or Instance.new("RemoteFunction")
GetPlayerDataRF.Name = "GetPlayerData"
GetPlayerDataRF.Parent = RemoteEvents

local EquipSkinRE = RemoteEvents:FindFirstChild("EquipSkin") or Instance.new("RemoteEvent")
EquipSkinRE.Name = "EquipSkin"
EquipSkinRE.Parent = RemoteEvents

-- Player data modification remote function
local PlayerDataRF = RemoteEvents:FindFirstChild("PlayerDataRF") or Instance.new("RemoteFunction")
PlayerDataRF.Name = "PlayerDataRF"
PlayerDataRF.Parent = RemoteEvents

-- Silence other scripts that wait for DuelEvent
if not RS:FindFirstChild("DuelEvent") then
	local ev = Instance.new("RemoteEvent")
	ev.Name = "DuelEvent"
	ev.Parent = RS
end

-- Optional loot box remotes (not used by the new Quests UI, but harmless)
local LootBoxRE = RS:FindFirstChild("LootBoxRE") or Instance.new("RemoteEvent")
LootBoxRE.Name = "LootBoxRE"
LootBoxRE.Parent = RS

-- Config for skin pools (for box openings) – single canonical module lives in RS.Shared
local SkinConfig = nil
pcall(function()
	SkinConfig = require(RS:WaitForChild("Shared"):WaitForChild("SkinConfig"))
end)

-- In-memory player data (simple)
-- Simple Lua tables (kept types implicit for Studio-style simplicity)
local DATA = {} -- [userId] = player data table

local function deepcopy(t)
	if type(t) ~= "table" then return t end
	local o = {}
	for k,v in pairs(t) do
		o[k] = (type(v) == "table") and deepcopy(v) or v
	end
	return o
end

-- Seed some AK/M4 skins (must match ReplicatedStorage/SkinLibrary child names)
local DEFAULT_SKINS = {}

-- Function to populate all skins from SkinConfig
local function populateDefaultSkins()
	-- First, add the hardcoded skins
	local hardcodedSkins = {
		["M4-Dragoon"]     = true,
		["M4-Cyborg"]      = true,
		["M4-Leviathan"]   = true,
		["M4-Death"]       = true,
		["M4-Monster"]     = true,
		["M4-Mind"]        = true,
		["M4-Blood&Bones"] = true,
		["M4-Default"]     = true,
		["M4-Elite"]       = true,
		["AK-Chaos"]       = true,
		["AK-Ice"]         = true,
		["AK-Jungle"]      = true,
		["Luger-Default"]  = true,
		["Luger-Gold"]     = true,
		["Luger-Elite"]    = true,
	}
	
	for skinId, _ in pairs(hardcodedSkins) do
		DEFAULT_SKINS[skinId] = true
	end
	
	-- Now scan SkinLibrary directly on the server
	local skinLibrary = game:GetService("ReplicatedStorage"):FindFirstChild("SkinLibrary")
	if skinLibrary then
		warn(string.format("[PlayerDataManager] Found SkinLibrary with %d children", #skinLibrary:GetChildren()))
		
		local scannedCount = 0
		for _, model in ipairs(skinLibrary:GetChildren()) do
			if model:IsA("Model") or model:IsA("MeshPart") or model:IsA("BasePart") then
				local skinId = model.Name
				if not DEFAULT_SKINS[skinId] then -- Don't overwrite hardcoded ones
					DEFAULT_SKINS[skinId] = true
					scannedCount = scannedCount + 1
					print(string.format("[PlayerDataManager] Added skin from SkinLibrary: %s", skinId))
				end
			end
		end
		
		warn(string.format("[PlayerDataManager] Added %d skins from SkinLibrary", scannedCount))
	else
		warn("[PlayerDataManager] SkinLibrary not found in ReplicatedStorage")
	end
	
	local totalCount = 0
	for _ in pairs(DEFAULT_SKINS) do totalCount = totalCount + 1 end
	warn(string.format("[PlayerDataManager] Total default skins: %d", totalCount))
	
	-- Debug: Print first 15 skins to verify
	local debugCount = 0
	for skinId, _ in pairs(DEFAULT_SKINS) do
		debugCount = debugCount + 1
		if debugCount <= 15 then
			warn(string.format("[PlayerDataManager] Skin %d: %s", debugCount, skinId))
		else
			break
		end
	end
	if totalCount > 15 then
		warn(string.format("[PlayerDataManager] ... and %d more skins", totalCount - 15))
	end
end

-- Call the function to populate default skins
populateDefaultSkins()

local function ensure(plr)
	local d = DATA[plr.UserId]
	if not d then
		d = {
			money = 300000,
			wins = 0,
			battles = 0,
			death = 0,
			losses = 0, 
			trumpCoin = 10,
			rank = 2, -- Default rank is now 1
			skins = deepcopy(DEFAULT_SKINS),
			weaponStats = {},
			boxes = {BASIC=1, BRONZE=1, SILVER=1, GOLD=1, OMEGA=1},
			runHits = 0, -- running hit counter for a session
			bullseyeCurrent = 0, -- current bullseye round score
			bullseyeHigh = 0, -- highest bullseye score achieved
			targetHitTimestamps = {}, -- recent target hit timestamps for rank evaluation
		}
		DATA[plr.UserId] = d
	end
	return d
end

-- Function to give all skins to existing players (for testing)
_G.giveAllSkinsToPlayer = function(plr)
	local d = ensure(plr)
	local count = 0
	for skinId, _ in pairs(DEFAULT_SKINS) do
		if not d.skins[skinId] then
			d.skins[skinId] = true
			count = count + 1
		end
	end
	warn(string.format("[PlayerDataManager] Gave %d new skins to %s", count, plr.Name))
	return count
end

-- Function to give all skins to all players (for testing)
_G.giveAllSkinsToAllPlayers = function()
	local totalGiven = 0
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		totalGiven = totalGiven + _G.giveAllSkinsToPlayer(plr)
	end
	warn(string.format("[PlayerDataManager] Gave skins to all players, total new skins: %d", totalGiven))
	return totalGiven
end

-- Function to refresh DEFAULT_SKINS and give all skins to all players
_G.refreshAllSkins = function()
	-- Re-populate DEFAULT_SKINS by scanning again
	DEFAULT_SKINS = {}
	populateDefaultSkins()
	
	-- Give all the newly found skins to all players
	return _G.giveAllSkinsToAllPlayers()
end

-- Helpers for weapon stats
local function ensureWeaponStats(d, weaponName)
	d.weaponStats[weaponName] = d.weaponStats[weaponName] or {bulletsShot=0, itemsShot=0, timeRolled=0}
	return d.weaponStats[weaponName]
end

-- _G API for other systems (Quests, gameplay)
_G.getData = function(plr) return ensure(plr) end
_G.getDataSnapshot = function(plr) return deepcopy(ensure(plr)) end

_G.addMoney = function(plr, delta)
	local d = ensure(plr)
	d.money = (d.money or 0) + (delta or 0)
end

_G.addTrumpCoins = function(plr, delta)
	local d = ensure(plr)
	d.trumpCoin = (d.trumpCoin or 0) + (delta or 0)
end

_G.setMoney = function(plr, value)
	local d = ensure(plr); d.money = math.max(0, value or 0)
end

_G.setCoins = function(plr, value)
	local d = ensure(plr); d.trumpCoin = math.max(0, value or 0)
end

_G.hasSkin = function(plr, skinId)
	local d = ensure(plr); return d.skins[skinId] == true
end

_G.grantSkin = function(plr, skinId)
	if type(skinId) ~= "string" or skinId == "" then return end
	local d = ensure(plr)
	d.skins[skinId] = true
end

_G.markWeaponSpawned = function(plr, weaponName)
	local d = ensure(plr)
	local ws = ensureWeaponStats(d, weaponName)
	if (ws.timeRolled or 0) == 0 then ws.timeRolled = os.time() end
end

_G.bumpWeaponStats = function(plr, weaponName, deltaBullets, deltaItems)
	local d = ensure(plr)
	local ws = ensureWeaponStats(d, weaponName)
	if deltaBullets then ws.bulletsShot += deltaBullets end
	if deltaItems  then ws.itemsShot   += deltaItems  end
end

-- Loot Boxes (no UI here; Quests can grant and optionally auto-open)
local BOXES = {
	BASIC   = { skinRate=0.04, weights={common=85, rare=12, epic=3,  legendary=0,  mythic=0} },
	BRONZE  = { skinRate=0.07, weights={common=72, rare=22, epic=6,  legendary=0,  mythic=0} },
	SILVER  = { skinRate=0.12, weights={common=58, rare=30, epic=10, legendary=2,  mythic=0} },
	GOLD    = { skinRate=0.25, weights={common=40, rare=32, epic=20, legendary=7,  mythic=1} },
	OMEGA   = { skinRate=0.38, weights={common=25, rare=35, epic=25, legendary=12, mythic=3} },
}
local _ORDER = {"BASIC","BRONZE","SILVER","GOLD","OMEGA"} -- unused order list (reserved)

local function weightedPick(weights)
	local total=0; for _,w in pairs(weights) do total+=w end
	if total <= 0 then return "common" end
	local r = math.random()*total
	for k,w in pairs(weights) do
		if r < w then return k end
		r -= w
	end
	return "common"
end

local function pickSkinFromRarity(rarity)
	if not SkinConfig or not SkinConfig.GetPoolsByRarity then return nil end
	local pools = SkinConfig.GetPoolsByRarity()
	local pool = pools[rarity] or {}
	if #pool == 0 then
		for _, r in ipairs({"mythic","legendary","epic","rare","common"}) do
			if pools[r] and #pools[r] > 0 then pool = pools[r]; break end
		end
	end
	if #pool == 0 then return nil end
	return pool[math.random(1, #pool)]
end

_G.GrantBox = function(plr, tier, count)
	local d = ensure(plr)
	if not BOXES[tier] then return end
	d.boxes[tier] = (d.boxes[tier] or 0) + math.max(1, count or 1)
end

_G.OpenBox = function(plr, tier)
	local d = ensure(plr)
	local conf = BOXES[tier]; if not conf then return {ok=false, err="bad_tier"} end
	if (d.boxes[tier] or 0) <= 0 then return {ok=false, err="no_box"} end
	d.boxes[tier] -= 1

	if math.random() < conf.skinRate then
		local rarity = weightedPick(conf.weights)
		local skinId = pickSkinFromRarity(rarity)
		if not skinId then
			LootBoxRE:FireClient(plr, {type="miss", tier=tier})
			return {ok=true, miss=true}
		end
		local dupe = d.skins[skinId] == true
		d.skins[skinId] = true
		LootBoxRE:FireClient(plr, {type="drop", tier=tier, skinId=skinId, rarity=rarity, dupe=dupe})
		return {ok=true, skinId=skinId, rarity=rarity, dupe=dupe}
	else
		LootBoxRE:FireClient(plr, {type="miss", tier=tier})
		return {ok=true, miss=true}
	end
end

-- Inventory snapshot for client
GetPlayerDataRF.OnServerInvoke = function(plr)
	local d = ensure(plr)
	-- one-time debug log for wiring verification
	if not script:FindFirstChild("_LoggedFirstInvoke") then
		local flag = Instance.new("BoolValue")
		flag.Name = "_LoggedFirstInvoke"
		flag.Parent = script
		local count = 0; if type(d.skins) == "table" then for _ in pairs(d.skins) do count += 1 end end
		warn(("[PDM] GetPlayerData -> money=%s, coins=%s, rank=%s, skins=%d"):format(tostring(d.money), tostring(d.trumpCoin), tostring(d.rank), count))
	end
	return {
		money = d.money,
		trumpCoin = d.trumpCoin,
		rank = d.rank,
		skins = d.skins,              -- MatrixVault reads this and looks up models in ReplicatedStorage/SkinLibrary
		weaponStats = d.weaponStats,  -- For item page stats
		-- boxes are not shown by the Inventory UI, but kept for rewards
		boxes = d.boxes,
		runHits = d.runHits,
		bullseyeCurrent = d.bullseyeCurrent,
		bullseyeHigh = d.bullseyeHigh,
		rankProgress = (_G.getRankProgress and _G.getRankProgress(plr)) or nil,
	}
end

-- Player data modification handler
PlayerDataRF.OnServerInvoke = function(plr, action, data)
	local d = ensure(plr)
	
	if action == "AddCrateItem" then
		-- Add item won from crate to player inventory
		if not data or not data.name then
			warn("[PlayerDataRF] AddCrateItem: Invalid item data")
			return {success = false, error = "Invalid item data"}
		end
		
		-- Add the item to skins
		d.skins[data.name] = true
		warn(string.format("[PlayerDataRF] Added crate item to %s: %s (%s)", plr.Name, data.name, data.rarity))
		return {success = true}
		
	elseif action == "UseCrate" then
		-- Remove crate from inventory and update count
		if not data or not data.crateType then
			warn("[PlayerDataRF] UseCrate: Invalid crate type")
			return {success = false, error = "Invalid crate type"}
		end
		
		local crateType = data.crateType
		
		-- Check if player has the crate in boxes (legacy) or create crates table
		if not d.crates then
			d.crates = {}
		end
		
		-- Check if player has this crate type
		if d.boxes and d.boxes[crateType] and d.boxes[crateType] > 0 then
			d.boxes[crateType] = d.boxes[crateType] - 1
			warn(string.format("[PlayerDataRF] Removed %s from %s's boxes (legacy)", crateType, plr.Name))
		elseif d.crates[crateType] and d.crates[crateType] > 0 then
			d.crates[crateType] = d.crates[crateType] - 1
			warn(string.format("[PlayerDataRF] Removed %s from %s's crates", crateType, plr.Name))
		else
			warn(string.format("[PlayerDataRF] Player %s doesn't have crate type: %s", plr.Name, crateType))
			return {success = false, error = "Player doesn't have this crate"}
		end
		
		return {success = true}
	end
	
	warn(string.format("[PlayerDataRF] Unknown action: %s", tostring(action)))
	return {success = false, error = "Unknown action"}
end

-- Equip skin on a tool (just attribute for client visuals/other systems)
local function findTool(plr, nameMaybe)
	local char = plr.Character
	local backpack = plr:FindFirstChildOfClass("Backpack")

	if nameMaybe and #nameMaybe > 0 then
		if char then
			local t = char:FindFirstChild(nameMaybe)
			if t and t:IsA("Tool") then return t end
		end
		if backpack then
			local t = backpack:FindFirstChild(nameMaybe)
			if t and t:IsA("Tool") then return t end
		end
	end
	if char then
		for _, ch in ipairs(char:GetChildren()) do
			if ch:IsA("Tool") then return ch end
		end
	end
	if backpack then
		for _, ch in ipairs(backpack:GetChildren()) do
			if ch:IsA("Tool") then return ch end
		end
	end
	return nil
end

EquipSkinRE.OnServerEvent:Connect(function(plr, payload)
	warn(string.format("[PlayerDataManager] EquipSkin request from %s with payload: %s", plr.Name, game:GetService("HttpService"):JSONEncode(payload)))
	
	if type(payload) ~= "table" then 
		warn("[PlayerDataManager] Invalid payload - not a table")
		return 
	end
	
	local skinId = payload.skinId
	if type(skinId) ~= "string" or skinId == "" then 
		warn("[PlayerDataManager] Invalid skinId")
		return 
	end
	
	if not _G.hasSkin(plr, skinId) then 
		warn(string.format("[PlayerDataManager] Player %s does not own skin '%s'", plr.Name, skinId))
		return 
	end

	local tool = findTool(plr, payload.toolName)
	if not tool then 
		warn(string.format("[PlayerDataManager] Tool not found for %s (toolName: %s)", plr.Name, tostring(payload.toolName)))
		return 
	end

	warn(string.format("[PlayerDataManager] ✅ Setting SkinId '%s' on tool '%s' for %s", skinId, tool.Name, plr.Name))
	pcall(function()
		tool:SetAttribute("SkinId", skinId)
		warn(string.format("[PlayerDataManager] ✅ SkinId attribute set successfully on %s", tool.Name))
		
		-- Also directly apply the skin using SkinService
		if _G.SkinService and _G.SkinService.ApplySkinToTool then
			_G.SkinService.ApplySkinToTool(tool, skinId)
			warn(string.format("[PlayerDataManager] ✅ Applied skin '%s' to tool '%s' via SkinService", skinId, tool.Name))
		else
			warn("[PlayerDataManager] SkinService not available - skin visual may not apply")
		end
	end)
end)

-- Lifecycle
Players.PlayerAdded:Connect(function(plr) ensure(plr) end)
Players.PlayerRemoving:Connect(function(plr) DATA[plr.UserId] = nil end)

-- FIXED: Use the correct DATA table instead of undefined playerData
-- REMOVED: _G.getData = function(player) return playerData[player.userId] end

-- Add a timestamp to show when the module was loaded
local _currentTime = "2025-08-20 22:27:53"
local _currentUser = "Hulk11121"
