-- RobuxProducts.server.lua
-- Handles Robux Developer Product purchases for the Emporium coin packages.
--
-- HOW TO SET UP:
--   1. Go to https://create.roblox.com → your game → Monetization → Developer Products
--   2. Create one product per coin package:
--        • "100 Trump Coins"  → price 50 Robux
--        • "500 Trump Coins"  → price 150 Robux
--        • "2500 Trump Coins" → price 500 Robux
--   3. After creating each product, copy its numeric Product ID and paste it below.

local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")

-- ── PRODUCT ID MAP ────────────────────────────────────────────────────────
-- Replace the 0s with the actual Product IDs from Creator Hub.
local PRODUCT_REWARDS = {
	[3549502093] = 100,   -- Stack  (50 R$)  → 100 Trump Coins
	[3549502408] = 500,   -- Car    (150 R$) → 500 Trump Coins
	[3549502646] = 2500,  -- Yacht  (500 R$) → 2500 Trump Coins
}

-- ── PROCESS RECEIPT ───────────────────────────────────────────────────────
-- Called by Roblox after a successful Robux purchase.
-- Must return Enum.ProductPurchaseDecision.PurchaseGranted or NotProcessedYet.
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local productId = receiptInfo.ProductId
	local playerId  = receiptInfo.PlayerId
	warn(string.format("[RobuxProducts] 🔔 ProcessReceipt fired! productId=%d playerId=%d", productId, playerId))

	local reward = PRODUCT_REWARDS[productId]
	if not reward then
		warn(string.format("[RobuxProducts] Unknown productId %d — not handled here", productId))
		-- Return NotProcessedYet so Roblox keeps retrying (another script may handle it)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Find the player
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		-- Player left before we could grant — return NotProcessedYet so Roblox retries on next join
		warn(string.format("[RobuxProducts] Player %d not in server — will retry later", playerId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Grant the coins via PlayerDataManager's _G API
	-- Retry up to 10s in case PlayerDataManager hasn't finished loading yet
	local granted = false
	for _ = 1, 20 do
		if _G.addTrumpCoins then
			_G.addTrumpCoins(player, reward)
			warn(string.format("[RobuxProducts] ✅ Granted %d Trump Coins to %s (productId %d)",
				reward, player.Name, productId))
			granted = true
			break
		end
		task.wait(0.5)
	end
	if not granted then
		warn("[RobuxProducts] ❌ _G.addTrumpCoins never available after 10s — NOT PROCESSED")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Tell the client to refresh their coin display
	local RemoteEvents = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
	if RemoteEvents then
		local rf = RemoteEvents:FindFirstChild("CoinPurchaseSuccess")
		if rf then
			rf:FireClient(player, reward)
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

warn("[RobuxProducts] ✅ ProcessReceipt handler registered")

-- ── EXPOSE PRODUCT IDS TO CLIENT ─────────────────────────────────────────
-- Client reads this via a RemoteFunction so it knows which productId to prompt.
local RemoteEvents = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents", 10)
if RemoteEvents then
	-- CoinProductIdRF: client calls with package name ("Stack"/"Car"/"Yacht"),
	-- server returns the productId number.
	local rf = RemoteEvents:FindFirstChild("CoinProductIdRF")
	if not rf then
		rf = Instance.new("RemoteFunction")
		rf.Name = "CoinProductIdRF"
		rf.Parent = RemoteEvents
	end

	-- Map package name → productId
	local NAME_TO_PRODUCT = {
		Stack = 3549502093,
		Car   = 3549502408,
		Yacht = 3549502646,
	}

	rf.OnServerInvoke = function(_player, packageName)
		return NAME_TO_PRODUCT[packageName] or 0
	end

	-- CoinPurchaseSuccess: server fires to client after successful grant
	local successRE = RemoteEvents:FindFirstChild("CoinPurchaseSuccess")
	if not successRE then
		successRE = Instance.new("RemoteEvent")
		successRE.Name = "CoinPurchaseSuccess"
		successRE.Parent = RemoteEvents
	end
end

warn("[RobuxProducts] ✅ Ready. Fill in productIds at the top of this file after creating Developer Products.")
