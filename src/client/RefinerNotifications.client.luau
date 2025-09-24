-- RefinerNotifications.client.luau
-- Shows floating notifications for refiner interactions

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Create notification system
local function createNotification(text, color, duration)
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create notification GUI if it doesn't exist
    local notificationGui = playerGui:FindFirstChild("RefinerNotifications")
    if not notificationGui then
        notificationGui = Instance.new("ScreenGui")
        notificationGui.Name = "RefinerNotifications"
        notificationGui.ResetOnSpawn = false
        notificationGui.Parent = playerGui
    end
    
    -- Create notification frame
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(0.5, -150, 0, -70)
    notification.BackgroundColor3 = color or Color3.fromRGB(40, 40, 40)
    notification.BorderSizePixel = 0
    notification.Parent = notificationGui
    
    -- Add corner and stroke
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = notification
    
    -- Add text
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = notification
    
    -- Animate in
    local slideIn = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -150, 0, 20)}
    )
    slideIn:Play()
    
    -- Wait and animate out
    spawn(function()
        wait(duration or 2)
        local slideOut = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = UDim2.new(0.5, -150, 0, -70),
                BackgroundTransparency = 1,
                TextTransparency = 1
            }
        )
        slideOut:Play()
        slideOut.Completed:Wait()
        notification:Destroy()
    end)
end

-- Export the function globally so other scripts can use it
_G.ShowRefinerNotification = createNotification

-- Example usage (can be called from other scripts):
-- _G.ShowRefinerNotification("🔒 Requires Rank 3!", Color3.fromRGB(255, 100, 100), 3)
-- _G.ShowRefinerNotification("💰 Not enough money!", Color3.fromRGB(255, 200, 100), 2)
-- _G.ShowRefinerNotification("✅ Refiner purchased!", Color3.fromRGB(100, 255, 100), 2)
