-- ModuleScript: PlayAnimationInRig (inside FirstPlaceAvatar)
local PlayAnimationInRig = {}

-- Function to apply HumanoidDescription to the rig and update the name
function PlayAnimationInRig.SetRigAppearance(humanoidDescription, playerName)
	local rig = script.Parent:FindFirstChild("Rig") -- make sure this matches your rig's name
	if not rig then
		warn("Rig not found inside FirstPlaceAvatar")
		return
	end

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Apply the player's appearance
		if humanoidDescription then
			humanoid:ApplyDescription(humanoidDescription)
		end

		-- Set the name above the head
		if playerName then
			humanoid.DisplayName = playerName
		end
	else
		warn("Humanoid not found inside Rig")
	end
end

return PlayAnimationInRig
