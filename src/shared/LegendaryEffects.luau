-- LegendaryEffects.luau
-- Fire effects for legendary rarity weapons in inventory slots

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Fire particle effect creator
local function createFireParticle(container)
    -- Get fire particle from ReplicatedStorage/Particles
    local particlesFolder = ReplicatedStorage:FindFirstChild("Particles")
    if not particlesFolder then
        warn("LegendaryEffects: Particles folder not found!")
        return
    end
    
    -- Look for fire-like particles (you can adjust this to match your particle names)
    local fireParticles = {}
    for _, child in ipairs(particlesFolder:GetChildren()) do
        if child:IsA("Decal") and child.Name:match("Particle%d+") then
            table.insert(fireParticles, child)
        end
    end
    
    if #fireParticles == 0 then
        warn("LegendaryEffects: No fire particles found!")
        return
    end
    
    -- Choose random fire particle
    local randomFireParticle = fireParticles[math.random(1, #fireParticles)]
    
    -- Create ImageLabel for the fire particle
    local fireParticle = Instance.new("ImageLabel")
    fireParticle.Name = "LegendaryFire_" .. randomFireParticle.Name
    fireParticle.Image = randomFireParticle.Texture
    fireParticle.BackgroundTransparency = 1
    fireParticle.ImageTransparency = 1 -- Start invisible
    
    -- Fire particle size (medium-large)
    local size = math.random(80, 140)
    fireParticle.Size = UDim2.fromOffset(size, size)
    
    -- Spawn near bottom of container (fire rises up)
    local containerWidth = container.AbsoluteSize.X
    local containerHeight = container.AbsoluteSize.Y
    local margin = size / 2
    
    local spawnX = math.random(margin, math.max(margin, containerWidth - margin))
    local spawnY = containerHeight - margin -- Start near bottom
    fireParticle.Position = UDim2.fromOffset(spawnX, spawnY)
    fireParticle.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Fire colors (orange/red/yellow)
    local fireColors = {
        Color3.fromRGB(255, 140, 0),   -- Orange
        Color3.fromRGB(255, 100, 0),   -- Red-orange
        Color3.fromRGB(255, 200, 0),   -- Yellow-orange
        Color3.fromRGB(255, 69, 0),    -- Red
        Color3.fromRGB(255, 215, 0),   -- Gold
    }
    fireParticle.ImageColor3 = fireColors[math.random(1, #fireColors)]
    
    fireParticle.ZIndex = 25
    fireParticle.Parent = container
    
    -- Fire rises up and gets smaller
    local endY = margin -- Rise to top
    local endSize = math.random(40, 80) -- Shrink as it rises
    
    -- Movement time (fire moves quickly upward)
    local moveTime = math.random(8, 12) -- 8-12 seconds
    
    -- Fade in quickly
    local fadeIn = TweenService:Create(fireParticle,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {ImageTransparency = 0}
    )
    
    -- Move upward and shrink (like real fire)
    local moveTween = TweenService:Create(fireParticle,
        TweenInfo.new(moveTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {
            Position = UDim2.fromOffset(spawnX + math.random(-20, 20), endY),
            Size = UDim2.fromOffset(endSize, endSize)
        }
    )
    
    -- Fade out near the end
    local fadeOut = TweenService:Create(fireParticle,
        TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {ImageTransparency = 1}
    )
    
    -- Start animations
    fadeIn:Play()
    moveTween:Play()
    
    fadeIn.Completed:Connect(function()
        task.wait(moveTime - 3) -- Start fading out before movement ends
        fadeOut:Play()
    end)
    
    fadeOut.Completed:Connect(function()
        fireParticle:Destroy()
    end)
end

-- Get the legendary aura decal from ReplicatedStorage  
local function getLegendaryAuraDecal()
    local decalsFolder = ReplicatedStorage:FindFirstChild("Decals")
    if decalsFolder then
        local legendaryDecal = decalsFolder:FindFirstChild("LegendaryAura")
        if legendaryDecal then
            return legendaryDecal.Texture
        else
            warn("LegendaryEffects: LegendaryAura decal not found in Decals folder")
        end
    else
        warn("LegendaryEffects: Decals folder not found in ReplicatedStorage")
    end
    
    -- Fallback texture (you can replace with actual legendary texture)
    return "rbxassetid://98886850679836"
end

local function createLegendaryFireEffect(slot, gridView)
    -- Create aura frame
    local auraFrame = Instance.new("Frame")
    auraFrame.Name = "LegendaryAura_Frame_" .. slot.Name
    auraFrame.Size = UDim2.new(0, 199, 0, 250) -- Standard aura size
    auraFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    auraFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    auraFrame.BackgroundTransparency = 1
    auraFrame.ZIndex = 15
    auraFrame.Parent = slot
    
    -- Create legendary aura decal (background)
    local legendaryDecal = Instance.new("ImageLabel")
    legendaryDecal.Name = "LegendaryAuraDecal"
    legendaryDecal.Size = UDim2.new(1, 0, 1, 0)
    legendaryDecal.Position = UDim2.new(0, 0, 0, 0)
    legendaryDecal.BackgroundTransparency = 1
    legendaryDecal.Image = getLegendaryAuraDecal()
    legendaryDecal.ImageTransparency = 0
    legendaryDecal.ZIndex = auraFrame.ZIndex + 1
    legendaryDecal.Parent = auraFrame
    
    -- Pulsing animation for the aura
    local pulseTween = TweenService:Create(
        legendaryDecal,
        TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {ImageTransparency = 0.2}
    )
    pulseTween:Play()
    
    -- Create fire particle container (inside the slot, 10% smaller)
    local fireFrame = Instance.new("Frame")
    fireFrame.Name = "LegendaryFireFrame"
    fireFrame.Size = UDim2.new(0.9, 0, 0.9, 0) -- 10% smaller than slot
    fireFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    fireFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fireFrame.BackgroundTransparency = 1
    fireFrame.ClipsDescendants = true -- Clip fire particles
    fireFrame.ZIndex = auraFrame.ZIndex + 2
    fireFrame.Parent = slot
    
    -- Fire particle spawning loop (2-3 particles at a time for fire effect)
    task.spawn(function()
        while auraFrame.Parent do
            -- Check existing fire particles
            local existingFires = {}
            for _, child in ipairs(fireFrame:GetChildren()) do
                if child.Name:match("LegendaryFire_") then
                    table.insert(existingFires, child)
                end
            end
            
            -- Spawn fire if we have less than 3 particles (for continuous fire effect)
            if #existingFires < 3 then
                createFireParticle(fireFrame)
            end
            
            task.wait(math.random(2, 4)) -- Spawn new fire every 2-4 seconds
        end
    end)
    
    -- Cleanup function
    local function cleanup()
        if pulseTween then
            pulseTween:Cancel()
        end
        if auraFrame then 
            auraFrame:Destroy()
        end
        if fireFrame then
            fireFrame:Destroy()
        end
    end
    
    return auraFrame, cleanup
end

return {
    createLegendaryFireEffect = createLegendaryFireEffect
}
