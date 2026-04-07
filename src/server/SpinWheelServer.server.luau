-- SpinWheelServer.server.luau
-- Daily spin-the-wheel reward system.
-- Players spin once every SPIN_COOLDOWN seconds for a random prize.

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ── SETTINGS (edit here) ──────────────────────────────────────────────────
local SPIN_COOLDOWN = 86400  -- seconds between spins (86400 = 24 hours)

-- Prize table — label shown on the wheel, type/amount for awarding,
-- weight controls relative drop chance. Weights don't need to sum to 100.
local PRIZES = {
	{ label = "500 Gold",   type = "gold",  amount = 500,                weight = 30 },
	{ label = "Crate",      type = "crate", name = "Supply Crate",       weight = 25 },
	{ label = "Skin",       type = "skin",  rare = false,                weight = 10 },
	{ label = "1000 Gold",  type = "gold",  amount = 1000,               weight = 18 },
	{ label = "2x Crate",   type = "crate", name = "Supply Crate", qty = 2, weight = 8 },
	{ label = "2500 Gold",  type = "gold",  amount = 2500,               weight = 5  },
	{ label = "Rare Skin",  type = "skin",  rare = true,                 weight = 3  },
	{ label = "5000 Gold",  type = "gold",  amount = 5000,               weight = 1  },
}

local SKIN_POOL = {
	"IronSword", "SteelDagger", "GoldenBow", "ShadowBlade", "CrystalStaff",
}
local RARE_SKIN_POOL = {
	"RubyBlade", "ObsidianStaff", "DiamondDagger",
}

-- ── REMOTE SETUP ──────────────────────────────────────────────────────────
local RemoteEvents = RS:WaitForChild("RemoteEvents")
local SpinWheelRF  = RemoteEvents:FindFirstChild("SpinWheelRF") or Instance.new("RemoteFunction")
SpinWheelRF.Name   = "SpinWheelRF"
SpinWheelRF.Parent = RemoteEvents

-- ── HELPERS ───────────────────────────────────────────────────────────────
local function waitForData(timeout)
	local t = 0
	while not _G.getData and t < timeout do
		task.wait(0.1); t += 0.1
	end
	return _G.getData ~= nil
end

local function pickPrize()
	local total = 0
	for _, p in ipairs(PRIZES) do total += p.weight end
	local roll = math.random(1, total)
	local cum  = 0
	for i, p in ipairs(PRIZES) do
		cum += p.weight
		if roll <= cum then return i, p end
	end
	return 1, PRIZES[1]
end

-- ── REMOTE HANDLER ────────────────────────────────────────────────────────
SpinWheelRF.OnServerInvoke = function(plr, action)
	if not _G.getData then
		return { success = false, error = "Data not ready" }
	end

	local d = _G.getData(plr)

	-- ── GET DATA ──────────────────────────────────────────────────────────
	if action == "GetData" then
		local now          = os.time()
		local lastSpin     = d.spinWheelLastSpin or 0
		local cooldownLeft = math.max(0, (lastSpin + SPIN_COOLDOWN) - now)
		-- Send prize labels to client so it can render the wheel segments
		local labels = {}
		for _, p in ipairs(PRIZES) do table.insert(labels, p.label) end
		return {
			success      = true,
			canSpin      = cooldownLeft <= 0,
			cooldownLeft = cooldownLeft,
			labels       = labels,
		}

	-- ── SPIN ──────────────────────────────────────────────────────────────
	elseif action == "Spin" then
		local now          = os.time()
		local lastSpin     = d.spinWheelLastSpin or 0
		local cooldownLeft = math.max(0, (lastSpin + SPIN_COOLDOWN) - now)

		if cooldownLeft > 0 then
			return { success = false, reason = "cooldown", cooldownLeft = cooldownLeft }
		end

		d.spinWheelLastSpin = now
		local winnerIndex, prize = pickPrize()

		-- Build a safe copy of the prize to return (no mutation of the table)
		local prizeResult = { type = prize.type, label = prize.label }

		if prize.type == "gold" then
			prizeResult.amount = prize.amount
			_G.addMoney(plr, prize.amount)
			warn(string.format("[SpinWheel] %s → +%d gold", plr.Name, prize.amount))

		elseif prize.type == "crate" then
			local qty = prize.qty or 1
			prizeResult.name = prize.name
			prizeResult.qty  = qty
			for _ = 1, qty do
				if _G.giveCrate then _G.giveCrate(plr, prize.name) end
			end
			warn(string.format("[SpinWheel] %s → crate x%d", plr.Name, qty))

		elseif prize.type == "skin" then
			local pool     = prize.rare and RARE_SKIN_POOL or SKIN_POOL
			local skinName = pool[math.random(1, #pool)]
			prizeResult.name = skinName
			prizeResult.rare = prize.rare
			if _G.giveSkin then _G.giveSkin(plr, skinName) end
			warn(string.format("[SpinWheel] %s → skin: %s", plr.Name, skinName))
		end

		return {
			success     = true,
			winnerIndex = winnerIndex,
			prize       = prizeResult,
			cooldown    = SPIN_COOLDOWN,
		}
	end

	return { success = false, error = "Unknown action" }
end

task.spawn(function()
	if waitForData(15) then
		warn("[SpinWheelServer] ✅ Ready")
	else
		warn("[SpinWheelServer] ⚠️  Data system not available after 15s")
	end
end)

warn("[SpinWheelServer] Loaded")
