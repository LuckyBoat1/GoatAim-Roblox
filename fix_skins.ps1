$keep = @(
    '357 Magnum','357 Magnum - Desert','357 Magnum - Ice',
    '870 Express','870 Express - Carbon','870 Express - White','870 Express - Sakura',
    'AA12','AA12 - Brown','AA12 - Amas',
    'AK47','AK74','AK-Jungle','AK-Chaos',
    'Alpha Sapphire','Alpine','Apple','AS-VAL',
    'Weak bat','Walking Stick','Wild West','Vacuum','Vector',
    'Tactical Boom','Sweet Strike','Stone Hammer','Swiss Guard','Stinger','Shovel',
    'Small axe','Sharp Stick','Ribbon Lance','Rocket Launcher','Serpent','Sharp',
    'Q Bone','Rapid Fire','Pocket Blast','Metal bar','MP5','Pretty Gun','Marksman',
    'M249','M16','LMG AE','Lime Shot','Knife','Quick Escape','Dog Bone','Desert Eagle',
    'Burner','Butcher','Broken Hope','Balanced','Zone','Zap','ToothPick','Tech Six',
    'Solar Staff','Somber','Slicer','Side Arm','Sharp Iron','Scarlet Shot',
    'Shadow Strike','Shark Eye','Rune eye','Saber-Tooth','Rocket Rain','Pyranna',
    'Rock Head','Quick Shot','Pokey','Pointy','Noble Strike','Moon Hunter',
    "Knight's Lance",'Jaw Breaker','Hotdog',"Hunter's sword",'Impulse','Halk Smash',
    'Grout','Good boy','Dagestan','Cyan','Bone Slicer','Bitter Sweet','Basic Camo',
    'Work','Tiger Strike',
    'Amethyst','Anarchy','Apex','Astroid','Axe of Wealth','Axe of Wealth ',
    'Black Frost','Black Matter','Blood','Blood Hungry','Blueberry','Buzz Cut',
    'Carpenter','Champion','China Fury','Cookie Cutter','Crimson Drake','Demon',
    'Destroyer','Drip','Ego','End','Flame','Gem Hammer','Golden Sweet','GreatSword',
    'Heavy Spin','Hot Cheetoz','Huge Spoon','Horror','Just give me my money',
    'Laser Beam','Magma Flow','Midnight','Moon Pike','Omega','Red Falcon','Razor Edge',
    'Sea Bone','Skeleton','Skull Disintigrator','Sky','Spooky Edge','The Log','trump'
)

$keepSet = @{}
foreach ($k in $keep) { $keepSet[$k] = $true }

$path = 'd:\Apps\Roblox\src\shared\SkinConfig.lua'
$lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)

$pattern = [regex]'^\s*\["(.+?)"\]\s*=\s*\{'
$result = [System.Collections.Generic.List[string]]::new()
$commented = 0
$kept = 0

foreach ($line in $lines) {
    $m = $pattern.Match($line)
    if ($m.Success) {
        $skinName = $m.Groups[1].Value
        if (-not $keepSet.ContainsKey($skinName)) {
            $line = '--' + $line
            $commented++
        } else {
            $kept++
        }
    }
    $result.Add($line)
}

[System.IO.File]::WriteAllLines($path, $result, [System.Text.Encoding]::UTF8)
Write-Host "Done. Kept: $kept, Commented out: $commented"
