$ErrorActionPreference = "Stop"
$version = "0.76.0"
$labRoot = Split-Path -Parent $PSScriptRoot
$parentDir = Split-Path -Parent $labRoot
$downloadDir = Join-Path $parentDir "downloads"
$toolDir = Join-Path $parentDir "trivy_${version}_windows-64bit"
New-Item -ItemType Directory -Force -Path $downloadDir, $toolDir | Out-Null

$baseUrl = "https://github.com/aquasecurity/trivy/releases/download/v$version"
$archive = "trivy_${version}_windows-64bit.zip"
$archivePath = Join-Path $downloadDir $archive
$checksumsPath = Join-Path $downloadDir "trivy_${version}_checksums.txt"

Invoke-WebRequest "$baseUrl/$archive" -OutFile $archivePath
Invoke-WebRequest "$baseUrl/trivy_${version}_checksums.txt" -OutFile $checksumsPath

$line = Get-Content $checksumsPath |
    Where-Object { ($_ -split '\s+')[-1] -eq $archive } |
    Select-Object -First 1
if (-not $line) {
    throw "Archive not found in checksum manifest"
}

$expected = ($line -split '\s+')[0]
$actual = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
Write-Host "Expected SHA-256: $expected"
Write-Host "Actual SHA-256:   $actual"
if ($expected -ne $actual) {
    throw "SHA-256 verification failed"
}
Write-Host "SHA-256 OK"

Expand-Archive -LiteralPath $archivePath -DestinationPath $toolDir -Force
& (Join-Path $toolDir "trivy.exe") --version
if ($LASTEXITCODE -ne 0) {
    throw "Could not start Trivy"
}

