-- set_aura_zoffset_commandbar.lua
-- Run in Roblox Studio Command Bar.
-- Walks MODEL_NAMES → part (Blue/Green/Orange/Part/Pink)
--   → attachment (Aura/Aura2/Aura3/Aura4) → ParticleEmitter
-- and assigns incrementing ZOffset values starting at 0.200.

local MODEL_NAMES = {
	"ZIndexTest", -- ← replace with your model name(s)
}

local PART_NAMES = { "Blue", "Green", "Orange", "Part", "Pink" }
local AURA_NAMES = { "Aura", "Aura2", "Aura3", "Aura4" }

local zOffset = 0.200
local updated = 0
local missed  = 0

for _, modelName in ipairs(MODEL_NAMES) do
	local model = game.Workspace:FindFirstChild(modelName, true)
	if not model then
		warn("[AuraZOffset] Model not found: " .. modelName)
		missed = missed + 1
		continue
	end

	for _, partName in ipairs(PART_NAMES) do
		local part = model:FindFirstChild(partName, true)
		if not part then
			warn("[AuraZOffset] Part not found: " .. partName .. " inside " .. modelName)
			missed = missed + 1
			continue
		end

		for _, auraName in ipairs(AURA_NAMES) do
			local attachment = part:FindFirstChild(auraName)
			if not attachment then
				warn("[AuraZOffset] Attachment not found: " .. auraName .. " inside " .. partName)
				missed = missed + 1
				continue
			end

			for _, child in ipairs(attachment:GetChildren()) do
				if child:IsA("ParticleEmitter") then
					child.ZOffset = zOffset
					print(string.format("[AuraZOffset] %s › %s › %s › %s  →  ZOffset = %.3f",
						modelName, partName, auraName, child.Name, zOffset))
					zOffset = zOffset + 0.001
					updated = updated + 1
				end
			end
		end
	end
end

print(string.format("\n[AuraZOffset] Done — %d emitters updated, %d warnings.", updated, missed))
