import re

# Read the file
with open(r"d:\Apps\Roblox\src\shared\SkinConfig.lua", "r", encoding="utf-8") as f:
    content = f.read()

# Pattern to match skin entries WITHOUT comments
# Matches lines like: ["SkinName"] = { ... },
# but NOT lines that already have -- comments
pattern = r'(\t\["([^"]+)"\]\s*=\s*\{[^}]+\}),(\s*)\n(?!\s*--)'
--
# Replacement adds the comment
def add_comment(match):
    full_line = match.group(1)
    skin_name = match.group(2)
    whitespace = match.group(3)
    return f'{full_line},       -- ["{skin_name}"]\n'

# Replace all matches
new_content = re.sub(pattern, add_comment, content)

# Write back
with open(r"d:\Apps\Roblox\src\shared\SkinConfig.lua", "w", encoding="utf-8") as f:
    f.write(new_content)

print("Done! Added comments to all skin entries.")
