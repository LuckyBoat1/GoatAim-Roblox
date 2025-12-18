-- Script to play bull animation on demand
-- Place this in ServerScriptService

local bull = workspace:WaitForChild("bull")
local animController = bull:WaitForChild("AnimationController")

-- Make sure there's an Animator instance
local animator = animController:FindFirstChildOfClass("Animator")
if not animator then
	animator = Instance.new("Animator")
	animator.Parent = animController
	print("✅ Created Animator instance")
end

-- Create the animation object
local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://YOUR_ANIMATION_ID_HERE" -- Replace with your actual animation ID
animation.Parent = animController

-- Load the animation
local animTrack = animator:LoadAnimation(animation)

print("🎬 Bull animation loaded and ready!")

-- Function to play the animation
local function playBullAnimation()
	if animTrack.IsPlaying then
		print("⏭️ Animation already playing, skipping...")
		return
	end
	
	animTrack:Play()
	print("🎬 Playing bull animation!")
end

-- Add a ProximityPrompt to the bull so players can trigger it
local proximityPrompt = Instance.new("ProximityPrompt")
proximityPrompt.ActionText = "Trigger Bull Animation"
proximityPrompt.ObjectText = "Bull"
proximityPrompt.MaxActivationDistance = 10
proximityPrompt.HoldDuration = 0
proximityPrompt.Parent = bull.PrimaryPart or bull:FindFirstChildWhichIsA("BasePart")

proximityPrompt.Triggered:Connect(function(player)
	print("🎮 Animation triggered by", player.Name)
	playBullAnimation()
end)

print("✅ ProximityPrompt added to bull - walk up and press E to trigger!")
