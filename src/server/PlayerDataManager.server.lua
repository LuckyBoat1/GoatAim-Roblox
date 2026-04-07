-- PlayerDataManager: Simple player data + skins + boxes + equip glue
-- Compatible with MatrixVault Inventory client (GetPlayerData RF, EquipSkin RE).
-- Seeds some AK/M4 skins as owned by default so they appear in the Inventory grid.
-- Provides _G helpers used by Quests (money/coins, box grant/open, skin grant, stats).

------------------------------------------------------------------------
-- ⚙️  SETTING: Set to true to give EVERY skin to all players.
--    Set to false to only give the default / earned skins.
------------------------------------------------------------------------
local GIVE_ALL_ITEMS = false

------------------------------------------------------------------------

print("!!! DEBUG: PlayerDataManager SYNC CHECK " .. os.time() .. " !!!")

-- ── SETTINGS ──────────────────────────────────────────────────────────────
-- Set to true only during development to auto-equip the Power skin on spawn.
local AUTO_EQUIP_POWER = false
-- Set to true to auto-equip a random owned common weapon on every respawn.
local AUTO_EQUIP_STARTER = true

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Warn loudly in Studio if API Services are not enabled
if RunService:IsStudio() then
	warn("[PlayerDataManager] ⚠️  STUDIO MODE: Make sure 'Enable Studio Access to API Services' is ON in Game Settings → Security or DataStore saves will silently fail!")
end

-- Persistent storage (version bump this string when data schema changes incompatibly)
local PlayerStore = DataStoreService:GetDataStore("GoatAimData_v2")  -- bumped to wipe all data

-- OrderedDataStores for global all-time leaderboards (written on every save)
local LB_ClassicScore  = DataStoreService:GetOrderedDataStore("LB_ClassicScore")
local LB_BullseyeScore = DataStoreService:GetOrderedDataStore("LB_BullseyeScore")
local LB_PlaytimeScore = DataStoreService:GetOrderedDataStore("LB_PlaytimeScore")
local LB_KillsScore    = DataStoreService:GetOrderedDataStore("LB_KillsScore")
local LB_WinsScore     = DataStoreService:GetOrderedDataStore("LB_WinsScore")
local LB_GoldScore     = DataStoreService:GetOrderedDataStore("LB_GoldScore")

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

-- Gold earned notification (client floating numbers)
local GoldChangedRE = RemoteEvents:FindFirstChild("GoldChanged") or Instance.new("RemoteEvent")
GoldChangedRE.Name = "GoldChanged"
GoldChangedRE.Parent = RemoteEvents

-- Optional loot box remotes (not used by the new Quests UI, but harmless)
local LootBoxRE = RS:FindFirstChild("LootBoxRE") or Instance.new("RemoteEvent")
LootBoxRE.Name = "LootBoxRE"
LootBoxRE.Parent = RS

-- Config for skin pools (for box openings) – single canonical module lives in RS.Shared
local SkinConfig = nil
local CrateConfig = nil
pcall(function()
	SkinConfig = require(RS:WaitForChild("Shared"):WaitForChild("SkinConfig"))
	CrateConfig = require(RS:WaitForChild("Shared"):WaitForChild("CrateConfig"))
end)

-- In-memory player data (simple)
-- Simple Lua tables (kept types implicit for Studio-style simplicity)
local DATA = {} -- [userId] = player data table

-- If GetAsync errors (not just "new player"), we block all saves for that player.
-- This prevents blank defaults from being written over real data.
local LOAD_FAILED = {}  -- [userId] = true  →  load errored, do NOT save

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
	-- No hardcoded free skins — starter weapon is given via the starterWeaponGiven
	-- flow in Players.PlayerAdded (1 random common weapon per new account).
	-- Leaving DEFAULT_SKINS empty here so no mythic/epic skins are silently granted.
end

-- Call the function to populate default skins
populateDefaultSkins()

-- Build a whitelist of ONLY the active (uncommented) SkinConfig entries.
-- This is the single source of truth: commented-out = not released = not given.
local ACTIVE_SKIN_IDS = {} -- { [skinId] = true }
if SkinConfig then
	local allSkins = SkinConfig.GetAllSkins and SkinConfig.GetAllSkins()
	if allSkins then
		for _, entry in ipairs(allSkins) do
			if entry.id then
				ACTIVE_SKIN_IDS[entry.id] = true
			end
		end
	end
end
local activeSkinCount = 0
for _ in pairs(ACTIVE_SKIN_IDS) do activeSkinCount += 1 end
warn(string.format("[PlayerDataManager] Active SkinConfig entries (whitelist): %d", activeSkinCount))

-- If GIVE_ALL_ITEMS is on, give every ACTIVE skin to new players.
if GIVE_ALL_ITEMS then
	for skinId in pairs(ACTIVE_SKIN_IDS) do
		DEFAULT_SKINS[skinId] = 1
	end
	warn(string.format("[PlayerDataManager] GIVE_ALL_ITEMS: DEFAULT_SKINS now has %d skins", activeSkinCount))
end

local function ensure(plr)
	local d = DATA[plr.UserId]
	if not d then
		d = {
			money = 1000,                           -- No starter gold
			wins = 0,
			battles = 0,
			death = 0,
			losses = 0,
			winstreak = 0, 
			trumpCoin = 0,
			exp = 0,                             -- Total EXP (drives rank progression)
			lvl = 1,                             -- Player level (derived from EXP)
			rank = 0,                            -- Default rank
			starterWeaponGiven = false,         -- Will be set true after first weapon is granted
			skins = {},                          -- No starter skins
			weaponStats = {},
			boxes = {BRONZE=0, SILVER=1, SAPPHIRE=0, OMEGA=0, RUBY=0}, -- 1 free Silver crate only
			runHits = 0, -- running hit counter for a session
			bullseyeCurrent = 0, -- current bullseye round score
			bullseyeHigh = 0, -- highest bullseye score achieved
			targetHitTimestamps = {}, -- recent target hit timestamps for rank evaluation
			
			-- Storage (second inventory accessible from HQ)
			storage = {}, -- { [skinId] = count }
			crateStorage = {}, -- { [crateType] = count }
			
			-- Health & Armor Stats (for PvE and The Abyss)
			maxHealth = 100, -- Base max health
			currentHealth = 100, -- Current health (full by default)
			armor = 0, -- Armor value (reduces damage)
			healthUpgradeLevel = 0, -- Track health upgrade progression
			armorUpgradeLevel = 0, -- Track armor upgrade progression
			
			-- HQ Upgrade Tree: Passive (AFK) Upgrades
			goldPerSecondLevel = 0, -- Passive gold generation
			refinerSpeedLevel = 0, -- Refiner efficiency (faster crate production)
			
			-- HQ Upgrade Tree: Active Upgrades
			pvpGoldBonusLevel = 0, -- Bonus gold from PVP kills
			abyssGoldBonusLevel = 0, -- Bonus gold from Abyss kills
			pveGoldBonusLevel = 0, -- Bonus gold from PvE kills
			playTimeBonusLevel = 0, -- Bonus gold for time spent in game
			totalPlaytime = 0, -- Total playtime in seconds (across sessions)

			-- Crafting Materials
			commonMaterials    = 0,
			rareMaterials      = 0,
			epicMaterials      = 0,
			legendaryMaterials = 0,
			mythicMaterials    = 0,

			-- Supply Drop
			supplyDropTier        = 1, -- Current tier (1 = Bronze ... 7 = Ruby)
			supplyDropLastClaimed = 0, -- Unix timestamp of last successful claim
		}
		DATA[plr.UserId] = d
	end

	-- Schema migration: patch any keys added after this player's data was first saved.
	-- Safe to run on both new and loaded players ("or" won't overwrite existing values).
	local d = DATA[plr.UserId]
	d.money               = d.money               or 0
	d.wins                = d.wins                or 0
	d.battles             = d.battles             or 0
	d.death               = d.death               or 0
	d.losses              = d.losses              or 0
	d.winstreak           = d.winstreak           or 0
	d.trumpCoin           = d.trumpCoin           or 0
	d.exp                 = d.exp                 or 0
	d.lvl                 = d.lvl                 or 1
	d.rank                = d.rank                or 0
	if d.starterWeaponGiven == nil then d.starterWeaponGiven = false end
	d.skins               = d.skins               or deepcopy(DEFAULT_SKINS)
	d.weaponStats         = d.weaponStats         or {}
	d.boxes               = d.boxes               or {BRONZE=0, SILVER=0, SAPPHIRE=0, OMEGA=0, RUBY=0}
	d.runHits             = d.runHits             or 0
	d.bullseyeCurrent     = d.bullseyeCurrent     or 0
	d.bullseyeHigh        = d.bullseyeHigh        or 0
	d.targetHitTimestamps = d.targetHitTimestamps or {}
	d.storage             = d.storage             or {}
	d.crateStorage        = d.crateStorage        or {}
	d.maxHealth           = d.maxHealth           or 100
	d.currentHealth       = d.currentHealth       or 100
	d.armor               = d.armor               or 0
	d.healthUpgradeLevel  = d.healthUpgradeLevel  or 0
	d.armorUpgradeLevel   = d.armorUpgradeLevel   or 0
	d.goldPerSecondLevel  = d.goldPerSecondLevel  or 0
	d.refinerSpeedLevel   = d.refinerSpeedLevel   or 0
	d.pvpGoldBonusLevel   = d.pvpGoldBonusLevel   or 0
	d.abyssGoldBonusLevel = d.abyssGoldBonusLevel or 0
	d.pveGoldBonusLevel   = d.pveGoldBonusLevel   or 0
	d.playTimeBonusLevel  = d.playTimeBonusLevel  or 0
	d.totalPlaytime       = d.totalPlaytime       or 0
	d.commonMaterials     = d.commonMaterials     or 100
	d.rareMaterials       = d.rareMaterials       or 100
	d.epicMaterials       = d.epicMaterials       or 100
	d.legendaryMaterials  = d.legendaryMaterials  or 100
	d.mythicMaterials     = d.mythicMaterials     or 100
	d.supplyDropTier        = d.supplyDropTier        or 1
	d.supplyDropLastClaimed = d.supplyDropLastClaimed or 0

	return d
end

-- ── DATASTORE HELPERS ─────────────────────────────────────────────────────

-- Recursively strips any value that Roblox DataStore cannot serialize.
-- FIX: use explicit type check instead of "and t or nil" so boolean false
-- is kept (the "and/or" idiom converts false → nil, silently dropping it).
local function sanitize(v)
	local t = type(v)
	if t == "string" or t == "number" or t == "boolean" then
		return v  -- primitives kept as-is, including false
	elseif t == "table" then
		local out = {}
		for k, child in pairs(v) do
			if type(k) ~= "string" and type(k) ~= "number" then continue end
			local sv = sanitize(child)
			if sv ~= nil then
				out[k] = sv
			end
		end
		return out
	end
	-- Instance, Vector3, function, thread, userdata → drop silently
	return nil
end

local function saveData(plr)
	-- Safety: if loading errored for this player, never write blank defaults over their real data.
	if LOAD_FAILED[plr.UserId] then
		warn(string.format("[PlayerDataManager] ⛔ BLOCKED save for %s — their data failed to load (DataStore error). Real data is protected.", plr.Name))
		return
	end

	local d = DATA[plr.UserId]
	if not d then
		warn("[PlayerDataManager] saveData: no data for", plr.Name)
		return
	end

	-- Clean snapshot — never pass live table or non-serializable values to DataStore
	local snapshot = sanitize(deepcopy(d))

	-- SetAsync is simpler and more predictable for full-table overwrites.
	-- UpdateAsync's callback can fire multiple times on retry; SetAsync does not.
	local ok, err = pcall(function()
		PlayerStore:SetAsync(plr.UserId, snapshot)  -- use number key (consistent)
	end)

	if ok then
		warn(string.format("[PlayerDataManager] ✅ SAVED %s | gold=%s | skins=%d | silver_boxes=%s",
			plr.Name,
			tostring(snapshot.money),
			(function() local n = 0; for _ in pairs(snapshot.skins or {}) do n += 1 end; return n end)(),
			tostring((snapshot.boxes or {}).SILVER)
		))
		-- Write to leaderboard OrderedDataStores (positive integers only)
		task.spawn(function()
			if (snapshot.runHits or 0) > 0 then
				pcall(function() LB_ClassicScore:SetAsync(plr.UserId, math.floor(snapshot.runHits)) end)
			end
			if (snapshot.bullseyeHigh or 0) > 0 then
				pcall(function() LB_BullseyeScore:SetAsync(plr.UserId, math.floor(snapshot.bullseyeHigh)) end)
			end
			if (snapshot.totalPlaytime or 0) > 0 then
				pcall(function() LB_PlaytimeScore:SetAsync(plr.UserId, math.floor(snapshot.totalPlaytime)) end)
			end
			if (snapshot.battles or 0) > 0 then
				pcall(function() LB_KillsScore:SetAsync(plr.UserId, math.floor(snapshot.battles)) end)
			end
			if (snapshot.wins or 0) > 0 then
				pcall(function() LB_WinsScore:SetAsync(plr.UserId, math.floor(snapshot.wins)) end)
			end
			if (snapshot.money or 0) > 0 then
				pcall(function() LB_GoldScore:SetAsync(plr.UserId, math.floor(snapshot.money)) end)
			end
		end)
	else
		warn("[PlayerDataManager] ❌ SAVE FAILED for", plr.Name, "→", tostring(err))
		warn("[PlayerDataManager] ⚠️  Studio: Game Settings → Security → 'Enable Studio Access to API Services'")
	end
end

local function loadData(plr)
	-- Try number key first (current format)
	local loadErrored = false
	local ok, result = pcall(function()
		return PlayerStore:GetAsync(plr.UserId)
	end)
	if not ok then
		warn("[PlayerDataManager] ❌ LOAD FAILED (number key) for", plr.Name, "→", tostring(result))
		loadErrored = true
		result = nil
	end

	-- Fallback: old string key (pre-fix versions saved with tostring(UserId))
	if result == nil then
		local ok2, result2 = pcall(function()
			return PlayerStore:GetAsync(tostring(plr.UserId))
		end)
		if ok2 and result2 ~= nil then
			warn("[PlayerDataManager] ⚠️  Found data under OLD string key for", plr.Name, "— migrating to number key")
			result = result2
			loadErrored = false -- found it under string key, not a real error
			-- Immediately re-save under the number key so future loads use it
			local ok3, err3 = pcall(function()
				PlayerStore:SetAsync(plr.UserId, sanitize(deepcopy(result2)))
			end)
			if ok3 then
				warn("[PlayerDataManager] ✅ Migrated", plr.Name, "to number key")
			else
				warn("[PlayerDataManager] ❌ Migration save failed for", plr.Name, "→", tostring(err3))
			end
		end
	end

	if result ~= nil then
		warn(string.format("[PlayerDataManager] ✅ LOADED %s | gold=%s | skins=%d",
			plr.Name,
			tostring(result.money),
			(function() local n = 0; for _ in pairs(result.skins or {}) do n += 1 end; return n end)()
		))
	elseif loadErrored then
		warn("[PlayerDataManager] ⚠️  LOAD ERRORED for", plr.Name, "— data protected, will retry")
	else
		warn("[PlayerDataManager] ℹ️  No save found for", plr.Name, "— fresh account")
	end
	return result, loadErrored
end

-- Function to give all skins to existing players (for testing)
_G.giveAllSkinsToPlayer = function(plr)
	local d = ensure(plr)
	local count = 0
	for skinId, _ in pairs(DEFAULT_SKINS) do
		if not d.skins[skinId] then
			d.skins[skinId] = 1
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
	if (delta or 0) > 0 then
		pcall(function() GoldChangedRE:FireClient(plr, delta, "reward") end)
	end
end

_G.addExp = function(plr, delta)
	local d = ensure(plr)
	d.exp = (d.exp or 0) + (delta or 0)
	d.lvl = d.lvl or 1
	-- Auto level-up: 100 * currentLevel EXP per level
	while d.exp >= (100 * d.lvl) do
		d.exp = d.exp - (100 * d.lvl)
		d.lvl = d.lvl + 1
	end
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
	local d = ensure(plr); return d.skins[skinId] ~= nil
end

_G.grantSkin = function(plr, skinId)
	if type(skinId) ~= "string" or skinId == "" then return end
	local d = ensure(plr)
	d.skins[skinId] = (d.skins[skinId] or 0) + 1
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

-- Loot Boxes — each crate gives ONLY its own rarity (100% skin drop)
local BOXES = {
	BRONZE   = { skinRate=1.0, weights={common=100, rare=0,   epic=0,   legendary=0,   mythic=0}   },  -- Common only
	SILVER   = { skinRate=1.0, weights={common=0,   rare=100, epic=0,   legendary=0,   mythic=0}   },  -- Rare only
	SAPPHIRE = { skinRate=1.0, weights={common=0,   rare=0,   epic=100, legendary=0,   mythic=0}   },  -- Epic only
	OMEGA    = { skinRate=1.0, weights={common=0,   rare=0,   epic=0,   legendary=100, mythic=0}   },  -- Legendary only
	RUBY     = { skinRate=1.0, weights={common=0,   rare=0,   epic=0,   legendary=0,   mythic=100} },  -- Mythic only
}
local _ORDER = {"BRONZE","SILVER","SAPPHIRE","OMEGA","RUBY"} -- unused order list (reserved)

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
		local dupe = d.skins[skinId] ~= nil
		d.skins[skinId] = (d.skins[skinId] or 0) + 1
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
	-- Build a filtered copy for the client — never mutate d.skins in-place.
	-- Removing skins from the actual DATA table would permanently lose them.
	local filteredSkins
	if next(ACTIVE_SKIN_IDS) then -- only filter if whitelist loaded successfully
		filteredSkins = {}
		for skinId, qty in pairs(d.skins) do
			if ACTIVE_SKIN_IDS[skinId] then
				filteredSkins[skinId] = qty
			end
		end
	else
		-- Whitelist empty (SkinConfig unavailable) — return all skins unfiltered
		filteredSkins = d.skins
	end
	-- one-time debug log for wiring verification
	if not script:FindFirstChild("_LoggedFirstInvoke") then
		local flag = Instance.new("BoolValue")
		flag.Name = "_LoggedFirstInvoke"
		flag.Parent = script
		local count = 0; if type(d.skins) == "table" then for _, q in pairs(d.skins) do count += (type(q) == "number" and q or 1) end end
		warn(("[PDM] GetPlayerData -> money=%s, coins=%s, rank=%s, skins=%d"):format(tostring(d.money), tostring(d.trumpCoin), tostring(d.rank), count))
	end
	-- Compute derived HQ stats
	local goldPerSec = (d.goldPerSecondLevel or 0) * 6 -- +6 gold/sec per level
	local activeRefiners = 0
	local refinersFolder = workspace:FindFirstChild("Refiners")
	if refinersFolder then
		for _, inst in ipairs(refinersFolder:GetChildren()) do
			local progressFlag = plr:FindFirstChild("RefinerProgress") and plr.RefinerProgress:FindFirstChild(inst.Name)
			if progressFlag and progressFlag.Value then
				activeRefiners = activeRefiners + 1
			end
		end
	end
	local refinerSpeedMult = 1 + (d.refinerSpeedLevel or 0) * 0.15 -- +15% speed per level
	local cratesPerDay = activeRefiners * refinerSpeedMult

	return {
		money = d.money,
		trumpCoin = d.trumpCoin,
		exp = d.exp or 0,
		lvl = d.lvl or 1,
		rank = d.rank,
		skins = filteredSkins,
		weaponStats = d.weaponStats,
		boxes = d.boxes,
		runHits = d.runHits,
		bullseyeCurrent = d.bullseyeCurrent,
		bullseyeHigh = d.bullseyeHigh,
		rankProgress = (_G.getRankProgress and _G.getRankProgress(plr)) or nil,
		-- PvP stats
		wins = d.wins or 0,
		losses = d.losses or 0,
		death = d.death or 0,
		battles = d.battles or 0,
		winstreak = d.winstreak or 0,
		-- Storage
		storage = d.storage or {},
		crateStorage = d.crateStorage or {},
		-- HQ Stats
		maxHealth = d.maxHealth or 100,
		armor = d.armor or 0,
		goldPerSecond = goldPerSec,
		cratesPerDay = cratesPerDay,
		-- Upgrade levels (for UI)
		healthUpgradeLevel = d.healthUpgradeLevel or 0,
		armorUpgradeLevel = d.armorUpgradeLevel or 0,
		goldPerSecondLevel = d.goldPerSecondLevel or 0,
		refinerSpeedLevel = d.refinerSpeedLevel or 0,
		pvpGoldBonusLevel = d.pvpGoldBonusLevel or 0,
		abyssGoldBonusLevel = d.abyssGoldBonusLevel or 0,
		pveGoldBonusLevel = d.pveGoldBonusLevel or 0,
		playTimeBonusLevel = d.playTimeBonusLevel or 0,
		totalPlaytime = d.totalPlaytime or 0,
		-- Crafting Materials
		commonMaterials    = d.commonMaterials or 0,
		rareMaterials      = d.rareMaterials or 0,
		epicMaterials      = d.epicMaterials or 0,
		legendaryMaterials = d.legendaryMaterials or 0,
		mythicMaterials    = d.mythicMaterials or 0,
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

		local targetName = data.name

		-- Validate the skin is active (in SkinConfig's SKINS table).
		-- SkinLibrary may contain models that are commented-out / unreleased.
		-- If the rolled skin isn't active, substitute a random active skin of the same rarity.
		if next(ACTIVE_SKIN_IDS) and not ACTIVE_SKIN_IDS[targetName] then
			warn(string.format("[PlayerDataRF] AddCrateItem: '%s' not in whitelist, finding substitute", targetName))
			local targetRarity = (data.rarity or "common"):lower()
			local pool = SkinConfig and SkinConfig.GetPoolsByRarity and SkinConfig.GetPoolsByRarity()
			local candidates = pool and pool[targetRarity] or {}
			if #candidates > 0 then
				targetName = candidates[math.random(1, #candidates)]
				warn(string.format("[PlayerDataRF] AddCrateItem: substituted '%s' (%s)", targetName, targetRarity))
			else
				-- Last-resort: pick any active skin
				local anyPool = {}
				for id in pairs(ACTIVE_SKIN_IDS) do table.insert(anyPool, id) end
				if #anyPool > 0 then
					targetName = anyPool[math.random(1, #anyPool)]
					warn(string.format("[PlayerDataRF] AddCrateItem: last-resort substitute '%s'", targetName))
				else
					warn("[PlayerDataRF] AddCrateItem: no valid substitute found")
					return {success = false, error = "No valid skin available"}
				end
			end
		end

		-- Add the skin to inventory
		d.skins[targetName] = (d.skins[targetName] or 0) + 1
		warn(string.format("[PlayerDataRF] Added crate item to %s: %s (requested: %s, rarity: %s)",
			plr.Name, targetName, data.name, data.rarity or "?"))
		return {success = true, grantedName = targetName}
		
	elseif action == "BuyItem" then
		local itemKey = data.itemKey
		if not CrateConfig or not CrateConfig.Crates then
			return {success = false, error = "Server config error"}
		end

		local crateData = CrateConfig.Crates[itemKey]
		if not crateData then
			return {success = false, error = "Invalid item"}
		end
		
		local price = crateData.openCost or 0
		if (d.money or 0) >= price then
			d.money = d.money - price
			-- Grant the crate
			d.boxes[itemKey] = (d.boxes[itemKey] or 0) + 1
			warn(string.format("[PlayerDataRF] %s bought %s for $%d", plr.Name, itemKey, price))
			return {success = true, newBalance = d.money}
		else
			return {success = false, error = "Insufficient funds"}
		end

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
	
	elseif action == "MoveAllToStorage" then
		-- Bulk move ALL inventory skins to storage in one call
		if not d.storage then d.storage = {} end
		local count = 0
		for skinId, qty in pairs(d.skins) do
			d.storage[skinId] = (d.storage[skinId] or 0) + (type(qty) == "number" and qty or 1)
			count = count + (type(qty) == "number" and qty or 1)
		end
		-- Clear all skins from inventory
		d.skins = {}
		warn(string.format("[PlayerDataRF] %s moved ALL %d skins to storage", plr.Name, count))
		return {success = true, count = count}
	
	elseif action == "MoveToStorage" then
		-- Move ONE copy from inventory (skins) to storage
		if not data or not data.skinId then
			return {success = false, error = "No skinId provided"}
		end
		local skinId = data.skinId
		if not d.skins[skinId] then
			return {success = false, error = "Item not in inventory"}
		end
		if not d.storage then d.storage = {} end
		-- Decrement inventory (remove entry if 0)
		local qty = type(d.skins[skinId]) == "number" and d.skins[skinId] or 1
		if qty <= 1 then
			d.skins[skinId] = nil
		else
			d.skins[skinId] = qty - 1
		end
		d.storage[skinId] = (d.storage[skinId] or 0) + 1
		warn(string.format("[PlayerDataRF] %s moved %s to storage", plr.Name, skinId))
		return {success = true}
		
	elseif action == "MoveFromStorage" then
		-- Move ONE copy from storage back to inventory (skins)
		if not data or not data.skinId then
			return {success = false, error = "No skinId provided"}
		end
		local skinId = data.skinId
		if not d.storage then d.storage = {} end
		if not d.storage[skinId] then
			return {success = false, error = "Item not in storage"}
		end
		-- Decrement storage (remove entry if 0)
		local qty = type(d.storage[skinId]) == "number" and d.storage[skinId] or 1
		if qty <= 1 then
			d.storage[skinId] = nil
		else
			d.storage[skinId] = qty - 1
		end
		d.skins[skinId] = (d.skins[skinId] or 0) + 1
		warn(string.format("[PlayerDataRF] %s moved %s from storage to inventory", plr.Name, skinId))
		return {success = true}

	elseif action == "MoveCrateToStorage" then
		-- Move ONE crate from boxes (inventory) to crateStorage
		if not data or not data.crateType then
			return {success = false, error = "No crateType provided"}
		end
		local crateType = data.crateType
		if not d.crateStorage then d.crateStorage = {} end
		-- Consume from boxes first, then legacy crates table
		if d.boxes and d.boxes[crateType] and d.boxes[crateType] > 0 then
			d.boxes[crateType] = d.boxes[crateType] - 1
		elseif d.crates and d.crates[crateType] and d.crates[crateType] > 0 then
			d.crates[crateType] = d.crates[crateType] - 1
		else
			return {success = false, error = "Crate not in inventory"}
		end
		d.crateStorage[crateType] = (d.crateStorage[crateType] or 0) + 1
		warn(string.format("[PlayerDataRF] %s moved crate %s to storage", plr.Name, crateType))
		return {success = true}

	elseif action == "MoveCrateFromStorage" then
		-- Move ONE crate from crateStorage back to boxes (inventory)
		if not data or not data.crateType then
			return {success = false, error = "No crateType provided"}
		end
		local crateType = data.crateType
		if not d.crateStorage then d.crateStorage = {} end
		local storedQty = d.crateStorage[crateType] or 0
		if storedQty <= 0 then
			return {success = false, error = "Crate not in storage"}
		end
		d.crateStorage[crateType] = storedQty - 1
		if d.crateStorage[crateType] <= 0 then d.crateStorage[crateType] = nil end
		d.boxes[crateType] = (d.boxes[crateType] or 0) + 1
		warn(string.format("[PlayerDataRF] %s retrieved crate %s from storage", plr.Name, crateType))
		return {success = true}
	
	elseif action == "HQUpgrade" then
		-- Headquarters skill tree upgrade system
		if not data or not data.upgradeKey then
			return {success = false, error = "No upgradeKey provided"}
		end
		local key = data.upgradeKey
		
		-- Upgrade configs: { dataField, maxLevel, costs, applyFn }
		local UPGRADE_CONFIGS = {
			health = {
				field = "healthUpgradeLevel", maxLevel = 5,
				costs = {1000, 3000, 7000, 15000, 30000},
				apply = function(dd, lvl)
					dd.maxHealth = 100 + (lvl * 20)
					dd.currentHealth = dd.maxHealth
				end,
			},
			armor = {
				field = "armorUpgradeLevel", maxLevel = 5,
				costs = {2000, 5000, 10000, 20000, 40000},
				apply = function(dd, lvl)
					dd.armor = lvl * 10
				end,
			},
			goldPerSecond = {
				field = "goldPerSecondLevel", maxLevel = 10,
				costs = {500, 1500, 4000, 8000, 15000, 25000, 40000, 65000, 100000, 150000},
				apply = function() end, -- computed on read
			},
			refinerSpeed = {
				field = "refinerSpeedLevel", maxLevel = 10,
				costs = {2000, 5000, 12000, 25000, 50000, 80000, 120000, 175000, 250000, 400000},
				apply = function() end, -- computed on read
			},
			pvpGoldBonus = {
				field = "pvpGoldBonusLevel", maxLevel = 10,
				costs = {1000, 2500, 5000, 10000, 18000, 30000, 50000, 80000, 120000, 200000},
				apply = function() end,
			},
			abyssGoldBonus = {
				field = "abyssGoldBonusLevel", maxLevel = 10,
				costs = {1000, 2500, 5000, 10000, 18000, 30000, 50000, 80000, 120000, 200000},
				apply = function() end,
			},
			pveGoldBonus = {
				field = "pveGoldBonusLevel", maxLevel = 10,
				costs = {1000, 2500, 5000, 10000, 18000, 30000, 50000, 80000, 120000, 200000},
				apply = function() end,
			},
			playTimeBonus = {
				field = "playTimeBonusLevel", maxLevel = 10,
				costs = {800, 2000, 4500, 9000, 16000, 28000, 45000, 70000, 110000, 180000},
				apply = function() end,
			},
		}
		
		local cfg = UPGRADE_CONFIGS[key]
		if not cfg then
			return {success = false, error = "Invalid upgrade key: " .. tostring(key)}
		end
		
		local currentLevel = d[cfg.field] or 0
		if currentLevel >= cfg.maxLevel then
			return {success = false, reason = "max_level", level = currentLevel}
		end
		
		local cost = cfg.costs[currentLevel + 1]
		if not cost then
			return {success = false, reason = "max_level", level = currentLevel}
		end
		
		if (d.money or 0) < cost then
			return {success = false, reason = "insufficient_funds", cost = cost, money = d.money}
		end
		
		-- Apply upgrade
		d.money = d.money - cost
		d[cfg.field] = currentLevel + 1
		cfg.apply(d, currentLevel + 1)
		
		warn(string.format("[PlayerDataRF] %s upgraded %s to level %d for $%d", plr.Name, key, currentLevel + 1, cost))
		return {
			success = true,
			level = currentLevel + 1,
			cost = cost,
			newMoney = d.money,
		}
	
	elseif action == "CraftWeapon" then
		-- Craft a random weapon of the given rarity, consuming 10 materials
		if not data or not data.rarity then
			return {success = false, error = "No rarity provided"}
		end
		local rarity = data.rarity
		local MATERIAL_KEYS = {
			common    = "commonMaterials",
			rare      = "rareMaterials",
			epic      = "epicMaterials",
			legendary = "legendaryMaterials",
			mythic    = "mythicMaterials",
		}
		local matKey = MATERIAL_KEYS[rarity]
		if not matKey then
			return {success = false, error = "Invalid rarity"}
		end
		local CRAFT_COST = 10
		local current = d[matKey] or 0
		if current < CRAFT_COST then
			return {success = false, error = "Not enough materials", have = current, need = CRAFT_COST}
		end
		-- Pick a random skin of this rarity from SkinConfig
		if not SkinConfig or not SkinConfig.GetPoolsByRarity then
			return {success = false, error = "SkinConfig not loaded"}
		end
		local pools = SkinConfig.GetPoolsByRarity()
		local pool = pools[rarity] or {}
		if #pool == 0 then
			return {success = false, error = "No skins for rarity: " .. rarity}
		end
		local skinId = pool[math.random(1, #pool)]
		-- Deduct materials
		d[matKey] = current - CRAFT_COST
		-- Add skin to inventory
		d.skins[skinId] = (d.skins[skinId] or 0) + 1
		warn(string.format("[PlayerDataRF] %s crafted %s (%s) for %d %s materials", plr.Name, skinId, rarity, CRAFT_COST, rarity))
		return {
			success = true,
			skinId = skinId,
			rarity = rarity,
			materialsLeft = d[matKey],
		}

	elseif action == "DisassembleWeapon" then
		-- Disassemble a weapon: gives 2 materials of same grade + 1 of higher grade
		if not data or not data.skinId then
			return {success = false, error = "No skinId provided"}
		end
		local skinId = data.skinId

		-- Check ownership
		if not d.skins[skinId] or d.skins[skinId] <= 0 then
			return {success = false, error = "You don't own this weapon"}
		end

		-- Get rarity from SkinConfig
		if not SkinConfig or not SkinConfig.GetSkinMeta then
			return {success = false, error = "SkinConfig not loaded"}
		end
		local meta = SkinConfig.GetSkinMeta(skinId)
		if not meta or not meta.rarity then
			return {success = false, error = "Unknown weapon rarity"}
		end
		local rarity = meta.rarity:lower()

		local MATERIAL_KEYS = {
			common    = "commonMaterials",
			rare      = "rareMaterials",
			epic      = "epicMaterials",
			legendary = "legendaryMaterials",
			mythic    = "mythicMaterials",
		}
		-- Higher grade mapping
		local NEXT_RARITY = {
			common    = "rare",
			rare      = "epic",
			epic      = "legendary",
			legendary = "mythic",
			mythic    = "mythic", -- no higher grade, extra mythic instead
		}

		local sameKey = MATERIAL_KEYS[rarity]
		local higherRarity = NEXT_RARITY[rarity]
		local higherKey = MATERIAL_KEYS[higherRarity]

		if not sameKey or not higherKey then
			return {success = false, error = "Invalid rarity: " .. rarity}
		end

		-- Remove one copy of the weapon
		d.skins[skinId] = d.skins[skinId] - 1
		if d.skins[skinId] <= 0 then
			d.skins[skinId] = nil
		end

		-- Award materials: 2 same grade + 1 higher grade
		d[sameKey] = (d[sameKey] or 0) + 2
		d[higherKey] = (d[higherKey] or 0) + 1

		warn(string.format("[PlayerDataRF] %s disassembled %s (%s) → +2 %s, +1 %s",
			plr.Name, skinId, rarity, rarity, higherRarity))
		return {
			success = true,
			skinId = skinId,
			rarity = rarity,
			sameGrade = rarity,
			sameAmount = 2,
			higherGrade = higherRarity,
			higherAmount = 1,
			materialsAfter = {
				[sameKey] = d[sameKey],
				[higherKey] = d[higherKey],
			},
		}
	elseif action == "EnsureCommonSkin" then
		-- Returns a common skinId the player owns.
		-- If they don't own any common, grants one randomly (free — it's a starter).
		local commonPool = {}
		if SkinConfig and SkinConfig.GetPoolsByRarity then
			local ok, pools = pcall(SkinConfig.GetPoolsByRarity)
			if ok and pools and pools["common"] then
				commonPool = pools["common"]
			end
		end
		if #commonPool == 0 then
			commonPool = { "AK47", "357 Magnum", "870 Express", "Desert Eagle", "AA12", "AS-VAL", "LMG AE", "Apple" }
		end
		-- Find any common the player already owns in their inventory
		local chosen = nil
		for _, skinId in ipairs(commonPool) do
			if d.skins[skinId] and d.skins[skinId] > 0 then
				chosen = skinId
				break
			end
		end
		-- Grant a random common if they have none
		if not chosen then
			chosen = commonPool[math.random(1, #commonPool)]
			d.skins[chosen] = (d.skins[chosen] or 0) + 1
			warn(string.format("[PlayerDataRF] EnsureCommonSkin: granted free common '%s' to %s", chosen, plr.Name))
		end
		return { success = true, skinId = chosen }

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

-- ===============================
-- HEALTH & ARMOR SYSTEM (_G API)
-- ===============================

-- Get player's current health
_G.getHealth = function(plr)
	local d = ensure(plr)
	return d.currentHealth or d.maxHealth or 100
end

-- Get player's max health
_G.getMaxHealth = function(plr)
	local d = ensure(plr)
	return d.maxHealth or 100
end

-- Get player's armor
_G.getArmor = function(plr)
	local d = ensure(plr)
	return d.armor or 0
end

-- Get player's max armor (based on upgrade level)
_G.getMaxArmor = function(plr)
	local d = ensure(plr)
	return (d.armorUpgradeLevel or 0) * 10
end

-- Set player's current health (clamp between 0 and max)
_G.setHealth = function(plr, value)
	local d = ensure(plr)
	d.currentHealth = math.clamp(value or 0, 0, d.maxHealth or 100)
	return d.currentHealth
end

-- Heal player (add to current health, don't exceed max)
_G.healPlayer = function(plr, amount)
	local d = ensure(plr)
	d.currentHealth = math.clamp((d.currentHealth or 100) + (amount or 0), 0, d.maxHealth or 100)
	return d.currentHealth
end

-- Damage player (armor absorbs damage first, then HP)
-- Armor is disabled in PvP Arena / Arcade PvP (hearts-based duels), but active in Abyss PvP and PvE
-- Returns: {newHealth, damageDealt, isDead}
_G.damagePlayer = function(plr, damage, ignoreArmor)
	local d = ensure(plr)
	damage = damage or 0
	
	-- Skip armor if player is in a hearts-based duel (PvP Arena / Arcade PvP)
	local inDuel = _G.PvpDuel and _G.PvpDuel.isInDuel and _G.PvpDuel.isInDuel(plr)
	
	-- Armor absorbs damage first (flat shield, not percentage)
	if not ignoreArmor and not inDuel and d.armor and d.armor > 0 then
		local absorbed = math.min(d.armor, damage)
		d.armor = d.armor - absorbed
		damage = damage - absorbed
		-- Sync armor attribute so client bar drops instantly
		local maxArmor = (d.armorUpgradeLevel or 0) * 10
		plr:SetAttribute("Armor", d.armor)
		plr:SetAttribute("MaxArmor", maxArmor)
	end
	
	d.currentHealth = math.max(0, (d.currentHealth or 100) - damage)
	local isDead = d.currentHealth <= 0
	
	-- Only reduce Humanoid health by the damage that got past armor.
	-- Never overwrite with an absolute value — that causes phantom HP loss when armor absorbs everything.
	if damage > 0 then
		local char = plr and plr.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Health = math.max(0, hum.Health - damage)
			end
		end
	end
	
	return {
		newHealth = d.currentHealth,
		damageDealt = damage,
		isDead = isDead
	}
end

-- Reset player to full health
_G.resetHealth = function(plr)
	local d = ensure(plr)
	d.currentHealth = d.maxHealth or 100
	return d.currentHealth
end

-- Upgrade max health (costs money)
-- Returns: {success, newMaxHealth, cost}
_G.upgradeMaxHealth = function(plr)
	local d = ensure(plr)
	local currentLevel = d.healthUpgradeLevel or 0
	
	-- Health upgrade tiers: +10 HP per level, cost increases
	local upgradeCosts = {1000, 3000, 7000, 15000, 30000} -- 5 tiers max
	
	if currentLevel >= #upgradeCosts then
		return {success = false, reason = "max_level", newMaxHealth = d.maxHealth}
	end
	
	local cost = upgradeCosts[currentLevel + 1]
	if (d.money or 0) < cost then
		return {success = false, reason = "insufficient_funds", cost = cost, newMaxHealth = d.maxHealth}
	end
	
	-- Apply upgrade
	d.money = d.money - cost
	d.healthUpgradeLevel = currentLevel + 1
	d.maxHealth = 100 + (d.healthUpgradeLevel * 20) -- +20 HP per level
	d.currentHealth = d.maxHealth -- Heal to full on upgrade
	
	return {
		success = true,
		newMaxHealth = d.maxHealth,
		cost = cost,
		level = d.healthUpgradeLevel
	}
end

-- Upgrade armor (costs money)
-- Returns: {success, newArmor, cost}
_G.upgradeArmor = function(plr)
	local d = ensure(plr)
	local currentLevel = d.armorUpgradeLevel or 0
	
	-- Armor upgrade tiers: +5 armor per level, cost increases
	local upgradeCosts = {2000, 5000, 10000, 20000, 40000} -- 5 tiers max
	
	if currentLevel >= #upgradeCosts then
		return {success = false, reason = "max_level", newArmor = d.armor}
	end
	
	local cost = upgradeCosts[currentLevel + 1]
	if (d.money or 0) < cost then
		return {success = false, reason = "insufficient_funds", cost = cost, newArmor = d.armor}
	end
	
	-- Apply upgrade
	d.money = d.money - cost
	d.armorUpgradeLevel = currentLevel + 1
	d.armor = d.armorUpgradeLevel * 10 -- 10% damage reduction per level (max 50%)
	
	return {
		success = true,
		newArmor = d.armor,
		cost = cost,
		level = d.armorUpgradeLevel
	}
end

-- Set armor value directly (for temporary armor pickups, etc.)
_G.setArmor = function(plr, value)
	local d = ensure(plr)
	d.armor = math.max(0, value or 0)
	-- Sync attribute so client gets instant update
	local maxArmor = (d.armorUpgradeLevel or 0) * 10
	plr:SetAttribute("Armor", d.armor)
	plr:SetAttribute("MaxArmor", maxArmor)
	return d.armor
end

-- ===============================
-- END HEALTH & ARMOR SYSTEM
-- ===============================

-- ===============================
-- ARMOR REGENERATION (runs for ALL players, +1 every 0.1s = 10/s)
-- ===============================
local ARMOR_REGEN_INTERVAL = 0.2 -- seconds between +1 armor ticks

task.spawn(function()
	while true do
		task.wait(ARMOR_REGEN_INTERVAL)
		for _, plr in ipairs(Players:GetPlayers()) do
			pcall(function()
				local d = DATA[plr.UserId]
				if not d then return end
				local maxArmor = (d.armorUpgradeLevel or 0) * 10
				if maxArmor <= 0 then return end
				local cur = d.armor or 0
				if cur >= maxArmor then return end
				-- Skip regen if player is in a hearts-based duel
				if _G.PvpDuel and _G.PvpDuel.isInDuel and _G.PvpDuel.isInDuel(plr) then return end
				d.armor = math.min(maxArmor, cur + 1)
				-- Push to client via Attributes (instant, no RemoteFunction needed)
				plr:SetAttribute("Armor", d.armor)
				plr:SetAttribute("MaxArmor", maxArmor)
			end)
		end
	end
end)

-- ===============================
-- GOLD PER SECOND (Passive AFK Income)
-- ===============================
local GOLD_TICK_INTERVAL = 1 -- seconds between gold ticks

-- Expose gold bonus multiplier for other systems (PvP, Abyss, PvE)
_G.getGoldBonusMultiplier = function(plr, source)
	local d = ensure(plr)
	local base = 1
	if source == "pvp" then
		base = base + (d.pvpGoldBonusLevel or 0) * 0.10 -- +10% per level
	elseif source == "abyss" then
		base = base + (d.abyssGoldBonusLevel or 0) * 0.10
	elseif source == "pve" then
		base = base + (d.pveGoldBonusLevel or 0) * 0.10
	end
	-- Play time bonus adds to all sources
	base = base + (d.playTimeBonusLevel or 0) * 0.05 -- +5% per level
	return base
end

-- Passive gold ticker
task.spawn(function()
	while true do
		task.wait(GOLD_TICK_INTERVAL)
		for _, plr in ipairs(Players:GetPlayers()) do
			local ok, _ = pcall(function()
				local d = DATA[plr.UserId]
				if d then
					local goldPerSec = (d.goldPerSecondLevel or 0) * 6 -- +6 gold/sec per level (active)
					local afkGoldPerSec = (d.playTimeBonusLevel or 0) * 2 -- +2 gold/sec per level (AFK)
					local totalGold = goldPerSec + afkGoldPerSec
					if totalGold > 0 then
						d.money = (d.money or 0) + totalGold
						GoldChangedRE:FireClient(plr, totalGold, "tick")
					end
				end
			end)
		end
	end
end)

-- Expose refiner speed multiplier for RefinerSystem
_G.getRefinerSpeedMultiplier = function(plr)
	local d = ensure(plr)
	return 1 + (d.refinerSpeedLevel or 0) * 0.15 -- +15% faster per level
end

-- Lifecycle
local sessionJoinTimes: { [number]: number } = {} -- UserId -> tick()
_G.sessionJoinTimes = sessionJoinTimes -- Expose for PlaytimeLeaderboard

-- Keep a live registry of Player objects so BindToClose can always find them
-- even after PlayerRemoving has fired (DATA is not cleared until after BindToClose).
local PLAYER_REGISTRY = {} -- [userId] = Player

local function onPlayerAdded(plr)
	-- Load persisted data before ensure() so the migration patch merges against it
	local saved, loadErrored = loadData(plr)
	if type(saved) == "table" then
		DATA[plr.UserId] = saved
		LOAD_FAILED[plr.UserId] = nil -- clear any previous failed-load flag
	elseif loadErrored then
		-- DataStore errored — protect this player's real data by blocking saves.
		-- ensure() will give them a temporary session copy that is NEVER written back.
		LOAD_FAILED[plr.UserId] = true
		warn(string.format("[PlayerDataManager] 🛑 %s's data failed to load — saves blocked to protect real data!", plr.Name))
		-- Retry once after 10 seconds in case it was a transient DataStore hiccup
		task.delay(10, function()
			if not Players:FindFirstChild(plr.Name) then return end -- player left
			if not LOAD_FAILED[plr.UserId] then return end -- already recovered
			warn("[PlayerDataManager] 🔄 Retrying load for", plr.Name, "...")
			local saved2, err2 = loadData(plr)
			if type(saved2) == "table" then
				warn("[PlayerDataManager] ✅ Retry load succeeded for", plr.Name, "— restoring data and unblocking saves")
				DATA[plr.UserId] = saved2
				ensure(plr) -- patch schema onto freshly restored data
				LOAD_FAILED[plr.UserId] = nil
			elseif not err2 then
				-- Retry returned nil with no error = genuinely new account
				warn("[PlayerDataManager] ℹ️  Retry confirmed new account for", plr.Name, "— unblocking saves")
				LOAD_FAILED[plr.UserId] = nil
			else
				warn("[PlayerDataManager] ❌ Retry also failed for", plr.Name, "— saves remain blocked")
			end
		end)
	end
	ensure(plr)
	sessionJoinTimes[plr.UserId] = tick()
	PLAYER_REGISTRY[plr.UserId] = plr

	-- ── STARTER PACK (once per session) ─────────────────────────────────────
	-- Silver crate + 500 gold are baked into `ensure()` defaults.
	-- Give 1 random COMMON weapon on every fresh session (synchronous, no defer).
	do
		local d = ensure(plr)
		if not d.starterWeaponGiven then
			d.starterWeaponGiven = true

			-- Build the common pool from SkinConfig (static SKINS table — no scan needed)
			local commonPool = {}
			if SkinConfig and SkinConfig.GetPoolsByRarity then
				local ok, pools = pcall(SkinConfig.GetPoolsByRarity)
				if ok and pools and pools["common"] then
					commonPool = pools["common"]
				end
			end

			-- Hardcoded fallback in case SkinConfig fails entirely
			if #commonPool == 0 then
				commonPool = {
					"AK47", "357 Magnum", "870 Express", "Desert Eagle",
					"AA12", "AS-VAL", "LMG AE", "Apple",
				}
				warn("[PlayerDataManager] ⚠ Using hardcoded common pool fallback for", plr.Name)
			end

			warn(("[PlayerDataManager] Common pool size: %d"):format(#commonPool))

			local skinId = commonPool[math.random(1, #commonPool)]
			d.skins[skinId] = (d.skins[skinId] or 0) + 1
			warn(("[PlayerDataManager] ✅ Starter common weapon → %s: %s"):format(plr.Name, skinId))
		end
	end

	-- Immediately save after init so we can confirm DataStore is working.
	-- This fires 2s after join, long before PlayerRemoving/BindToClose.
	task.delay(2, function()
		if DATA[plr.UserId] then
			warn("[PlayerDataManager] 🔄 Initial post-join save for", plr.Name)
			saveData(plr)
		end
	end)

	-- Always restore stored MaxHealth on every respawn
	local function applyMaxHealth(char)
		local humanoid = char:WaitForChild("Humanoid", 5)
		if humanoid then
			local d = ensure(plr)
			local storedMaxHealth = d.maxHealth or 100
			humanoid.MaxHealth = storedMaxHealth
			humanoid.Health    = storedMaxHealth
			print("[PlayerDataManager] ✅ Applied MaxHealth: " .. storedMaxHealth .. " to " .. plr.Name)
		end
	end
	plr.CharacterAdded:Connect(applyMaxHealth)
	-- Handle first spawn: if character already exists before this connection was set up
	-- (happens because loadData is async and yields for several seconds).
	if plr.Character then task.spawn(applyMaxHealth, plr.Character) end

	-- Auto-equip "Power" skin on spawn (developer testing only — set AUTO_EQUIP_POWER = true)
	if AUTO_EQUIP_POWER then
		plr.CharacterAdded:Connect(function(char)
		-- Wait for tools to load
		task.wait(1)
		
		local tool = findTool(plr, "Hand") or findTool(plr, "Tool")
		if tool then
			print("[PlayerDataManager] ⚡ Auto-equipping 'Power' skin for testing")
			
			-- Ensure player owns it (just in case)
			local d = ensure(plr)
			if not d.skins["Power"] then d.skins["Power"] = 1 end
			
			-- Set attribute
			tool:SetAttribute("SkinId", "Power")
			
			-- Apply visual
			if _G.SkinService and _G.SkinService.ApplySkinToTool then
				_G.SkinService.ApplySkinToTool(tool, "Power")
			end
			
			-- Equip it
			char.Humanoid:EquipTool(tool)
		else
			warn("[PlayerDataManager] Could not find tool to auto-equip Power skin")
		end
	end)
	end -- end AUTO_EQUIP_POWER

	-- Hand tool auto-equip is now handled client-side by AutoEquipHand.client.luau.
	-- Client-side Humanoid:EquipTool is far more reliable than server-side calls.
	-- StarterPack already provides the Hand to every player's Backpack on spawn.
end

-- Wire up lifecycle: connect AND seed players already in-game at script load
-- (In Studio the test player is present before scripts run, so PlayerAdded never fires for them)
Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, plr)
end

local serverClosing = false -- set true when BindToClose fires

local function flushPlaytime(plr)
	local joinTick = sessionJoinTimes[plr.UserId]
	if joinTick then
		local d = DATA[plr.UserId]
		if d then
			d.totalPlaytime = (d.totalPlaytime or 0) + math.floor(tick() - joinTick)
		end
		sessionJoinTimes[plr.UserId] = nil
	end
end

Players.PlayerRemoving:Connect(function(plr)
	flushPlaytime(plr)
	-- Save synchronously. Do NOT clear DATA yet — BindToClose may need it
	-- if the server is shutting down at the same time.
	saveData(plr)
	PLAYER_REGISTRY[plr.UserId] = nil
	LOAD_FAILED[plr.UserId] = nil  -- clean up regardless
	if not serverClosing then
		-- Only free memory on a normal leave; keep it during shutdown so
		-- BindToClose can attempt a second save if UpdateAsync failed above.
		DATA[plr.UserId] = nil
	end
end)

-- BindToClose: guaranteed last-resort save for every entry still in DATA.
-- Iterates DATA directly (not Players:GetPlayers()) so it catches players
-- whose PlayerRemoving fired just before shutdown started.
game:BindToClose(function()
	serverClosing = true
	warn("[PlayerDataManager] 🔒 BindToClose: saving all remaining data...")

	local pending = {}
	for userId, d in pairs(DATA) do
		local plr = PLAYER_REGISTRY[userId]
		if plr and d then
			flushPlaytime(plr)
			table.insert(pending, plr)
		end
	end

	-- Save in parallel
	local done = 0
	local total = #pending
	for _, plr in ipairs(pending) do
		task.spawn(function()
			saveData(plr)
			done += 1
		end)
	end

	-- Yield until all saves finish (Roblox gives 30s; we wait up to 25s)
	local deadline = tick() + 25
	repeat task.wait(0.1) until done >= total or tick() >= deadline

	warn(string.format("[PlayerDataManager] 🔒 BindToClose: %d/%d saves completed", done, total))
end)

-- Autosave every 60 seconds to reduce data loss on unexpected crashes
task.spawn(function()
	while true do
		task.wait(30)  -- autosave every 30s
		for _, plr in ipairs(Players:GetPlayers()) do
			task.spawn(saveData, plr)
		end
	end
end)

-- _G.testSave(): run from Studio command bar to manually test DataStore
-- Usage: game:GetService("ServerScriptService"):WaitForChild("...") -- just run in server command bar:
-- for _,p in ipairs(game.Players:GetPlayers()) do _G.testSave(p) end
_G.testSave = function(plr)
	plr = plr or game:GetService('Players'):GetPlayers()[1]
	if not plr then warn('[testSave] No players in game') return end
	warn('[testSave] Force-saving', plr.Name, '...')
	saveData(plr)
	warn('[testSave] Done. Check output above for ✅ or ❌')
end

-- FIXED: Use the correct DATA table instead of undefined playerData
-- REMOVED: _G.getData = function(player) return playerData[player.userId] end

-- Add a timestamp to show when the module was loaded
local _currentTime = "2025-08-20 22:27:53"
local _currentUser = "Hulk11121"
