local challenges= {
	{desc = "Hit 50 Targets", type = "hits", target = 50, reward = 25}, 
	{desc = "Reach 85% accuracy", type = "accuracy",target = 85, reward = 50},
	{desc = "Reach speed 2", type = "speed", target = 2, reward = 100}
}
_G.checkChallenge = function(player, type, value)
	
	local data = _G.getData(player)
	
	for i , challenge in pairs (challenges) do
		if challenge.type == type and value >= challenge and not data.dailyComplete[i] then
			data.dailyComplete[i] = true
			_G.addmoney(player, challenge.reward)
			_G.notify(player, "Challenge Complete ".. challenge.reward .. " Money.")
		end
	end
	
	
end




	
