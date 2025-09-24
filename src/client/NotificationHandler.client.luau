local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NotifyEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("NotifyEvent")

local function createUi()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NotificationGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "NotifyText"
	textLabel.Size = UDim2.new(0.6,0,0.15,0)
	textLabel.Position = UDim2.new(0.2,0,0.3,0)
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.BackgroundTransparency =1
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1,1,1)
	textLabel.TextStrokeColor3 =Color3.new(0,0,0)
	textLabel.TextStrokeTransparency = 0.5
	textLabel.ZIndex = 5
	textLabel.Visible = false
	textLabel.Parent = screenGui
	
	
	
	
end

createUi()

local function showNotification(text)
	local screenGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("NotificationGui")
	local label = screenGui:WaitForChild("NotifyText")
	
	label.Text = text
	label.TextTransparency = 1
	label.Visible = true
	
	local tweenService = game:GetService("TweenService")
	local fadeIn = tweenService:Create(label, TweenInfo.new(0.4),{TextTransparency = 0})
	fadeIn:Play()
	fadeIn.Completed:Wait()
	
	wait(2)
	
	local fadeOut = tweenService:Create (label, TweenInfo.new(0.4), {TextTransparency = 0})
	fadeOut:Play()
	fadeOut.Completed:Wait()
	label.Visible = false
	
	
end

NotifyEvent.OnClientEvent:Connect(showNotification)