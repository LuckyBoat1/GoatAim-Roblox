
local function printHierarchy(instance, indent)
    indent = indent or ""
    print(indent .. instance.Name .. " (" .. instance.ClassName .. ")")
    for _, child in ipairs(instance:GetChildren()) do
        printHierarchy(child, indent .. "  ")
    end
end

local arena = workspace:FindFirstChild("BullArena") or workspace:FindFirstChild("BullArena_1")
if arena then
    print("Found Arena: " .. arena.Name)
    printHierarchy(arena)
else
    print("BullArena not found in workspace")
end
