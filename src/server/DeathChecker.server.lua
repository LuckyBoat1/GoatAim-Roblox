local Players = game:GetService("Players")

local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	humanoid.Died:Connect(function()
		print("💀 DEATH CHECKER: " .. player.Name .. " has died!")
		print("📍 Position: " .. tostring(rootPart.Position))
		--
		-- Check for creator tag (common weapon system convention)
		local creatorTag = humanoid:FindFirstChild("creator")
		if creatorTag then
			print("⚔️ Killed by: " .. tostring(creatorTag.Value))
		else--
			print("❓ No killer tag found.")
		end

		-- Check what they were touching
		local touchingParts = rootPart:GetTouchingParts()
		print("🛑 Touching " .. #touchingParts .. " parts:")
		for _, part in ipairs(touchingParts) do
			print("   - " .. part.Name .. " (" .. part.ClassName .. ") Parent: " .. part.Parent.Name)
			if part.Name == "KillBrick" or part.Name == "Lava" or part:FindFirstChild("KillScript") then
				warn("   ⚠️ SUSPICIOUS PART DETECTED: " .. part.Name)
			end
		end
		
		-- Check if they fell into the void
		if rootPart.Position.Y < -50 then
			warn("   ⚠️ Player fell into the void (Y < -50)")
			warn("   📉 Velocity: " .. tostring(rootPart.Velocity))
			if rootPart.Velocity.Y < -50 then
				warn("   💨 Falling very fast! The floor might be unanchored.")
			end
		end
		
		-- Check distance to Bull Arena spawn if relevant
		-- We can try to find the nearest BullArena
		for _, arena in ipairs(workspace:GetChildren()) do
			if arena.Name:match("BullArena") then
				local spawn = arena:FindFirstChild("ArenaPlatform")
				if spawn then
					local spawnPos
					if spawn:IsA("BasePart") then
						spawnPos = spawn.Position
					elseif spawn:IsA("Model") then
						if spawn.PrimaryPart then
							spawnPos = spawn.PrimaryPart.Position
						else
							local part = spawn:FindFirstChildWhichIsA("BasePart", true)
							if part then spawnPos = part.Position end
						end
					end
					
					if spawnPos then
						local dist = (rootPart.Position - spawnPos).Magnitude
						if dist < 100 then
							print("   🏟️ Died near " .. arena.Name .. " (Distance: " .. math.floor(dist) .. " studs)")
						end
					end
				end
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end)

print("✅ Death Checker initialized")
