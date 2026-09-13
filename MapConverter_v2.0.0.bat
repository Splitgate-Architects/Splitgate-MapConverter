<# :
@echo off
title Splitgate Content Converter
setlocal
chcp 65001 >nul
set "BASEDIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content '%~f0' -Raw)"
pause
exit /b %errorlevel%
#>

# ============================================================
# POWERSHELL LOGIC STARTS HERE
# ============================================================
$ErrorActionPreference = "Stop"
$baseDir = $env:BASEDIR
$inputDir = Join-Path $baseDir "Input"
$outputDir = Join-Path $baseDir "Output"
$comment = "Packed by CreativeCore1047"

# Definition der unterstützten Content-Typen (angepasst an neues Setup)
$contentTypes = @(
    @{ id = "Maps";      marker = "World.cf1047";         hasImg = $true },
    @{ id = "Prefabs";   marker = "Prefab.cf1047_prefab"; hasImg = $true },
    @{ id = "Modes";     marker = "payload.json";         hasImg = $false }
)

Write-Host "Starting universal content processing..." -ForegroundColor Cyan
Write-Host "Input Root:  $inputDir" -ForegroundColor Cyan
Write-Host "Output Root: $outputDir" -ForegroundColor Cyan
Write-Host "================================================="

if (-not (Test-Path $inputDir))  { New-Item -ItemType Directory -Path $inputDir | Out-Null }
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }

foreach ($type in $contentTypes) {
    $inSubDir = Join-Path $inputDir $type.id
    $outSubDir = Join-Path $outputDir $type.id
    if (-not (Test-Path $inSubDir))  { New-Item -ItemType Directory -Path $inSubDir | Out-Null }
    if (-not (Test-Path $outSubDir)) { New-Item -ItemType Directory -Path $outSubDir | Out-Null }
}

# --- Strict Latin Slug Helper ---
function ConvertTo-StrictLatin {
    param([string]$Text, [switch]$AllowDashes)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    
    $t = $Text -replace '\^[0-9]', '' -replace '\+', 'plus' -replace '&', 'and'
    $t = $t.Normalize([Text.NormalizationForm]::FormKD)
    
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $t.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    $t = $sb.ToString().ToLowerInvariant()
    
    if ($AllowDashes) {
        $t = $t -replace '\s+', '-'
        $t = $t -replace '[^a-z0-9-]', ''
        $t = $t -replace '-+', '-'
        return $t.Trim('-')
    } else {
        return ($t -replace '[^a-z0-9]', '')
    }
}

$processedTotal = 0
$skippedTotal = 0

foreach ($type in $contentTypes) {
    $currentInDir = Join-Path $inputDir $type.id
    $currentOutDir = Join-Path $outputDir $type.id
    $folders = Get-ChildItem -Path $currentInDir -Directory

    if ($folders.Count -eq 0) { continue }
    Write-Host "`nProcessing category: [$($type.id.ToUpper())]" -ForegroundColor Magenta

    foreach ($folder in $folders) {
        $subFolder = $folder.FullName
        $readme = Join-Path $subFolder "README.md"
        $jsonPath = Join-Path $subFolder "Info.json"
        $markerFile = Join-Path $subFolder $type.marker
        $imgFile = Join-Path $subFolder "Screenshot.jpg"

        $hasCustomInfo = Test-Path $jsonPath
        $hasReadme = Test-Path $readme

        # Validierung: Nur der Format-Marker und ggf. das Bild sind zwingend
        $missing = @()
        if (-not (Test-Path $markerFile)) { $missing += $type.marker }
        if ($type.hasImg -and -not (Test-Path $imgFile)) { $missing += "Screenshot.jpg" }

        if ($missing.Count -gt 0) {
            Write-Host "  -> [SKIPPED] $($folder.Name) | Missing: $($missing -join ', ')" -ForegroundColor Red
            $skippedTotal++
            continue
        }

        $itemName = ""
        $author = ""

        # Daten-Extraktion
        if ($hasCustomInfo) {
            try {
                $parsedJson = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($parsedJson.name) { $itemName = $parsedJson.name }
                if ($parsedJson.author) { $author = $parsedJson.author }
            } catch {
                Write-Host "     [WARNING] Could not parse Info.json. Proceeding with folder name." -ForegroundColor DarkYellow
            }
        } elseif ($hasReadme) {
            $lines = @(Get-Content $readme -Encoding UTF8 | Where-Object { $_.Trim() -ne "" })
            if ($lines.Count -ge 2) {
                if ($lines[0] -match "^#+\s*(.*)") { $itemName = $matches[1].Trim() }
                if ($lines[1] -match "(?i)^#+\s*Author:\s*(.*)") { $author = $matches[1].Trim() }
            }
        }

        # Fallback auf Ordnernamen, falls keine Metadaten extrahiert wurden
        if ([string]::IsNullOrWhiteSpace($itemName)) { $itemName = $folder.Name }
        if ([string]::IsNullOrWhiteSpace($author)) { $author = "Unknown" }

        # Temporäre Info.json erstellen (das Spielarchiv erfordert diese Datei)
        if (-not $hasCustomInfo) {
            $jsonObj = [ordered]@{ name = $itemName; author = $author }
            $jsonObj | ConvertTo-Json -Depth 2 | Set-Content $jsonPath -Encoding UTF8
        }

        # Dateinamen generieren
        $cleanOrigin = $folder.Name.ToLower() -replace '[^a-z0-9-]', ''
        
        if (-not $hasCustomInfo -and -not $hasReadme) {
            # Clean Fallback: Keine Info-Dateien = Dateiname entspricht exakt dem bereinigten Ordnernamen
            $baseFileName = $cleanOrigin
        } else {
            $cleanAuthor = ConvertTo-StrictLatin $author
            $cleanItem = ConvertTo-StrictLatin $itemName -AllowDashes
            if ([string]::IsNullOrEmpty($cleanAuthor)) { $cleanAuthor = "unknown" }
            if ([string]::IsNullOrEmpty($cleanItem)) { $cleanItem = "unknown" }
            $baseFileName = "${cleanOrigin}_${cleanAuthor}_${cleanItem}"
        }

        $binFileName = "${baseFileName}.bin"
        $imgFileName = "${baseFileName}.jpg"
        
        $binPath = Join-Path $currentOutDir $binFileName
        $targetImgPath = Join-Path $currentOutDir $imgFileName

        # Massenverarbeitungs-Check
        if (Test-Path $binPath) {
            Write-Host "  -> [EXISTS] $($folder.Name) -> $binFileName already in output. Skipping." -ForegroundColor DarkGray
            $skippedTotal++
            continue
        }

        Write-Host "  -> [PACKING] $($folder.Name) -> $binFileName" -ForegroundColor Yellow

        $zipPath = Join-Path $baseDir "temp_$($folder.Name).zip"
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

        $filesToPack = @("Info.json", $type.marker)
        if ($type.hasImg) { $filesToPack += "Screenshot.jpg" }

        Push-Location $subFolder
        Compress-Archive -Path $filesToPack -DestinationPath $zipPath -Force
        Pop-Location

        if (Test-Path $zipPath) {
            # ZIP Comment Hex-Patching
            $bytes = [System.IO.File]::ReadAllBytes($zipPath)
            $commentBytes = [System.Text.Encoding]::ASCII.GetBytes($comment)
            $eocdPos = -1
            for ($i = $bytes.Length - 22; $i -ge 0; $i--) {
                if ($bytes[$i] -eq 0x50 -and $bytes[$i+1] -eq 0x4B -and $bytes[$i+2] -eq 0x05 -and $bytes[$i+3] -eq 0x06) {
                    $eocdPos = $i
                    break
                }
            }

            if ($eocdPos -ne -1) {
                $head = $bytes[0..($eocdPos + 19)]
                $newLen = [System.BitConverter]::GetBytes([UInt16]$commentBytes.Length)
                $result = New-Object byte[] ($head.Length + 2 + $commentBytes.Length)
                [Array]::Copy($head, 0, $result, 0, $head.Length)
                [Array]::Copy($newLen, 0, $result, $head.Length, 2)
                [Array]::Copy($commentBytes, 0, $result, $head.Length + 2, $commentBytes.Length)
                [System.IO.File]::WriteAllBytes($zipPath, $result)
            } else {
                Write-Host "     [WARNING] Could not find signature for ZIP comment." -ForegroundColor DarkYellow
            }

            Move-Item -Path $zipPath -Destination $binPath -Force
            if ($type.hasImg) {
                Copy-Item -Path $imgFile -Destination $targetImgPath -Force
            }

            Write-Host "     Successfully packed!" -ForegroundColor Green
            $processedTotal++
        } else {
            Write-Host "     [ERROR] ZIP archive could not be created." -ForegroundColor Red
            $skippedTotal++
        }

        # Aufräumen: Nur temporäre Info.json löschen
        if (-not $hasCustomInfo -and (Test-Path $jsonPath)) { 
            Remove-Item $jsonPath -Force 
        }
    }
}

Write-Host "`n================================================="
Write-Host "Process completed! Packed: $processedTotal | Skipped: $skippedTotal" -ForegroundColor Cyan