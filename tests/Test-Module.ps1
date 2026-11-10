<#
.SYNOPSIS
    Offline test suite for the "AD1259 - Vlach Culture" submod.

.DESCRIPTION
    Verifies everything that can be verified without starting the game:

      1. every module file is well-formed XML
      2. SubModule.xml declares every data file, the DLL and its entry type
      3. the generated files are in sync with tools/vlach.config.psd1
      4. module XML validates against the game's own XSD schemas (XmlSchemas\)
      5. the XSLT patches, applied to AD1259's real data, change exactly the intended
         settlements / clan / nobles and nothing else
      6. the settlement selection is complete (no Bulgarian village of a Vlach town missed)
      7. every id referenced by the module exists in the modlist's data
      8. the culture is complete (culture-keyed equipment twins, names, basic troops, glyphs)
      9. the troop tree is sane (reachable, levels rise, cavalry has horses)
     10. the DLL registers the culture inside the real AD1259.dll and copies the culture-art
         style on a real Gauntlet brush (run in a child process)
     11. the sources also compile with the .NET Framework compiler (C# 5)

    Exit code 0 when all checks pass, 1 otherwise.

.PARAMETER ModuleDir
    Assembled module to test (default: out\AD1259_Vlach, as produced by build.ps1).
#>
[CmdletBinding()]
param(
    [string]$GameDir = 'C:\Program Files (x86)\Steam\steamapps\common\Mount & Blade II Bannerlord',
    [string]$ModuleDir
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $ModuleDir) { $ModuleDir = Join-Path $repo 'out\AD1259_Vlach' }
. (Join-Path $repo 'tools\Common.ps1')

$cfg = Read-VlachConfig -Path (Join-Path $repo 'tools\vlach.config.psd1')
$data = Join-Path $ModuleDir 'ModuleData'
$adDir = Join-Path $GameDir 'Modules\AD1259'
$adData = Join-Path $adDir 'ModuleData'
$gameBin = Join-Path $GameDir 'bin\Win64_Shipping_Client'
$script:failed = 0

function Invoke-Check {
    param([string]$Name, [scriptblock]$Body)
    $problems = @()
    try { $problems = @(& $Body) } catch { $problems = @("exception: $($_.Exception.Message)") }
    $problems = @($problems | Where-Object { $_ })
    if ($problems.Count -eq 0) {
        Write-Host "PASS  $Name" -ForegroundColor Green
    } else {
        $script:failed++
        Write-Host "FAIL  $Name" -ForegroundColor Red
        $problems | Select-Object -First 25 | ForEach-Object { Write-Host "        $_" }
        if ($problems.Count -gt 25) { Write-Host "        ... and $($problems.Count - 25) more" }
    }
}

function Get-XsltIds([string]$Path) {
    $text = [IO.File]::ReadAllText($Path)
    return @([regex]::Matches($text, "@id='([^']+)'") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
}

function Invoke-Xslt([string]$XsltPath, [System.Xml.XmlDocument]$Source) {
    # (Not named $Input: that is a PowerShell automatic variable.)
    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xslt.Load($XsltPath)
    $sw = New-Object System.IO.StringWriter
    $writer = [System.Xml.XmlWriter]::Create($sw, $xslt.OutputSettings)
    $xslt.Transform([System.Xml.XPath.IXPathNavigable]$Source, [System.Xml.Xsl.XsltArgumentList]$null, $writer)
    $writer.Close()
    $out = New-Object System.Xml.XmlDocument
    $out.LoadXml($sw.ToString())
    return $out
}

function Merge-Folder([string]$Folder, [string]$Root, [string]$Element) {
    $merged = New-DataDocument -Root $Root
    foreach ($f in Get-ChildItem $Folder -Filter '*.xml' | Sort-Object Name) {
        foreach ($n in (Read-XmlFile $f.FullName).SelectNodes("/$Root/$Element")) {
            [void]$merged.DocumentElement.AppendChild($merged.ImportNode($n, $true))
        }
    }
    return $merged
}

function Compare-Patched {
    <# Compares elements by id before/after a patch. $Expected: id -> @{ attribute = expected value }.
       Listed elements must differ exactly by those attribute values; every other element must be
       unchanged. #>
    param([System.Xml.XmlDocument]$Before, [System.Xml.XmlDocument]$After, [string]$XPath, [hashtable]$Expected)
    # Compared by position: an identity-based XSLT keeps document order, and AD1259 contains a
    # few duplicate ids (e.g. dead_lord_ilkhanate_4), so an id-keyed comparison would be wrong.
    $problems = @()
    $beforeNodes = @($Before.SelectNodes($XPath))
    $afterNodes = @($After.SelectNodes($XPath))
    if ($beforeNodes.Count -ne $afterNodes.Count) { return @("element count changed: $($beforeNodes.Count) -> $($afterNodes.Count)") }
    $seen = @{}
    for ($i = 0; $i -lt $beforeNodes.Count; $i++) {
        $b = $beforeNodes[$i]; $a = $afterNodes[$i]; $id = $b.GetAttribute('id')
        if ($a.GetAttribute('id') -ne $id) { $problems += "element $i is $($a.GetAttribute('id')) after patching, expected $id"; continue }
        if ($Expected.ContainsKey($id)) { $seen[$id] = $true; $problems += Test-OnlyAttributesChanged $b $a $Expected[$id] }
        elseif ($b.OuterXml -ne $a.OuterXml) { $problems += "$id changed but is not part of the design" }
    }
    foreach ($id in $Expected.Keys) { if (-not $seen.ContainsKey($id)) { $problems += "$id not found in AD1259 data" } }
    return $problems
}

function Test-OnlyAttributesChanged($before, $after, [hashtable]$expectedValues) {
    foreach ($attr in @($expectedValues.Keys)) {
        if ($before.GetAttribute($attr) -eq $expectedValues[$attr]) {
            return "$($before.GetAttribute('id')): $attr already had the expected value before patching (test would prove nothing)"
        }
    }
    $problems = @()
    foreach ($attr in $expectedValues.Keys) {
        if ($after.GetAttribute($attr) -ne $expectedValues[$attr]) {
            $problems += "$($before.GetAttribute('id')): $attr is '$($after.GetAttribute($attr))', expected '$($expectedValues[$attr])'"
        }
    }
    $b2 = $before.CloneNode($true)
    foreach ($attr in $expectedValues.Keys) { $b2.SetAttribute($attr, $expectedValues[$attr]) }
    if ($b2.OuterXml -ne $after.OuterXml) { $problems += "$($before.GetAttribute('id')): changed beyond $($expectedValues.Keys -join ', ')" }
    return $problems
}

Write-Host "Testing $ModuleDir"
Write-Host "Against $adDir"
Write-Host ''

# ---------------------------------------------------------------------------------
Invoke-Check '1. Module files are well-formed XML' {
    foreach ($f in @(Get-ChildItem $ModuleDir -Recurse -Include *.xml, *.xslt)) {
        try { [void](Read-XmlFile $f.FullName) } catch { "$($f.Name): $($_.Exception.Message)" }
    }
}

# ---------------------------------------------------------------------------------
Invoke-Check '2. SubModule.xml declares every data file, the DLL and its entry type' {
    $sm = Read-XmlFile (Join-Path $ModuleDir 'SubModule.xml')
    if ($sm.SelectSingleNode('/Module/Id').GetAttribute('value') -ne 'AD1259_Vlach') { 'Id is not AD1259_Vlach' }
    $dep = $sm.SelectSingleNode("/Module/DependedModules/DependedModule[@Id='AD1259']")
    if (-not $dep) { 'AD1259 is not a DependedModule' }
    elseif ($dep.GetAttribute('DependentVersion') -ne $cfg.Ad1259Version) { "DependentVersion is not $($cfg.Ad1259Version)" }
    $declared = @{}
    foreach ($x in $sm.SelectNodes('/Module/Xmls/XmlNode/XmlName')) {
        $p = $x.GetAttribute('path'); $declared["$p.xml"] = $true
        if (-not (Test-Path (Join-Path $data "$p.xml"))) { "declared file missing: $p.xml" }
    }
    foreach ($f in Get-ChildItem $data -Filter *.xml) { if (-not $declared.ContainsKey($f.Name)) { "not declared in SubModule.xml: $($f.Name)" } }
    foreach ($f in Get-ChildItem $data -Filter *.xslt) {
        if (-not $declared.ContainsKey(($f.BaseName + '.xml'))) { "$($f.Name) has no declared .xml of the same name, so the game would never apply it" }
    }
    $sub = $sm.SelectSingleNode('/Module/SubModules/SubModule')
    $dll = Join-Path $ModuleDir ('bin\Win64_Shipping_Client\' + $sub.SelectSingleNode('DLLName').GetAttribute('value'))
    if (-not (Test-Path $dll)) { "DLL missing: $dll" }
    else {
        $typeName = $sub.SelectSingleNode('SubModuleClassType').GetAttribute('value')
        $bytes = [IO.File]::ReadAllBytes($dll)
        $ascii = [Text.Encoding]::ASCII.GetString($bytes)
        foreach ($part in $typeName.Split('.')) { if ($ascii.IndexOf($part) -lt 0) { "entry type part '$part' of $typeName not found in the DLL metadata" } }
    }
}

# ---------------------------------------------------------------------------------
Invoke-Check '3. Generated files are in sync with the config' {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('ad1259vlach_gen_' + [guid]::NewGuid().ToString('N'))
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'tools\Generate-ModuleData.ps1') -GameDir $GameDir -OutDir $tmp | Out-Null
        if ($LASTEXITCODE -ne 0) { 'generator failed' }
        foreach ($f in Get-ChildItem $tmp -Filter 'vlach_generated_*.xml') {
            $mine = Join-Path $data $f.Name
            if (-not (Test-Path $mine)) { "missing in module: $($f.Name)"; continue }
            if ((Get-FileHash $f.FullName).Hash -ne (Get-FileHash $mine).Hash) { "$($f.Name) is out of date: run build.ps1 -Generate" }
        }
    } finally { if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp } }
}

# ---------------------------------------------------------------------------------
Invoke-Check '4. Module XML validates against the game XSD schemas' {
    $sm = Read-XmlFile (Join-Path $ModuleDir 'SubModule.xml')
    foreach ($x in $sm.SelectNodes('/Module/Xmls/XmlNode/XmlName')) {
        $xsd = Join-Path $GameDir ("XmlSchemas\{0}.xsd" -f $x.GetAttribute('id'))
        if (-not (Test-Path $xsd)) { "no schema $xsd"; continue }
        $file = Join-Path $data ($x.GetAttribute('path') + '.xml')
        $set = New-Object System.Xml.Schema.XmlSchemaSet
        [void]$set.Add($null, $xsd)
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.ValidationType = [System.Xml.ValidationType]::Schema
        $settings.Schemas = $set
        $script:xsdErrors = New-Object System.Collections.Generic.List[string]
        $settings.add_ValidationEventHandler({ param($s, $e) $script:xsdErrors.Add("line $($e.Exception.LineNumber): $($e.Message)") })
        $reader = [System.Xml.XmlReader]::Create($file, $settings)
        try { while ($reader.Read()) { } } finally { $reader.Close() }
        foreach ($err in $script:xsdErrors) { "$(Split-Path -Leaf $file) $err" }
    }
}

# ---------------------------------------------------------------------------------
Invoke-Check '5a. Settlement patch changes exactly the listed settlements' {
    $xsltIds = Get-XsltIds (Join-Path $data 'vlach_settlements.xslt')
    $diff = Compare-Object ($xsltIds | Sort-Object) (@($cfg.VlachSettlements) | Sort-Object)
    if ($diff) { "XSLT and config disagree: " + (($diff | ForEach-Object { "$($_.SideIndicator)$($_.InputObject)" }) -join ' ') }
    $before = Read-XmlFile (Join-Path $adData 'settlements.xml')
    $after = Invoke-Xslt (Join-Path $data 'vlach_settlements.xslt') $before
    $expected = @{}
    foreach ($id in $cfg.VlachSettlements) { $expected[$id] = @{ culture = 'Culture.vlach' } }
    Compare-Patched $before $after '/Settlements/Settlement' $expected
}

Invoke-Check '5b. Clan patch changes only the Vlach clan, which stays in Bulgaria' {
    $before = Merge-Folder (Join-Path $adData 'spclans') 'Factions' 'Faction'
    $after = Invoke-Xslt (Join-Path $data 'vlach_clans.xslt') $before
    Compare-Patched $before $after '/Factions/Faction' @{ $cfg.VlachClan = @{ culture = 'Culture.vlach' } }
    $clan = $after.SelectSingleNode("/Factions/Faction[@id='$($cfg.VlachClan)']")
    if ($clan -and $clan.GetAttribute('super_faction') -ne 'Kingdom.bulgaria') { 'the clan left the Kingdom of Bulgaria' }
}

Invoke-Check '5c. Noble patch changes only the eight Vlach nobles (culture + two names)' {
    $before = Merge-Folder (Join-Path $adData 'lords_main') 'NPCCharacters' 'NPCCharacter'
    $after = Invoke-Xslt (Join-Path $data 'vlach_lords.xslt') $before
    $expected = @{}
    foreach ($id in $cfg.VlachLords) {
        $values = @{ culture = 'Culture.vlach' }
        if ($cfg.RenamedLords.ContainsKey($id)) { $values['name'] = "{=ad1259vlach_$id}$($cfg.RenamedLords[$id])" }
        $expected[$id] = $values
    }
    Compare-Patched $before $after '/NPCCharacters/NPCCharacter' $expected
    $heroes = (Merge-Folder (Join-Path $adData 'heroes') 'Heroes' 'Hero').SelectNodes("/Heroes/Hero[@faction='Faction.$($cfg.VlachClan)']")
    $heroIds = @($heroes | ForEach-Object { $_.GetAttribute('id') } | Sort-Object)
    if (Compare-Object $heroIds (@($cfg.VlachLords) | Sort-Object)) { "config VlachLords differ from the clan's heroes in AD1259: $($heroIds -join ', ')" }
}

# ---------------------------------------------------------------------------------
Invoke-Check '6. Settlement selection is complete and consistent' {
    $doc = Read-XmlFile (Join-Path $adData 'settlements.xml')
    $byId = @{}; foreach ($s in $doc.SelectNodes('/Settlements/Settlement')) { $byId[$s.GetAttribute('id')] = $s }
    $selected = @{}; foreach ($id in $cfg.VlachSettlements) { $selected[$id] = $true }
    $towns = @($cfg.VlachSettlements | Where-Object { $byId.ContainsKey($_) -and $byId[$_].SelectSingleNode('Components/Town') })
    foreach ($t in $towns) {
        if ($byId[$t].GetAttribute('owner') -notmatch '^Faction\.clan_bulgaria_') { "$t is not owned by a Bulgarian clan" }
    }
    foreach ($s in $byId.Values) {
        $v = $s.SelectSingleNode('Components/Village'); if (-not $v) { continue }
        $bound = $v.GetAttribute('bound') -replace '^Settlement\.', ''
        $id = $s.GetAttribute('id')
        if ($towns -contains $bound -and $s.GetAttribute('culture') -eq 'Culture.bulgaria' -and -not $selected.ContainsKey($id)) {
            "village $id of Vlach town $bound is Bulgarian but not selected"
        }
        if ($selected.ContainsKey($id) -and $towns -notcontains $bound -and $s.GetAttribute('culture') -ne 'Culture.hungarian') {
            "village $id is selected but neither belongs to a Vlach town nor is a Hungarian (Transylvanian) village"
        }
    }
}

# ---------------------------------------------------------------------------------
$modlist = 'Native', 'SandBoxCore', 'BirthAndDeath', 'CustomBattle', 'SandBox', 'StoryMode', 'RBM',
           'ExpandedArmouryBL', 'swadian armoury', 'OpenSourceArmory', 'OpenSourceSaddlery', 'OpenSourceWeaponry',
           'Templar Armor', 'Templar Equipment', 'SettlementIconRedesign', 'AD1259'
Invoke-Check '7. Every referenced id exists in the modlist data' {
    $index = New-Object 'System.Collections.Generic.HashSet[string]'
    $readerSettings = New-Object System.Xml.XmlReaderSettings
    $readerSettings.DtdProcessing = [System.Xml.DtdProcessing]::Ignore
    $dirs = @($modlist | ForEach-Object { Join-Path $GameDir "Modules\$_\ModuleData" }) + $data
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) { continue }   # code-only modules (BirthAndDeath, SettlementIconRedesign) have no data
        foreach ($f in Get-ChildItem $dir -Recurse -Filter *.xml) {
            $r = [System.Xml.XmlReader]::Create($f.FullName, $readerSettings)
            try {
                while ($r.Read()) {
                    if ($r.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                        $id = $r.GetAttribute('id'); if ($id) { [void]$index.Add("$($r.LocalName)|$id") }
                    }
                }
            } catch { } finally { $r.Close() }
        }
    }
    $kinds = @{ NPCCharacter = @('NPCCharacter'); EquipmentRoster = @('EquipmentRoster'); PartyTemplate = @('MBPartyTemplate')
                BodyProperty = @('BodyProperty'); SkillSet = @('SkillSet'); Item = @('Item', 'CraftedItem'); Culture = @('Culture')
                Settlement = @('Settlement'); Kingdom = @('Kingdom'); Faction = @('Faction'); Hero = @('Hero') }
    $missing = @{}
    foreach ($f in Get-ChildItem $data -Filter *.xml) {
        $doc = Read-XmlFile $f.FullName
        foreach ($attr in $doc.SelectNodes('//@*')) {
            if ($attr.Value -match '^(NPCCharacter|EquipmentRoster|PartyTemplate|BodyProperty|SkillSet|Item|Culture|Settlement|Kingdom|Faction|Hero)\.(.+)$') {
                $kind = $Matches[1]; $ref = $Matches[2]
                if (-not ($kinds[$kind] | Where-Object { $index.Contains("$_|$ref") })) { $missing["$($f.Name): $kind.$ref"] = $true }
            }
        }
        foreach ($set in $doc.SelectNodes('//EquipmentSet[@id]')) {
            if (-not $index.Contains("EquipmentRoster|$($set.GetAttribute('id'))")) { $missing["$($f.Name): EquipmentSet $($set.GetAttribute('id'))"] = $true }
        }
    }
    $missing.Keys | Sort-Object
}

# ---------------------------------------------------------------------------------
Invoke-Check '8. Culture is complete' {
    $cu = (Read-XmlFile (Join-Path $data 'vlach_generated_culture.xml')).SelectSingleNode("/SPCultures/Culture[@id='vlach']")
    if (-not $cu) { 'culture vlach missing'; return }
    if ($cu.GetAttribute('is_main_culture') -ne 'true') { 'not a main (playable) culture' }

    # Feats must be real: the set used by AD1259 and vanilla cultures.
    $knownFeats = @{}
    foreach ($f in @(Get-ChildItem (Join-Path $adData 'spcultures') -Filter *.xml) + @(Get-ChildItem (Join-Path $GameDir 'Modules\SandBoxCore\ModuleData') -Filter 'spcultures*.xml')) {
        foreach ($x in (Read-XmlFile $f.FullName).SelectNodes('//cultural_feats/feat')) { $knownFeats[$x.GetAttribute('id')] = $true }
    }
    $feats = @($cu.SelectNodes('cultural_feats/feat') | ForEach-Object { $_.GetAttribute('id') })
    if ($feats.Count -ne 3) { "expected 3 feats, found $($feats.Count)" }
    foreach ($f in $feats) { if (-not $knownFeats.ContainsKey($f)) { "unknown feat $f" } }

    foreach ($list in 'male_names', 'female_names', 'clan_names') { if ($cu.SelectNodes("$list/name").Count -lt 5) { "$list is too short" } }

    # Every Bulgarian roster the game may look up by culture id or tag has a Vlach twin.
    $mine = @{}; foreach ($r in (Read-XmlFile (Join-Path $data 'vlach_generated_equipment.xml')).SelectNodes('/EquipmentRosters/EquipmentRoster')) { $mine[$r.GetAttribute('id')] = $r }
    foreach ($rel in $cfg.EquipmentSources) {
        foreach ($r in (Read-XmlFile (Join-Path $adData $rel)).SelectNodes('/EquipmentRosters/EquipmentRoster')) {
            $id = $r.GetAttribute('id')
            if ($id -notmatch 'bulgaria' -or $id -match $cfg.EquipmentIdExcludePattern) { continue }
            $twin = $id -replace 'bulgaria', 'vlach'
            if (-not $mine.ContainsKey($twin)) { "no Vlach twin for $id"; continue }
            if ($r.HasAttribute('culture') -and $mine[$twin].GetAttribute('culture') -ne 'Culture.vlach') { "$twin is not tagged Culture.vlach" }
            $fb = ($r.SelectNodes('Flags') | ForEach-Object { $_.OuterXml }) -join ''
            $fm = ($mine[$twin].SelectNodes('Flags') | ForEach-Object { $_.OuterXml }) -join ''
            if ($fb -ne $fm) { "$twin flags differ from $id" }
        }
    }
    foreach ($needed in 'player_char_creation_show_vlach', 'player_char_creation_vlach_retainer_m', 'mother_char_creation_none_vlach',
                        'father_char_creation_farmer_vlach', 'comingofage_kid_vlach_cutscene_template', 'vlach_bat_template_medium',
                        'vlach_civ_template_default', 'child_education_equipments_stage_1_page_0_branch_default_vlach') {
        if (-not $mine.ContainsKey($needed)) { "missing roster $needed" }
    }

    # Basic troops must be flagged as such.
    $troops = @{}; foreach ($t in (Read-XmlFile (Join-Path $data 'vlach_generated_troops.xml')).SelectNodes('/NPCCharacters/NPCCharacter')) { $troops[$t.GetAttribute('id')] = $t }
    foreach ($a in 'basic_troop', 'elite_basic_troop') {
        $id = $cu.GetAttribute($a) -replace '^NPCCharacter\.', ''
        if (-not $troops.ContainsKey($id)) { "$a $id is not a Vlach troop" } elseif ($troops[$id].GetAttribute('is_basic_troop') -ne 'true') { "$a $id lacks is_basic_troop" }
    }

    # Only glyphs known to be used by AD1259 texts (no comma-below s/t).
    foreach ($f in Get-ChildItem $data -Filter *.xml) {
        $text = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
        if ($text -match '[\u0218-\u021B]') { "$($f.Name) contains s/t with comma below, which the game fonts may lack" }
    }
}

# ---------------------------------------------------------------------------------
Invoke-Check '9. Troop tree is sane' {
    $troops = @{}; foreach ($t in (Read-XmlFile (Join-Path $data 'vlach_generated_troops.xml')).SelectNodes('/NPCCharacters/NPCCharacter')) { $troops[$t.GetAttribute('id')] = $t }
    $rosters = @{}
    foreach ($f in Get-ChildItem (Join-Path $adData 'trooptree_equipment_sets') -Filter *.xml) {
        foreach ($r in (Read-XmlFile $f.FullName).SelectNodes('/EquipmentRosters/EquipmentRoster')) { $rosters[$r.GetAttribute('id')] = $r }
    }
    $reached = @{}
    $queue = New-Object System.Collections.Queue
    foreach ($root in 'vlach_levy', 'vlach_noble_youth') { $queue.Enqueue($root); $reached[$root] = $true }
    while ($queue.Count -gt 0) {
        $id = $queue.Dequeue(); $t = $troops[$id]
        if (-not $t) { "upgrade target $id is not defined"; continue }
        if ($t.GetAttribute('culture') -ne 'Culture.vlach') { "$id is not Vlach culture" }
        foreach ($u in $t.SelectNodes('upgrade_targets/upgrade_target')) {
            $uid = $u.GetAttribute('id') -replace '^NPCCharacter\.', ''
            if ($troops.ContainsKey($uid) -and [int]$troops[$uid].GetAttribute('level') -le [int]$t.GetAttribute('level')) { "$id -> $uid does not raise the level" }
            if (-not $reached.ContainsKey($uid)) { $reached[$uid] = $true; $queue.Enqueue($uid) }
        }
        if ($t.GetAttribute('default_group') -match 'Cavalry|HorseArcher') {
            $bat = $t.SelectSingleNode('Equipments/EquipmentSet[not(@equipmentType)]').GetAttribute('id')
            $r = $rosters[$bat]
            if (-not $r) { "$id battle roster $bat not found" }
            else { foreach ($set in $r.SelectNodes('EquipmentSet')) { if (-not $set.SelectSingleNode("Equipment[@slot='Horse']")) { "$id is mounted but a set of $bat has no horse" } } }
        }
    }
    foreach ($id in $troops.Keys) { if (-not $reached.ContainsKey($id)) { "$id is not reachable from the basic or noble root" } }
    if ($troops.Count -ne @($cfg.Troops).Count) { "expected $(@($cfg.Troops).Count) troops, found $($troops.Count)" }
}

# ---------------------------------------------------------------------------------
Invoke-Check '10. DLL registers the culture inside the real AD1259.dll' {
    $probe = Join-Path ([IO.Path]::GetTempPath()) ('ad1259vlach_probe_' + [guid]::NewGuid().ToString('N') + '.ps1')
    @'
param($GameBin, $Ad1259Dll, $VlachDll)
$ErrorActionPreference = 'Stop'
$dirs = @($GameBin, (Split-Path $Ad1259Dll), (Split-Path $VlachDll))
[AppDomain]::CurrentDomain.add_AssemblyResolve({ param($s, $e)
    $n = ($e.Name -split ',')[0]
    foreach ($d in $dirs) { $p = Join-Path $d "$n.dll"; if (Test-Path $p) { return [Reflection.Assembly]::LoadFrom($p) } }
    return $null }.GetNewClosure())
$ad = [Reflection.Assembly]::LoadFrom($Ad1259Dll)
$vl = [Reflection.Assembly]::LoadFrom($VlachDll)
$register = $vl.GetType('AD1259Vlach.CultureRegistration').GetMethod('Register', [Type[]]@([Reflection.Assembly], [string]))
$r1 = $register.Invoke($null, @($ad, 'vlach')); "R1|$($r1.Success)|$($r1.Message)"
$defs = $ad.GetType('AD1259.Patches.CustomCultureDefinitions')
foreach ($f in 'AllCultureIds', 'CulturesWithOwnEquipmentsIds', 'EmpireCultureIds', 'AseraiCultureIds', 'BattaniaCultureIds', 'KhuzaitCultureIds', 'SturgiaCultureIds', 'VlandiaCultureIds') {
    "SET|$f|" + $defs.GetField($f, [Reflection.BindingFlags]'Static,Public,NonPublic').GetValue($null).Contains('vlach')
}
[object[]]$callArgs = @('vlach', $null)
$ok = $ad.GetType('AD1259.Patches.CultureMapUtil').GetMethod('TryGetBaseCulture').Invoke($null, $callArgs)
"BASE|$ok|$($callArgs[1])"
$r2 = $register.Invoke($null, @($ad, 'vlach')); "R2|$($r2.Success)|$($r2.Message)"
"SUB|" + $vl.GetType('AD1259Vlach.SubModule').BaseType.FullName
# Culture art: copy a style on a real Gauntlet brush the way AD1259's brush file defines it.
try {
    [void][Reflection.Assembly]::LoadFrom((Join-Path $GameBin 'TaleWorlds.GauntletUI.dll'))
    $brush = New-Object TaleWorlds.GauntletUI.Brush
    $src = New-Object TaleWorlds.GauntletUI.Style (,[TaleWorlds.GauntletUI.BrushLayer[]]@($brush.Layers))
    $src.DefaultStyle = $brush.DefaultStyle
    $src.Name = 'bulgaria'
    $src.GetLayer('Default').AlphaFactor = 0.25
    $brush.AddStyle($src)
    [object[]]$copyArgs = @($brush.PSObject.BaseObject, 'bulgaria', 'vlach')
    $copy = $vl.GetType('AD1259Vlach.CultureArtStyles').GetMethod('CopyStyle').Invoke($null, $copyArgs)
    "ART|$($copy.Name)|$($brush.GetStyle('vlach').GetLayer('Default').AlphaFactor)|$($brush.GetStyle('bulgaria').Name)"
} catch { $e = $_.Exception; while ($e.InnerException) { $e = $e.InnerException }; "ART|ERROR|$($e.GetType().Name): $($e.Message -replace '\|', '/')|" }
# Culture-card sprite: aliases in a real SpriteData, found by the same lookup the widget uses.
try {
    [void][Reflection.Assembly]::LoadFrom((Join-Path $GameBin 'TaleWorlds.TwoDimension.dll'))
    $data = New-Object TaleWorlds.TwoDimension.SpriteData 'probe'
    $sprites = @{}
    foreach ($suffix in '', '_1', '_2', '_3', '_4') {
        $sprites[$suffix] = [Runtime.Serialization.FormatterServices]::GetUninitializedObject([TaleWorlds.TwoDimension.SpriteGeneric])
        $data.Sprites['CharacterCreation\Culture\bulgaria' + $suffix] = $sprites[$suffix]
    }
    $aliases = $vl.GetType('AD1259Vlach.CultureArtStyles').GetMethod('AddSpriteAliases')
    $problems = New-Object 'System.Collections.Generic.List[string]'
    [object[]]$aliasArgs = @($data.PSObject.BaseObject, 'bulgaria', 'vlach', $problems.PSObject.BaseObject)
    $first = $aliases.Invoke($null, $aliasArgs)
    $second = $aliases.Invoke($null, $aliasArgs)
    $same = 0; foreach ($suffix in $sprites.Keys) { if ($data.SpriteExists('CharacterCreation\Culture\vlach' + $suffix) -and [object]::ReferenceEquals($data.GetSprite('CharacterCreation\Culture\vlach' + $suffix), $sprites[$suffix])) { $same++ } }
    "SPRITE|$first|$second|$same|$($problems.Count)"
} catch { $e = $_.Exception; while ($e.InnerException) { $e = $e.InnerException }; "SPRITE|ERROR|$($e.GetType().Name): $($e.Message -replace '\|', '/')|||" }
'@ | Set-Content -Path $probe -Encoding UTF8
    try {
        $lines = & powershell -NoProfile -ExecutionPolicy Bypass -File $probe -GameBin $gameBin `
            -Ad1259Dll (Join-Path $adDir 'bin\Win64_Shipping_Client\AD1259.dll') `
            -VlachDll (Join-Path $ModuleDir 'bin\Win64_Shipping_Client\AD1259.Vlach.dll') 2>&1
        $map = @{}; foreach ($l in $lines) { $parts = "$l".Split('|'); if ($parts.Count -ge 2) { $map[$parts[0] + '|' + $(if ($parts[0] -eq 'SET') { $parts[1] } else { '' })] = $parts } }
        if (-not $map.ContainsKey('R1|')) { "probe did not run: $($lines -join ' / ')"; return }
        if ($map['R1|'][1] -ne 'True') { "first registration failed: $($map['R1|'][2])" }
        foreach ($f in 'AllCultureIds', 'CulturesWithOwnEquipmentsIds', 'EmpireCultureIds') { if ($map["SET|$f"][2] -ne 'True') { "vlach missing from $f" } }
        foreach ($f in 'AseraiCultureIds', 'BattaniaCultureIds', 'KhuzaitCultureIds', 'SturgiaCultureIds', 'VlandiaCultureIds') { if ($map["SET|$f"][2] -ne 'False') { "vlach wrongly added to $f" } }
        if ($map['BASE|'][1] -ne 'True' -or $map['BASE|'][2] -ne 'empire') { "AD1259 maps vlach to '$($map['BASE|'][2])', expected 'empire'" }
        if ($map['R2|'][1] -ne 'True' -or $map['R2|'][2] -notmatch 'already registered') { "second registration not idempotent: $($map['R2|'][2])" }
        if ($map['SUB|'][1] -ne 'TaleWorlds.MountAndBlade.MBSubModuleBase') { "SubModule derives from $($map['SUB|'][1])" }
        if (-not $map.ContainsKey('ART|')) { 'culture-art probe produced no output' }
        elseif ($map['ART|'][1] -ne 'vlach' -or $map['ART|'][2] -ne '0.25' -or $map['ART|'][3] -ne 'bulgaria') { "culture-art style copy failed: $($map['ART|'][1..3] -join ' | ')" }
        if (-not $map.ContainsKey('SPRITE|')) { 'culture-sprite probe produced no output' }
        elseif (($map['SPRITE|'][1..4] -join ',') -ne '5,0,5,0') { "culture-sprite aliases wrong (added, re-added, resolved, problems): $($map['SPRITE|'][1..4] -join ' | ')" }
        # The aliases need the template culture's sprites to exist in AD1259's sprite data.
        $spriteXml = Join-Path $adDir 'GUI\AD1259SpriteData.xml'
        if (-not (Test-Path $spriteXml)) { "AD1259 sprite data not found: $spriteXml" }
        else {
            $names = @{}; foreach ($n in (Read-XmlFile $spriteXml).SelectNodes('//*[SpritePartName]/Name')) { $names[$n.InnerText] = $true }
            foreach ($suffix in '', '_1', '_2', '_3', '_4') {
                $name = 'CharacterCreation\Culture\' + $cfg.TemplateCulture + $suffix
                if (-not $names.ContainsKey($name)) { "AD1259 has no sprite '$name' to alias" }
            }
        }
    } finally { Remove-Item $probe -ErrorAction SilentlyContinue }
}

# ---------------------------------------------------------------------------------
Invoke-Check '11. Sources compile with the .NET Framework compiler (C# 5 fallback)' {
    $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    if (-not (Test-Path $csc)) { return }   # nothing to verify on this machine
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('ad1259vlach_fw_' + [guid]::NewGuid().ToString('N') + '.dll')
    $refs = 'TaleWorlds.MountAndBlade', 'TaleWorlds.Library', 'TaleWorlds.Core', 'TaleWorlds.Engine', 'TaleWorlds.Engine.GauntletUI',
            'TaleWorlds.GauntletUI', 'TaleWorlds.TwoDimension', 'TaleWorlds.ObjectSystem', 'TaleWorlds.Localization', 'TaleWorlds.DotNet', 'TaleWorlds.InputSystem' |
            ForEach-Object { "/reference:$(Join-Path $gameBin "$_.dll")" }
    $refs += "/reference:$(Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\netstandard.dll')"
    $src = Get-ChildItem (Join-Path $repo 'src\AD1259.Vlach') -Recurse -Filter *.cs | Select-Object -ExpandProperty FullName
    $output = & $csc /nologo /target:library /warnaserror+ "/out:$tmp" @refs @src 2>&1
    if ($LASTEXITCODE -ne 0) { "framework csc failed: $($output -join ' / ')" }
    Remove-Item $tmp -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:failed -gt 0) { Write-Host "$script:failed check(s) failed." -ForegroundColor Red; exit 1 }
Write-Host 'All checks passed.' -ForegroundColor Green
exit 0
