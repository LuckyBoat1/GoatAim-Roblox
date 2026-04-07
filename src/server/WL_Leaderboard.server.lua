-- WL_Leaderboard.server.lua
-- DISABLED: logic moved to _KillsWL_Leaderboards.server.lua
-- This file is kept to avoid breaking Studio's file reference.
return
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EVENT_NAME        = "WLLeaderboardEvent"
local UPDATE_EVENT_NAME = "UpdateTopWLEvent"
local BROADCAST_KEY     = "WLScore"
local WINS_KEY          = "wins"
local LOSSES_KEY        = "losses"
local UPDATE_INTERVAL   = 2
local MAX_ENTRIES       = 10

local LeaderboardEvent = ReplicatedStorage:FindFirstChild(EVENT_NAME)
if not LeaderboardEvent then
LeaderboardEvent = Instance.new("RemoteEvent")
LeaderboardEvent.Name = EVENT_NAME
LeaderboardEvent.Parent = ReplicatedStorage
end

local UpdateAvatarEvent = ReplicatedStorage:FindFirstChild(UPDATE_EVENT_NAME)
if not UpdateAvatarEvent then
UpdateAvatarEvent = Instance.new("RemoteEvent")
UpdateAvatarEvent.Name = UPDATE_EVENT_NAME
UpdateAvatarEvent.Parent = ReplicatedStorage
end

local function buildLeaderboard()
local entries = {}
for _, player in ipairs(Players:GetPlayers()) do
local wins = 0
local losses = 0
if _G.getData then
local ok, data = pcall(_G.getData, player)
if ok and data then
wins   = data[WINS_KEY]   or 0
losses = data[LOSSES_KEY] or 0
end
end
table.insert(entries, {
Name      = player.Name,
UserId    = player.UserId,
Value     = wins,
Formatted = wins .. " / " .. losses,
})
end
table.sort(entries, function(a, b) return a.Value > b.Value end)
while #entries > MAX_ENTRIES do table.remove(entries) end
return entries
end

local function broadcast()
local entries = buildLeaderboard()
if #entries == 0 then return end
LeaderboardEvent:FireAllClients({ [BROADCAST_KEY] = entries })
end

task.wait(3)
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
if tick() - lastUpdate >= UPDATE_INTERVAL then
lastUpdate = tick()
pcall(broadcast)
end
end)

print("✅ [WL_Leaderboard] Loaded")
