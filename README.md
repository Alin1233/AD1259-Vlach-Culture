# AD1259 - Vlach Culture

A submod for **[Anno Domini 1259 continued](https://www.nexusmods.com/mountandblade2bannerlord/mods/6723)**
(Mount & Blade II: Bannerlord) that adds a **playable Vlach culture** and gives the Romanian
lands of the AD1259 map Vlach notables, nobles and recruits.

Politics are untouched: the Vlach clan stays a vassal of the Kingdom of Bulgaria and every
settlement keeps its owner.

| | |
|---|---|
| Module id | `AD1259_Vlach` (folder `Modules\AD1259_Vlach`) |
| Version | v1.0.0 |
| Requires | Anno Domini 1259 **v1.4.6** and its required mods |
| Built and tested on | Bannerlord v1.4.8 |
| Save games | **New campaign required.** Do not add it to, or remove it from, an existing save. |

## Features

- **Playable at character creation.** "Vlach" appears in AD1259's culture list, with its own
  description, culture art (shared with Bulgaria), Romanian parents' names and the Bulgarian /
  Byzantine-style backstory options that AD1259 uses for Bulgaria.
- **Culture bonuses**
  - *Carpathian forests*: faster party movement in forests (`battanian_forest_speed`)
  - *Vlach light horse*: cheaper mounted recruits (`khuzait_cheaper_recruits_mounted`)
  - *Transhumant shepherds*: more animal production in villages (`khuzait_increased_animal_production`)
- **Vlach troop tree** (16 troops): AD1259's own Vlach infantry and archers, a new Vlach light
  cavalry line, and a noble line of *viteji*, *curteni* and *boyars*.
- **Romanian names**: 40 male, 32 female and 8 clan names for every Vlach character generated
  in game (notables, children, new lords, companions you create).
- **Vlach lands**: 23 settlements take the Vlach culture (Vlach notables and volunteers):
  - Bulgarian-held towns north of the Danube: Bacău, Giurgiu, Piteşti, Bălţi, Kellia (Chilia),
    Mauricastro (Cetatea Albă) and their 12 Bulgarian villages;
  - Transylvania proper (villages only, Hungary keeps them): Hunyad, Doboka, Kolozsvár,
    Küküllővár, Prázsmár.
- **Vlach nobles**: the eight nobles of the clan *Vlachs of Muntenia and Oltenia* (Seneslau,
  Litovoi, Farcaş, Bărbat, ...) become Vlach; "Johannes" and "Eufrosynia" take their Romanian
  forms Ioan and Eufrosina.

Full lists are in [docs/CONTENT.md](docs/CONTENT.md).

### Known trade-offs

- Piteşti, Bălţi, Kellia and Mauricastro are Vlach towns owned by Bulgaria's royal clan
  (Bulgarian culture), so they get Bannerlord's normal **"Owner Culture" loyalty penalty
  (-3/day)**. This was chosen on purpose over a code patch; see
  [docs/DESIGN.md](docs/DESIGN.md#loyalty).
- AD1259's Bulgarian troop tree still contains its own Vlach branch, so the encyclopedia lists
  "Vlach Serf", "Vlach Spearman", ... twice (one Bulgarian, one Vlach culture).
- There are no Vlach wanderers (companions) yet: they need hand-written backstories.
- The POC colour mod built into AD1259 has no Vlach-specific palette; it uses its defaults.

## Installation

### Players

1. Install Anno Domini 1259 v1.4.6 and its requirements as described on its Nexus page.
2. Copy the `AD1259_Vlach` folder into `...\Mount & Blade II Bannerlord\Modules\`.
3. Right-click `bin\Win64_Shipping_Client\AD1259.Vlach.dll` > Properties > *Unblock* (if shown).
4. In the launcher enable **AD1259 - Vlach Culture** and place it **directly after AD1259**.
5. Start a **new** sandbox campaign and pick *Vlach*.

Load order:

```
Harmony, UIExtenderEx, ButterLib, Mod Configuration Menu
Native, SandBox Core, Birth and Aging Options, CustomBattle, Sandbox, StoryMode
RBM, ExpandedArmouryBL, swadian armoury, Open Source Armory / Saddlery / Weaponry,
Templar Armor, Templar Equipment, Settlement Icons Redesign
AD1259
AD1259 - Vlach Culture      <- here
```

With Novus Launcher, use the preset **"AD1259 + Vlach"** (`NovusLauncher\Presets\AD1259_Vlach.xml`).
Keep the plain **"AD1259"** preset for campaigns started without the submod.

### Uninstalling

Disable the module in the launcher (or delete `Modules\AD1259_Vlach`). Campaigns started with
it need it to stay enabled.

## Troubleshooting

The module writes to Bannerlord's log (`C:\ProgramData\Mount and Blade II Bannerlord\logs\rgl_log_*.txt`)
with the prefix `[AD1259_Vlach]`. A healthy start shows:

```
[AD1259_Vlach] Registered culture 'vlach' with AD1259 (AllCultureIds, CulturesWithOwnEquipmentsIds, EmpireCultureIds).
[AD1259_Vlach] Added 4 character-creation art style(s) for 'vlach'.
```

If registration fails (usually a different AD1259 version), a red message appears on the main
menu and the culture is not offered at character creation; nothing else is affected.

## Building from source

Repository layout:

```
Module/                   exactly what is installed (SubModule.xml + ModuleData)
  ModuleData/vlach_generated_*.xml   generated, do not edit by hand
  ModuleData/vlach_*.xml / .xslt     hand-written
src/AD1259.Vlach/         C# entry point (culture registration + culture art)
tools/vlach.config.psd1   every design decision (bonuses, names, troops, settlements)
tools/Generate-ModuleData.ps1        builds the generated files from AD1259's data
tests/Test-Module.ps1     offline test suite
build.ps1                 compile + assemble + test (+ install)
docs/                     design notes and content reference
```

Requirements: Windows, Windows PowerShell 5.1, .NET Framework 4.7.2+, Bannerlord with AD1259
installed. A Roslyn `csc.exe` (Visual Studio / Build Tools) is used if present, otherwise the
.NET Framework `csc.exe` that ships with Windows (the code is kept at C# 5 for that reason).

```powershell
# after changing tools\vlach.config.psd1 (or updating AD1259):
powershell -ExecutionPolicy Bypass -File build.ps1 -Generate

# build + test:
powershell -ExecutionPolicy Bypass -File build.ps1

# build + test + install into the game:
powershell -ExecutionPolicy Bypass -File build.ps1 -Install

# custom game folder:
powershell -ExecutionPolicy Bypass -File build.ps1 -GameDir "D:\Games\Mount & Blade II Bannerlord" -Install
```

`build.ps1 -Install` refuses to install if any test fails and only ever replaces a folder whose
`SubModule.xml` has the id `AD1259_Vlach`.

## Credits

- **Anno Domini 1259 continued**: Bubu, d&h, Almo and the original AD1259 team (Yannis and
  contributors). AD1259's files are open source with credit; this submod builds on its data and
  its Vlach troops, clan and nobles.
- Equipment referenced by the Vlach troops comes from the mods AD1259 requires: Swadian Armoury
  (ADamnSexyName), Open Source Armory / Saddlery / Weaponry, Calradic / Expanded Bannerlord
  Armoury, Templar Armor / Equipment. No assets are redistributed; only their ids are used.
- Historical names follow the 1247 Diploma of the Knights Hospitaller (Seneslau, Litovoi,
  Ioan, Farcaş) and the later Wallachian and Moldavian dynasties.
