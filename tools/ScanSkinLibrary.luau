-- Temporary script to scan SkinLibrary and list all actual items
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function scanSkinLibrary()
    local skinLibrary = ReplicatedStorage:FindFirstChild("SkinLibrary")
    if not skinLibrary then
        warn("SkinLibrary not found in ReplicatedStorage!")
        return
    end
    
    print("=== ACTUAL SKINLIBRARY CONTENTS ===")
    local items = {}
    
    for _, model in ipairs(skinLibrary:GetChildren()) do
        if model:IsA("Model") or model:IsA("MeshPart") or model:IsA("BasePart") then
            table.insert(items, model.Name)
        end
    end
    
    -- Sort alphabetically
    table.sort(items)
    
    print(string.format("Found %d items in SkinLibrary:", #items))
    for i, itemName in ipairs(items) do
        print(string.format("[%d] '%s'", i, itemName))
    end
    print("=== END SKINLIBRARY SCAN ===")
    
    return items
end

-- Run the scan
scanSkinLibrary()
