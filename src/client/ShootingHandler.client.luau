-- ShootingHandler.client.luau
-- Paste the ShootingHandler LocalScript code here.
print("[ShootingHandler] ShootingHandler loaded and ready.")
local Rs = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Require SkinConfig to identify weapon types
local SkinConfig = require(Rs:WaitForChild("Shared"):WaitForChild("SkinConfig"))

local shootEvent = Rs:WaitForChild("ShootEvent", 20)
if not shootEvent then
	warn("[ShootingHandler] CRITICAL: ShootEvent not found after 20 seconds! Shooting will not work.")
end
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- List of weapon types that are MELEE (should NOT shoot)
local MELEE_TYPES = {
	"Blade", "Spear", "Axe", "GreatAxe", "HandAxe", "Sword", "Greatsword",
	"Hammer", "Mace", "Club", "Halberd", "Staff", "Machete", "Shiv",
	"Cutlass", "Banner", "Bone", "Melee"
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Respect gameProcessed when a UI is handling the input
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		print("[ShootingHandler] 🖱️ MB1 Detected. GameProcessed:", gameProcessed)
		
		-- Don't shoot if UI is handling the click (gameProcessed = true means UI captured it)
		if gameProcessed then
			print("[ShootingHandler] ❌ Click captured by UI, not shooting")
			return
		end
		
		if not shootEvent then
			warn("[ShootingHandler] ❌ Cannot shoot - ShootEvent is missing!")
			return
		end
		
		-- 1. Check if player has a character
		local character = player.Character
		if not character then 
			warn("[ShootingHandler] ❌ No Character")
			return 
		end

		-- 2. Check if a weapon (Tool) is equipped
		local weapon = character:FindFirstChildOfClass("Tool")
		if not weapon then
			-- User is clicking but has no weapon, so do nothing
			print("[ShootingHandler] ❌ No Weapon Equipped")
			return 
		end
		
		-- 3. Fire shoot event (Removed mouse.Target check to allow shooting at sky/void)
		if mouse.Hit then
			print("[ShootingHandler] 🔫 Firing ShootEvent at", mouse.Hit.Position)
			shootEvent:FireServer(mouse.Hit.Position)
		else
			warn("[ShootingHandler] ⚠️ Mouse.Hit is nil")
		end
	end
end)
