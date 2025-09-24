-- ShootingHandler.client.luau
-- Paste the ShootingHandler LocalScript code here.
print("[ShootingHandler] Placeholder loaded – replace with real code.")
local Rs = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local shootEvent = Rs:WaitForChild("ShootEvent")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
		if mouse.Target then
			print("Shooting at", mouse.Hit.Position)
			shootEvent:FireServer(mouse.Hit.Position)
		else
			print("Mouse has no valid target to shoot at!")
		end
	end
end)
