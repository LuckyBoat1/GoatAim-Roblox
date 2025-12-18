local workspace = game:GetService("Workspace")

local modelName = "BullArena"
-- Search recursively in case it's inside a folder like "BullArena"
local model = workspace:FindFirstChild(modelName, true)

if not model then
	warn("Could not find model: " .. modelName)
	return
end

local count = 0
for _, descendant in ipairs(model:GetDescendants()) do
	if descendant:IsA("BasePart") then
		descendant.Anchored = true
		count = count + 1
	end
end

print("✅ Successfully anchored " .. count .. " parts in " .. modelName)
