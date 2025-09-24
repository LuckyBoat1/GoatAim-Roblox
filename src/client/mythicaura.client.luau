-- MythicAura Client Script - Places red aura over mythic slots
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Blood-red color for mythic aura
local MYTHIC_RED = Color3.fromRGB(255, 30, 60)

-- Get the Aura decal from ReplicatedStorage
local function getAuraDecal()
    local decalsFolder = ReplicatedStorage:FindFirstChild("Decals")
    if decalsFolder then
        local auraDecal = decalsFolder:FindFirstChild("Aura")
        if auraDecal then
            print("MythicAura: Found Aura decal with texture:", auraDecal.Texture)
            return auraDecal.Texture
        else
            warn("MythicAura: Aura decal not found in Decals folder")
        end
    else
        warn("MythicAura: Decals folder not found in ReplicatedStorage")
    end
    
    -- Fallback texture
    return "rbxassetid://98886850679836"
end

-- Create aura effect over a mythic slot, parented to inventory container
local function createAuraEffect(slotFrame, inventoryContainer)
    if not slotFrame or not inventoryContainer then 
        warn("MythicAura: Missing slotFrame or inventoryContainer")
        return 
    end
    
    -- Remove existing aura if present
    local existingAura = inventoryContainer:FindFirstChild("MythicAura_" .. slotFrame.Name)
    if existingAura then
        existingAura:Destroy()
    end
    
    -- Create aura ImageLabel
    local aura = Instance.new("ImageLabel")
    aura.Name = "MythicAura_" .. slotFrame.Name
    aura.Image = getAuraDecal()
    
    -- Make it much bigger and more visible
    aura.Size = UDim2.new(0, slotFrame.AbsoluteSize.X * 2.5, 0, slotFrame.AbsoluteSize.Y * 2.5) -- Even bigger for visibility
    
    -- Position aura at the same absolute position as the slot
    local slotPosition = slotFrame.AbsolutePosition
    local containerPosition = inventoryContainer.AbsolutePosition
    local relativeX = slotPosition.X - containerPosition.X
    local relativeY = slotPosition.Y - containerPosition.Y
    
    -- Center the aura on the slot position with better offset
    local offsetX = (slotFrame.AbsoluteSize.X * 2.5 - slotFrame.AbsoluteSize.X) / 2
    local offsetY = (slotFrame.AbsoluteSize.Y * 2.5 - slotFrame.AbsoluteSize.Y) / 2
    
    aura.Position = UDim2.new(0, relativeX - offsetX, 0, relativeY - offsetY)
    aura.AnchorPoint = Vector2.new(0, 0)
    aura.BackgroundTransparency = 1
    aura.ImageColor3 = MYTHIC_RED
    aura.ImageTransparency = 0.3 -- More visible (was 0.5)
    aura.ZIndex = 15 -- Very high to ensure visibility
    aura.BorderSizePixel = 0
    aura.ScaleType = Enum.ScaleType.Stretch
    
    aura.Parent = inventoryContainer -- Parent to inventory container, not the slot
    
    print("MythicAura: Created aura at position:", aura.Position, "size:", aura.Size)
    
    -- Gentle pulsing animation
    local pulseConnection
    pulseConnection = RunService.Heartbeat:Connect(function()
        if not aura or not aura.Parent then
            if pulseConnection then
                pulseConnection:Disconnect()
            end
            return
        end
        
        local time = tick()
        local pulse = 0.3 + math.sin(time * 2) * 0.15 -- Pulse between 0.15 and 0.45 transparency for better visibility
        aura.ImageTransparency = pulse
    end)
    
    print("MythicAura: Created aura effect for slot:", slotFrame.Name, "parented to inventory container")
    return aura
end

-- Find and apply aura to mythic slots
local function applyAuraToMythicSlots()
    -- Wait for inventory GUI to load
    local inventoryGui = playerGui:WaitForChild("InventoryGUI", 10)
    if not inventoryGui then
        warn("MythicAura: InventoryGUI not found")
        return
    end
    
    -- Find inventory container
    local inventoryContainer = inventoryGui:FindFirstChild("InventoryContainer")
    if not inventoryContainer then
        warn("MythicAura: InventoryContainer not found")
        return
    end
    
    print("MythicAura: Found InventoryContainer, searching for mythic slots...")
    
    -- Function to check and apply aura to slots
    local function checkSlots()
        for _, child in pairs(inventoryContainer:GetDescendants()) do
            if child:IsA("Frame") and (child.Name:find("Slot") or child.Name:find("slot")) then
                -- Check if this slot has mythic lightning effects (more reliable detection)
                local lightningEffects = child:FindFirstChild("MythicLightningEffects")
                local hasStroke = child:FindFirstChild("UIStroke")
                
                if lightningEffects or (hasStroke and hasStroke.Color == MYTHIC_RED) then
                    -- This is a mythic slot, add aura (parented to inventory container)
                    print("MythicAura: Found mythic slot:", child.Name)
                    createAuraEffect(child, inventoryContainer)
                else
                    -- Remove aura if no longer mythic
                    local existingAura = inventoryContainer:FindFirstChild("MythicAura_" .. child.Name)
                    if existingAura then
                        existingAura:Destroy()
                        print("MythicAura: Removed aura from non-mythic slot:", child.Name)
                    end
                end
            end
        end
    end
    
    -- Initial check
    checkSlots()
    
    -- Monitor for new slots being added
    inventoryContainer.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Frame") and descendant.Name:find("Slot") then
            task.wait(0.1) -- Wait a moment for the slot to be fully set up
            checkSlots()
        end
    end)
    
    -- Periodic check for mythic status changes
    task.spawn(function()
        while true do
            task.wait(2) -- Check every 2 seconds
            checkSlots()
        end
    end)
end

-- Start the aura system
print("MythicAura: Starting mythic aura system...")
applyAuraToMythicSlots()
