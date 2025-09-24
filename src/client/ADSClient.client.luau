
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- SkinConfig simple direct require (Studio-style)
local SkinConfig = require(Rs:WaitForChild("Shared"):WaitForChild("SkinConfig"))
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- Optional: force third-person for testing so you can see the weapon
do
	local FORCE_THIRD_PERSON = false  -- DISABLED to allow first-person
	if FORCE_THIRD_PERSON then
		pcall(function()
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMinZoomDistance = 5
			player.CameraMaxZoomDistance = 20
		end)
	end
end

local currentTool = nil -- Tool
local hipGrip = nil -- CFrame
local adsGrip = nil -- CFrame
local hipFOV = nil -- number
local adsFOV = nil -- number
local aiming = false

local gripDriver = nil -- CFrameValue

local function tweenGrip(tool, toCF, dur)
	if not gripDriver then
		local newVal = Instance.new("CFrameValue")
		gripDriver = newVal
		newVal:GetPropertyChangedSignal("Value"):Connect(function()
			if currentTool == tool then
				pcall(function() tool.Grip = newVal.Value end)
			end
		end)
	end
	local drv = gripDriver -- capture non-nil
	drv.Value = tool.Grip
	TweenService:Create(drv, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = toCF }):Play()
end

local function tweenFOV(toFOV, dur)
	local start = cam.FieldOfView
	local t0 = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((tick() - t0)/dur, 0, 1)
		local ease = 1 - (1-a)*(1-a)
		cam.FieldOfView = start + (toFOV - start)*ease
		if a >= 1 then conn:Disconnect() end
	end)
end

local function isADSAllowed(tool)
	local attr = tool:GetAttribute("ADSExcluded")
	if attr ~= nil then return attr == false end
	return SkinConfig.IsADSAllowed(tool.Name, tool:GetAttribute("SkinId"))
end

local function setupTool(tool)
	currentTool = tool
	hipGrip = tool.Grip
	
	-- Server handles all weapon positioning and rotation
	-- Client only handles ADS functionality
	
	adsGrip = nil
	hipFOV = cam.FieldOfView
	adsFOV = nil

	if isADSAllowed(tool) then
		local adsFolder = tool:FindFirstChild("ADS")
		if adsFolder then
			local g = adsFolder:FindFirstChild("ADSGrip")
			if g and g:IsA("CFrameValue") then adsGrip = g.Value end
			local f = adsFolder:FindFirstChild("ADSFOV")
			if f and f:IsA("NumberValue") then adsFOV = f.Value end
		end
		if not adsGrip then
			adsGrip = SkinConfig.GetADSGripForSkin(tool:GetAttribute("SkinId"), tool.Name)
		end
		if not adsFOV then
			adsFOV = SkinConfig.GetADSFOVForSkin(tool:GetAttribute("SkinId"), tool.Name)
		end
	else
		adsGrip = nil
	end
	aiming = false
end

local function teardownTool()
	-- DISABLED: Let server handle all grip positioning
	-- if currentTool and hipGrip then
	--	pcall(function() currentTool.Grip = hipGrip end)
	-- end
	currentTool, hipGrip, adsGrip, hipFOV, adsFOV = nil, nil, nil, nil, nil
	aiming = false
end

local function beginADS()
	if not currentTool or not adsGrip or aiming then return end
	aiming = true
	tweenGrip(currentTool, adsGrip, 0.18)
	tweenFOV(adsFOV or 55, 0.14)
end

local function endADS()
	if not currentTool or not hipGrip or not aiming then return end
	aiming = false
	tweenGrip(currentTool, hipGrip, 0.16)
	tweenFOV(hipFOV or cam.FieldOfView, 0.12)
end

local function bindInputs()
	ContextActionService:BindAction("ADS_Hold", function(_, state)
		if not currentTool or not adsGrip then return Enum.ContextActionResult.Pass end
		if state == Enum.UserInputState.Begin then beginADS()
		elseif state == Enum.UserInputState.End then endADS() end
		return Enum.ContextActionResult.Sink
	end, true, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)

	ContextActionService:BindAction("ADS_ShiftHold", function(_, state)
		if not currentTool or not adsGrip then return Enum.ContextActionResult.Pass end
		if state == Enum.UserInputState.Begin then beginADS()
		elseif state == Enum.UserInputState.End then endADS() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.LeftShift)
end

local function ensureMobileButton()
	if not UserInputService.TouchEnabled then return end
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if not gui then return end

	local hud = gui:FindFirstChild("ADS_UI") or Instance.new("ScreenGui")
	hud.Name = "ADS_UI"
	hud.ResetOnSpawn = false
	hud.Parent = gui

	local btn = hud:FindFirstChild("ADSButton") or Instance.new("TextButton")
	btn.Name = "ADSButton"
	btn.Size = UDim2.new(0, 60, 0, 60)
	btn.Position = UDim2.new(1, -80, 1, -80)
	btn.BackgroundColor3 = Color3.fromRGB(20,30,25)
	btn.Text = "ADS"
	btn.TextSize = 18
	btn.TextColor3 = Color3.fromRGB(20,250,120)
	btn.Parent = hud
	if not btn:FindFirstChildOfClass("UICorner") then
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = btn
		local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(20,250,120); s.Thickness = 2; s.Parent = btn
	end

	btn.MouseButton1Down:Connect(function() if currentTool and adsGrip then beginADS() end end)
	btn.MouseButton1Up:Connect(function() if currentTool then endADS() end end)
end

local function hookCharacter(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			child.Equipped:Connect(function() setupTool(child) end)
			child.Unequipped:Connect(teardownTool)
		end
	end)
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") then
			child.Equipped:Connect(function() setupTool(child) end)
			child.Unequipped:Connect(teardownTool)
		end
	end
end

local playerObj = Players.LocalPlayer
playerObj.CharacterAdded:Connect(function(char)
	hookCharacter(char)
	ensureMobileButton()
end)
if playerObj.Character then
	hookCharacter(playerObj.Character)
	ensureMobileButton()
end

bindInputs()