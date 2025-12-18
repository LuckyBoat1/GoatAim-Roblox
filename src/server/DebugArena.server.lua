local function dumpHierarchy(instance, indent)
	indent = indent or ""
	print(indent .. instance.Name .. " (" .. instance.ClassName .. ")")
	for _, child in ipairs(instance:GetChildren()) do
		dumpHierarchy(child, indent .. "  ")
	end
end

print("=" .. string.rep("=", 50))
print("🕵️ DEBUG: DUMPING BULL ARENA HIERARCHY")
print("=" .. string.rep("=", 50))

local arena = workspace:WaitForChild("BullArena", 1)
if arena then
	dumpHierarchy(arena)
else
	print("❌ BullArena not found in Workspace!")
end

print("=" .. string.rep("=", 50))
print("🕵️ DEBUG DUMP COMPLETE")
print("=" .. string.rep("=", 50))
