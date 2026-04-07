-- SupplyDropServer.server.lua
-- Handles the Ruby model SupplyDrop reward system.
-- Tiers: Bronze → Silver → Gold → Diamond → Emerald → Obsidian → Ruby (MAX).
-- Claim: awards gold after cooldown expires.
-- Upgrade: costs gold to reach the next tier with better rewards & shorter cooldown.

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ── REWARD SETTINGS (edit these to tune drop rates) ─────────────────────
local CLAIM_COOLDOWN = 1200        -- 20 minutes between claims (all tiers)

-- Top-level reward type chances (weights, don't need to sum to 100)
local REWARD_WEIGHTS = {
	{ type = "gold",  weight = 60 },  -- 60% chance — gold
	{ type = "crate", weight = 30 },  -- 30% chance — supply crate
	{ type = "skin",  weight = 10 },  -- 10% chance — skin
}

-- ── JACKPOT SETTINGS ──────────────────────────────────────────────────────
local JACKPOT_CHANCE    = 0.5      -- % chance of jackpot instead of normal gold (0–100)
local JACKPOT_AMOUNT    = 100000   -- gold awarded on jackpot

-- ── GOLD SETTINGS — min/max per tier ─────────────────────────────────────
-- When the reward is "gold", a random value between GoldMin and GoldMax is awarded.
-- (Jackpot overrides this entirely if it triggers.)
local GOLD_RANGE = {
	[1] = { min = 300,   max = 700   },  -- Bronze
	[2] = { min = 700,   max = 1500  },  -- Silver
	[3] = { min = 1500,  max = 3000  },  -- Gold
	[4] = { min = 3000,  max = 6000  },  -- Diamond
	[5] = { min = 6000,  max = 12000 },  -- Emerald
	[6] = { min = 12000, max = 22000 },  -- Obsidian
	[7] = { min = 22000, max = 40000 },  -- Ruby
}

-- ── CRATE RARITY SETTINGS ─────────────────────────────────────────────────
-- Each entry: { name = "CrateID", weight = N }
-- Names match _G.GrantBox tier strings. Higher weight = more common.
local CRATE_POOL = {
	{ name = "BRONZE",   weight = 50 },  -- most common
	{ name = "SILVER",   weight = 30 },
	{ name = "SAPPHIRE", weight = 15 },
	{ name = "OMEGA",    weight = 4  },
	{ name = "RUBY",     weight = 1  },  -- rarest
}

-- ── SKIN RARITY SETTINGS ──────────────────────────────────────────────────
-- Rarity-only pool — weights give exact 1-in-N drop chances per rarity.
-- Total weight = 10000 so ratios are exact.
-- Common: 1/1 (fallback), Rare: 1/10, Epic: 1/100, Legendary: 1/1000, Mythic: 1/10000
local SKIN_POOL = {
	{ rarity = "Common",    weight = 8889 },
	{ rarity = "Rare",      weight = 1000 },
	{ rarity = "Epic",      weight = 100  },
	{ rarity = "Legendary", weight = 10   },
	{ rarity = "Mythic",    weight = 1    },
}

-- ── TIER DEFINITIONS ──────────────────────────────────────────────────────
-- goldReward : gold per claim (when gold reward type is picked)
-- upgradeCost: gold required to advance to the next tier (nil = max tier)
local SUPPLY_DROP_TIERS = {
	[1] = { name = "Bronze",   goldReward = 500,   cooldown = CLAIM_COOLDOWN, upgradeCost = 5000   },
	[2] = { name = "Silver",   goldReward = 1000,  cooldown = CLAIM_COOLDOWN, upgradeCost = 15000  },
	[3] = { name = "Gold",     goldReward = 2000,  cooldown = CLAIM_COOLDOWN, upgradeCost = 40000  },
	[4] = { name = "Diamond",  goldReward = 4000,  cooldown = CLAIM_COOLDOWN, upgradeCost = 100000 },
	[5] = { name = "Emerald",  goldReward = 7500,  cooldown = CLAIM_COOLDOWN, upgradeCost = 250000 },
	[6] = { name = "Obsidian", goldReward = 15000, cooldown = CLAIM_COOLDOWN, upgradeCost = 600000 },
	[7] = { name = "Ruby",     goldReward = 30000, cooldown = CLAIM_COOLDOWN, upgradeCost = nil    },
}
local MAX_TIER = 7

-- ── REMOTE SETUP ──────────────────────────────────────────────────────────
local RemoteEvents = RS:WaitForChild("RemoteEvents")

local SupplyDropRF = RemoteEvents:FindFirstChild("SupplyDropRF") or Instance.new("RemoteFunction")
SupplyDropRF.Name   = "SupplyDropRF"
SupplyDropRF.Parent = RemoteEvents

-- ── DATA HELPERS ──────────────────────────────────────────────────────────
-- Wait until PlayerDataManager's _G helpers are available (it runs first).
local function waitForData(timeout)
	local t = 0
	while not _G.getData and t < timeout do
		task.wait(0.1)
		t += 0.1
	end
	return _G.getData ~= nil
end

-- ── HELPERS ───────────────────────────────────────────────────────────────
local function weightedPick(pool)
	local total = 0
	for _, entry in ipairs(pool) do total += entry.weight end
	local roll = math.random(1, total)
	local cum  = 0
	for _, entry in ipairs(pool) do
		cum += entry.weight
		if roll <= cum then return entry end
	end
	return pool[1]
end

-- ── REWARD PICKER ─────────────────────────────────────────────────────────
local function pickReward(tier)
	-- 1. Pick reward type
	local typeEntry = weightedPick(REWARD_WEIGHTS)

	if typeEntry.type == "crate" then
		local crate = weightedPick(CRATE_POOL)
		return { type = "crate", name = crate.name }

	elseif typeEntry.type == "skin" then
		local skin = weightedPick(SKIN_POOL)
		return { type = "skin", name = skin.rarity }

	else -- gold
		-- Check jackpot first
		if math.random() * 100 < JACKPOT_CHANCE then
			return { type = "gold", amount = JACKPOT_AMOUNT, jackpot = true }
		end
		-- Normal gold: random value within tier's range
		local range  = GOLD_RANGE[tier] or GOLD_RANGE[1]
		local amount = math.random(range.min, range.max)
		return { type = "gold", amount = amount }
	end
end

-- ── REMOTE HANDLER ────────────────────────────────────────────────────────
SupplyDropRF.OnServerInvoke = function(plr, action)
	-- Guard: data system must be ready
	if not _G.getData then
		return { success = false, error = "Data system not ready" }
	end

	local d    = _G.getData(plr)
	local tier = d.supplyDropTier or 1
	tier       = math.clamp(tier, 1, MAX_TIER)

	local tierData = SUPPLY_DROP_TIERS[tier]
	if not tierData then
		return { success = false, error = "Invalid tier" }
	end

	-- ── GET DATA ──────────────────────────────────────────────────────────
	if action == "GetData" then
		local now         = os.time()
		local lastClaimed = d.supplyDropLastClaimed or 0
		local cooldownLeft = math.max(0, (lastClaimed + tierData.cooldown) - now)
		local nextTier    = SUPPLY_DROP_TIERS[tier + 1]

		return {
			success       = true,
			tier          = tier,
			tierName      = tierData.name,
			goldReward    = tierData.goldReward,
			cooldown      = tierData.cooldown,
			cooldownLeft  = cooldownLeft,
			canClaim      = cooldownLeft <= 0,
			upgradeCost   = tierData.upgradeCost,
			isMaxTier     = tier >= MAX_TIER,
			nextTierName  = nextTier and nextTier.name or nil,
			nextTierReward = nextTier and nextTier.goldReward or nil,
			currentMoney  = d.money or 0,
		}

	-- ── CLAIM ─────────────────────────────────────────────────────────────
	elseif action == "Claim" then
		local now         = os.time()
		local lastClaimed = d.supplyDropLastClaimed or 0
		local cooldownLeft = math.max(0, (lastClaimed + tierData.cooldown) - now)

		if cooldownLeft > 0 then
			return { success = false, reason = "cooldown", cooldownLeft = cooldownLeft }
		end

		-- Pick random reward and record timestamp
		d.supplyDropLastClaimed = now
		local reward = pickReward(tier)

		if reward.type == "gold" then
			_G.addMoney(plr, reward.amount)
			if reward.jackpot then
				warn(string.format("[SupplyDrop] 🎉 JACKPOT! %s Tier %d (%s) → +%d gold",
					plr.Name, tier, tierData.name, reward.amount))
			else
				warn(string.format("[SupplyDrop] %s Tier %d (%s) → +%d gold",
					plr.Name, tier, tierData.name, reward.amount))
			end
		elseif reward.type == "crate" then
			if _G.GrantBox then _G.GrantBox(plr, reward.name, 1) end
			warn(string.format("[SupplyDrop] %s claimed Tier %d (%s) → crate: %s",
				plr.Name, tier, tierData.name, reward.name))
		elseif reward.type == "skin" then
			if _G.giveSkin then _G.giveSkin(plr, reward.name) end
			warn(string.format("[SupplyDrop] %s claimed Tier %d (%s) → skin: %s",
				plr.Name, tier, tierData.name, reward.name))
		end

		return {
			success  = true,
			reward   = reward,
			newMoney = d.money,
			cooldown = tierData.cooldown,
		}

	-- ── UPGRADE ───────────────────────────────────────────────────────────
	elseif action == "Upgrade" then
		if tier >= MAX_TIER then
			return { success = false, reason = "max_tier" }
		end

		local cost = tierData.upgradeCost
		if not cost then
			return { success = false, reason = "max_tier" }
		end

		if (d.money or 0) < cost then
			return { success = false, reason = "insufficient_funds", cost = cost, money = d.money }
		end

		-- Deduct cost and advance tier
		d.money           = (d.money or 0) - cost
		d.supplyDropTier  = tier + 1
		local newTierData = SUPPLY_DROP_TIERS[tier + 1]

		warn(string.format("[SupplyDrop] %s upgraded to Tier %d (%s) for $%d",
			plr.Name, tier + 1, newTierData.name, cost))

		return {
			success      = true,
			newTier      = tier + 1,
			newTierName  = newTierData.name,
			newMoney     = d.money,
		}
	end

	warn(string.format("[SupplyDropServer] Unknown action '%s' from %s", tostring(action), plr.Name))
	return { success = false, error = "Unknown action" }
end

-- Block exploit: players cannot invoke for other players (OnServerInvoke already scopes by player)
-- Validate all inputs are primitives — no table injection risk since action is a string.

-- ── BILLBOARD SETTINGS (edit here) ───────────────────────────────────────
local BILLBOARD_MAX_DISTANCE = 75   -- studs — how far away the sign is visible

-- ── SUPPLY DROP BILLBOARD ─────────────────────────────────────────────────
-- Creates a polished "Supply Drop" billboard above the Ruby model.
local function createSupplyDropBillboard()
	-- Find the Ruby model's root part
	local rubyModel, rootPart
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and string.find(obj.Name:lower(), "ruby") then
			rubyModel = obj
			break
		end
	end
	if not rubyModel then
		warn("[SupplyDropServer] Billboard: Ruby model not found")
		return
	end
	rootPart = rubyModel.PrimaryPart or rubyModel:FindFirstChildWhichIsA("BasePart", true)
	if not rootPart then
		warn("[SupplyDropServer] Billboard: no BasePart in Ruby model")
		return
	end

	-- Remove any existing billboard we may have made
	local existing = rootPart:FindFirstChild("SupplyDropBillboard")
	if existing then existing:Destroy() end

	-- ── Adornee attachment so the billboard floats above the model ─────────
	local attachment = Instance.new("Attachment")
	attachment.Name      = "SupplyDropBillboardAttachment"
	attachment.Position  = Vector3.new(0, 8, 0)   -- height above root part
	attachment.Parent    = rootPart

	-- ── BillboardGui ───────────────────────────────────────────────────────
	local bb = Instance.new("BillboardGui")
	bb.Name              = "SupplyDropBillboard"
	bb.Adornee           = attachment
	bb.Size              = UDim2.new(0, 400, 0, 100)
	bb.StudsOffset       = Vector3.new(0, 0, 0)
	bb.AlwaysOnTop       = false
	bb.MaxDistance       = BILLBOARD_MAX_DISTANCE
	bb.ResetOnSpawn      = false
	bb.Parent            = rootPart

	-- ── Outer glow frame ───────────────────────────────────────────────────
	local glow = Instance.new("Frame")
	glow.Name                    = "Glow"
	glow.Size                    = UDim2.new(1, 10, 1, 10)
	glow.Position                = UDim2.new(0, -5, 0, -5)
	glow.BackgroundColor3        = Color3.fromRGB(255, 55, 80)
	glow.BackgroundTransparency  = 0.55
	glow.BorderSizePixel         = 0
	glow.ZIndex                  = 99
	glow.Parent                  = bb
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 14)

	-- ── Main background (ClipsDescendants keeps all content inside) ───────
	local bg = Instance.new("Frame")
	bg.Name                    = "Background"
	bg.Size                    = UDim2.new(1, 0, 1, 0)
	bg.Position                = UDim2.new(0, 0, 0, 0)
	bg.BackgroundColor3        = Color3.fromRGB(12, 8, 20)
	bg.BackgroundTransparency  = 0.08
	bg.BorderSizePixel         = 0
	bg.ClipsDescendants        = true
	bg.ZIndex                  = 100
	bg.Parent                  = bb
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

	local grad = Instance.new("UIGradient")
	grad.Color    = ColorSequence.new{
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(80,  20,  40)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20,  10,  30)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(60,  10,  80)),
	}
	grad.Rotation = 45
	grad.Parent   = bg

	-- ── Top accent bar ─────────────────────────────────────────────────────
	local accent = Instance.new("Frame")
	accent.Size                   = UDim2.new(0.5, 0, 0, 3)
	accent.Position               = UDim2.new(0.25, 0, 0, 3)
	accent.BackgroundColor3       = Color3.fromRGB(255, 55, 80)
	accent.BackgroundTransparency = 0
	accent.BorderSizePixel        = 0
	accent.ZIndex                 = 101
	accent.Parent                 = bg
	Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

	-- ── "📦 SUPPLY DROP" title ─────────────────────────────────────────────
	local title = Instance.new("TextLabel")
	title.Size                   = UDim2.new(1, -20, 0, 50)
	title.Position               = UDim2.new(0, 10, 0, 6)
	title.BackgroundTransparency = 1
	title.Text                   = "📦  SUPPLY DROP"
	title.Font                   = Enum.Font.FredokaOne
	title.TextSize               = 32
	title.TextScaled             = true
	title.TextWrapped            = false
	title.TextColor3             = Color3.fromRGB(255, 255, 255)
	title.TextStrokeColor3       = Color3.fromRGB(180, 30, 50)
	title.TextStrokeTransparency = 0.4
	title.TextXAlignment         = Enum.TextXAlignment.Center
	title.TextYAlignment         = Enum.TextYAlignment.Center
	title.ZIndex                 = 102
	title.Parent                 = bg

	-- ── Subtitle ───────────────────────────────────────────────────────────
	local sub = Instance.new("TextLabel")
	sub.Size                   = UDim2.new(1, -20, 0, 28)
	sub.Position               = UDim2.new(0, 10, 0, 56)
	sub.BackgroundTransparency = 1
	sub.Text                   = "Press E to open"
	sub.Font                   = Enum.Font.Gotham
	sub.TextSize               = 18
	sub.TextScaled             = true
	sub.TextWrapped            = false
	sub.TextColor3             = Color3.fromRGB(200, 160, 180)
	sub.TextXAlignment         = Enum.TextXAlignment.Center
	sub.TextYAlignment         = Enum.TextYAlignment.Center
	sub.ZIndex                 = 102
	sub.Parent                 = bg

	-- ── Bottom accent bar ──────────────────────────────────────────────────
	local accentBot = Instance.new("Frame")
	accentBot.Size                   = UDim2.new(0.3, 0, 0, 2)
	accentBot.Position               = UDim2.new(0.35, 0, 1, -4)
	accentBot.BackgroundColor3       = Color3.fromRGB(170, 90, 255)
	accentBot.BackgroundTransparency = 0
	accentBot.BorderSizePixel        = 0
	accentBot.ZIndex                 = 101
	accentBot.Parent                 = bg
	Instance.new("UICorner", accentBot).CornerRadius = UDim.new(1, 0)

	warn("[SupplyDropServer] Billboard created on", rootPart:GetFullName())
end

-- ── FIX PP PARENTING ───────────────────────────────────────────────────
-- ProximityPrompt MUST be a child of a BasePart (or Attachment) to show
-- the "Press E" bubble. If the PP ended up under a Model, move it into
-- the first BasePart we can find inside that model.
local function fixRubyPromptParenting()
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			local cur = desc.Parent
			local inRuby = false
			while cur and cur ~= workspace do
				if string.find(cur.Name:lower(), "ruby") then inRuby = true break end
				cur = cur.Parent
			end
			if inRuby and desc.Parent and desc.Parent:IsA("Model") then
				local part = desc.Parent:FindFirstChildWhichIsA("BasePart", true)
				if part then
					warn(string.format("[SupplyDropServer] Reparenting PP from Model '%s' into BasePart '%s'",
						desc.Parent.Name, part.Name))
					desc.Parent = part
					desc.MaxActivationDistance = 20
				else
					warn("[SupplyDropServer] ⚠️  PP is in Ruby Model but no BasePart found to reparent into!")
				end
			end
		end
	end
end

-- ── SERVER-SIDE DIAGNOSTICS ────────────────────────────────────────────
-- All logging lives here so it shows up in the server console during
-- team-testing (client output is invisible to other testers).
local function logRubySetup()
	local found = 0
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			local inRuby = false
			local cur = desc.Parent
			while cur and cur ~= workspace do
				if string.find(cur.Name:lower(), "ruby") then inRuby = true break end
				cur = cur.Parent
			end
			warn(string.format("[SupplyDropServer] PP: %s | inRuby: %s | parentClass: %s",
				desc:GetFullName(), tostring(inRuby), desc.Parent.ClassName))
			found += 1
		end
	end
	warn(string.format("[SupplyDropServer] Total ProximityPrompts in workspace: %d", found))
end

-- Wait for data system before accepting calls
task.spawn(function()
	if waitForData(10) then
		warn("[SupplyDropServer] ✅ Ready — data system confirmed.")
	else
		warn("[SupplyDropServer] ⚠️  Data system not available after 10s — calls will return error until it loads.")
	end

	-- Fix PP parenting first (must be in BasePart, not Model)
	task.wait(1)
	fixRubyPromptParenting()
	createSupplyDropBillboard()

	-- Run diagnostics after fix so we can confirm it worked
	task.wait(2)
	logRubySetup()
end)

warn("[SupplyDropServer] Loaded")
