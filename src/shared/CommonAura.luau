-- CommonAura Module - Creates simple aura effects over common weapon slots

local CommonAura = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get the CommonAura decal from ReplicatedStorage  
local function getAuraDecal()
    local decalsFolder = ReplicatedStorage:FindFirstChild("Decals")
    if decalsFolder then
        local auraDecal = decalsFolder:FindFirstChild("CommonAura")
        if auraDecal then
            return auraDecal.Texture
        else
            warn("CommonAura: CommonAura decal not found in Decals folder")
        end
    else
        warn("CommonAura: Decals folder not found in ReplicatedStorage")
    end
    
    -- Fallback texture
    return "rbxassetid://98886850679836"
end

local function createCommonAuraEffect(slot, gridView)
    -- Create aura frame 5% smaller than other rarities
    local auraFrame = Instance.new("Frame")
    auraFrame.Name = "CommonAura_Frame_" .. slot.Name
    auraFrame.Size = UDim2.new(0, 239, 0, 275) -- Made 10% wider (217*1.10=239) and 10% taller (250*1.10=275)
    auraFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    auraFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    auraFrame.BackgroundTransparency = 1
    auraFrame.ZIndex = 15 -- Same as other rarities
    auraFrame.Parent = slot
    
    -- Create common aura decal
    local commonDecal = Instance.new("ImageLabel")
    commonDecal.Name = "CommonAuraDecal"
    commonDecal.Size = UDim2.new(1, 0, 1, 0) -- Fill the frame
    commonDecal.Position = UDim2.new(0, 0, 0, 0)
    commonDecal.BackgroundTransparency = 1
    commonDecal.Image = getAuraDecal()
    commonDecal.ImageTransparency = 0 -- Fully visible
    -- No color tinting - use original texture colors
    commonDecal.ZIndex = auraFrame.ZIndex + 1
    commonDecal.Parent = auraFrame
    
    -- Simple pulsing animation like other rarities
    local pulseTween = TweenService:Create(
        commonDecal,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {ImageTransparency = 0.3} -- Pulse to slightly transparent
    )
    pulseTween:Play()
    
    -- No particles for common rarity - just the aura decal
    
    -- Cleanup function
    local function cleanup()
        if pulseTween then
            pulseTween:Cancel()
        end
        if auraFrame then 
            auraFrame:Destroy()
        end
    end
    
    return auraFrame, cleanup
end

function CommonAura.ApplyCommonAuraEffect(slot, gridView)
    if not slot then 
        return false, nil 
    end
    
    if not gridView then
        return false, nil
    end
    
    -- Remove any existing common aura effects from this slot
    local existing = slot:FindFirstChild("CommonAura_Frame_" .. slot.Name)
    if existing then 
        existing:Destroy() 
    end
    
    return createCommonAuraEffect(slot, gridView)
end

-- Test function
function CommonAura.Test()
    return "CommonAura module is working!"
end

return CommonAura
