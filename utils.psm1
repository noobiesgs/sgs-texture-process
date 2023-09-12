$PVRTexToolCLI = "D:\Program Files\Imagination Technologies\PowerVR_Graphics\PowerVR_Tools\PVRTexTool\CLI\Windows_x86_64\PVRTexToolCLI.exe"
$Magick = "D:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe"

function MigrateFile {
    param(
        [System.IO.FileSystemInfo] $file
    )
    $destinationPath = Join-Path -Path $output -ChildPath $file.FullName.Substring($file.FullName.IndexOf($sgsResourceFolder) + $sgsResourceFolder.Length)
    if (-not (Test-Path -Path $destinationPath)) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) -Force | Out-Null
        Copy-Item -Path $file.FullName -Destination $destinationPath -Force
        Write-Host "Copyed $($file.Name)"
    }
}

function ResolveJPG {
    param(
        [System.IO.FileSystemInfo] $jpgFile
    )

    $bytes = [byte[]]::new(2)
    $fileStream = [System.Io.File]::OpenRead($jpgFile.FullName)
    $fileStream.Read($bytes, 0, 2) | Out-Null

    if ($bytes[0] -ne 0xFF -or ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8)) {
        $fileStream.Close()
        return
    }

    Write-Host "Resolving $($jpgFile.FullName)"
    $bytes = [byte[]]@(0xFF)
    $targetFileName = [System.IO.Path]::GetFileNameWithoutExtension($jpgFile.Name)
    $targetFileName = [System.IO.Path]::Combine($jpgFile.Directory, $targetFileName + "_tmp" + ".jpg")

    if (Test-Path $targetFileName) {
        Remove-Item $targetFileName
    }

    $targetFileStream = [System.IO.File]::Create($targetFileName)
    $targetFileStream.Write($bytes, 0, $bytes.Length)

    $fileStream.Seek(33, [System.IO.SeekOrigin]::Begin) | Out-Null
    $buffer = [byte[]]::new(65536)
    while ($fileStream.Position -lt $fileStream.Length) {
        $bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)
        $targetFileStream.Write($buffer, 0, $bytesRead)
    }

    $fileStream.Close()
    $targetFileStream.Close()

    [System.IO.File]::Delete($jpgFile.FullName)
    Rename-Item -Path $targetFileName -NewName $jpgFile.FullName
}

function ResolvePNG {
    param(
        [System.IO.FileSystemInfo] $pngFile
    )

    $bytes = [byte[]]::new(2)
    $fileStream = [System.Io.File]::OpenRead($pngFile.FullName)
    $fileStream.Read($bytes, 0, 2) | Out-Null

    if ($bytes[0] -ne 0x89 -or ($bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50)) {
        $fileStream.Close()
        return
    }

    Write-Host "Resolving $($pngFile.FullName)"
    $bytes = [byte[]]@(0x89)
    $targetFileName = [System.IO.Path]::GetFileNameWithoutExtension($pngFile.Name)
    $targetFileName = [System.IO.Path]::Combine($pngFile.Directory, $targetFileName + "_tmp" + ".png")

    if (Test-Path $targetFileName) {
        Remove-Item $targetFileName
    }

    $targetFileStream = [System.IO.File]::Create($targetFileName)
    $targetFileStream.Write($bytes, 0, $bytes.Length)

    $fileStream.Seek(33, [System.IO.SeekOrigin]::Begin) | Out-Null
    $buffer = [byte[]]::new(65536)
    while ($fileStream.Position -lt $fileStream.Length) {
        $bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)
        $targetFileStream.Write($buffer, 0, $bytesRead)
    }

    $fileStream.Close()
    $targetFileStream.Close()

    [System.IO.File]::Delete($pngFile.FullName)
    Rename-Item -Path $targetFileName -NewName $pngFile.FullName
}

function DecompressZlib {
    param(
        [string] $inputFile,
        [string] $outputFile
    )

    $sourceStream = New-Object System.IO.FileStream($inputFile, [System.IO.FileMode]::Open)
    $sourceStream.Seek(16, [System.IO.SeekOrigin]::Begin) | Out-Null

    # check zlib header
    if ($sourceStream.ReadByte() -ne 0x78 -or $sourceStream.ReadByte() -ne 0x9C) {
        return $false
    }

    
    if (Test-Path $outputFile) {
        Remove-Item $outputFile
    }

    $deflateStream = New-Object System.IO.Compression.DeflateStream($sourceStream, [System.IO.Compression.CompressionMode]::Decompress)
    $outputStream = New-Object System.IO.FileStream($outputFile, [System.IO.FileMode]::Create)

    $deflateStream.CopyTo($outputStream)

    $outputStream.Close()
    $deflateStream.Close()
    $sourceStream.Close()

    return $true
}

function CCZ2Png {
    param(
        [string] $inputFile
    )

    $outputFile = $inputFile -replace "\.pvr.ccz$", ".pvr"
    
    $vaild = DecompressZlib -inputFile $inputFile -outputFile $outputFile

    if (-not $vaild) {
        return
    }

    $outputPng = $outputFile -replace "\.pvr$", ".png"
    & $PVRTexToolCLI -ics sRGB -i $outputFile -d $outputPng

    Remove-Item $outputFile
    Remove-Item $($outputFile -replace "\.pvr$", "_Out.pvr")
    Remove-Item $inputFile

    $alphaFile = $inputFile + "@alpha"
    
    if (-not (Test-Path $alphaFile)) {
        return
    }

    $newAlphaFile = $alphaFile -replace "\.pvr.ccz@alpha$", "_alpha.pvr.ccz"
    Rename-Item -Path $alphaFile -NewName $newAlphaFile

    CCZ2Png -inputFile $newAlphaFile

    $outputAlphaFile = $newAlphaFile -replace "_alpha.pvr.ccz$", "_alpha.png"
    & $Magick $outputPng $outputAlphaFile -compose copy-opacity -composite $outputPng
    Remove-Item $outputAlphaFile
}

