$path = "d:\Apps\Roblox\src\shared\SkinConfig.lua"
$bytes = [System.IO.File]::ReadAllBytes($path)
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $stripped = $bytes[3..($bytes.Length - 1)]
    [System.IO.File]::WriteAllBytes($path, $stripped)
    Write-Host "BOM removed successfully"
} else {
    Write-Host "No BOM found - file is already clean"
}
