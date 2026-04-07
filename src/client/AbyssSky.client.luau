-- AbyssSky.client.luau
-- ENTER: poll detects player inside any AbyssHitBox part → activate sky.
-- EXIT:  player must be outside ALL parts for EXIT_HOLD seconds continuously.
--        LeftAbyss server event is intentionally IGNORED for sky control —
--        it fires per-part and causes flicker when crossing between zones.
--        Only SpawnButton's _G.leaveSky() triggers an immediate exit.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local POLL_INTERVAL = 0.25  -- seconds between position checks
local OBB_BUFFER    = 30    -- stud buffer on each axis to cover inter-part gaps
local EXIT_HOLD     = 2.0   -- seconds outside ALL parts before restoring sky

local player       = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
-- AbyssPvPEvent still exists for other systems but does NOT control sky anymore
local AbyssPvPEvent = RemoteEvents:WaitForChild("AbyssPvPEvent") -- luacheck: ignore (kept for reference)

-- ── Collect AbyssHitBox parts ─────────────────────────────────────────────
local abyssParts: {BasePart} = {}

local function collectParts()
	abyssParts = {}
	local hitbox = workspace:FindFirstChild("AbyssHitBox", true)
	if not hitbox then return end
	if hitbox:IsA("BasePart") then
		table.insert(abyssParts, hitbox)
	else
		for _, d in ipairs(hitbox:GetDescendants()) do
			if d:IsA("BasePart") then table.insert(abyssParts, d) end
		end
	end
	print(("[AbyssSky] Found %d AbyssHitBox parts"):format(#abyssParts))
end

task.spawn(function()
	task.wait(2); collectParts()
	if #abyssParts == 0 then task.wait(6); collectParts() end
end)

-- ── OBB inside-check ─────────────────────────────────────────────────────
local function insideAnyPart(pos: Vector3): boolean
	for _, part in ipairs(abyssParts) do
		local local_ = part.CFrame:PointToObjectSpace(pos)
		local h = part.Size * 0.5
		if math.abs(local_.X) <= h.X + OBB_BUFFER
			and math.abs(local_.Z) <= h.Z + OBB_BUFFER
			and local_.Y >= -h.Y - 20
			and local_.Y <=  h.Y + 40 then
			return true
		end
	end
	return false
end

-- ── State ────────────────────────────────────────────────────────────────
local inAbyssSky   = false
local outsideSince: number? = nil  -- tick() when player first left all parts

local function enterSky()
	if inAbyssSky then return end
	inAbyssSky   = true
	outsideSince = nil
	if _G.activateAbyssSky then _G.activateAbyssSky() end
end

local function leaveSky()
	inAbyssSky   = false
	outsideSince = nil
	if _G.RestoreDefaultSky then _G.RestoreDefaultSky() end
end

-- Exposed so SpawnButton can force-exit instantly on teleport
_G.leaveSky = leaveSky

-- ── Poll loop: handles BOTH enter and exit ────────────────────────────────
-- Exit only triggers after EXIT_HOLD seconds continuously outside all parts.
-- Crossing between zones = brief gap = outsideSince resets before EXIT_HOLD
-- is reached, so the sky never flickers.
task.spawn(function()
	while true do
		task.wait(POLL_INTERVAL)
		if #abyssParts == 0 then continue end

		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		if insideAnyPart(root.Position) then
			outsideSince = nil          -- reset exit timer every time inside
			if not inAbyssSky then enterSky() end
		elseif inAbyssSky then
			outsideSince = outsideSince or tick()
			if tick() - outsideSince >= EXIT_HOLD then
				leaveSky()
			end
		else
			outsideSince = nil
		end
	end
end)

-- ── Respawn: restore sky if spawning outside abyss ────────────────────────
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and (#abyssParts == 0 or not insideAnyPart(root.Position)) then
		leaveSky()
	end
end)
