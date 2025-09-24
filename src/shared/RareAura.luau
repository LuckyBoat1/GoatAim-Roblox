-- RareAura Module - Creates green aura effects over rare weapon slots

local RareAura = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Create random particle effect
local function createRandomParticleEffect(container)
    local particlesFolder = ReplicatedStorage:FindFirstChild("Particles")
    if not particlesFolder then
        warn("RareAura: Particles folder not found in ReplicatedStorage")
        return
    end
    
    -- Get random particle from available decals
    local decals = {}
    for _, child in ipairs(particlesFolder:GetChildren()) do
        if child:IsA("Decal") or (child:IsA("StringValue") and child.Name:find("rbxassetid://")) then
            table.insert(decals, child)
        end
    end
    
    if #decals == 0 then
        warn("RareAura: No particle decals found")
        return
    end
    
    local randomDecal = decals[math.random(1, #decals)]
    local texture = randomDecal:IsA("Decal") and randomDecal.Texture or randomDecal.Value
    
    print("RareAura: Creating particle with texture:", texture)
    
    -- Create particle ImageLabel
    local particle = Instance.new("ImageLabel")
    particle.Name = "RareParticle_" .. tick()
    particle.Image = texture
    particle.BackgroundTransparency = 1
    
    -- Same sizing as epic particles - 225-330 pixels for 50% bigger particles
    local baseSize = math.random(225, 330)
    particle.Size = UDim2.new(0, baseSize, 0, baseSize)
    
    -- Random starting position around the container edges
    local edge = math.random(1, 4)
    if edge == 1 then -- Top
        particle.Position = UDim2.new(math.random(-50, 150) / 100, 0, -0.3, 0)
    elseif edge == 2 then -- Right
        particle.Position = UDim2.new(1.2, 0, math.random(-50, 150) / 100, 0)
    elseif edge == 3 then -- Bottom
        particle.Position = UDim2.new(math.random(-50, 150) / 100, 0, 1.2, 0)
    else -- Left
        particle.Position = UDim2.new(-0.3, 0, math.random(-50, 150) / 100, 0)
    end
    
    particle.AnchorPoint = Vector2.new(0.5, 0.5)
    particle.ImageColor3 = Color3.fromRGB(100, 150, 255) -- Blue color for rare particles
    particle.ImageTransparency = 1 -- Start invisible
    particle.ZIndex = container.ZIndex + 3
    particle.Parent = container
    
    -- Animate particle floating in and fading out
    local moveTween = TweenService:Create(
        particle,
        TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(0.5, 0, 0.5, 0), -- Move to center
            ImageTransparency = 0 -- Fade in
        }
    )
    
    local fadeOutTween = TweenService:Create(
        particle,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {
            ImageTransparency = 1, -- Fade out
            Size = UDim2.new(0, baseSize * 1.5, 0, baseSize * 1.5) -- Grow while fading
        }
    )
    
    moveTween:Play()
    
    -- Start fade out after 2 seconds
    task.wait(2)
    fadeOutTween:Play()
    
    fadeOutTween.Completed:Connect(function()
        if particle and particle.Parent then
            particle:Destroy()
        end
    end)
end

-- Get the RareAura decal from ReplicatedStorage  
local function getAuraDecal()
    local decalsFolder = ReplicatedStorage:FindFirstChild("Decals")
    if decalsFolder then
        local auraDecal = decalsFolder:FindFirstChild("RareAura")
        if auraDecal then
            print("RareAura: Found RareAura decal with texture:", auraDecal.Texture)
            return auraDecal.Texture
        else
            warn("RareAura: RareAura decal not found in Decals folder")
        end
    else
        warn("RareAura: Decals folder not found in ReplicatedStorage")
    end
    
    -- Fallback texture - same as epic but will be colored green
    return "rbxassetid://98886850679836"
end

local function createRareAuraEffect(slot, gridView)
    print("RAREAURA DEBUG: Creating rare particle aura for slot:", slot.Name)
    print("RAREAURA DEBUG: Slot size:", slot.Size, "position:", slot.Position)
    print("RAREAURA DEBUG: GridView:", gridView and gridView.Name or "nil")
    
    -- Create aura frame same size as epic (matching epic structure)
    local auraFrame = Instance.new("Frame")
    auraFrame.Name = "RareAura_Frame_" .. slot.Name
    auraFrame.Size = UDim2.new(0, 252, 0, 289) -- Made 10% wider (229*1.10=252) and 10% taller (263*1.10=289)
    auraFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    auraFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    auraFrame.BackgroundTransparency = 1
    auraFrame.ZIndex = 15 -- Same as epic
    auraFrame.Parent = slot
    
    -- Create rare aura decal
    local rareDecal = Instance.new("ImageLabel")
    rareDecal.Name = "RareAuraDecal"
    rareDecal.Size = UDim2.new(1, 0, 1, 0) -- Fill the frame
    rareDecal.Position = UDim2.new(0, 0, 0, 0)
    rareDecal.BackgroundTransparency = 1
    rareDecal.Image = getAuraDecal()
    rareDecal.ImageTransparency = 0 -- Fully visible
    -- No color tinting - use original texture colors
    rareDecal.ZIndex = auraFrame.ZIndex + 1
    rareDecal.Parent = auraFrame
    
    -- Simple pulsing animation like epic
    local pulseTween = TweenService:Create(
        rareDecal,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {ImageTransparency = 0.3} -- Pulse to slightly transparent
    )
    pulseTween:Play()
    
    -- Create RARE particle effects with custom decals - ONE AT A TIME!
    -- Create outer frame (no clipping) - 10% smaller than slot (same as epic)
    local outerParticleFrame = Instance.new("Frame")
    outerParticleFrame.Name = "OuterParticleFrame"
    outerParticleFrame.Size = UDim2.new(0.9, 0, 0.9, 0) -- 90% of slot size (10% smaller)
    outerParticleFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center it in the slot
    outerParticleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    outerParticleFrame.BackgroundTransparency = 1
    outerParticleFrame.ClipsDescendants = false -- No clipping on outer frame
    outerParticleFrame.ZIndex = auraFrame.ZIndex + 2
    outerParticleFrame.Parent = slot
    
    -- Create inner frame (with clipping) inside the outer frame
    local innerParticleFrame = Instance.new("Frame")
    innerParticleFrame.Name = "InnerParticleFrame"
    innerParticleFrame.Size = UDim2.new(1, 0, 1, 0) -- Full size of outer frame
    innerParticleFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center in outer frame
    innerParticleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    innerParticleFrame.BackgroundTransparency = 1
    innerParticleFrame.ClipsDescendants = true -- THIS CLIPS THE PARTICLES
    innerParticleFrame.ZIndex = outerParticleFrame.ZIndex + 1
    innerParticleFrame.Parent = outerParticleFrame -- Inside the outer frame
    
    task.spawn(function()
        -- Add initial random delay so slots don't all spawn at the same time
        local initialDelay = math.random(0, 60) -- Random delay up to 1 minute
        task.wait(initialDelay)
        
        while auraFrame.Parent do
            -- Wait for any existing particles to finish before spawning new one
            local existingParticles = {}
            for _, child in ipairs(innerParticleFrame:GetChildren()) do
                if child.Name:match("RareParticle_") then
                    table.insert(existingParticles, child)
                end
            end
            
            -- Only spawn if no particles exist
            if #existingParticles == 0 then
                createRandomParticleEffect(innerParticleFrame) -- Put particles in the INNER clipped frame
            end
            
            -- Wait 3 minutes (180 seconds) with small random variation
            local waitTime = 180 + math.random(-15, 15) -- 3 minutes ± 15 seconds for variety
            task.wait(waitTime)
        end
    end)
    
    print("RAREAURA DEBUG: Created rare aura with particle system")
    
    -- Cleanup function
    local function cleanup()
        print("RAREAURA DEBUG: Cleaning up rare aura and particles")
        if pulseTween then
            pulseTween:Cancel()
        end
        if auraFrame then 
            auraFrame:Destroy()
        end
    end
    
    return auraFrame, cleanup
end

function RareAura.ApplyRareAuraEffect(slot, gridView)
    if not slot then 
        return false, nil 
    end
    
    if not gridView then
        return false, nil
    end
    
    -- Remove any existing rare aura effects from this slot
    local existing = slot:FindFirstChild("RareAura_Frame_" .. slot.Name)
    if existing then 
        existing:Destroy() 
    end
    
    print("RAREAURA DEBUG: Applying rare aura to slot:", slot.Name)
    return createRareAuraEffect(slot, gridView)
end

-- Test function
function RareAura.Test()
    return "RareAura module is working!"
end

return RareAura
