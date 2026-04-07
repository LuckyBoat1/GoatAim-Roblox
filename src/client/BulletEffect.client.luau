-- BulletEffect.client.luau
-- Listens for BulletEffectEvent fired by the server and plays the particle effect locally.
-- ParticleEmitter:Emit() only works client-side; server calls don't replicate.
--
-- Template structure expected in ReplicatedStorage > Bullets:
--   Model
--     Part
--       Attachment
--         ParticleEmitter   (one or more)
--       Attachment          (optional second)
--         ParticleEmitter

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Debris            = game:GetService("Debris")

local SkinConfig    = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkinConfig"))
local BulletsFolder = ReplicatedStorage:WaitForChild("Bullets", 10)

local BulletEffectEvent = ReplicatedStorage:WaitForChild("BulletEffectEvent", 10)
if not BulletEffectEvent then
	warn("[BulletEffect] BulletEffectEvent not found — effects will not play.")
	return
end

local BULLET_SPEED = 300  -- studs per second — raise for faster-looking shots

-- ── Rarity → template name resolver (mirrors server logic) ───────────────────
-- Explicit per-skin overrides (must match server side)
local SKIN_BULLET_OVERRIDE = {
	["Power"]       = "RedMatter",
	["Necromancer"] = "Darkness",
}

local function resolveBulletTemplate(skinId)
	if not BulletsFolder or not skinId then return nil end

	local override = SKIN_BULLET_OVERRIDE[skinId]
	if override then
		local t = BulletsFolder:FindFirstChild(override)
		if t then return t end
	end

	local meta   = SkinConfig.GetSkinMeta(skinId)
	local rarity = meta and meta.rarity or "common"
	local weapon = meta and meta.weapon or "Unknown"

	local candidates = {}

	if rarity == "mythic" or rarity == "legendary" then
		table.insert(candidates, "RedMatter")
	elseif rarity == "epic" then
		table.insert(candidates, "Darkness")
	elseif rarity == "rare" then
		table.insert(candidates, "Rare")
	else
		table.insert(candidates, "Common")
	end

	table.insert(candidates, "Rare")
	table.insert(candidates, "Common")

	for _, name in ipairs(candidates) do
		local t = BulletsFolder:FindFirstChild(name)
		if t then return t end
	end
	return nil
end

-- ── Effect player ─────────────────────────────────────────────────────────────
local function playEffect(skinId, startPos, endPos)
	local template = resolveBulletTemplate(skinId)
	if not template then
		warn("[BulletEffect] No template found for skin:", skinId)
		return
	end

	local effect = template:Clone()

	-- Find the BasePart — look for a direct child part first, then search deep
	local part
	if effect:IsA("Model") then
		-- Check PrimaryPart, then direct BasePart children, then deep search
		part = effect.PrimaryPart
		if not part then
			for _, child in ipairs(effect:GetChildren()) do
				if child:IsA("BasePart") then
					part = child
					break
				end
			end
		end
		if not part then
			part = effect:FindFirstChildWhichIsA("BasePart", true)
		end
	elseif effect:IsA("BasePart") then
		part = effect
	end

	if not part then
		warn("[BulletEffect] No BasePart found in template:", template.Name)
		effect:Destroy()
		return
	end

	part.CanCollide = false
	part.Anchored   = true

	if effect:IsA("Model") then
		effect.PrimaryPart = part
		effect:SetPrimaryPartCFrame(CFrame.lookAt(startPos, endPos))
	else
		effect.CFrame = CFrame.lookAt(startPos, endPos)
	end

	effect.Parent = workspace

	local meta   = SkinConfig.GetSkinMeta(skinId)
	local rarity = meta and meta.rarity or "common"
	local isHeavy = rarity == "epic" or rarity == "legendary" or rarity == "mythic"

	-- Must enable AFTER parenting to workspace
	local longestLifetime = 0.5
	for _, emitter in ipairs(effect:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			longestLifetime = math.max(longestLifetime, emitter.Lifetime.Max)
			emitter.Enabled = true   -- stream while bullet travels
			if isHeavy then
				emitter:Emit(5)      -- immediate burst for epic/legendary/mythic only
			end
		end
	end

	-- Travel from startPos → endPos, then stop emitting and clean up
	local direction   = (endPos - startPos).Unit
	local totalDist   = (endPos - startPos).Magnitude
	local travelled   = 0

	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local step = BULLET_SPEED * dt
		travelled += step

		if travelled >= totalDist then
			-- Arrived — stop emitters and let existing particles die out
			conn:Disconnect()
			for _, emitter in ipairs(effect:GetDescendants()) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Enabled = false
				end
			end
			Debris:AddItem(effect, longestLifetime + 0.25)
			return
		end

		local newPos = startPos + direction * travelled
		local cf = CFrame.lookAt(newPos, newPos + direction)
		if effect:IsA("Model") then
			effect:SetPrimaryPartCFrame(cf)
		else
			effect.CFrame = cf
		end
	end)
end

-- ── Listen ────────────────────────────────────────────────────────────────────
BulletEffectEvent.OnClientEvent:Connect(playEffect)

print("[BulletEffect] Ready.")
