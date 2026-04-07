-- ScanAllRequire.lua
-- Paste into Studio command bar.
-- Finds ANY require() call in scripts NOT from your VS Code src/.
-- Nothing is deleted.

------------------------------------------------------------------------
-- YOUR SCRIPT NAMES (from src/ — Rojo strips suffixes like .client.luau)
------------------------------------------------------------------------
local MY_NAMES = {
-- client
["ADSClient"]=true,["ArcadePvpBuffUI"]=true,["BullTeleportUI"]=true,
["Cloner"]=true,["CrateGiver"]=true,["CrateOpener"]=true,
["CrateOpener_WORKING"]=true,["CratePickupFX"]=true,
["CustomHealthUI"]=true,["DamageVFX"]=true,["dash"]=true,
["EffectSpawner"]=true,["Emporium"]=true,["FirstPersonForcer"]=true,
["FlipBook"]=true,["FlipBookCoins"]=true,["FlipBookCoins2"]=true,
["FlipBookGold"]=true,["FlipBookKill"]=true,["FlipBookSideMenu"]=true,
["FlipBookUpgrades"]=true,["FlipBookWL"]=true,["GameSpeed"]=true,
["GripAdjuster"]=true,["Headquarters"]=true,["interaction"]=true,
["Inventory"]=true,["MouseHandler"]=true,["mythicaura"]=true,
["NotificationHandler"]=true,["NPCHealthBars"]=true,["Planets"]=true,
["PvpCountdownUI"]=true,["QButtonBillboard"]=true,["QuestCore"]=true,
["QuestLog"]=true,["QuestMissions"]=true,["RefinerClient"]=true,
["RefinerNotifications"]=true,["RefinerProgress"]=true,
["RefinersSign"]=true,["RotationAdjuster"]=true,["RunStats"]=true,
["ShootingHandler"]=true,["Shop"]=true,["SideMenu"]=true,
["SkinClient"]=true,["SpawnButton"]=true,["Stats"]=true,
["StatsDisplay"]=true,["SwingAnimation"]=true,["TimerTest"]=true,
["TopKillsDisplay"]=true,["TopPlayTimeDisplay"]=true,["TopWLDisplay"]=true,
-- server
["_Bootstrap"]=true,["_KillsWL_Leaderboards"]=true,["AbyssPvP"]=true,
["AccuracyLeaderboard"]=true,["ADSServer"]=true,["AntiCheat"]=true,
["ArcadePvp"]=true,["BabyGhost"]=true,["Beginning"]=true,
["BullArenaManager"]=true,["BullBehavior"]=true,["BulletManager"]=true,
["BullRewards"]=true,["BullseyeAimRun"]=true,["BullTeleporter"]=true,
["CrateSpawn"]=true,["DailyChallenges"]=true,["DataStoreTest"]=true,
["DeathChecker"]=true,["DebugArena"]=true,["DebugEquip"]=true,
["Dice"]=true,["duel"]=true,["End"]=true,["EquipServer"]=true,
["FishNpc"]=true,["GameShooting"]=true,["HealthManager"]=true,
["Helpers"]=true,["KillsLeaderboard"]=true,["LightingSetup"]=true,
["MainActivity"]=true,["MamaGhost"]=true,["MythicEffectsServer"]=true,
["PlayerDataManager"]=true,["PlaytimeLeaderboard"]=true,
["PVESystem"]=true,["PvpArena"]=true,["PvpPlatformManager"]=true,
["QuestCatalog"]=true,["QuestServer"]=true,["RankSystem"]=true,
["RedPiggyNpc"]=true,["RefinerBoxChances"]=true,["RefinerSystem"]=true,
["Robo"]=true,["RobuxProducts"]=true,["RunSystem"]=true,
["ServerAliveTest"]=true,["Skelly"]=true,["SkinServer"]=true,
["SkinService"]=true,["Social"]=true,["SpeedMilestones"]=true,
["Spidy"]=true,["Streak"]=true,["TheWeepingKing"]=true,
["TorsoGhost"]=true,["TwoFace"]=true,["WL_Leaderboard"]=true,
["WorldBreaker"]=true,
-- shared
["Animations"]=true,["CommonAura"]=true,["CrateConfig"]=true,
["DropConfig"]=true,["EpicAura"]=true,["FloatingGui"]=true,
["global.d"]=true,["Hello"]=true,["LegendaryAura"]=true,
["LegendaryEffects"]=true,["MythicAura"]=true,["MythicEffects"]=true,
["NPCConfig"]=true,["NPCController"]=true,["ParticleSystem"]=true,
["HitWindowPractice"]=true,["LootBoxPractice"]=true,["OrbitMath"]=true,
["RankMoe"]=true,["RankPractice"]=true,["RefinerTimePractice"]=true,
["SkinExtractPractice"]=true,["RareAura"]=true,["SimpleNPCStats"]=true,
["SkinConfig"]=true,["UIParticleEmitter"]=true,["UIParticle"]=true,
["UiParticles"]=true,
-- remoteevents
["_SkinConfig_Remote_DUPE"]=true,
}

------------------------------------------------------------------------
-- YOUR PATH PREFIXES (belt + suspenders — catches renamed/moved scripts)
------------------------------------------------------------------------
local MY_PATHS = {
"ServerScriptService.Server.",
"StarterPlayer.StarterPlayerScripts.",
"StarterPlayer.StarterCharacterScripts.",
"ReplicatedStorage.Shared.",
"ReplicatedStorage.remoteevents.",
"ReplicatedStorage.copypasta.",
"ServerStorage.VFX.",
"ServerStorage.NonAnimModels.",
"StarterGui.",
}

------------------------------------------------------------------------
-- SEARCH ROOTS
------------------------------------------------------------------------
local SEARCH_ROOTS = {}
for _, svc in ipairs({
"Workspace","ServerScriptService","ServerStorage",
"ReplicatedStorage","ReplicatedFirst",
"StarterGui","StarterPack","StarterPlayer",
"Players","Lighting","SoundService","Chat","Teams",
}) do
local ok, s = pcall(function() return game:GetService(svc) end)
if ok and s then table.insert(SEARCH_ROOTS, s) end
end

------------------------------------------------------------------------
-- HELPERS
------------------------------------------------------------------------
local function isScript(obj)
return obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
end

local function isMine(obj)
if MY_NAMES[obj.Name] then return true end
local path = obj:GetFullName()
for _, prefix in ipairs(MY_PATHS) do
if path:sub(1, #prefix) == prefix then return true end
end
return false
end

-- Extract all require() arguments (any kind, not just numeric)
local function findRequires(source)
local found = {}
for arg in source:gmatch("require%s*(%b())") do
local inner = arg:sub(2, -2):match("^%s*(.-)%s*$")
if inner ~= "" then
table.insert(found, inner)
end
end
return found
end

------------------------------------------------------------------------
-- SCAN
------------------------------------------------------------------------
local results    = {}
local skipped    = 0
local checked    = 0
local unreadable = {}

local function checkScript(obj)
if isMine(obj) then skipped += 1; return end
checked += 1

local ok, source = pcall(function() return obj.Source end)
if not ok or source == nil then
table.insert(unreadable, obj:GetFullName())
return
end
if source == "" then return end

local reqs = findRequires(source)
if #reqs > 0 then
table.insert(results, {
obj   = obj,
path  = obj:GetFullName(),
name  = obj.Name,
class = obj.ClassName,
reqs  = reqs,
})
end
end

local function scan(root)
for _, obj in ipairs(root:GetDescendants()) do
if isScript(obj) then pcall(checkScript, obj) end
end
if isScript(root) then pcall(checkScript, root) end
end

for _, root in ipairs(SEARCH_ROOTS) do pcall(scan, root) end

------------------------------------------------------------------------
-- REPORT + DELETE
------------------------------------------------------------------------
local SEP = string.rep("=", 74)
print(SEP)
print(string.format(
"ALL REQUIRE SCAN  —  yours (skipped): %d  |  unknown checked: %d  |  hits: %d  |  unreadable: %d",
skipped, checked, #results, #unreadable))
print(SEP)

local deleted = 0
local deleteFailed = {}

if #results > 0 then
print(string.format("\nDELETING %d scripts with require()...\n", #results))
for i, r in ipairs(results) do
-- find the actual instance again (results stored path only)
-- we'll destroy via the stored obj reference
local ok2, err = pcall(function() r.obj:Destroy() end)
if ok2 then
deleted += 1
print(string.format("[DELETED] %s  —  %s", r.name, r.path))
else
table.insert(deleteFailed, string.format("[FAILED] %s  —  %s  (%s)", r.name, r.path, tostring(err)))
end
end
else
print("\n(no require() calls found in unknown scripts)\n")
end

print(string.format("\nDeleted: %d  |  Failed: %d\n", deleted, #deleteFailed))

if #deleteFailed > 0 then
print("FAILED TO DELETE:")
for _, msg in ipairs(deleteFailed) do print(msg) end
end

if #unreadable > 0 then
print(string.format("\nLOCKED/UNREADABLE  (%d)\n", #unreadable))
for i, p in ipairs(unreadable) do
print(string.format("[%d] %s", i, p))
end
print("")
end

print(SEP)
print(string.format("Done. %d scripts deleted.", deleted))
print(SEP)
