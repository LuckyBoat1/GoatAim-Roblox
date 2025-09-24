local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

RunService.RenderStepped:Connect(function()
	for _, obj in pairs(Workspace:GetChildren())do
		if obj:IsA("BasePart") and obj:GetAttribute("PlayerId") then
			if obj:GetAttribute("PlayerId") ~= player.UserId then
				
				obj.LocalTransparencyModifier = 1

			else 
				obj.LocalTransparencyModifier = 0
			end
		end
	end
end)