# Design notes

How the submod works and why it is built this way. Facts below were checked against
AD1259 v1.4.6 and Bannerlord v1.4.8 (assemblies inspected by reflection, data parsed directly).

## Principles

1. **Never modify AD1259.** All changes are made from a separate module that loads after it.
   Uninstalling the submod restores AD1259 exactly.
2. **Data over code.** Culture, troops, texts, templates and map changes are module XML. The DLL
   only does what data cannot do.
3. **Patch, do not copy.** Changes to AD1259 objects (settlements, the clan, nobles) are
   XSLT patches that touch single attributes, not copies of AD1259 files.
4. **Generate what is mechanical.** The 228 culture-tagged templates are produced from Bulgaria's
   by a deterministic script, and the generated files are checked in and tested for being in
   sync with the config.
5. **Fail soft.** If AD1259 changes, the DLL reports the problem on the main menu and the
   rest of the game is unaffected.

## How Bannerlord loads module data

For each `XmlName id` (e.g. `Settlements`), the game walks the modules in load order and the
`XmlNode`s of each module in order. For every file it:

1. applies `<path>.xslt` from the same folder, **if it exists**, to the data merged so far
   (all earlier modules), and
2. merges `<path>.xml` into the result.

AD1259 itself relies on this: its `settlements.xslt` removes every vanilla `Settlement` before
its own `settlements.xml` adds the AD1259 map. Because the transform runs *before* the module's
own file, an `.xslt` needs a (here empty) `.xml` partner to be triggered at all. That is why
the submod ships `vlach_settlements.xml`, `vlach_clans.xml` and `vlach_lords.xml` with only a
root element. The test suite (check 2) fails if an `.xslt` has no declared partner.

Each patch is an identity transform plus templates for the attributes that change, for example:

```xml
<xsl:template match="Faction[@id='clan_bulgaria_3']/@culture">
    <xsl:attribute name="culture">Culture.vlach</xsl:attribute>
</xsl:template>
```

## Why so many templates are cloned

A culture is more than its `<Culture>` element. The game looks things up **by culture id** or
**by culture tag**, and a missing entry means a crash, an empty outfit or a skipped feature:

| Looked up by | Examples | Where it matters |
|---|---|---|
| id pattern `..._<culture>...` | `player_char_creation_vlach_retainer_m`, `mother_char_creation_farmer_vlach`, `player_char_creation_childhood_age_vlach_hunter_f`, `comingofage_kid_vlach_cutscene_template` | character creation, cutscenes |
| id pattern | `child_education_equipments_stage_1_page_0_branch_0_vlach`, `child_education_templates_stage_2_page_0_branch_0_vlach` | child education (Birth and Aging) |
| `culture` + `Flags` | `vlach_bat_template_*` (IsLordTemplate), `vlach_king_template_*` (IsKingdomRulerTemplate), `child_template_vlach_*` (IsChildEquipmentTemplate) | outfits of lords, ladies, rulers and children generated during the game |
| culture lists | `notable_templates`, `lord_templates`, `rebellion_hero_templates` | notables of Vlach settlements, new lords, rebels |
| text id `<string>.<culture>` | `str_culture_description.vlach`, `str_faction_ruler.vlach` | UI and dialogue |

`tools/Generate-ModuleData.ps1` clones every roster of Bulgaria's three culture-specific
equipment files whose id contains `bulgaria`, except two groups that are only referenced
explicitly by Bulgarian NPCs (`spc_notab*`, `npc_*_equipment_bulgaria`). It retags them
`Culture.vlach` and replaces `bulgaria` with `vlach` in the id. Check 8 verifies that every such
Bulgarian roster has a Vlach twin with identical `Flags`.

The cloned notables keep pointing at Bulgaria's equipment rosters, which keeps their outfits
identical. Three AD1259 notable templates reference rosters that do not exist
(`spc_notable_bulgaria_3`, `_3b`, and `_3c`, which is spelled `spc_notabble_bulgaria_3c` in
AD1259). The clones drop those dangling references (a comment marks the spot) and keep their
other, valid equipment sets.

## The DLL

`src/AD1259.Vlach` (under 300 lines including comments, no Harmony) does two things.

### 1. Registering the culture with AD1259's character creation

AD1259 does not read its playable cultures from data. `AD1259.Patches.CustomCultureDefinitions`
holds static `HashSet<string>` fields, and AD1259's own Harmony patches of
`CharacterCreationCampaignBehavior` consult them:

| Set | Effect of containing `vlach` |
|---|---|
| `AllCultureIds` | the culture is offered on the selection screen (`InitializeCharacterCreationCultures` prefix) |
| `CulturesWithOwnEquipmentsIds` | equipment ids such as `player_char_creation_vlach_...` are used as-is instead of being remapped to a vanilla culture |
| `EmpireCultureIds` | family, childhood, youth and adulthood options of the Empire narrative are shown (same group as Bulgaria) |

`CultureRegistration.Register` finds the loaded `AD1259` assembly, resolves all three fields
**before** changing any of them (no partial registration), and adds the id. It is idempotent
and uses only base-library types, so check 10 can run it against the real `AD1259.dll`
outside the game. It runs in `OnSubModuleLoad`, which is safe because `DependedModules` makes
AD1259 load first, and character creation reads the sets much later.

### 2. Character-creation art

AD1259's `GUI/Brushes/ui_CharacterCreation.xml` defines `Culture.Banner.Layer.1..4` with one
style per culture id. The culture screen switches these brushes to the style named after the
selected culture, so a culture without styles shows no picture. `CultureArtStyles.Apply`
copies the `bulgaria` style to a new `vlach` style on each brush (in
`OnBeforeInitialModuleScreenSetAsRoot`, after UI resources are loaded). The API it uses
(`UIResourceManager.BrushFactory`, `Brush.GetStyle/AddStyle`, `new Style(brush.Layers)`,
`Style.FillFrom`) was checked by reflection on the v1.4.8 assemblies.

### Failure behaviour

Problems are written to the rgl log with the prefix `[AD1259_Vlach]` and shown once on the
main menu in red. If AD1259's internals change, the only consequence is that *Vlach* is not
offered at character creation. The data (settlements, nobles, troops) still loads.

## Loyalty

Bannerlord's `DefaultSettlementLoyaltyModel` applies **-3 loyalty per day** ("Owner Culture")
when a town's culture differs from its owner clan's culture, and ±1 for the governor's culture
(read from the v1.4.8 assembly: `SettlementOwnerDifferentCultureLoyaltyEffect = -3`).

- Bacău and Giurgiu: owner clan and town are both Vlach, so there is no penalty.
- Villages have no loyalty, so the Transylvanian and other villages are unaffected.
- Piteşti, Bălţi, Kellia and Mauricastro: Vlach towns owned by Bulgarian-culture clans, so the
  penalty applies.

Three options were considered: (a) a Harmony patch treating Vlach and Bulgarian as compatible,
(b) the vanilla penalty, (c) keeping those four towns Bulgarian. **(b) was chosen.** To change
it later, a prefix on `DefaultSettlementLoyaltyModel.GetSettlementLoyaltyChangeDueToOwnerCulture`
could skip the penalty for the vlach/bulgaria pair. Alternatively, remove the four towns from
`vlach_settlements.xslt` and the config.

## Compatibility

- **AD1259 version.** Pinned to v1.4.6 (`DependentVersion`, generator check, DLL checks).
  After an AD1259 update, run `build.ps1 -Generate` and the tests. The tests compare the
  patches with the new data and report renamed or removed ids.
- **Other submods** that change the same settlements, `clan_bulgaria_3` or the
  `lord_bulgaria_3*` nobles: XSLT patches compose, so whichever loads later wins for the same
  attribute.
- **Translations.** New texts use localisation ids prefixed `ad1259vlach_`; the two renamed
  nobles get new ids, so translation mods show the English names for those two.
- **Saves.** The culture, troops and settlement cultures are part of the campaign. Start a new
  campaign; do not add or remove the module mid-campaign.

## What the tests cannot cover

`tests/Test-Module.ps1` checks data, patches, references and the DLL logic offline. It cannot
start a campaign. These must be confirmed in game:

- the culture list, art and backstory screens
- the starting equipment of a Vlach character
- Vlach notables in Bacău and Piteşti, and Vlach volunteers there
- the culture of the Vlach nobles in the encyclopedia
