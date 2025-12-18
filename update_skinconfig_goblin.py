import re

file_path = r"d:\Apps\Roblox\src\shared\SkinConfig.lua"

with open(file_path, "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if '-- OLD: ["Goblin_' in line and "isGoblin=true" not in line:
        # Insert isGoblin=true before the closing brace
        # Pattern: ... adsAllowed=false }, ...
        # We want: ... adsAllowed=false, isGoblin=true }, ...
        
        # Find the last occurrence of '}' before the comment
        # The line looks like: 	["Name"] = { ... },       -- OLD: ...
        
        # Split by comment
        parts = line.split("-- OLD:")
        code_part = parts[0]
        comment_part = parts[1] if len(parts) > 1 else ""
        
        # Find the closing brace in code_part
        last_brace_index = code_part.rfind("}")
        if last_brace_index != -1:
            # Insert isGoblin=true
            new_code_part = code_part[:last_brace_index] + ", isGoblin=true " + code_part[last_brace_index:]
            new_line = new_code_part + "-- OLD:" + comment_part
            new_lines.append(new_line)
        else:
            new_lines.append(line)
    else:
        new_lines.append(line)

with open(file_path, "w") as f:
    f.writelines(new_lines)

print("Updated SkinConfig.lua with isGoblin=true")
