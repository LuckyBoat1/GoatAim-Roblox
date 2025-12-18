local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local QuestCatalog = require(script.Parent.QuestCatalog)

-- Create Remotes
local QuestRF = RS:FindFirstChild("QuestRF") or Instance.new("RemoteFunction")
QuestRF.Name = "QuestRF"
QuestRF.Parent = RS

local QuestRE = RS:FindFirstChild("QuestRE") or Instance.new("RemoteEvent")
QuestRE.Name = "QuestRE"
QuestRE.Parent = RS

-- Temporary data storage if _G.getData is not available
local TempData = {}

-- Helper to get player quest data safely
local function getPlayerQuests(player)
	local data = _G.getData and _G.getData(player)
	
	local q
	if not data then
		-- Use temp data if main data system is offline
		if not TempData[player.UserId] then
			TempData[player.UserId] = { active={}, completed={}, bounties={} }
		end
		q = TempData[player.UserId]
	else
		if not data.quests then 
			data.quests = { active={}, completed={}, bounties={} } 
		end
		q = data.quests
	end
	
	-- Ensure fields exist
	if not q.active then q.active = {} end
	if not q.completed then q.completed = {} end
	if not q.bounties then q.bounties = {} end
	
	return q
end

local function getQuestState(player)
	local pQuests = getPlayerQuests(player)
	local allMissions = QuestCatalog.list()
	local missions = {}
	
	for _, q in ipairs(allMissions) do
		local status = "available"
		if pQuests.completed and pQuests.completed[q.id] then
			status = "completed"
		elseif pQuests.active and pQuests.active[q.id] then
			status = "active"
		end
		
		table.insert(missions, {
			id = q.id,
			def = q.def,
			status = status
		})
	end
	
	-- Convert active dictionary to list for client
	local activeList = {}
	for id, data in pairs(pQuests.active or {}) do
		local entry = {
			id = id,
			progress = data.progress,
			startedAt = data.startedAt,
			completed = data.completed
		}
		
		if data.isBounty then
			entry.kind = "bounty"
			if data.def then
				entry.name = data.def.name
				entry.desc = data.def.desc
				entry.rarity = data.def.rarity
				entry.objectives = data.def.objectives
				entry.reward = data.def.reward
			end
		else
			entry.kind = "mission"
			local def = QuestCatalog.get(id)
			if def then
				entry.name = def.name
				entry.desc = def.desc
				entry.rarity = "common"
				entry.objectives = {{key=def.stat, count=def.goal}}
				entry.reward = def.reward
			end
		end
		table.insert(activeList, entry)
	end
	
	-- Generate bounties if missing or insufficient
	if not pQuests.bounties then pQuests.bounties = {} end
	
	local categories = {"warlord", "marksman", "inferno", "apocalypse", "vendetta", "mayhem", "rambo", "annihilator", "the_void"}
	
	-- Replenish up to 3 bounties
	local attempts = 0
	while #pQuests.bounties < 3 and attempts < 50 do
		attempts = attempts + 1
		local cat = categories[math.random(1, #categories)]
		
		-- Check if we already have a bounty of this category to avoid duplicates if possible
		local hasCat = false
		for _, b in ipairs(pQuests.bounties) do
			if b.quest.rarity == cat then hasCat = true break end
		end
		
		if not hasCat or attempts > 20 then -- Relax uniqueness constraint after 20 attempts
			local tier = math.random(1, 2)
			local questId = cat .. "_" .. tier
			local def = QuestCatalog.get(questId)
			
			if def then
				local reward = {
					money = math.floor((def.reward.money or 0) * 1.5),
					xp = math.floor((def.reward.xp or 0) * 1.5)
				}
				
				table.insert(pQuests.bounties, {
					offerId = "bounty_"..os.time().."_"..math.random(1000,9999),
					expiresAt = os.time() + 3600,
					quest = {
						id = questId,
						name = def.name,
						desc = def.desc,
						rarity = cat, -- Use category for theming
						objectives = {{key = def.stat, count = def.goal}},
						reward = reward
					}
				})
			end
		end
	end
	
	return {
		ok = true,
		now = os.time(),
		missions = missions,
		active = activeList,
		bounties = pQuests.bounties or {},
		log = {} 
	}
end

QuestRF.OnServerInvoke = function(player, action, arg1)
	if action == "get" then
		return getQuestState(player)
	elseif action == "reroll" then
		local pQuests = getPlayerQuests(player)
		pQuests.bounties = {} -- Clear bounties to force regeneration
		return getQuestState(player)
	elseif action == "accept" then
		local pQuests = getPlayerQuests(player)
		
		if type(arg1) == "table" and arg1.kind == "bounty" then
			local offerId = arg1.offerId
			
			local bounty = nil
			local foundIndex = nil
			for i, b in ipairs(pQuests.bounties) do
				if b.offerId == offerId then
					bounty = b
					foundIndex = i
					break
				end
			end
			
			if not bounty then return {ok=false, err="Invalid bounty"} end
			
			-- Add to active quests
			local activeId = "bounty_" .. bounty.quest.id .. "_" .. os.time()
			
			pQuests.active[activeId] = {
				progress = 0,
				startedAt = os.time(),
				isBounty = true,
				def = bounty.quest -- Store definition since it's dynamic/modified
			}
			
			-- Remove from available bounties
			table.remove(pQuests.bounties, foundIndex)
			
			QuestRE:FireClient(player, {type="accepted", id=activeId})
			QuestRE:FireClient(player, {type="progress"})
			return {ok=true}
		else
			local questId = arg1
			local def = QuestCatalog.get(questId)
			if not def then return {ok=false, err="Invalid quest"} end
			
			if pQuests.active[questId] or pQuests.completed[questId] then
				return {ok=false, err="Already active or completed"}
			end
			
			pQuests.active[questId] = { progress=0, startedAt=os.time() }
			QuestRE:FireClient(player, {type="accepted", id=questId})
			QuestRE:FireClient(player, {type="progress"})
			return {ok=true}
		end
	end
	return {ok=false}
end

print("QuestServer loaded and remotes initialized.")
