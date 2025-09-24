local friends  = {}
_G.addFriend = function (player1,player2)
	friends[player1.userId] = friends[player1.userId] or {}
	friends[player2.userId] = friends[player2.userId] or {}
	
	table.insert(friends[player1.userId], player2.userId)
	table.insert(friends[player2.userId], player1.userId)
end

_G.getFriendLeaderboard = function (player)
	local myFriends = friends [player.userId] or {}
	local stats = {}
	
	for _, friendId in pairs (myFriends) do
		
		local data = _G.getData(player)
		
		if data then table.insert(stats, {friendId, data.bestAccuracy})
			
		end
	end
	return stats
end