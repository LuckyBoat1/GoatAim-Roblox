--!strict
-- SkinExtractPractice: Extract owned skin names from heterogeneous data tables

export type Dict = { [any]: any }

local SkinExtractPractice = {}

local function add(set: { [string]: boolean }, name: any)
	if type(name) == "string" and #name > 0 then set[name] = true end
end

local function collect(set: { [string]: boolean }, tbl: any)
	if type(tbl) ~= "table" then return end
	for k, v in pairs(tbl) do
		if type(v) == "string" then
			add(set, v)
		elseif type(k) == "string" and (v == true or v == 1) then
			add(set, k)
		elseif type(v) == "table" then
			if type(v.name) == "string" then add(set, v.name)
			elseif type(v.Name) == "string" then add(set, v.Name) end
		end
	end
end

function SkinExtractPractice.ownedSet(data: Dict?): { [string]: boolean }
	local set: { [string]: boolean } = {}
	if type(data) ~= "table" then return set end
	collect(set, data.ownedSkins)
	collect(set, data.skins)
	collect(set, data.unlockedSkins)
	collect(set, data.weaponsOwned)
	collect(set, data.weaponsUnlocked)
	collect(set, data.unlocked)
	if type(data.inventory) == "table" then
		collect(set, data.inventory.skins)
		collect(set, data.inventory.ownedSkins)
	end
	if next(set) == nil and type(data.cosmetics) == "table" then
		collect(set, data.cosmetics.skins)
	end
	return set
end

return SkinExtractPractice
