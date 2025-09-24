-- LocalScript (StarterGui)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local DuelEvent = ReplicatedStorage:WaitForChild("DuelEvent")

-- Assume you already have your "Interact Menu" with a Duel button
local duelButton = script.Parent:WaitForChild("DuelButton") -- adjust to your GUI path

-- 📌 When clicking Duel button, send request to server
duelButton.MouseButton1Click:Connect(function()
	local target = player:GetAttribute("CurrentTarget") -- we’ll set this when interacting
	if target then
		DuelEvent:FireServer("RequestDuel", target)
	end
end)

-- 📌 Create popup for duel invites
local function createInvitePopup(fromPlayer)
	local screenGui = Instance.new("ScreenGui", player.PlayerGui)
	local frame = Instance.new("Frame", screenGui)
	frame.Size = UDim2.new(0, 300, 0, 150)
	frame.Position = UDim2.new(0.5, -150, 0.5, -75)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BackgroundTransparency = 0.2

	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, 0, 0.5, 0)
	label.BackgroundTransparency = 1
	label.Text = fromPlayer.Name .. " is inviting you to a duel!"
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 20

	local accept = Instance.new("TextButton", frame)
	accept.Size = UDim2.new(0.5, -5, 0.5, -5)
	accept.Position = UDim2.new(0, 0, 0.5, 0)
	accept.Text = "Accept"
	accept.BackgroundColor3 = Color3.fromRGB(0, 200, 0)

	local decline = Instance.new("TextButton", frame)
	decline.Size = UDim2.new(0.5, -5, 0.5, -5)
	decline.Position = UDim2.new(0.5, 5, 0.5, 0)
	decline.Text = "Decline"
	decline.BackgroundColor3 = Color3.fromRGB(200, 0, 0)

	-- Accept / Decline buttons
	accept.MouseButton1Click:Connect(function()
		DuelEvent:FireServer("AcceptDuel", fromPlayer)
		screenGui:Destroy()
	end)

	decline.MouseButton1Click:Connect(function()
		DuelEvent:FireServer("DeclineDuel", fromPlayer)
		screenGui:Destroy()
	end)
end

-- 📌 Listen for duel events from server
DuelEvent.OnClientEvent:Connect(function(action, fromPlayer)
	if action == "Invite" then
		createInvitePopup(fromPlayer)
	elseif action == "Declined" then
		warn(fromPlayer.Name .. " declined your duel.")
	elseif action == "Message" then
		warn(fromPlayer.Name .. ": " .. "Transporting to duel arena...")
	end
end)

