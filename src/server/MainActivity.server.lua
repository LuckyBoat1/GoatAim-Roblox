-- Updated onShot function for PlayerDataManager
-- Current Date and Time: 2025-08-21 00:23:30
-- User: Hulk11121

_G.onShot = function(player)
	-- Safety check for player parameter
	if not player or not player:IsA("Player") then
		warn("onShot: Invalid player provided")
		return
	end

	local success, data = pcall(function()
		return _G.getData(player)
	end)

	if not success or not data then
		warn("onShot: Could not get player data for", player.Name)
		return
	end

	-- Initialize sessionShots if it doesn't exist
	data.sessionShots = (data.sessionShots or 0) + 1

	-- Also increment totalShots if that's being tracked
	if data.totalShots ~= nil then
		data.totalShots = data.totalShots + 1
	end

	-- If weapon stats are being tracked, try to update current weapon
	pcall(function()
		local character = player.Character
		if character then
			local tool = character:FindFirstChildOfClass("Tool")
			if tool and tool.Name then
				-- Use bumpWeaponStats if available
				if _G.bumpWeaponStats then
					_G.bumpWeaponStats(player, tool.Name, 1, 0)
				elseif data.weaponStats and data.weaponStats[tool.Name] then
					data.weaponStats[tool.Name].bulletsShot = 
						(data.weaponStats[tool.Name].bulletsShot or 0) + 1
				end
			end
		end
	end)

	return data.sessionShots
end

