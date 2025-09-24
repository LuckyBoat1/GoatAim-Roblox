-- Test script to debug ItemEffects loading
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== ItemEffects Loading Test ===")

-- Wait for Shared folder
local shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not shared then
    warn("Shared folder not found!")
    return
end

print("Shared folder found:", shared)

-- List contents of Shared
print("Contents of Shared:")
for _, child in ipairs(shared:GetChildren()) do
    print("  -", child.Name, child.ClassName)
end

-- Try to load ItemEffects
local success, result = pcall(function()
    return require(shared:WaitForChild("ItemEffects", 5))
end)

if success then
    print("✅ ItemEffects loaded successfully!")
    print("ItemEffects functions:", result)
    
    -- Test if the functions exist
    if result.ApplyMythicFrameEffects then
        print("✅ ApplyMythicFrameEffects function exists")
    else
        print("❌ ApplyMythicFrameEffects function missing")
    end
    
    if result.ApplyLegendaryFrameEffects then
        print("✅ ApplyLegendaryFrameEffects function exists")
    else
        print("❌ ApplyLegendaryFrameEffects function missing")
    end
else
    print("❌ Failed to load ItemEffects:")
    print("Error:", result)
end
