-- GripAdjuster LocalScript - Shows grip adjustment UI when weapon is equipped
-- Put this in StarterGui or client scripts folder

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = nil
local currentTool = nil

-- DO NOT keep persistent grip adjustment values - reset each weapon switch
-- local persistentX, persistentY, persistentZ = 0, 0, 0

-- Slider references (will be set when UI is created)
local xSlider, ySlider, zSlider = nil, nil, nil

-- Function to update grip in real-time
local function updateGrip()
    if not currentTool or not xSlider or not ySlider or not zSlider then return end
    
    local x = tonumber(xSlider.Text) or 0
    local y = tonumber(ySlider.Text) or 0
    local z = tonumber(zSlider.Text) or 0
    
    -- Use grip after server processing (with rotations) but store it once to prevent stacking
    local baseGrip = currentTool:GetAttribute("ClientBaseGrip")
    if not baseGrip then
        -- Wait a moment for server to finish processing, then store the result
        wait(0.1)
        baseGrip = currentTool.Grip
        currentTool:SetAttribute("ClientBaseGrip", baseGrip)
        print("[GripAdjuster] Stored base grip (after server rotation):", baseGrip)
    end
    
    -- Use same calculation method as server: originalGrip * adjustment
    local adjustment = CFrame.new(x, y, z)  
    currentTool.Grip = baseGrip * adjustment
    
    print("[GripAdjuster] Applied adjustment (" .. x .. ", " .. y .. ", " .. z .. ") to base grip")
end

-- Create the grip adjustment UI
local function createGripUI()
    if gui then gui:Destroy() end
    
    gui = Instance.new("ScreenGui")
    gui.Parent = playerGui
    gui.Name = "GripAdjuster"
    gui.ResetOnSpawn = false
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 220, 0, 200)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -100) -- Left side, centered vertically
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
    mainFrame.Parent = gui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "Grip Adjuster ✓"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    title.BorderSizePixel = 0
    title.Parent = mainFrame
    
    -- Create sliders for X, Y, Z
    local function createSlider(name, position, defaultValue)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 40)
        frame.Position = UDim2.new(0, 10, 0, position)
        frame.BackgroundTransparency = 1
        frame.Parent = mainFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 30, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.Text = name .. ":"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextScaled = true
        label.BackgroundTransparency = 1
        label.Parent = frame
        
        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(0, 60, 0, 30)
        textBox.Position = UDim2.new(0, 40, 0, 5)
        textBox.Text = tostring(defaultValue)
        textBox.TextColor3 = Color3.new(1, 1, 1)
        textBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        textBox.BorderSizePixel = 1
        textBox.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
        textBox.TextScaled = true
        textBox.ClearTextOnFocus = false
        textBox.Name = name
        textBox.Parent = frame
        
        -- Plus button
        local plusBtn = Instance.new("TextButton")
        plusBtn.Size = UDim2.new(0, 30, 0, 30)
        plusBtn.Position = UDim2.new(0, 110, 0, 5)
        plusBtn.Text = "+"
        plusBtn.TextColor3 = Color3.new(1, 1, 1)
        plusBtn.BackgroundColor3 = Color3.new(0, 0.7, 0)
        plusBtn.BorderSizePixel = 1
        plusBtn.TextScaled = true
        plusBtn.Parent = frame
        
        -- Minus button
        local minusBtn = Instance.new("TextButton")
        minusBtn.Size = UDim2.new(0, 30, 0, 30)
        minusBtn.Position = UDim2.new(0, 150, 0, 5)
        minusBtn.Text = "-"
        minusBtn.TextColor3 = Color3.new(1, 1, 1)
        minusBtn.BackgroundColor3 = Color3.new(0.7, 0, 0)
        minusBtn.BorderSizePixel = 1
        minusBtn.TextScaled = true
        minusBtn.Parent = frame
        
        -- Button functionality with proper decimal formatting
        plusBtn.MouseButton1Click:Connect(function()
            local current = tonumber(textBox.Text) or 0
            local newValue = current + 0.1
            textBox.Text = string.format("%.1f", newValue)  -- Format to 1 decimal place
            updateGrip()
        end)
        
        minusBtn.MouseButton1Click:Connect(function()
            local current = tonumber(textBox.Text) or 0
            local newValue = current - 0.1
            textBox.Text = string.format("%.1f", newValue)  -- Format to 1 decimal place
            updateGrip()
        end)
        
        return textBox
    end
    
    -- Reset to 0,0,0 for each new weapon (no persistence)
    xSlider = createSlider("X", 40, 0)
    ySlider = createSlider("Y", 90, 0)
    zSlider = createSlider("Z", 140, 0)
    
    -- Connect text box events
    xSlider.FocusLost:Connect(updateGrip)
    ySlider.FocusLost:Connect(updateGrip)
    zSlider.FocusLost:Connect(updateGrip)
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 5)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.BackgroundColor3 = Color3.new(0.7, 0, 0)
    closeBtn.BorderSizePixel = 0
    closeBtn.TextScaled = true
    closeBtn.Parent = mainFrame
    
    closeBtn.MouseButton1Click:Connect(function()
        if gui then
            gui:Destroy()
            gui = nil
        end
    end)
end

-- Hide the grip UI
local function hideGripUI()
    if gui then
        gui:Destroy()
        gui = nil
    end
    currentTool = nil
end

-- Watch for tool equipping/unequipping
local function watchCharacter(character)
    if not character then return end
    
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            currentTool = child
            print("[GripAdjuster] Tool equipped:", child.Name)
            
            -- Clear any old base grip so it gets stored fresh
            child:SetAttribute("ClientBaseGrip", nil)
            
            createGripUI()
            print("[GripAdjuster] UI shown for:", child.Name)
            
            -- No persistent adjustments - each weapon starts at 0,0,0
            -- The UI will show 0,0,0 and the weapon will use server's fullOffset
            
            -- Watch for tool being unequipped
            child.AncestryChanged:Connect(function()
                if not child.Parent then
                    print("[GripAdjuster] Tool unequipped - hiding UI")
                    hideGripUI()
                end
            end)
        end
    end)
    
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and child == currentTool then
            print("[GripAdjuster] Tool removed - hiding UI")
            hideGripUI()
        end
    end)
end

-- Initialize for current character
if player.Character then
    watchCharacter(player.Character)
end

-- Watch for character spawning
player.CharacterAdded:Connect(function(character)
    print("[GripAdjuster] Character spawned, setting up tool watching")
    watchCharacter(character)
end)

print("[GripAdjuster] Client-side grip adjuster initialized")
