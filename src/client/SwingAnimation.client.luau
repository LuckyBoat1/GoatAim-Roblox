-- SwingAnimation.client.luau
-- Melee 4-hit combo: R15SwordSwing1→2→3→4 via Animator.
-- Speeds: Swing1=1x  Swing2=1.5x  Swing3=3x  Swing4=1.5x
-- Sequence resets if the player waits >0.5s between hits.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Rs               = game:GetService("ReplicatedStorage")

local SkinConfig   = require(Rs:WaitForChild("Shared"):WaitForChild("SkinConfig"))

local player = Players.LocalPlayer

-- ── Settings ────────────────────────────────────────────────────────────────────
local SPEED_MULTIPLIER = 1.0   -- global speed multiplier applied to all 4 swings (e.g. 1.5 = 50% faster)

-- ── Combo sequence { animId, speedMultiplier } ────────────────────────────────
local COMBO = {
	{ id = 114166239882684, speed = 1.0 },  -- R15SwordSwing1
	{ id = 115728566817162, speed = 1.5 },  -- R15SwordSwing2
	{ id = 102280903885330, speed = 3.0 },  -- R15SwordSwing3
	{ id = 126789743778720, speed = 1.5 },  -- R15SwordSwing4
}
local COMBO_RESET_DELAY = 0.5   -- seconds of pause before sequence resets to Swing1

-- ── State ─────────────────────────────────────────────────────────────────────
local currentTool     = nil
local currentToolConn = nil   -- tool.Activated connection
local comboIndex      = 1
local lastSwingAt     = 0
local isSwinging      = false
local cachedTracks    = {}   -- [animId] → AnimationTrack; cleared on respawn

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function getAnimator()
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	return hum:FindFirstChildOfClass("Animator")
end

local function getTrack(animId)
	if cachedTracks[animId] then return cachedTracks[animId] end
	local animator = getAnimator()
	if not animator then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. animId
	local track = animator:LoadAnimation(anim)
	anim:Destroy()
	track.Looped = false
	cachedTracks[animId] = track
	return track
end

-- Weapons that use the combo swing system
local function shouldHaveSwingAnimation(skinName)
	if not skinName then return false end
	local meta = SkinConfig.GetSkinMeta(skinName)
	if not meta then return false end
	local meleeTypes = {
		Blade=true, Spear=true, Axe=true, GreatAxe=true, HandAxe=true,
		Sword=true, Greatsword=true, Hammer=true, Mace=true, Club=true,
		Halberd=true, Staff=true, Machete=true, Shiv=true, Cutlass=true,
		Banner=true, Bone=true,
	}
	if meleeTypes[meta.weapon] then return true end
	if meta.weapon == "Melee" then
		local lower = string.lower(skinName)
		return lower:find("spear") ~= nil or lower:find("axe") ~= nil
	end
	return false
end

-- ── Swing logic ───────────────────────────────────────────────────────────────
local function doSwing()
	print("[SwingAnimation] doSwing called, currentTool=", currentTool, "isSwinging=", isSwinging)
	if not currentTool then print("[SwingAnimation] BAIL: no currentTool") return end
	if isSwinging then print("[SwingAnimation] BAIL: already swinging") return end

	local skinId = currentTool:GetAttribute("SkinId")
	print("[SwingAnimation] SkinId=", skinId)
	if not skinId then print("[SwingAnimation] BAIL: no SkinId attribute") return end
	local isMelee = shouldHaveSwingAnimation(skinId)
	print("[SwingAnimation] shouldHaveSwingAnimation=", isMelee)
	if not isMelee then print("[SwingAnimation] BAIL: not a melee skin") return end
	if not player.Character then print("[SwingAnimation] BAIL: no character") return end

	-- Reset combo if too much time has passed since the last swing ended
	if (tick() - lastSwingAt) >= COMBO_RESET_DELAY then
		comboIndex = 1
	end

	local entry = COMBO[comboIndex]
	print("[SwingAnimation] Swing combo", comboIndex, "animId=", entry.id)
	local track = getTrack(entry.id)
	if not track then
		warn("[SwingAnimation] BAIL: Could not load track for combo", comboIndex)
		return
	end
	print("[SwingAnimation] track loaded, Length=", track.Length)

	-- Stop all currently playing swing tracks
	for _, t in pairs(cachedTracks) do
		if t.IsPlaying then t:Stop(0) end
	end

	isSwinging = true
	track:Play(0)
	track:AdjustSpeed(entry.speed * SPEED_MULTIPLIER)
	print("[SwingAnimation] ▶ Playing swing", comboIndex, "speed=", entry.speed * SPEED_MULTIPLIER)

	-- Advance the sequence (wraps 4→1)
	comboIndex = (comboIndex % #COMBO) + 1

	-- Release the swing lock and stamp the reset timer when this animation finishes
	track.Stopped:Once(function()
		isSwinging = false
		lastSwingAt = tick()
	end)
end

-- ── Tool tracking ─────────────────────────────────────────────────────────────
local function onToolEquipped(tool)
	-- Always connect regardless of SkinId — the attribute may not have replicated
	-- from the server yet when ChildAdded fires. doSwing checks it at click time.
	currentTool = tool
	comboIndex  = 1
	lastSwingAt = 0
	if currentToolConn then currentToolConn:Disconnect() end
	currentToolConn = tool.Activated:Connect(doSwing)
	print("[SwingAnimation] tool equipped:", tool.Name, "SkinId:", tool:GetAttribute("SkinId"))
end

local function onToolUnequipped(tool)
	if tool == currentTool then
		if currentToolConn then
			currentToolConn:Disconnect()
			currentToolConn = nil
		end
		-- Stop any in-progress swing animation
		for _, t in pairs(cachedTracks) do
			if t.IsPlaying then t:Stop(0.1) end
		end
		currentTool = nil
		isSwinging  = false
		comboIndex  = 1
	end
end

-- ── Character setup ───────────────────────────────────────────────────────────
local function onCharacterAdded(character)
	-- Invalidate cached tracks — they belong to the previous Animator
	cachedTracks = {}
	isSwinging   = false
	comboIndex   = 1
	currentTool  = nil
	if currentToolConn then
		currentToolConn:Disconnect()
		currentToolConn = nil
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then onToolEquipped(child) end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then onToolUnequipped(child) end
	end)

	-- Already holding a tool on spawn
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then onToolEquipped(child) end
	end
end

-- ── Init ──────────────────────────────────────────────────────────────────────
if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

print("[SwingAnimation] 4-hit R15 melee combo initialized")
