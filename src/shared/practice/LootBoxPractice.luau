--!strict
-- LootBoxPractice: Weighted rarity selection and pool-based skin pick

export type Weights = { [string]: number }
export type Pools = { [string]: { string } } -- rarity => list of skinIds

local LootBoxPractice = {}

-- Return a rarity key based on weights table (keys are rarity)
function LootBoxPractice.weightedPick(weights: Weights): string
	local total = 0
	for _, w in pairs(weights) do total += w end
	if total <= 0 then return "common" end
	local r = math.random() * total
	for k, w in pairs(weights) do
		if r < w then return k end
		r -= w
	end
	return "common"
end

-- Pick a skin from a rarity pool, falling back to the richest pool if empty
function LootBoxPractice.pickSkin(pools: Pools, rarity: string): string?
	local pool = pools[rarity] or {}
	if #pool == 0 then
		for _, r in ipairs({"mythic","legendary","epic","rare","common"}) do
			if pools[r] and #pools[r] > 0 then pool = pools[r]; break end
		end
	end
	if #pool == 0 then return nil end
	return pool[math.random(1, #pool)]
end

return LootBoxPractice
