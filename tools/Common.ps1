# Shared helpers for the generator, build and test scripts. Dot-source this file.
# Windows PowerShell 5.1 compatible.

Set-StrictMode -Version 2

function Read-VlachConfig {
    <# Loads tools/vlach.config.psd1 as UTF-8 (Import-PowerShellDataFile in 5.1 would read a
       BOM-less file as ANSI and mangle Romanian letters). Only data is allowed in the file. #>
    param([Parameter(Mandatory)] [string]$Path)
    $text = [IO.File]::ReadAllText((Resolve-Path $Path).Path, [Text.Encoding]::UTF8)
    $block = [scriptblock]::Create($text)
    $block.CheckRestrictedLanguage([string[]]@(), [string[]]@(), $false)
    return (& $block)
}

function Get-ModuleVersion {
    param([Parameter(Mandatory)] [string]$SubModulePath)
    $doc = Read-XmlFile $SubModulePath
    return $doc.SelectSingleNode('/Module/Version').GetAttribute('value')
}

function Read-XmlFile {
    param([Parameter(Mandatory)] [string]$Path)
    $doc = New-Object System.Xml.XmlDocument
    $doc.PreserveWhitespace = $false
    $doc.Load((Resolve-Path -LiteralPath $Path).Path)
    return $doc
}

function New-DataDocument {
    param([Parameter(Mandatory)] [string]$Root, [string]$Comment)
    $doc = New-Object System.Xml.XmlDocument
    [void]$doc.AppendChild($doc.CreateXmlDeclaration('1.0', 'utf-8', $null))
    if ($Comment) { [void]$doc.AppendChild($doc.CreateComment($Comment)) }
    [void]$doc.AppendChild($doc.CreateElement($Root))
    return $doc
}

function Save-XmlFile {
    param([Parameter(Mandatory)] [System.Xml.XmlDocument]$Document, [Parameter(Mandatory)] [string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.IndentChars = "`t"
    $settings.NewLineChars = "`r`n"
    $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
    $writer = [System.Xml.XmlWriter]::Create($Path, $settings)
    try { $Document.Save($writer) } finally { $writer.Close() }
}

function Get-Opt {
    <# Optional hashtable value; $null when the key is absent (StrictMode-safe). #>
    param([hashtable]$Table, [string]$Key)
    if ($Table.ContainsKey($Key)) { return $Table[$Key] }
    return $null
}

function Select-First {
    <# First argument that is neither $null nor an empty string. #>
    foreach ($v in $args) { if ($null -ne $v -and "$v" -ne '') { return $v } }
    return $null
}

function Convert-LocalizedText {
    <# Applies $Transform to the visible text of "{=id}text", keeping the localisation id. #>
    param([string]$Text, [scriptblock]$Transform)
    if ($Text -match '^(\{=[^}]*\})(.*)$') { return $Matches[1] + (& $Transform $Matches[2]) }
    return (& $Transform $Text)
}
