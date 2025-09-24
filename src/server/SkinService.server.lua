-- SkinService: applies skins from ReplicatedStorage/SkinLibrary to Tools/Models/Characters
-- - Aligns the skin's internal "Handle" to Tool.Handle
-- - Hides the Tool.Handle visuals (keeps it for mechanics)
-- - Welds all skin BaseParts to Tool.Handle (Anchored=false, CanCollide=false, Massless=true)
-- Rotation control:
--   - Global defaults (set below or as attributes on ReplicatedStorage/SkinLibrary)
--   - Per-skin overrides via attributes on the skin model: MountYawDeg, MountPitchDeg, MountRollDeg
--   - Per-tool overrides via attributes on the Tool: MountYawDeg, MountPitchDeg, MountRollDeg
--   - Optional CFrameValue "MountOffset" anywhere under the skin model for fine-tuned offsets

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Global rotation defaults (degrees). Set Y to 180 if all skins face backwards for your tools.
local DEFAULT_MOUNT_YAW_DEG   = 180
local DEFAULT_MOUNT_PITCH_DEG = 0
local DEFAULT_MOUNT_ROLL_DEG  = 0

local SkinLibrary = ReplicatedStorage:FindFirstChild("SkinLibrary")
if not SkinLibrary then
	warn("[SkinService] ReplicatedStorage/SkinLibrary not found. Skins won't apply.")
end

local function getSkin(skinId)
	if not SkinLibrary or type(skinId) ~= "string" then return nil end
	return SkinLibrary:FindFirstChild(skinId, true)
end

local function collectBaseParts(root)
	local out = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(out, d) end
	end
	return out
end

local function ensurePrimaryPart(m)
	if m.PrimaryPart then return end
	local h = m:FindFirstChild("Handle", true)
	if h and h:IsA("BasePart") then
		m.PrimaryPart = h
	else
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then m.PrimaryPart = d; break end
		end
	end
end

local function hideToolHandle(tool)
	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then return end

	if tool:GetAttribute("OrigHandleTransparency") == nil then
		tool:SetAttribute("OrigHandleTransparency", handle.Transparency)
	end
	if tool:GetAttribute("OrigHandleCastShadow") == nil then
		tool:SetAttribute("OrigHandleCastShadow", handle.CastShadow and 1 or 0)
	end

	handle.Transparency = 1
	handle.CastShadow = false
	handle.CanCollide = false
	handle.Massless = true

	for _, d in ipairs(handle:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		end
	end
end

local function restoreToolHandle(tool)
	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then return end
	local origT = tool:GetAttribute("OrigHandleTransparency")
	local origC = tool:GetAttribute("OrigHandleCastShadow")
	if origT ~= nil then handle.Transparency = tonumber(origT) or 0 end
	if origC ~= nil then handle.CastShadow = (tonumber(origC) or 1) ~= 0 end
end

local function clearToolSkin(tool)
	local folder = tool:FindFirstChild("SkinParts")
	if folder then folder:Destroy() end
	for _, c in ipairs(tool:GetChildren()) do
		if c:GetAttribute("IsSkin") or c:GetAttribute("IsCharacterSkin") then
			c:Destroy()
		end
	end
	restoreToolHandle(tool)
	tool:SetAttribute("AppliedSkin", nil)
	tool:SetAttribute("SkinId", nil)
end

local function weldToHandle(tool, source)
	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then
		warn(("[SkinService] Tool '%s' has no BasePart Handle; cannot attach skin."):format(tool.Name))
		return
	end

	local container = tool:FindFirstChild("SkinParts")
	if not container then
		container = Instance.new("Folder")
		container.Name = "SkinParts"
		container.Parent = tool
	else
		for _, c in ipairs(container:GetChildren()) do c:Destroy() end
	end

	-- Clone into a working model to use Model:PivotTo
	local workModel
	if source:IsA("Model") then
		workModel = source:Clone()
	else
		workModel = Instance.new("Model")
		workModel.Name = source.Name .. "_TMP"
		local clone = source:Clone()
		clone.Parent = workModel
	end

	ensurePrimaryPart(workModel)

	-- Base alignment: match skin's own "Handle" (if present) to Tool.Handle
	local pivotCF = workModel:GetPivot()
	local skinHandlePart = workModel:FindFirstChild("Handle", true)

	local targetPivot
	if skinHandlePart and skinHandlePart:IsA("BasePart") then
		-- skinHandlePart = pivotCF * H_rel  ->  pivot' = Tool.Handle * inverse(H_rel)
		local H_rel = pivotCF:ToObjectSpace(skinHandlePart.CFrame)
		targetPivot = handle.CFrame * H_rel:Inverse()
	else
		targetPivot = handle.CFrame
	end

	-- Apply rotations in this order: global default -> per-skin -> per-tool, plus optional MountOffset
	do
		-- Global defaults (can be set as attributes on SkinLibrary to override constants)
		local gYaw   = tonumber(SkinLibrary and SkinLibrary:GetAttribute("DefaultMountYawDeg"))   or DEFAULT_MOUNT_YAW_DEG
		local gPitch = tonumber(SkinLibrary and SkinLibrary:GetAttribute("DefaultMountPitchDeg")) or DEFAULT_MOUNT_PITCH_DEG
		local gRoll  = tonumber(SkinLibrary and SkinLibrary:GetAttribute("DefaultMountRollDeg"))  or DEFAULT_MOUNT_ROLL_DEG

		-- Per-skin overrides (attributes on the skin model root)
		local sYaw   = tonumber(source:GetAttribute("MountYawDeg"))
		local sPitch = tonumber(source:GetAttribute("MountPitchDeg"))
		local sRoll  = tonumber(source:GetAttribute("MountRollDeg"))

		-- Per-tool overrides (attributes on the Tool)
		local tYaw   = tonumber(tool:GetAttribute("MountYawDeg"))
		local tPitch = tonumber(tool:GetAttribute("MountPitchDeg"))
		local tRoll  = tonumber(tool:GetAttribute("MountRollDeg"))

		local yawDeg   = tYaw or sYaw or gYaw
		local pitchDeg = tPitch or sPitch or gPitch
		local rollDeg  = tRoll or sRoll or gRoll

		if yawDeg ~= 0 or pitchDeg ~= 0 or rollDeg ~= 0 then
			targetPivot = targetPivot * CFrame.Angles(math.rad(pitchDeg), math.rad(yawDeg), math.rad(rollDeg))
		end

		-- Optional fine-tune via CFrameValue "MountOffset"
		local cfv = source:FindFirstChild("MountOffset", true)
		if cfv and cfv:IsA("CFrameValue") then
			targetPivot = targetPivot * cfv.Value
		end
	end

	-- Place the working model
	workModel:PivotTo(targetPivot)

	-- Move parts into tool and weld to Handle
	for _, bp in ipairs(collectBaseParts(workModel)) do
		-- Avoid naming conflict with Tool.Handle
		if bp.Name == "Handle" then
			bp.Name = "Skin_Handle"
		end

		local worldCF = bp.CFrame
		bp.Anchored = false
		bp.CanCollide = false
		bp.Massless = true
		bp:SetAttribute("IsSkin", true)
		bp.Parent = container
		bp.CFrame = worldCF

		local weld = Instance.new("WeldConstraint")
		weld.Name = "SkinWeld_" .. bp.Name
		weld.Part0 = bp
		weld.Part1 = handle
		weld.Parent = bp
	end

	-- Cleanup the working clone
	workModel:Destroy()
end

local function ApplySkinToTool(tool, skinId)
	if not tool or not tool:IsA("Tool") or type(skinId) ~= "string" then return end
	local skin = getSkin(skinId)
	if not skin then
		warn(("[SkinService] Skin '%s' not found under ReplicatedStorage/SkinLibrary"):format(skinId))
		return
	end

	clearToolSkin(tool)
	hideToolHandle(tool)
	weldToHandle(tool, skin)

	tool:SetAttribute("AppliedSkin", skinId)
	tool:SetAttribute("SkinId", skinId)
	print(("[SkinService] Applied skin '%s' to tool '%s'"):format(skinId, tool.Name))
end

local function ApplySkinToModel(model, skinId)
	if not model or not model:IsA("Model") or type(skinId) ~= "string" then return end
	local skin = getSkin(skinId)
	if not skin then
		warn(("[SkinService] Skin '%s' not found for model"):format(skinId))
		return
	end
	for _, c in ipairs(model:GetChildren()) do
		if c:GetAttribute("IsSkin") then c:Destroy() end
	end
	local clone = skin:Clone()
	for _, bp in ipairs(collectBaseParts(clone)) do
		bp.Anchored = false
		bp.CanCollide = false
		bp.Massless = true
		bp:SetAttribute("IsSkin", true)
		bp.Parent = model
	end
	model:SetAttribute("AppliedSkin", skinId)
end

local function ApplySkinToCharacter(player, skinId, attachTo)
	if not player or type(skinId) ~= "string" then return end
	local char = player.Character
	if not char then return end
	local skin = getSkin(skinId)
	if not skin then
		warn(("[SkinService] Skin '%s' not found for character"):format(skinId))
		return
	end
	for _, c in ipairs(char:GetDescendants()) do
		if c:GetAttribute("IsCharacterSkin") then c:Destroy() end
	end
	local target = char
	if type(attachTo) == "string" and #attachTo > 0 then
		target = char:FindFirstChild(attachTo) or char
	end
	local clone = skin:Clone()
	for _, bp in ipairs(collectBaseParts(clone)) do
		bp.Anchored = false
		bp.CanCollide = false
		bp.Massless = true
		bp:SetAttribute("IsCharacterSkin", true)
		bp.Parent = target
	end
	char:SetAttribute("AppliedSkin", skinId)
end

local function ClearAppliedSkin(target)
	if not target then return end
	for _, c in ipairs(target:GetChildren()) do
		if c:GetAttribute("IsSkin") or c:GetAttribute("IsCharacterSkin") then
			c:Destroy()
		end
	end
	target:SetAttribute("AppliedSkin", nil)
	if target:IsA("Tool") then
		restoreToolHandle(target)
		target:SetAttribute("SkinId", nil)
	end
end

local function GetSkinClone(skinId)
	local s = getSkin(skinId)
	return s and s:Clone() or Instance.new("Part")
end

_G.SkinService = {
	ApplySkinToTool = ApplySkinToTool,
	ApplySkinToModel = ApplySkinToModel,
	ApplySkinToCharacter = ApplySkinToCharacter,
	ClearAppliedSkin = ClearAppliedSkin,
	GetSkinClone = GetSkinClone,
}

print(("[SkinService] Ready. Source: ReplicatedStorage/SkinLibrary (%s)")
	:format(SkinLibrary and (#SkinLibrary:GetChildren() .. " entries") or "missing"))