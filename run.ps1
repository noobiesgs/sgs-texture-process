Import-Module ".\utils.psm1"

$sgsResourceFolder = "F:\sgs\sgs421\"
$output = "F:\sgs\sgs421-output\"
$migrateFiles = @("*.jpg", "*.png", "*.pvr.ccz", "*.pvr.ccz", "*.pvr.ccz@alpha", "*.skel", "*.atlas", "*.atlas", "*.ttf", "*.fnt", "*.mp3", "*.zip")

#start

if (-not (Test-Path -Path $output -PathType Container)) {
    New-Item -Path $output -ItemType Directory -Force | Out-Null
    Write-Host "output folder not found, created：$folderPath"
}

Get-ChildItem -Path $sgsResourceFolder -File -Recurse -Include $migrateFiles | ForEach-Object {
    MigrateFile -file $_ -sgsResourceFolder $sgsResourceFolder -output $output
}

Get-ChildItem -Path $output -File -Recurse -Filter "*.jpg" | ForEach-Object {
    ResolveJPG -jpgFile $_
}

Get-ChildItem -Path $output -File -Recurse -Filter "*.png" | ForEach-Object {
    ResolvePNG -pngFile $_
}

Get-ChildItem -Path $output -Recurse -Filter "*.pvr.ccz" | ForEach-Object {
    Write-Host "Convert pvr.ccz to png: $($_.FullName)"
    CCZ2Png -inputFile $_.FullName
}

Get-ChildItem -Path $output -Recurse | Where-Object { $_.Name -like "*@alpha" } | ForEach-Object {
    $newName = $_.FullName -replace ".pvr.ccz@alpha$", "_alpha.pvr.ccz"
    Write-Host $newName
    Rename-Item -Path $_.FullName -NewName $newName
}
