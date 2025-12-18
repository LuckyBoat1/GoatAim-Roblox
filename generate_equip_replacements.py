#!/usr/bin/env python3
"""
Generate replacement mappings from SkinConfig.lua for equip.server.lua
Extracts all old→new name mappings and creates find/replace commands
"""

import re

# Read SkinConfig.lua
with open(r"d:\Apps\Roblox\src\shared\SkinConfig.lua", "r", encoding="utf-8") as f:
    skinconfig = f.read()

# Extract all mappings where format is: ["NEW"] = {...}, -- ["old"]
# Pattern matches: ["NewName"] = { ... }, -- ["OldName"]
pattern = r'\["([^"]+)"\]\s*=\s*{[^}]+},\s*--\s*\["([^"]+)"\]'
matches = re.findall(pattern, skinconfig)

print(f"Found {len(matches)} mappings")

# Create mapping dictionary old -> new
mappings = {}
for new_name, old_name in matches:
    if old_name != new_name:  # Only map if names are different
        mappings[old_name] = new_name

print(f"Found {len(mappings)} names that need replacement")

# Print some examples
print("\nExample mappings:")
for i, (old, new) in enumerate(list(mappings.items())[:10]):
    print(f'  "{old}" -> "{new}"')

# Write to file for review
with open(r"d:\Apps\Roblox\name_mappings.txt", "w", encoding="utf-8") as f:
    f.write("OLD_NAME -> NEW_NAME\n")
    f.write("="*60 + "\n")
    for old, new in sorted(mappings.items()):
        f.write(f'"{old}" -> "{new}"\n')

print(f"\n✅ Wrote {len(mappings)} mappings to name_mappings.txt")
print(f"\nKey replacements needed:")
print(f'  "shiv" -> "Sharp Point"')
print(f'  "PKM" -> "Heavy Storm"')
print(f'  "Meshes/blue" -> "Blue"')
print(f'  "Goblin_Axe_Nature_01" -> "Grout"')
