-- AutoEquipHand.client.luau
-- Runs once per session; re-equips the "Hand" tool from Backpack on every spawn,
-- then auto-applies a common skin so the player always starts with one equipped.
-- If the player has no common skin in inventory, the server grants one for free.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Lazy-init the PlayerDataRF remote (it's created by PlayerDataManager on the server).
local function getPlayerDataRF()
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	return remotes and remotes:FindFirstChild("PlayerDataRF")
end

local function equipHand(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	-- Wait for the Humanoid to be in a live state (not None/Dead)
	local deadline = tick() + 5
	while humanoid:GetState() == Enum.HumanoidStateType.None and tick() < deadline do
		task.wait(0.05)
	end
	if humanoid.Health <= 0 then return end

	-- Poll for the Hand tool in Backpack (StarterPack populates it shortly after spawn)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then return end

	local tool
	local deadline2 = tick() + 5
	repeat
		tool = backpack:FindFirstChild("Hand") or backpack:FindFirstChildWhichIsA("Tool")
		if tool then break end
		task.wait(0.1)
	until tick() > deadline2

	if not tool then
		warn("[AutoEquipHand] ⚠️ Could not find Hand tool in Backpack after 5 s")
		return
	end

	-- Double-check the character hasn't died while we were waiting
	if humanoid.Health <= 0 then return end

	humanoid:EquipTool(tool)
	print("[AutoEquipHand] ✅ Equipped", tool.Name, "for", player.Name)

	-- Ask the server for a common skin (grants one free if the player has none).
	-- We then set SkinId on the tool, which SkinClient picks up and applies
	-- visually, and which EquipServer uses to set the correct grip rotation.
	local rf = getPlayerDataRF()
	if not rf then
		-- RF not ready yet — wait briefly and retry once
		task.wait(2)
		rf = getPlayerDataRF()
	end
	if rf then
		local ok, result = pcall(function()
			return rf:InvokeServer("EnsureCommonSkin")
		end)
		if ok and result and result.success and result.skinId then
			-- The tool reference is still valid even though it moved to the character.
			tool:SetAttribute("SkinId", result.skinId)
			print("[AutoEquipHand] ✅ Applied common skin:", result.skinId)
		else
			warn("[AutoEquipHand] ⚠️ EnsureCommonSkin failed:", ok, result)
		end
	else
		warn("[AutoEquipHand] ⚠️ PlayerDataRF not found — skin not applied")
	end
end

-- CharacterAdded fires on every respawn
player.CharacterAdded:Connect(equipHand)

-- Handle case where character already exists (script loaded after spawn)
if player.Character then
	task.spawn(equipHand, player.Character)
end
