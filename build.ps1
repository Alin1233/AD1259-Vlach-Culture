<#
.SYNOPSIS
    Builds, tests and (optionally) installs the "AD1259 - Vlach Culture" submod.

.DESCRIPTION
    1. (optional, -Generate) regenerates Module\ModuleData\vlach_generated_*.xml
    2. compiles src\AD1259.Vlach\*.cs into AD1259.Vlach.dll against the game's assemblies
    3. assembles the module in out\AD1259_Vlach (Module\ + bin\Win64_Shipping_Client\)
    4. runs tests\Test-Module.ps1 (skip with -SkipTests)
    5. (optional, -Package) writes the release archive out\AD1259_Vlach-<version>.zip
       (one top-level AD1259_Vlach folder, to be extracted into Modules\)
    6. (optional, -Install) copies out\AD1259_Vlach to <GameDir>\Modules\AD1259_Vlach

    The C# code is kept at language version 5 so it also compiles with the compiler that
    ships with Windows (.NET Framework 4.x csc.exe); a Roslyn csc.exe from Visual Studio /
    Build Tools is preferred when present.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File build.ps1 -Install
#>
[CmdletBinding()]
param(
    [string]$GameDir = 'C:\Program Files (x86)\Steam\steamapps\common\Mount & Blade II Bannerlord',
    [switch]$Generate,
    [switch]$SkipTests,
    [switch]$Package,
    [switch]$Install
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleId = 'AD1259_Vlach'
$out = Join-Path $root "out\$moduleId"
$gameBin = Join-Path $GameDir 'bin\Win64_Shipping_Client'

function Read-SubModuleVersion([string]$Path) {
    $doc = New-Object System.Xml.XmlDocument
    $doc.Load($Path)
    return $doc.SelectSingleNode('/Module/Version').GetAttribute('value')
}

function Find-Compiler {
    $candidates = @()
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $vswhere) {
        $candidates += & $vswhere -all -products * -find 'MSBuild\**\Roslyn\csc.exe' 2>$null
    }
    foreach ($vsRoot in "${env:ProgramFiles}\Microsoft Visual Studio", "${env:ProgramFiles(x86)}\Microsoft Visual Studio") {
        if (Test-Path $vsRoot) {
            $candidates += Get-ChildItem $vsRoot -Recurse -Filter csc.exe -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match '\\Roslyn\\csc\.exe$' } | Select-Object -ExpandProperty FullName
        }
    }
    $candidates += Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }
    throw 'No C# compiler found (install Visual Studio Build Tools, or use the .NET Framework 4.x csc.exe).'
}

# --- 1. Generate -------------------------------------------------------------------
if ($Generate) {
    & (Join-Path $root 'tools\Generate-ModuleData.ps1') -GameDir $GameDir
}

# --- 2. Compile --------------------------------------------------------------------
if (-not (Test-Path $gameBin)) { throw "Game binaries not found: $gameBin" }
$csc = Find-Compiler
$isRoslyn = $csc -match '\\Roslyn\\'
Write-Host "Compiler: $csc"

if (Test-Path $out) { Remove-Item -Recurse -Force $out }
$binOut = Join-Path $out 'bin\Win64_Shipping_Client'
New-Item -ItemType Directory -Force $binOut | Out-Null

$references = 'TaleWorlds.MountAndBlade', 'TaleWorlds.Library', 'TaleWorlds.Core', 'TaleWorlds.Engine',
              'TaleWorlds.Engine.GauntletUI', 'TaleWorlds.GauntletUI', 'TaleWorlds.TwoDimension',
              'TaleWorlds.ObjectSystem', 'TaleWorlds.Localization', 'TaleWorlds.DotNet', 'TaleWorlds.InputSystem'
$cscArgs = @('/nologo', '/target:library', '/optimize+', '/debug:portable', '/warnaserror+', '/nostdlib-',
             "/out:$(Join-Path $binOut 'AD1259.Vlach.dll')")
if ($isRoslyn) { $cscArgs += '/langversion:5'; $cscArgs += '/deterministic' } else { $cscArgs = $cscArgs | Where-Object { $_ -ne '/debug:portable' }; $cscArgs += '/debug:pdbonly' }
foreach ($r in $references) {
    $p = Join-Path $gameBin "$r.dll"
    if (-not (Test-Path $p)) { throw "Missing game assembly: $p" }
    $cscArgs += "/reference:$p"
}
# The game assemblies target netstandard2.0; .NET Framework 4.7.2+ ships the facade.
$netstandard = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\netstandard.dll'
if (-not (Test-Path $netstandard)) { throw "netstandard.dll facade not found ($netstandard); install .NET Framework 4.7.2 or later." }
$cscArgs += "/reference:$netstandard"
$cscArgs += Get-ChildItem (Join-Path $root 'src\AD1259.Vlach') -Recurse -Filter *.cs | Select-Object -ExpandProperty FullName

& $csc @cscArgs
if ($LASTEXITCODE -ne 0) { throw "Compilation failed (exit code $LASTEXITCODE)." }
Write-Host 'Compiled AD1259.Vlach.dll'

# --- 3. Assemble -------------------------------------------------------------------
Copy-Item (Join-Path $root 'Module\*') $out -Recurse -Force
foreach ($doc in 'README.md', 'LICENSE', 'CHANGELOG.md') { Copy-Item (Join-Path $root $doc) $out -Force }
Write-Host "Assembled module in $out"

# --- 4. Test -----------------------------------------------------------------------
if (-not $SkipTests) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tests\Test-Module.ps1') -GameDir $GameDir -ModuleDir $out
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed; not packaging or installing.' }
} elseif ($Package) {
    throw 'Refusing to package an untested build: do not combine -Package with -SkipTests.'
}

# --- 5. Package --------------------------------------------------------------------
if ($Package) {
    $version = (Read-SubModuleVersion (Join-Path $out 'SubModule.xml'))
    $zip = Join-Path $root "out\$moduleId-$version.zip"
    if (Test-Path $zip) { Remove-Item -Force $zip }
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    # Entries are written by hand: Compress-Archive on Windows PowerShell 5.1 stores
    # backslash separators, which some launchers/extractors do not treat as folders.
    $archive = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        $base = (Split-Path -Parent $out).Length + 1
        foreach ($file in Get-ChildItem $out -Recurse -File | Where-Object { $_.Extension -ne '.pdb' } | Sort-Object FullName) {
            $entry = $file.FullName.Substring($base).Replace('\', '/')
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entry, [System.IO.Compression.CompressionLevel]::Optimal)
        }
    } finally { $archive.Dispose() }
    Write-Host "Packaged $zip"
}

# --- 6. Install --------------------------------------------------------------------
if ($Install) {
    $target = Join-Path $GameDir "Modules\$moduleId"
    if (Test-Path $target) {
        # Only ever replace a folder that really is this module.
        $existing = Join-Path $target 'SubModule.xml'
        $id = if (Test-Path $existing) { ([xml](Get-Content -LiteralPath $existing -Raw)).Module.Id.value } else { $null }
        if ($id -ne $moduleId) { throw "$target exists but is not $moduleId (Id='$id'); refusing to overwrite." }
        Remove-Item -Recurse -Force $target
    }
    Copy-Item $out $target -Recurse
    Get-ChildItem $target -Recurse -Include *.dll | Unblock-File
    Write-Host "Installed to $target"
}
