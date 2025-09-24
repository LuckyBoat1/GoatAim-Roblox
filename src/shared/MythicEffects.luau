-- MythicEffects Module - Super simple, guaranteed to show lightning
local MythicEffects = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import MythicAura module
local MythicAura = require(script.Parent.MythicAura)

-- Blood-red color for mythic effects
local MYTHIC_RED = Color3.fromRGB(255, 30, 60)

-- SIMPLE POSITION SETTINGS - Change these to adjust lightning spawn area
local LIGHTNING_X_MIN = -34  -- Left boundary (made 10% smaller: -38*0.9 = -34.2 ≈ -34)
local LIGHTNING_X_MAX = 34   -- Right boundary (made 10% smaller: 38*0.9 = 34.2 ≈ 34)
local LIGHTNING_Y_MIN = -29  -- Top boundary (-29/100 = -0.29 scale units)
local LIGHTNING_Y_MAX = -29  -- Bottom boundary (-29/100 = -0.29 scale units)

-- Get all lightning decals from ReplicatedStorage
local function getAllLightningAssets()
    local assets = {}
    local decalsFolder = ReplicatedStorage:FindFirstChild("Decals")
    if decalsFolder then
        -- Get lightning assets (including Lightning Aura variants but excluding regular Aura)
        local lightningAssets = {
            "Lighting",
            "Lightning Aura", 
            "Lightning AuraI",
            "Lightning AuraO",
            "LightningTest",
            "LightningTest2",
            "roblox_asset_5864341017"
        }
        
        for _, assetName in pairs(lightningAssets) do
            local decal = decalsFolder:FindFirstChild(assetName)
            if decal then
                table.insert(assets, {texture = decal.Texture, name = assetName})
            end
        end
    end
    
    -- Fallback if none found
    if #assets == 0 then
        table.insert(assets, {texture = "rbxassetid://98886850679836", name = "Fallback Lightning"})
    end
    
    return assets
end

-- Get a random lightning asset with its name
local function getRandomLightningAsset()
    local assets = getAllLightningAssets()
    local chosen = assets[math.random(1, #assets)]
    return chosen
end

function MythicEffects.ApplyMythicFrameEffects(frame)
    if not frame then 
        return false, nil 
    end
    
    -- Remove any existing effects
    local existing = frame:FindFirstChild("MythicLightningEffects")
    if existing then 
        existing:Destroy() 
    end
    
    -- Remove any existing boundary lines from previous versions
    local boundariesToRemove = {"LeftBoundary", "RightBoundary", "TopBoundary", "BottomBoundary", "CenterDot"}
    for _, boundaryName in pairs(boundariesToRemove) do
        local boundary = frame:FindFirstChild(boundaryName)
        if boundary then
            boundary:Destroy()
        end
    end
    
    -- Create container
    local effectsContainer = Instance.new("Folder")
    effectsContainer.Name = "MythicLightningEffects"
    effectsContainer.Parent = frame
    
    -- Find viewport - this is the actual weapon display area
    local viewport = nil
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("ViewportFrame") then
            viewport = child
            break
        end
    end
    
    if not viewport then
        return false, nil
    end
    
    -- Don't clip lightning - let it extend beyond slot boundaries
    frame.ClipsDescendants = false
    
    -- Make weapon glow red
    if viewport then
        local worldModel = viewport:FindFirstChildOfClass("WorldModel")
        if worldModel then
            for _, part in pairs(worldModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Color = MYTHIC_RED
                    part.Material = Enum.Material.Neon
                end
            end
        end
    end
    
    -- No border stroke for mythic items (removed to avoid conflicting with inventory styling)
    
    -- Apply mythic aura effect (find grid UI)
    local auraCleanup = nil
    -- Use gridView as the aura parent for better scrolling and clipping
    local inventoryContainer = frame.Parent
    local gridView = inventoryContainer and inventoryContainer.Parent
    if gridView and gridView.Name == "GridView" then
        local _auraSuccess
        _auraSuccess, auraCleanup = MythicAura.ApplyMythicAuraEffect(frame, gridView)
    end
    
    -- Create effects
    local effects = {}
    
    -- Create 4 lightning strikes that appear randomly
    for i = 1, 4 do
        -- Main lightning bolt - use random asset from available lightning types
        local lightningAsset = getRandomLightningAsset()
        local lightning = Instance.new("ImageLabel")
        lightning.Name = "Lightning_Strike_" .. i
        lightning.Image = lightningAsset.texture
        
        -- Size effects - with specific sizing for Lightning Aura variants
        if lightningAsset.name == "Lightning AuraO" then
            lightning.Size = UDim2.new(1.006, 0, 1.257, 0) -- Lightning AuraO: 10% smaller (1.118*0.9=1.006, 1.397*0.9=1.257)
        elseif lightningAsset.name == "LightningTest" then
            lightning.Size = UDim2.new(1.328, 0, 1.106, 0) -- LightningTest: 10% smaller (1.475*0.9=1.328, 1.229*0.9=1.106)
        elseif lightningAsset.name == "Lightning AuraI" then
            lightning.Size = UDim2.new(1.162, 0, 1.006, 0) -- Lightning AuraI: 10% more wide (1.056*1.1=1.162, height unchanged)
        elseif lightningAsset.name == "Lightning Aura" then
            lightning.Size = UDim2.new(1.162, 0, 1.006, 0) -- Lightning Aura: 10% more wide (1.056*1.1=1.162, height unchanged)
        else
            lightning.Size = UDim2.new(1.006, 0, 1.006, 0) -- All other lightning: 10% smaller (1.118*0.9=1.006)
        end
        
        -- ONLY ONE POSITION SETTING - position lightning directly in weapon slot
        local randomX = math.random(LIGHTNING_X_MIN, LIGHTNING_X_MAX) / 100
        local randomY = math.random(LIGHTNING_Y_MIN, LIGHTNING_Y_MAX) / 100
        local finalX = 0.5 + randomX -- Center with variation
        local finalY = 0.5 + randomY -- Center vertically with variation
        lightning.Position = UDim2.new(finalX, 0, finalY, 0)
        
        lightning.AnchorPoint = Vector2.new(0.4, 0.2)
        lightning.BackgroundTransparency = 1
        lightning.ImageColor3 = MYTHIC_RED -- Force red color
        lightning.ImageTransparency = 1 -- Start invisible
        lightning.ZIndex = 6 -- Same as other slot elements (not super high)
        
        -- Force all lightning to use exact same color by overriding base colors
        lightning.BorderSizePixel = 0
        lightning.ScaleType = Enum.ScaleType.Stretch -- Ensure consistent scaling
        
        -- Override any base image colors to ensure pure red appearance
        lightning.TileSize = UDim2.new(1, 0, 1, 0) -- Prevent tiling effects
        lightning.SliceCenter = Rect.new(0, 0, 0, 0) -- Disable slicing that might affect color
        
        -- Add edge fading for "Lighting" asset (the one with flat edges)
        if lightningAsset.name == "Lighting" then
            local gradient = Instance.new("UIGradient")
            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.9), -- 0.9 transparency at edges (only 10% visible)
                NumberSequenceKeypoint.new(0.5, 0), -- Fully opaque in center
                NumberSequenceKeypoint.new(1, 0.9)  -- 0.9 transparency at edges (only 10% visible)
            })
            gradient.Rotation = 0 -- Horizontal gradient for edge fading
            gradient.Parent = lightning
        end
        
        lightning.Parent = frame -- Put lightning back in the slot frame (not viewport)
        
        table.insert(effects, lightning)
    end
    
    -- Lightning strike animation - continuous effects with no gaps but same speed
    local animationRunning = true
    
    task.spawn(function()
        -- Start with an immediate effect to ensure no initial gap
        local initialStrike = effects[math.random(1, #effects)]
        if initialStrike and initialStrike.Parent then
            task.spawn(function()
                initialStrike.ImageTransparency = 0
                task.wait(0.055)
                initialStrike.ImageTransparency = 0.8
                task.wait(0.022)
                initialStrike.ImageTransparency = 0
                task.wait(0.033)
                for transparency = 0, 1, 0.2 do
                    initialStrike.ImageTransparency = transparency
                    task.wait(0.01)
                end
                initialStrike.ImageTransparency = 1
            end)
        end
        
        while animationRunning do
            -- Random lightning spawning - limit to max 2 overlapping strikes
            local numStrikes = 1
            if math.random() < 0.6 then -- Reduced chance for multiple strikes
                numStrikes = 2 -- Maximum 2 simultaneous strikes only
            end
            
            -- Create the lightning strikes
            for i = 1, numStrikes do
                local randomStrike = effects[math.random(1, #effects)]
                if randomStrike and randomStrike.Parent then
                    task.spawn(function() -- Run each strike independently
                        -- Pick new random asset each time lightning strikes
                        local newLightningAsset = getRandomLightningAsset()
                        randomStrike.Image = newLightningAsset.texture
                        
                        -- Print which asset is being used
                        -- print("Lightning Strike using:", newLightningAsset.name)
                        
                        -- Update size based on the new asset - with specific sizing for Lightning Aura variants
                        if newLightningAsset.name == "Lightning AuraO" then
                            randomStrike.Size = UDim2.new(1.006, 0, 1.257, 0) -- Lightning AuraO: 10% smaller again
                        elseif newLightningAsset.name == "LightningTest" then
                            randomStrike.Size = UDim2.new(1.328, 0, 1.106, 0) -- LightningTest: 10% smaller again
                        elseif newLightningAsset.name == "Lightning AuraI" then
                            randomStrike.Size = UDim2.new(1.162, 0, 1.006, 0) -- Lightning AuraI: 10% more wide
                        elseif newLightningAsset.name == "Lightning Aura" then
                            randomStrike.Size = UDim2.new(1.162, 0, 1.006, 0) -- Lightning Aura: 10% more wide
                        else
                            randomStrike.Size = UDim2.new(1.006, 0, 1.006, 0) -- All other lightning: 10% smaller again
                        end
                        
                        -- Remove any existing gradient first
                        local existingGradient = randomStrike:FindFirstChild("UIGradient")
                        if existingGradient then
                            existingGradient:Destroy()
                        end
                        
                        -- Add edge fading for "Lighting" asset (the one with flat edges)
                        if newLightningAsset.name == "Lighting" then
                            local gradient = Instance.new("UIGradient")
                            gradient.Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0.9), -- 0.9 transparency at edges (only 10% visible)
                                NumberSequenceKeypoint.new(0.5, 0), -- Fully opaque in center
                                NumberSequenceKeypoint.new(1, 0.9)  -- 0.9 transparency at edges (only 10% visible)
                            })
                            gradient.Rotation = 0 -- Horizontal gradient for edge fading
                            gradient.Parent = randomStrike
                        end
                        
                        -- Randomize position each time lightning strikes
                        local newRandomX = math.random(LIGHTNING_X_MIN, LIGHTNING_X_MAX) / 100
                        local newRandomY = math.random(LIGHTNING_Y_MIN, LIGHTNING_Y_MAX) / 100
                        randomStrike.Position = UDim2.new(0.5 + newRandomX, 0, 0.5 + newRandomY, 0)
                        
                        -- Regular lightning flash sequence - like real lightning with 10% longer duration and fade out
                        randomStrike.ImageTransparency = 0 -- Fully visible instantly
                        task.wait(0.055) -- 10% longer initial flash (was 0.05, now 0.055)
                        
                        randomStrike.ImageTransparency = 0.8 -- Dim quickly
                        task.wait(0.022) -- 10% longer brief pause (was 0.02, now 0.022)
                        
                        randomStrike.ImageTransparency = 0 -- Flash again
                        task.wait(0.033) -- 10% longer second flash (was 0.03, now 0.033)
                        
                        -- Add fade out effect instead of instant disappear
                        for transparency = 0, 1, 0.2 do
                            randomStrike.ImageTransparency = transparency
                            task.wait(0.01) -- Smooth fade over 0.05 seconds
                        end
                        randomStrike.ImageTransparency = 1 -- Ensure fully transparent
                    end)
                end
                
                -- Small delay between multiple strikes if happening together
                if i < numStrikes then
                    task.wait(0.01)
                end
            end
            
            -- Keep original random delay between strike events (0.2 to 1.0 seconds) - NOT faster
            task.wait(math.random(20, 100) / 100)
        end
    end)
    
    -- Cleanup function
    local function cleanup()
        animationRunning = false -- Stop the animation loop
        
        for _, effect in ipairs(effects) do
            if effect and effect.Parent then
                effect:Destroy()
            end
        end
        
        -- No stroke to cleanup (removed stroke creation)
        
        if effectsContainer and effectsContainer.Parent then
            effectsContainer:Destroy()
        end
        
        -- Cleanup aura effects
        if auraCleanup then
            auraCleanup()
        end
        
        -- Restore weapon colors
        if viewport then
            local worldModel = viewport:FindFirstChildOfClass("WorldModel")
            if worldModel then
                for _, part in pairs(worldModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Color = Color3.new(1, 1, 1)
                        part.Material = Enum.Material.Plastic
                    end
                end
            end
        end
    end
    
    return true, cleanup
end

function MythicEffects.ApplyMythicModelEffects(model)
    if not model then 
        return false, nil 
    end
    
    local originalColors = {}
    local originalMaterials = {}
    
    -- Make all parts glow red
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Store original values
            originalColors[part] = part.Color
            originalMaterials[part] = part.Material
            
            -- Apply mythic effects
            part.Color = MYTHIC_RED
            part.Material = Enum.Material.Neon
        end
    end
    
    -- Cleanup function for model effects
    local function cleanupModel()
        for part, originalColor in pairs(originalColors) do
            if part and part.Parent then
                part.Color = originalColor
                part.Material = originalMaterials[part] or Enum.Material.Plastic
            end
        end
    end
    
    return true, cleanupModel
end

-- Test function for debugging
function MythicEffects.Test()
    return "MythicEffects module is working!"
end

-- The rest of your code remains unchanged...

return MythicEffects