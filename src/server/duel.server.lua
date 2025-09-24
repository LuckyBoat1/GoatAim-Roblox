-- Script (ServerScriptService)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuelEvent = ReplicatedStorage:WaitForChild("DuelEvent")

local arenaFolder = workspace:WaitForChild("DuelArenaSpawns")
local spawn1 = arenaFolder:WaitForChild("ArenaSpawn1")
local spawn2 = arenaFolder:WaitForChild("ArenaSpawn2")

-- Track duel requests
local pendingDuels = {}

DuelEvent.OnServerEvent:Connect(function(player, action, targetPlayer)
	if action == "RequestDuel" and targetPlayer and targetPlayer:IsA("Player") then
		-- Save duel request
		pendingDuels[targetPlayer] = player
		-- Tell target they got invited
		DuelEvent:FireClient(targetPlayer, "Invite", player)

	elseif action == "DeclineDuel" and targetPlayer then
		-- Tell requester it was declined
		DuelEvent:FireClient(targetPlayer, "Declined", player)
		pendingDuels[player] = nil

	elseif action == "AcceptDuel" and targetPlayer then
		if pendingDuels[player] == targetPlayer then
			-- Both players confirmed duel
			pendingDuels[player] = nil

			-- Notify both players
			DuelEvent:FireClient(player, "Message", targetPlayer)
			DuelEvent:FireClient(targetPlayer, "Message", player)

			-- Countdown before teleport
			task.delay(3, function()
				-- Teleport both players
				if player.Character and targetPlayer.Character then
					player.Character:MoveTo(spawn1.Position)
					targetPlayer.Character:MoveTo(spawn2.Position)

					-- Give both 5 sec invincibility
					local function makeInvincible(plr)
						if plr.Character then
							local hum = plr.Character:FindFirstChild("Humanoid")
							if hum then
								hum:SetAttribute("Invincible", true)
								task.delay(5, function()
									if hum then
										hum:SetAttribute("Invincible", false)
									end
								end)
							end
						end
					end

					makeInvincible(player)
					makeInvincible(targetPlayer)
				end
			end)
		end
	end
end)

