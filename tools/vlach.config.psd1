# =============================================================================
#  AD1259 - Vlach Culture : design configuration
# -----------------------------------------------------------------------------
#  Every design decision of the submod lives in this file. The generator
#  (tools/Generate-ModuleData.ps1) combines it with Bulgaria's data from an
#  installed copy of Anno Domini 1259 and writes the vlach_generated_*.xml
#  files into Module/ModuleData. The hand-written files (strings, party
#  templates, XSLT patches) reference the ids defined here.
#
#  Encoding: UTF-8. The generator reads this file as UTF-8 explicitly, so
#  Romanian letters (ă â î ş) are safe. Avoid ș/ț (comma below): none of
#  AD1259's own texts use them, so the game fonts are not known to have them.
# =============================================================================
@{
    # AD1259 version the generated data was taken from (checked by the generator).
    Ad1259Version = 'v1.4.6'

    # Culture that the Vlachs are modelled on. Its templates (notables, lord
    # templates, equipment rosters, character-creation art) are cloned.
    TemplateCulture = 'bulgaria'

    Culture = @{
        Id   = 'vlach'
        Name = '{=ad1259vlach_culture_name}Vlach'

        # Red and gold of the AD1259 Vlach clan banner (banner palette ids 145 / 143).
        Color  = '0xff830808'
        Color2 = '0xfff4ca14'

        # Where a new Vlach character starts on the campaign map (Giurgiu).
        StartX = '747'
        StartY = '1011'

        # Culture bonuses. Only feat ids that already exist in the game can be
        # used; these three are also used by other AD1259 cultures.
        Feats = @(
            'battanian_forest_speed'              # Carpathian forests: faster party movement in forests
            'khuzait_cheaper_recruits_mounted'    # Vlach light horse: cheaper mounted recruits
            'khuzait_increased_animal_production' # Transhumant shepherds: more animal production in villages
        )

        # Attributes that differ from the template culture. Everything not
        # listed (townsfolk, militia, caravans, villagers, meshes...) is shared
        # with Bulgaria on purpose: AD1259 itself models Bulgaria and the
        # Vlachs as one realm ("2 in 1").
        Attributes = @{
            elite_basic_troop                   = 'NPCCharacter.vlach_noble_youth'
            basic_troop                         = 'NPCCharacter.vlach_levy'
            default_party_template              = 'PartyTemplate.kingdom_hero_party_vlach_template'
            settlement_patrol_template_level_1  = 'PartyTemplate.patrol_party_vlach_template_level_1'
            settlement_patrol_template_level_2  = 'PartyTemplate.patrol_party_vlach_template_level_2'
            settlement_patrol_template_level_3  = 'PartyTemplate.patrol_party_vlach_template_level_3'
            rebels_party_template               = 'PartyTemplate.rebels_vlach_template'
            vassal_reward_party_template        = 'PartyTemplate.vassal_reward_troops_vlach'
            text                                = '{=ad1259vlach_culture_text}Unused in the game.'
            default_battle_equipment_roster     = 'EquipmentRoster.vlach_bat_template_medium'
            default_civilian_equipment_roster   = 'EquipmentRoster.vlach_civ_template_default'
            marriage_bride_equipment_roster     = 'EquipmentRoster.marriage_female_vlach_cutscene_template'
        }

        # The culture banner is the AD1259 Vlach clan banner (read from this clan).
        BannerFromClan = 'clan_bulgaria_3'

        MaleNames = @(
            'Basarab', 'Litovoi', 'Seneslau', 'Bărbat', 'Farcaş', 'Ioan', 'Mircea', 'Radu',
            'Vlad', 'Dan', 'Mihail', 'Neagu', 'Stanciu', 'Dragoş', 'Bogdan', 'Iuga',
            'Costea', 'Stefan', 'Petru', 'Roman', 'Alexandru', 'Iancu', 'Mihnea', 'Laiotă',
            'Vlaicu', 'Negru', 'Stoica', 'Oprea', 'Dragomir', 'Stan', 'Dumitru', 'Andrei',
            'Toma', 'Lupu', 'Ursu', 'Coman', 'Balc', 'Drag', 'Tihomir', 'Nan'
        )
        FemaleNames = @(
            'Ana', 'Maria', 'Elena', 'Ioana', 'Despina', 'Stana', 'Rada', 'Neaga',
            'Calea', 'Marina', 'Smaranda', 'Domnica', 'Ilinca', 'Velica', 'Anca', 'Bălaşa',
            'Voica', 'Stanca', 'Caplea', 'Anastasia', 'Irina', 'Teodora', 'Margareta', 'Florica',
            'Dobra', 'Neacşa', 'Floarea', 'Eufrosina', 'Vişa', 'Sora', 'Muşa', 'Zamfira'
        )
        ClanNames = @(
            'Basarab', 'Dăneşti', 'Drăculeşti', 'Muşatini', 'Craioveşti', 'Bogdăneşti',
            'Lupeşti', 'Bărbăteşti'
        )
    }

    # -------------------------------------------------------------------------
    # Troop tree.
    #   Source   : AD1259 troop whose skills/face/other attributes are copied.
    #   Level / Group / Battle / Civilian : override the source when given.
    #   Skills   : optional skill overrides.
    # Battle/Civilian are equipment roster ids (all exist in AD1259 1.4.6).
    # The Bulgarian tree keeps its own Vlach branch untouched.
    # -------------------------------------------------------------------------
    Face = 'BodyProperty.fighter_bulgaria'

    Troops = @(
        # --- Basic tree (village recruits) ---------------------------------
        @{ Id = 'vlach_levy';     Name = 'Vlach Levy';     Source = 'bulgaria_basic_root';   Basic = $true
           Upgrades = @('vlach_serf', 'vlach_rider') }

        # Infantry and archers: AD1259's own Vlach branch of the Bulgarian tree.
        @{ Id = 'vlach_serf';             Name = 'Vlach Serf';             Source = 'bulgaria_basic_root2'
           Upgrades = @('vlach_footman', 'vlach_hunter') }
        @{ Id = 'vlach_footman';          Name = 'Vlach Footman';          Source = 'bulgaria_basic_root20'
           Upgrades = @('vlach_spearman') }
        @{ Id = 'vlach_spearman';         Name = 'Vlach Spearman';         Source = 'bulgaria_basic_root200'
           Upgrades = @('vlach_veteran_spearman', 'vlach_maceman') }
        @{ Id = 'vlach_veteran_spearman'; Name = 'Vlach Veteran Spearman'; Source = 'bulgaria_basic_root2000' }
        @{ Id = 'vlach_maceman';          Name = 'Vlach Maceman';          Source = 'bulgaria_basic_root2001' }
        @{ Id = 'vlach_hunter';           Name = 'Vlach Hunter';           Source = 'bulgaria_basic_root21'
           Upgrades = @('vlach_bowman') }
        @{ Id = 'vlach_bowman';           Name = 'Vlach Bowman';           Source = 'bulgaria_basic_root210' }

        # Light cavalry (new): gives the "cheaper mounted recruits" bonus a purpose.
        @{ Id = 'vlach_rider'; Name = 'Vlach Rider'; Source = 'bulgaria_basic_root2'
           Level = '11'; Group = 'HorseArcher'
           Battle = 'cuman_rider_bat'; Civilian = 'bulgaria_basic_root2_civ'
           Skills = @{ Athletics = '50'; Riding = '80'; OneHanded = '50'; TwoHanded = '10'
                       Polearm = '40'; Bow = '60'; Crossbow = '5'; Throwing = '20' }
           Upgrades = @('vlach_horse_archer') }
        @{ Id = 'vlach_horse_archer'; Name = 'Vlach Horse Archer'; Source = 'cuman_rider'
           Level = '16'; Group = 'HorseArcher'
           Battle = 'bulgaria_elite_root1_bat'; Civilian = 'bulgaria_elite_root1_civ'
           Upgrades = @('vlach_veteran_horse_archer') }
        @{ Id = 'vlach_veteran_horse_archer'; Name = 'Vlach Veteran Horse Archer'; Source = 'bulgaria_elite_root1'
           Level = '21'; Group = 'HorseArcher'
           Battle = 'bulgaria_elite_root10_bat'; Civilian = 'bulgaria_elite_root10_civ' }

        # --- Noble tree (elite recruits): viteji -> curteni -> boyars -----------
        @{ Id = 'vlach_noble_youth'; Name = 'Vlach Boyar Son'; Source = 'bulgaria_elite_root'; Basic = $true
           Upgrades = @('vlach_viteaz', 'vlach_dismounted_viteaz') }
        @{ Id = 'vlach_viteaz';            Name = 'Vlach Viteaz';            Source = 'bulgaria_elite_root0'
           Upgrades = @('vlach_curtean') }
        @{ Id = 'vlach_curtean';           Name = 'Vlach Curtean';           Source = 'bulgaria_elite_root00'
           Upgrades = @('vlach_boyar') }
        @{ Id = 'vlach_boyar';             Name = 'Vlach Boyar';             Source = 'bulgaria_elite_root000' }
        @{ Id = 'vlach_dismounted_viteaz'; Name = 'Vlach Dismounted Viteaz'; Source = 'bulgaria_elite_root2' }
    )

    # -------------------------------------------------------------------------
    # Templates cloned from the template culture (id 'bulgaria' -> 'vlach').
    # -------------------------------------------------------------------------
    # NPC templates that the culture references (notables, headmen, lord
    # templates) and the child-education templates the game finds by culture id.
    CharacterSources = @(
        'spspecialcharacters\spspecialcharacters_bulgaria.xml'
        'education_character_templates\education_character_templates_bulgaria.xml'
    )
    # Only these NPC templates are cloned (regex on the id). Wanderers are not
    # cloned: they need hand-written backstories.
    CharacterIdPattern = '^(spc_notable_bulgaria_|spc_bulgaria_headman_|bulgaria_autogenerated_lord|child_education_templates_)'

    # Equipment rosters the game finds by culture id or by culture tag
    # (character creation, lords, ladies, rulers, children, education...).
    EquipmentSources = @(
        'sandbox_core_equipment_sets\sandboxcore_equipment_sets_bulgaria.xml'
        'sandbox_equipment_sets\sandbox_equipment_sets_bulgaria.xml'
        'education_equipment_templates\education_equipment_templates_bulgaria.xml'
    )
    # Rosters that are only referenced by explicit id from Bulgarian NPCs are
    # not needed (the cloned notables keep pointing at the Bulgarian ones).
    EquipmentIdExcludePattern = '^(spc_notab|npc_[a-z_]+_equipment_bulgaria$)'

    # -------------------------------------------------------------------------
    # Map changes (applied by the hand-written XSLT patches; listed here for
    # the test suite, which checks the patches against this list).
    # -------------------------------------------------------------------------
    VlachClan  = 'clan_bulgaria_3'
    VlachLords = @('lord_bulgaria_3a', 'lord_bulgaria_3b', 'lord_bulgaria_3c', 'lord_bulgaria_3d',
                   'lord_bulgaria_3e', 'lord_bulgaria_3f', 'lord_bulgaria_3g', 'lord_bulgaria_3h')
    RenamedLords = @{
        lord_bulgaria_3c = 'Ioan, Kenez of South Oltenia'   # was "Johannes" (Latin form in the 1247 Diploma)
        lord_bulgaria_3f = 'Eufrosina'                      # was "Eufrosynia"
    }
    VlachSettlements = @(
        # Towns north of the Danube held by Bulgaria
        'town_bacau', 'town_giurgiu', 'town_pitesti', 'town_balti', 'town_kellia', 'town_mauricastro'
        # Their Bulgarian-culture villages (Lomachyntsi, a Ruthenian village of Balti, stays Halych)
        'town_bacau_suceava', 'town_bacau_husi', 'town_bacau_barlad'
        'town_giurgiu_colentina', 'town_giurgiu_turnu'
        'town_pitesti_craiova', 'town_pitesti_corabla'
        'town_balti_soroca'
        'town_kellia_oblucita', 'town_kellia_palada'
        'town_mauricastro_orhei', 'town_mauricastro_causeni'
        # Transylvania proper (villages only; Hungary keeps every town and castle)
        'castle_soimos_hunyad', 'castle_kraszna_doboka', 'town_gyulafehervar_cluj',
        'town_gyulafehervar_kukullovar', 'castle_kronstadt_prazsmar'
    )
}
