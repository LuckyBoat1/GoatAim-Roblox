-- SpawnButton.client.luau
-- Spawn ScreenGui bobs the same way as the Stats frames:
--   sine-wave Y-scale offset on the Frame each RenderStepped (StatsDisplay pattern).
-- Separate invisible TextButton inside the Frame handles click/tap input.
-- ========================================================
-- ✏️ EASY EDIT
-- ========================================================
local GUI_NAME            = "Spawn"
local ATTACHMENT_NAME     = "Spawn"
local BOB_SPEED           = 1.4     -- rad/s  (matches StatsDisplay)
local BOB_AMP             = 0.025   -- Y scale fraction (~27px on 1080p)
local COMBAT_COOLDOWN     = 5
local ARENA_DUEL_MAX_DURATION = 75
-- ========================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------
-- ABYSS / COMBAT STATE
--------------------------------------------------------------------------
local inAbyss       = false
local lastCombatTime = 0  -- tick() of last combat action

-- Arena PvP duel state — spawn button is locked while a 1v1 / arcade duel is active.
-- Cleared automatically when the server fires "FightEnd" on PvpCountdownEvent.
local inArenaDuel      = false
local arenaDuelEndAt   = 0   -- tick() when FightEnd fired (drives safety-net auto-teleport)
local arenaDuelStartAt = 0   -- tick() when FightStart fired (dead-man's-switch)

-- Listen to AbyssPvPEvent for enter/leave/combat
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local AbyssPvPEvent = remoteEvents and remoteEvents:FindFirstChild("AbyssPvPEvent")

if AbyssPvPEvent then
	AbyssPvPEvent.OnClientEvent:Connect(function(action, ...)
		if action == "EnteredAbyss" then
			inAbyss = true
		elseif action == "LeftAbyss" then
			inAbyss = false
			lastCombatTime = 0 -- clear stale combat timer so button isn't locked on re-entry
		elseif action == "DamageTaken" or action == "HitMarker" or action == "Kill" or action == "Killed" then
			lastCombatTime = tick()
		end
	end)
end

-- PvpCountdownEvent listener — registered in a deferred task so that, by the time
-- any callback fires, all local functions (including teleportToSpawn) are in scope.
task.spawn(function()
	local PvpCountdownEvent = ReplicatedStorage:FindFirstChild("PvpCountdownEvent")
		or ReplicatedStorage:WaitForChild("PvpCountdownEvent", 15)
	if not PvpCountdownEvent then return end

	PvpCountdownEvent.OnClientEvent:Connect(function(action)
		if action == "Show" then
			-- Duel countdown showing: lock spawn button but don't start the 75s clock yet.
			inArenaDuel      = true
			arenaDuelEndAt   = 0
		elseif action == "FightStart" then
			-- Fight begun: lock spawn button and start the dead-man's-switch clock.
			inArenaDuel      = true
			arenaDuelEndAt   = 0
			arenaDuelStartAt = tick()
		elseif action == "FightEnd" then
			-- Duel ended: unlock and record time for safety-net auto-teleport.
			inArenaDuel      = false
			arenaDuelStartAt = 0
			arenaDuelEndAt   = tick()
		end
	end)
end)

local function getCombatRemaining(): number
	if not inAbyss then return 0 end
	local elapsed = tick() - lastCombatTime
	if elapsed >= COMBAT_COOLDOWN then return 0 end
	return math.ceil(COMBAT_COOLDOWN - elapsed)
end

--------------------------------------------------------------------------
-- FIND THE SPAWN ATTACHMENT IN WORKSPACE
--------------------------------------------------------------------------
local function findSpawnAttachment()
	for _, desc in workspace:GetDescendants() do
		if desc:IsA("Attachment") and desc.Name == ATTACHMENT_NAME then
			return desc
		end
	end
	return nil
end

--------------------------------------------------------------------------
-- TELEPORT PLAYER TO ATTACHMENT
--------------------------------------------------------------------------
local function teleportToSpawn()
	-- Block if in an active arena PvP duel (1v1 or Arcade).
	-- The button unlocks automatically when FightEnd fires.
	if inArenaDuel then
		warn("[SpawnButton] Arena PvP duel in progress — cannot use spawn button during fight")
		return
	end

	-- Block if in Abyss combat cooldown
	local remaining = getCombatRemaining()
	if remaining > 0 then
		warn("[SpawnButton] In combat — " .. remaining .. "s remaining")
		return
	end

	local attachment = findSpawnAttachment()
	if not attachment then
		warn("[SpawnButton] Could not find Attachment named '" .. ATTACHMENT_NAME .. "' in workspace")
		return
	end

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Teleport to the attachment's world position, keep player rotation
	local targetPos = attachment.WorldPosition
	rootPart.CFrame = CFrame.new(targetPos) * rootPart.CFrame.Rotation

	-- Restore sky instantly — don't wait for server LeftAbyss
	if _G.leaveSky then _G.leaveSky() end

	-- Hide the Bull arena HUD immediately if it's still showing
	if _G.HideBullHUD then
		_G.HideBullHUD()
	end
end

--------------------------------------------------------------------------
-- SETUP: find GUI, add click button, countdown label, store base position
--------------------------------------------------------------------------
local frame          = nil
local basePosition   = nil   -- UDim2 the frame sits at when not bobbing
local spawnLabel     = nil   -- TextLabel sibling of Frame inside the Spawn ScreenGui
local labelBasePos   = nil   -- its rest Position
local buttonReady    = false
local countdownLabel = nil

local function setup()
	if buttonReady then return true end

	local gui = playerGui:FindFirstChild(GUI_NAME)
	if not gui or not gui:IsA("ScreenGui") then return false end

	frame = gui:FindFirstChild("Frame")
	if not frame then return false end

	basePosition = frame.Position

	-- Find the TextLabel that lives directly inside the Spawn ScreenGui (sibling of Frame)
	for _, child in ipairs(gui:GetChildren()) do
		if child:IsA("TextLabel") then
			spawnLabel   = child
			labelBasePos = child.Position
			break
		end
	end

	-- Invisible click button on top of the frame
	if not frame:FindFirstChild("SpawnTeleportButton") then
		local btn = Instance.new("TextButton")
		btn.Name = "SpawnTeleportButton"
		btn.Size = UDim2.fromScale(1, 1)
		btn.Position = UDim2.fromScale(0, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 100
		btn.Parent = frame
		btn.MouseButton1Click:Connect(teleportToSpawn)
	end

	-- Combat countdown overlay
	if not frame:FindFirstChild("CombatCountdown") then
		local lbl = Instance.new("TextLabel")
		lbl.Name = "CombatCountdown"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.Position = UDim2.fromScale(0, 0)
		lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		lbl.BackgroundTransparency = 0.45
		lbl.Text = ""
		lbl.Font = Enum.Font.GothamBold
		lbl.TextColor3 = Color3.fromRGB(255, 70, 70)
		lbl.TextScaled = true
		lbl.ZIndex = 110
		lbl.Visible = false
		lbl.Parent = frame
		Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
		countdownLabel = lbl
	else
		countdownLabel = frame:FindFirstChild("CombatCountdown")
	end

	buttonReady = true
	print("[SpawnButton] Ready — click to teleport")
	return true
end

--------------------------------------------------------------------------
-- MAIN LOOP — bob animation + combat countdown + self-healing
--------------------------------------------------------------------------
local lastCheck = 0
local ARENA_AUTOTELEPORT_DELAY = 3


RunService.Heartbeat:Connect(function(dt)
	local now = tick()

	-- Dead-man's-switch: if inArenaDuel has been true for longer than the max possible
	-- fight duration, the FightEnd event was likely lost — force-unlock the spawn button.
	if inArenaDuel and arenaDuelStartAt > 0 and (now - arenaDuelStartAt) > ARENA_DUEL_MAX_DURATION then
		warn("[SpawnButton] Dead-man's-switch triggered — clearing stuck inArenaDuel flag")
		inArenaDuel      = false
		arenaDuelStartAt = 0
		arenaDuelEndAt   = tick()
	end

	-- Retry setup every 0.5s until the Spawn ScreenGui provided by StarterGui exists.
	if not buttonReady then
		if now - lastCheck > 0.5 then
			lastCheck = now
			setup()
		end
		return
	end

	-- Safety-net auto-teleport: if the arena duel just ended and the server
	-- hasn't moved us yet, teleport to spawn after ARENA_AUTOTELEPORT_DELAY seconds.
	if arenaDuelEndAt > 0 and (now - arenaDuelEndAt) >= ARENA_AUTOTELEPORT_DELAY then
		arenaDuelEndAt = 0 -- consume the trigger so we don't repeat
		teleportToSpawn()
		-- Force-hide the PvP overlay immediately — the teleport means the fight is
		-- definitely over and any lingering timer/hearts UI must be cleared now.
		if _G.ForcePvpHide then
			_G.ForcePvpHide()
		end
	end

	-- Update combat countdown / arena lock overlay
	if countdownLabel then
		if inArenaDuel then
			-- Show "FIGHT" label while locked in arena PvP
			countdownLabel.Visible = true
			countdownLabel.Text = "⚔"
			countdownLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
		else
			local remaining = getCombatRemaining()
			if remaining > 0 then
				countdownLabel.Visible = true
				countdownLabel.Text = tostring(remaining)
				countdownLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
			else
				countdownLabel.Visible = false
			end
		end
	end

	-- Bob: same sine-wave pattern as StatsDisplay bobContainer
	if frame and frame.Parent and basePosition then
		local yOff = math.sin(os.clock() * BOB_SPEED) * BOB_AMP
		frame.Position = UDim2.new(
			basePosition.X.Scale, basePosition.X.Offset,
			basePosition.Y.Scale + yOff, basePosition.Y.Offset
		)
		if spawnLabel and spawnLabel.Parent and labelBasePos then
			spawnLabel.Position = UDim2.new(
				labelBasePos.X.Scale, labelBasePos.X.Offset,
				labelBasePos.Y.Scale + yOff, labelBasePos.Y.Offset
			)
		end
	end
end)

-- Reset setup state on respawn so stale frame refs get refreshed
player.CharacterAdded:Connect(function()
	buttonReady = false
	frame = nil
	basePosition = nil
	spawnLabel = nil
	labelBasePos = nil
	countdownLabel = nil
	lastCheck = 0
end)

print("[SpawnButton] Loaded — waiting for Spawn GUI")
