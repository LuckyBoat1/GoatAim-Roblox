-- Client-side effect spawner (instant, no replication delay)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- Wait for RemoteEvent
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local spawnEffectEvent = remoteEvents:WaitForChild("SpawnEffectEvent")

local effectsFolder = ReplicatedStorage:WaitForChild("Effects")

spawnEffectEvent.OnClientEvent:Connect(function(effectName, npcModel, attachmentName, targetPosition, duration)
	duration = duration or 5
	
	-- Find the attachment on the NPC
	local attachment = npcModel and npcModel:FindFirstChild(attachmentName, true)
	if not attachment then
		warn("[EffectSpawner] Could not find attachment:", attachmentName, "on", npcModel)
		return
	end
	
	-- Get the effect template
	local effectTemplate = effectsFolder:FindFirstChild(effectName)
	if not effectTemplate then
		warn("[EffectSpawner] Could not find effect:", effectName)
		return
	end
	
	-- Rotate attachment to face target ONCE and lock it
	local lockedCFrame
	if targetPosition then
		local startPos = attachment.WorldPosition
		lockedCFrame = CFrame.lookAt(startPos, targetPosition)
		attachment.WorldCFrame = lockedCFrame
	end
	
	-- Clone and parent the effect
	local effectClone = effectTemplate:Clone()
	
	-- Collect all emitters FIRST (before parenting)
	local emitters = {}
	for _, child in ipairs(effectClone:GetDescendants()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false -- Make sure they're off initially
			table.insert(emitters, child)
		end
	end
	if effectClone:IsA("ParticleEmitter") then
		effectClone.Enabled = false
		table.insert(emitters, effectClone)
	end
	
	-- Parent AFTER collecting (so they don't start emitting early)
	effectClone.Parent = attachment
	
	-- Enable ALL emitters at the exact same moment
	for _, emitter in ipairs(emitters) do
		emitter.Enabled = true
	end
	
	-- Keep attachment locked in place during the effect (prevents spiral gaps)
	if lockedCFrame then
		task.spawn(function()
			local startTime = tick()
			while tick() - startTime < duration and effectClone.Parent do
				attachment.WorldCFrame = lockedCFrame
				task.wait()
			end
		end)
	end
	
	-- Cleanup after duration
	Debris:AddItem(effectClone, duration)
end)

print("[EffectSpawner] Client effect spawner ready")
