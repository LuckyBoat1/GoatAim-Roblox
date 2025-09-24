-- Test script to verify SkinConfig loads properly
local success, result = pcall(function()
    return require(script.Parent.src.shared.SkinConfig)
end)

if success then
    print("✅ SkinConfig loaded successfully")
    print("GetSkinMeta function exists:", result.GetSkinMeta ~= nil)
    print("GetAllSkinNames function exists:", result.GetAllSkinNames ~= nil)
    
    -- Test specific skin lookup
    local testSkin = "SKS Wood Large"
    local meta = result.GetSkinMeta(testSkin)
    if meta then
        print(string.format("✅ Found '%s': weapon='%s', rarity='%s'", 
            testSkin, meta.weapon or "none", meta.rarity or "none"))
    else
        print("❌ Could not find metadata for", testSkin)
    end
else
    print("❌ Failed to load SkinConfig:", result)
end
