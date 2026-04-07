-- CrateGiver.server.luau
-- Handles crate grant requests from the CrateGiver client GUI.
-- Uses _G.GrantBox (provided by PlayerDataManager) to add crates to the player's inventory.
--
-- ╔══════════════════════════════════════════════╗
-- ║  SETTINGS                                    ║
-- ╠══════════════════════════════════════════════╣
-- ║  ENABLED       – set false to stop granting  ║
-- ║  ADMIN_ONLY    – restrict to admin user IDs  ║
-- ║  ADMIN_USER_IDS – list of allowed user IDs   ║
-- ╚══════════════════════════════════════════════╝
local ENABLED        = false
local ADMIN_ONLY     = false   -- set true to lock to specific user IDs only
local ADMIN_USER_IDS = {       -- add user IDs here when ADMIN_ONLY = true
	-- 123456789,
}

local VALID_CRATES = {
	BRONZE   = true,
	SILVER   = true,
	SAPPHIRE = true,
	OMEGA    = true,
	RUBY     = true,
}

-- ── Setup ────────────────────────────────────────────────────────────────────

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	or (function()
		local f = Instance.new("Folder")
		f.Name = "RemoteEvents"
		f.Parent = ReplicatedStorage
		return f
	end)()

-- Create the RemoteEvent if it doesn't exist yet
local CrateGiverRE = RemoteEvents:FindFirstChild("CrateGiverRE")
if not CrateGiverRE then
	CrateGiverRE = Instance.new("RemoteEvent")
	CrateGiverRE.Name = "CrateGiverRE"
	CrateGiverRE.Parent = RemoteEvents
end

-- ── Helper ────────────────────────────────────────────────────────────────────

local function isAdmin(plr)
	if not ADMIN_ONLY then return true end
	for _, id in ipairs(ADMIN_USER_IDS) do
		if plr.UserId == id then return true end
	end
	return false
end

-- ── Handler ───────────────────────────────────────────────────────────────────

CrateGiverRE.OnServerEvent:Connect(function(plr, crateType, qty)
	if not ENABLED then return end
	if not isAdmin(plr) then
		warn(string.format("[CrateGiver] ⛔ %s is not authorised to use the CrateGiver", plr.Name))
		return
	end

	-- Sanitise inputs
	if type(crateType) ~= "string" or not VALID_CRATES[crateType] then
		warn(string.format("[CrateGiver] ❌ Invalid crateType '%s' from %s", tostring(crateType), plr.Name))
		return
	end
	qty = math.clamp(math.floor(tonumber(qty) or 1), 1, 100)

	-- Wait for _G.GrantBox to be registered by PlayerDataManager (it loads async)
	local deadline = tick() + 10
	while not _G.GrantBox and tick() < deadline do
		task.wait(0.2)
	end

	if not _G.GrantBox then
		warn("[CrateGiver] ❌ _G.GrantBox not available — PlayerDataManager may not be loaded")
		return
	end

	_G.GrantBox(plr, crateType, qty)
	warn(string.format("[CrateGiver] ✅ Granted %dx %s to %s", qty, crateType, plr.Name))
end)

warn("[CrateGiver] Server ready")
--