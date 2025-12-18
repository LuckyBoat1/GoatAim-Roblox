local Lighting = game:GetService("Lighting")

-- Set global lighting settings to reduce ambient light bleed
Lighting.Ambient = Color3.new(0.5, 0.5, 0.5) -- Darker ambient (was likely 1,1,1)
Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5) -- Darker outdoor ambient
Lighting.Brightness = 2 -- Increase direct light brightness to compensate
Lighting.GlobalShadows = true -- Ensure shadows are enabled

print("✅ Global Lighting Adjusted: Ambient reduced to 0.5 to fix light bleed")