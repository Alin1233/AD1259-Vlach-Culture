# Content reference

Everything the submod adds or changes. Source of truth: `tools/vlach.config.psd1` (design),
`Module/ModuleData/*.xslt` (patches) and the generated files.

## The Vlach culture (`vlach`)

| Property | Value |
|---|---|
| Name | Vlach |
| Playable | yes (`is_main_culture="true"`, registered with AD1259's character creation) |
| Colours | `#830808` dark red / `#F4CA14` gold (the AD1259 Vlach clan banner) |
| Culture banner | banner of the clan *Vlachs of Muntenia and Oltenia* |
| Start position | Giurgiu (747, 1011) |
| Backstory group | Empire-style narrative (same as Bulgaria in AD1259) |
| Character-creation art | Bulgaria's four parallax layers |
| Parents' names | Radu and Ana |
| Shared with Bulgaria | townsfolk, militia, villagers, caravans, tournament teams, mercenaries, clan banner icons, default policies |

### Bonuses

| Bonus | Feat id | Flavour |
|---|---|---|
| Faster party movement in forests | `battanian_forest_speed` | Carpathian forests |
| Cheaper mounted recruits | `khuzait_cheaper_recruits_mounted` | Vlach light horse |
| More animal production in villages | `khuzait_increased_animal_production` | Transhumant shepherds |

Only existing feat ids can be used; the exact percentages are those of the base game.

### Names

- **Male (40):** Basarab, Litovoi, Seneslau, Bărbat, Farcaş, Ioan, Mircea, Radu, Vlad, Dan,
  Mihail, Neagu, Stanciu, Dragoş, Bogdan, Iuga, Costea, Stefan, Petru, Roman, Alexandru, Iancu,
  Mihnea, Laiotă, Vlaicu, Negru, Stoica, Oprea, Dragomir, Stan, Dumitru, Andrei, Toma, Lupu,
  Ursu, Coman, Balc, Drag, Tihomir, Nan
- **Female (32):** Ana, Maria, Elena, Ioana, Despina, Stana, Rada, Neaga, Calea, Marina,
  Smaranda, Domnica, Ilinca, Velica, Anca, Bălaşa, Voica, Stanca, Caplea, Anastasia, Irina,
  Teodora, Margareta, Florica, Dobra, Neacşa, Floarea, Eufrosina, Vişa, Sora, Muşa, Zamfira
- **Clans (8):** Basarab, Dăneşti, Drăculeşti, Muşatini, Craioveşti, Bogdăneşti, Lupeşti, Bărbăteşti

Letters are limited to those AD1259's own texts already use (ă â î ş); ș/ț (comma below) are
avoided because the game fonts are not known to contain them. "Stefan" is written without
Ş for the same reason.

### Texts

`vlach_strings.xml`: culture description, adjectives, realm names (*Voivodeship of Wallachia*,
ruler *Voivode / Voivodess*), and how Vlach nobles introduce themselves.

## Troop tree

| Troop | Id | Level | Role | Upgrades to | Battle equipment (AD1259 roster) |
|---|---|---|---|---|---|
| Vlach Levy | `vlach_levy` | 6 | Infantry | Serf, Rider | `bulgaria_basic_root_bat` |
| Vlach Serf | `vlach_serf` | 11 | Infantry | Footman, Hunter | `bulgaria_basic_root2_bat` |
| Vlach Footman | `vlach_footman` | 16 | Infantry | Spearman | `bulgaria_basic_root20_bat` |
| Vlach Spearman | `vlach_spearman` | 21 | Infantry | Veteran Spearman, Maceman | `bulgaria_basic_root200_bat` |
| Vlach Veteran Spearman | `vlach_veteran_spearman` | 26 | Infantry | | `bulgaria_basic_root2000_bat` |
| Vlach Maceman | `vlach_maceman` | 26 | Infantry | | `bulgaria_basic_root2001_bat` |
| Vlach Hunter | `vlach_hunter` | 21 | Infantry* | Bowman | `bulgaria_basic_root21_bat` |
| Vlach Bowman | `vlach_bowman` | 26 | Infantry* | | `bulgaria_basic_root210_bat` |
| Vlach Rider | `vlach_rider` | 11 | Horse archer | Horse Archer | `cuman_rider_bat` |
| Vlach Horse Archer | `vlach_horse_archer` | 16 | Horse archer | Veteran Horse Archer | `bulgaria_elite_root1_bat` |
| Vlach Veteran Horse Archer | `vlach_veteran_horse_archer` | 21 | Horse archer | | `bulgaria_elite_root10_bat` |
| Vlach Boyar Son (noble root) | `vlach_noble_youth` | 16 | Infantry | Viteaz, Dismounted Viteaz | `bulgaria_elite_root_bat` |
| Vlach Viteaz | `vlach_viteaz` | 21 | Cavalry | Curtean | `bulgaria_elite_root0_bat` |
| Vlach Curtean | `vlach_curtean` | 26 | Cavalry | Boyar | `bulgaria_elite_root00_bat` |
| Vlach Boyar | `vlach_boyar` | 31 | Cavalry | | `bulgaria_elite_root000_bat` |
| Vlach Dismounted Viteaz | `vlach_dismounted_viteaz` | 26 | Infantry | | `bulgaria_elite_root2_bat` |

- Infantry and archers are AD1259's Vlach branch of the Bulgarian tree (skills and equipment
  unchanged). \*Hunter and Bowman keep AD1259's "Infantry" formation group.
- The light-cavalry line is new; the noble line re-uses the Bulgarian noble equipment with Vlach
  ranks (*viteaz* = warrior, *curtean* = court warrior, *boier* = boyar).
- Civilian equipment comes from the same AD1259 troops (the Rider uses the Vlach Serf's).

### Party templates (`vlach_party_templates.xml`)

| Template | Used for |
|---|---|
| `kingdom_hero_party_vlach_template` | starting / reinforcement troops of Vlach lords |
| `patrol_party_vlach_template_level_1..3` | patrols of Vlach towns |
| `rebels_vlach_template` | rebels raised in Vlach towns |
| `vassal_reward_troops_vlach` | troops granted by a Vlach ruler to a new vassal |

Villagers, caravans and militia use Bulgaria's templates.

## Map changes

### Settlements that become Vlach (23)

Owners are unchanged. Culture decides the notables (Vlach templates, Romanian names) and the
volunteers (Vlach troop tree).

| Settlement | Type | Owner (unchanged) |
|---|---|---|
| Bacău | town | Vlachs of Muntenia and Oltenia (Bulgaria) |
| Suceava, Huşi, Bârlad | villages of Bacău | same |
| Giurgiu | town | Vlachs of Muntenia and Oltenia (Bulgaria) |
| Colentina, Turnu | villages of Giurgiu | same |
| Piteşti | town | Bulgarian royal clan |
| Craiova, Corabla | villages of Piteşti | same |
| Bălţi | town | Bulgarian royal clan |
| Soroca | village of Bălţi | same (Lomachyntsi, a Ruthenian village, stays Halych) |
| Kellia (Chilia) | town | Bulgarian clan 2 |
| Oblucita, Palada | villages of Kellia | same |
| Mauricastro (Cetatea Albă) | town | Bulgarian royal clan |
| Orhei, Căuşeni | villages of Mauricastro | same |
| Hunyad (Hunedoara) | village of Soimos Castle | Hungary |
| Doboka (Dăbâca) | village of Kraszna Castle | Hungary |
| Kolozsvár (Cluj) | village of Gyulafehérvár | Hungary |
| Küküllővár (Cetatea de Baltă) | village of Gyulafehérvár | Hungary |
| Prázsmár (Prejmer) | village of Kronstadt Castle | Hungary |

The test suite checks that no Bulgarian-culture village of these six towns was left out.

### The Vlach clan and its nobles

`clan_bulgaria_3` *Vlachs of Muntenia and Oltenia* gets the Vlach culture and **stays in the
Kingdom of Bulgaria**. Its nobles:

| Id | Name | Change |
|---|---|---|
| `lord_bulgaria_3a` | Seneslau, Voivod of Muntenia (clan leader) | culture |
| `lord_bulgaria_3b` | Ioana | culture |
| `lord_bulgaria_3c` | **Ioan**, Kenez of South Oltenia (was "Johannes") | culture, name |
| `lord_bulgaria_3d` | Farcaş, Kenez of North Oltenia | culture |
| `lord_bulgaria_3e` | Litovoi, Voivod of North Oltenia | culture |
| `lord_bulgaria_3f` | **Eufrosina** (was "Eufrosynia") | culture, name |
| `lord_bulgaria_3g` | Bărbat, Voivod of North Oltenia | culture |
| `lord_bulgaria_3h` | Floarea | culture |

## Templates cloned from Bulgaria

Generated, retagged `Culture.vlach`, ids with `bulgaria` replaced by `vlach`:

- **200 equipment rosters**: character creation (all stages, parents, "show" outfits),
  coming-of-age and marriage cutscenes, lord / lady / ruler templates, child and teenager
  outfits, child-education outfits, wanderer/companion/gangster templates.
- **28 NPC templates**: 15 notables, 3 headmen, 4 lord templates (for lords generated in game
  and rebellions), 6 child-education templates.
