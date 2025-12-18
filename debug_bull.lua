
local function inspectBull()
	local arena = workspace:FindFirstChild("BullArena_1") or workspace:FindFirstChild("BullArena")
	if not arena then
		warn("BullArena not found")
		return
	end
	
	local bull = arena:FindFirstChild("bull")
	if not bull then
		warn("Bull not found in arena")
		return
	end
	
	print("Inspecting Bull:", bull:GetFullName())
	for _, part in ipairs(bull:GetDescendants()) do
		if part:IsA("BasePart") then
			print(string.format("Part: %s | CanCollide: %s | CanQuery: %s | CanTouch: %s | Transparency: %s | Size: %s",
				part.Name,
				tostring(part.CanCollide),
				tostring(part.CanQuery),
				tostring(part.CanTouch),
				tostring(part.Transparency),
				tostring(part.Size)
			))
		end
	end
end

inspectBull()
