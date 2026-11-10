<#
.SYNOPSIS
Builds the Windows release of the Flutter application and packages it for download.

.PARAMETER ApiBaseUrl
Default API URL compiled into the application.

.PARAMETER OutputDir
Destination directory; the artifact is written to <OutputDir>\windows.
#>
param(
    [string]$ApiBaseUrl = $(if ($env:API_BASE_URL) { $env:API_BASE_URL } else { 'http://localhost:8989' }),
    [string]$OutputDir = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$appDir = Resolve-Path (Join-Path $PSScriptRoot '..')
if (-not $OutputDir) { $OutputDir = Join-Path $appDir 'build\releases' }
$OutputDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)

$uri = $null
if (-not [Uri]::TryCreate($ApiBaseUrl, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -notin 'http', 'https' -or $ApiBaseUrl -match '["\\\s]') {
    throw "ApiBaseUrl must be an HTTP or HTTPS URL: $ApiBaseUrl"
}
$ApiBaseUrl = $ApiBaseUrl.TrimEnd('/')

Push-Location $appDir
try {
    $version = ((Select-String -Path pubspec.yaml -Pattern '^version:\s*(.+)$' | Select-Object -First 1).Matches[0].Groups[1].Value).Trim()

    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
    flutter build windows --release "--dart-define=API_BASE_URL=$ApiBaseUrl"
    if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed.' }

    $releaseDir = Get-ChildItem build\windows -Directory | ForEach-Object { Join-Path $_.FullName 'runner\Release' } |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $releaseDir) { throw 'Windows release bundle not found.' }
    $arch = Split-Path (Split-Path (Split-Path $releaseDir -Parent) -Parent) -Leaf

    $target = Join-Path $OutputDir 'windows'
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    New-Item -ItemType Directory -Path $target | Out-Null

    $staging = Join-Path ([IO.Path]::GetTempPath()) "application-windows-$([Guid]::NewGuid())"
    New-Item -ItemType Directory -Path $staging | Out-Null
    Copy-Item $releaseDir (Join-Path $staging 'application') -Recurse
    Compress-Archive -Path (Join-Path $staging 'application') -DestinationPath (Join-Path $target "application-windows-$arch.zip")
    Remove-Item $staging -Recurse -Force

    $buildInfo = [ordered]@{
        version    = $version
        apiBaseUrl = $ApiBaseUrl
        builtAt    = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    } | ConvertTo-Json
    [IO.File]::WriteAllText((Join-Path $target 'build-info.json'), $buildInfo, (New-Object Text.UTF8Encoding $false))

    Write-Host "Packaged windows into $target"
}
finally {
    Pop-Location
}
