# Changelog

## v1.0.1 (2026-11-10)

- Fixed: the Vlach culture showed placeholder art on the character-creation culture screen
  (copying Bulgaria's art styles threw a NullReferenceException at startup).
- Fixed: the Vlach card in the culture list showed the blank placeholder icon. The card looks
  up the sprite `CharacterCreation\Culture\vlach` by name; Bulgaria's sprites are now
  registered under the Vlach names at startup.
- Tests: check 10 now also copies a culture-art style on a real Gauntlet brush, checks the
  sprite aliases in a real SpriteData, and checks that AD1259 ships the sprites being aliased.

## v1.0.0 (2026-11-10)

First release, for Anno Domini 1259 v1.4.6 on Bannerlord v1.4.8.

- Playable Vlach culture: character creation, description, art, Empire-style backstory group.
- Bonuses: faster in forests, cheaper mounted recruits, more animal production in villages.
- Vlach troop tree: 16 troops (AD1259's Vlach infantry, new light cavalry, noble line).
- Romanian name lists (40 male, 32 female, 8 clans).
- 23 settlements take the Vlach culture (6 Bulgarian-held towns north of the Danube, their 12
  villages, 5 Transylvanian villages). Owners unchanged.
- Clan *Vlachs of Muntenia and Oltenia* and its 8 nobles become Vlach and stay in Bulgaria;
  Johannes → Ioan, Eufrosynia → Eufrosina.
- 200 equipment rosters and 28 NPC templates cloned from Bulgaria for the new culture.
