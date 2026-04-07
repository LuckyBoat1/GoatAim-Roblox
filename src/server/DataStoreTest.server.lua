-- DataStoreTest.server.lua
-- TEMPORARY: Run this to check if DataStore works at all.
-- Look in Studio output for ✅ or ❌ after ~3 seconds.
-- DELETE this file once confirmed working.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local testStore = DataStoreService:GetDataStore("__DSTest__")

local function testSave(plr)
	local key = tostring(plr.UserId)
	local value = { gold = 999, ts = os.time() }

	-- WRITE
	local wok, werr = pcall(function()
		testStore:SetAsync(key, value)
	end)
	if not wok then
		warn("[DSTest] ❌ WRITE FAILED →", werr)
		warn("[DSTest] → FIX: Game Settings → Security → Enable Studio Access to API Services")
		return
	end
	warn("[DSTest] ✅ WRITE OK for", plr.Name)

	-- READ BACK
	local rok, result = pcall(function()
		return testStore:GetAsync(key)
	end)
	if not rok then
		warn("[DSTest] ❌ READ FAILED →", result)
		return
	end
	if result and result.gold == 999 then
		warn("[DSTest] ✅ READ OK — DataStore is fully working! gold =", result.gold)
	else
		warn("[DSTest] ⚠️ READ returned unexpected value:", result)
	end
end

local function onPlayerAdded(plr)
	task.wait(2) -- give DataStore service time to init
	testSave(plr)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, plr)
end
