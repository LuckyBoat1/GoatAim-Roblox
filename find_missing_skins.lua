local ReplicatedStorage = game:GetService("ReplicatedStorage")
local skinLibrary = ReplicatedStorage:FindFirstChild("SkinLibrary")
if not skinLibrary then warn("❌ SkinLibrary not found!") return end
local allSkins = {}
for _, model in ipairs(skinLibrary:GetChildren()) do table.insert(allSkins, model.Name) end
table.sort(allSkins)
print("\n COPY THESE INTO SKINCONFIG.LUA SKINS TABLE:\n")
for _, skinName in ipairs(allSkins) do
    local weapon = "Blade"
    local rarity = "common"
    local adsAllowed = "false"
    if skinName:find("Revolver") then weapon = "Revolver"; adsAllowed = "true"
    elseif skinName:find("Pistol") or skinName:find("Glock") or skinName:find("Beretta") or skinName:find("Desert Eagle") or skinName:find("M1911") then weapon = "Pistol"; adsAllowed = "true"
    elseif skinName:find("AK") then weapon = "AK"; adsAllowed = "true"
    elseif skinName:find("M4") then weapon = "M4"; adsAllowed = "true"
    elseif skinName:find("Rifle") or skinName:find("SCAR") or skinName:find("Ranch") or skinName:find("M16") then weapon = "Rifle"; adsAllowed = "true"
    elseif skinName:find("Shotgun") or skinName:find("SPAS") or skinName:find("Super 90") or skinName:find("870") or skinName:find("AA12") then weapon = "Shotgun"; adsAllowed = "true"
    elseif skinName:find("Sniper") or skinName:find("Barrett") or skinName:find("SVD") then weapon = "Sniper"; adsAllowed = "true"
    elseif skinName:find("SMG") or skinName:find("MP5") or skinName:find("UMP") or skinName:find("Vector") or skinName:find("Uzi") then weapon = "SMG"; adsAllowed = "true"
    elseif skinName:find("LMG") or skinName:find("M249") or skinName:find("PKM") then weapon = "LMG"; adsAllowed = "true"
    elseif skinName:find("Launcher") or skinName:find("RPG") or skinName:find("rocket") then weapon = "Launcher"; adsAllowed = "true"
    end
    print('["' .. skinName .. '"] = { weapon="' .. weapon .. '", rarity="' .. rarity .. '", adsAllowed=' .. adsAllowed .. ' },')
end
print("\n✅ Total: " .. #allSkins .. " items")
