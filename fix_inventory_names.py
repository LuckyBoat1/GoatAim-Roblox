
import os

file_path = r"d:\Apps\Roblox\src\client\Inventory.client.luau"

replacements = {
    '"AK-Ice"': '"Sea Bone"',
    '"PB"': '"Pocket Blast"',
    '"Blood%Bones"': '"Blood&Bones"',
    '"leciathan"': '"Leviathan"',
    '"TRS-301"': '"Tactical Three"',
    '"Vintorez"': '"Whisper"',
    '"Power"': '"Ultimate"',
    '"Ball"': '"Sphere Strike"',
    '"Cane"': '"Walking Stick"',
    '"cane"': '"Walking Stick"',
    '"Crystal"': '"Prism Edge"',
    '"shna"': '"Classic Shot"',
    '"PKM"': '"Heavy Storm"',
    '"Viper/Mp5"': '"Serpent"',
    '"Amerigun"': '"trump"',
    '"Blaster"': '"Power Shot"',
    '"Blue Candy"': '"Cyan"',
    '"Candy"': '"Sweet Strike"',
    '"Laser"': '"Light Beam"',
    '"BattleAxeII"': '"Raven"',
    '"Blue Seer"': '"Blueberry"',
    '"Blue Sugar"': '"Snow Blaster!"',
    '"Boneblade"': '"Shark Bite"',
    '"Chroma Fang"': '"Rainbow Bite"',
    '"Fang"': '"Viper Tooth"'
}

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

for old, new in replacements.items():
    content = content.replace(old, new)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Replacements complete.")
