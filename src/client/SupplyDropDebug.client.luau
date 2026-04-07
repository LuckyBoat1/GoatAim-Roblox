-- SupplyDropDebug.client.luau
-- Paste output into chat or check Output window to diagnose SupplyDrop hookup.

local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

task.wait(3) -- let workspace fully populate

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("[SupplyDropDebug] Starting scan…")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- ── 1. Find ALL ProximityPrompts in workspace ──────────────────────────────
local allPrompts = {}
for _, desc in ipairs(workspace:GetDescendants()) do
	if desc:IsA("ProximityPrompt") then
		table.insert(allPrompts, desc)
	end
end

print(string.format("[SupplyDropDebug] Total ProximityPrompts found in Workspace: %d", #allPrompts))

if #allPrompts == 0 then
	warn("[SupplyDropDebug] ❌  NO ProximityPrompts exist in Workspace at all!")
	warn("[SupplyDropDebug]    → Make sure the Ruby model is in Workspace (not ServerStorage / ReplicatedStorage).")
	warn("[SupplyDropDebug]    → Make sure the ProximityPrompt is a direct child of a BasePart (not a Model or Folder).")
else
	for i, pp in ipairs(allPrompts) do
		-- Walk up the ancestry and collect names
		local ancestry = {}
		local cur = pp.Parent
		while cur and cur ~= workspace do
			table.insert(ancestry, 1, cur.Name)
			cur = cur.Parent
		end
		local path = "Workspace/" .. table.concat(ancestry, "/") .. "/" .. pp.Name
		print(string.format("[SupplyDropDebug]  PP[%d]  path: %s", i, path))
		print(string.format("[SupplyDropDebug]         Enabled=%s  MaxActivationDistance=%d  ActionText='%s'",
			tostring(pp.Enabled), pp.MaxActivationDistance, pp.ActionText))

		-- Check if any ancestor is named "Ruby"
		local foundRuby = false
		local rubyAncestor = nil
		cur = pp.Parent
		while cur and cur ~= workspace do
			if cur.Name == "Ruby" then
				foundRuby = true
				rubyAncestor = cur
				break
			end
			cur = cur.Parent
		end

		if foundRuby then
			print(string.format("[SupplyDropDebug]         ✅ Ancestor named 'Ruby' found: %s (%s)",
				rubyAncestor:GetFullName(), rubyAncestor.ClassName))
		else
			warn(string.format("[SupplyDropDebug]         ⚠️  NO ancestor named 'Ruby' — current script looks for a model named 'Ruby'"))
			-- Print what the ancestors ARE so user can fix the name
			local names = {}
			cur = pp.Parent
			while cur and cur ~= workspace do
				table.insert(names, string.format("'%s'(%s)", cur.Name, cur.ClassName))
				cur = cur.Parent
			end
			warn("[SupplyDropDebug]         Ancestors: " .. table.concat(names, " → "))
		end
	end
end

-- ── 2. Look for any Model named "Ruby" regardless of prompts ──────────────
print("─────────────────────────────────────────")
local rubyModels = {}
for _, desc in ipairs(workspace:GetDescendants()) do
	if desc.Name == "Ruby" then
		table.insert(rubyModels, desc)
	end
end
print(string.format("[SupplyDropDebug] Models/objects named 'Ruby' in Workspace: %d", #rubyModels))
for _, m in ipairs(rubyModels) do
	print(string.format("[SupplyDropDebug]   '%s' at %s", m.Name, m:GetFullName()))
	-- List direct children
	for _, child in ipairs(m:GetChildren()) do
		print(string.format("[SupplyDropDebug]     child: '%s' (%s)", child.Name, child.ClassName))
	end
end

-- ── 3. Check if SupplyDropRF exists ───────────────────────────────────────
print("─────────────────────────────────────────")
local RS = game:GetService("ReplicatedStorage")
local RemoteEvents = RS:FindFirstChild("RemoteEvents")
if RemoteEvents then
	local rf = RemoteEvents:FindFirstChild("SupplyDropRF")
	if rf then
		print("[SupplyDropDebug] ✅ SupplyDropRF RemoteFunction exists in RemoteEvents")
	else
		warn("[SupplyDropDebug] ❌ SupplyDropRF NOT found in RemoteEvents — server script may not have run yet")
		print("[SupplyDropDebug]    Contents of RemoteEvents:")
		for _, child in ipairs(RemoteEvents:GetChildren()) do
			print(string.format("[SupplyDropDebug]      '%s' (%s)", child.Name, child.ClassName))
		end
	end
else
	warn("[SupplyDropDebug] ❌ RemoteEvents folder not found in ReplicatedStorage")
end

-- ── 4. Live watch: print every new ProximityPrompt that appears ───────────
print("─────────────────────────────────────────")
print("[SupplyDropDebug] 👀 Watching for new ProximityPrompts added to Workspace…")
workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("ProximityPrompt") then
		warn(string.format("[SupplyDropDebug] NEW ProximityPrompt appeared: %s", desc:GetFullName()))
	end
end)

-- ── 5. Bypass mode DISABLED — was hooking every PP and creating a competing GUI ─
-- To re-enable for debugging, uncomment the block below.
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("[SupplyDropDebug] Scan complete. Bypass mode is OFF (read-only diagnostics only).")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
