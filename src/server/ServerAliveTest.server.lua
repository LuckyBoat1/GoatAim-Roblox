-- ServerAliveTest: If you see this in Output under "Server", server scripts are running!
warn("🔴🔴🔴 SERVER SCRIPTS ARE ALIVE! 🔴🔴🔴")
warn("🔴🔴🔴 If you see this, Rojo is syncing server scripts correctly 🔴🔴🔴")

-- Also list everything in ServerScriptService for debugging
for _, child in game:GetService("ServerScriptService"):GetDescendants() do
	if child:IsA("BaseScript") then
		warn("  📜 Server script found:", child:GetFullName(), "Enabled:", child.Enabled)
	end
end

-- Check if RemoteEvents folder exists and what's in it
local RS = game:GetService("ReplicatedStorage")
local remotes = RS:FindFirstChild("RemoteEvents")
if remotes then
	warn("✅ RemoteEvents folder found in ReplicatedStorage")
	for _, child in remotes:GetChildren() do
		warn("  📡 Remote:", child.Name, "Class:", child.ClassName)
	end
else
	warn("❌ RemoteEvents folder NOT FOUND in ReplicatedStorage")
end
