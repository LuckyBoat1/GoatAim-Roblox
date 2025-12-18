import re

file_path = r'd:\Apps\Roblox\src\server\equip.server.lua'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove ["111 and ["123 prefixes
content = content.replace('["111', '["')
content = content.replace('["123', '["')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Prefixes removed successfully!")
