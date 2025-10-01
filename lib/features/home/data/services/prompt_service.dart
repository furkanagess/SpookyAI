import '../models/prompt_category.dart';

class PromptService {
  static const List<PromptCategory> _promptCategories = [
    PromptCategory(
      id: 'halloween',
      name: 'Halloween Magic',
      icon: '🎃',
      description: 'Spooky and scary Halloween-themed prompts',
      prompts: [
        PromptItem(
          id: 'spooky_forest',
          title: 'Spooky Forest',
          prompt:
              'A dark, misty forest at night with twisted trees, glowing eyes in the shadows, and mysterious fog swirling between ancient oaks, cinematic horror lighting',
          isPopular: true,
          tags: ['forest', 'horror', 'atmosphere'],
        ),
        PromptItem(
          id: 'haunted_house',
          title: 'Haunted Mansion',
          prompt:
              'A grand Victorian mansion with broken windows, overgrown vines, lightning illuminating the facade, gothic architecture with eerie shadows',
          isPopular: true,
          tags: ['house', 'gothic', 'lightning'],
        ),
        PromptItem(
          id: 'ghost_portrait',
          title: 'Ghost Portrait',
          prompt:
              'A translucent ghost figure with flowing ethereal clothing, glowing eyes, surrounded by floating orbs of light, dramatic dark background',
          isPopular: true,
          tags: ['ghost', 'portrait', 'ethereal'],
        ),
        PromptItem(
          id: 'zombie_apocalypse',
          title: 'Zombie Apocalypse',
          prompt:
              'Post-apocalyptic cityscape with abandoned buildings, dark clouds, zombies in the shadows, dramatic lighting with orange sky',
          tags: ['zombie', 'apocalypse', 'city'],
        ),
        PromptItem(
          id: 'witch_ritual',
          title: 'Witch Ritual',
          prompt:
              'A mysterious witch performing a ritual in a candlelit room, floating objects, magical symbols in the air, dark mystical atmosphere',
          tags: ['witch', 'ritual', 'magic'],
        ),
        PromptItem(
          id: 'cursed_pumpkin_patch',
          title: 'Cursed Pumpkin Patch',
          prompt:
              'A field of glowing jack-o-lanterns with sinister faces, each carved with different expressions of horror, mist swirling between them under a blood-red moon',
          isPopular: true,
          tags: ['pumpkin', 'cursed', 'moon'],
        ),
        PromptItem(
          id: 'haunted_graveyard',
          title: 'Haunted Graveyard',
          prompt:
              'An ancient cemetery with crumbling tombstones, ghostly figures emerging from graves, skeletal hands reaching from the earth, ethereal blue mist',
          isPopular: true,
          tags: ['graveyard', 'ghosts', 'skeletons'],
        ),
        PromptItem(
          id: 'spider_queen_lair',
          title: 'Spider Queen\'s Lair',
          prompt:
              'A massive spider web spanning an entire room, giant spider with glowing red eyes in the center, victims wrapped in silk cocoons, dark corners',
          tags: ['spider', 'web', 'lair'],
        ),
        PromptItem(
          id: 'voodoo_doll_workshop',
          title: 'Voodoo Doll Workshop',
          prompt:
              'A dark workshop filled with voodoo dolls hanging from strings, pins scattered on a wooden table, candles flickering, mysterious shadows',
          tags: ['voodoo', 'doll', 'workshop'],
        ),
        PromptItem(
          id: 'crystal_ball_vision',
          title: 'Crystal Ball Vision',
          prompt:
              'A fortune teller gazing into a crystal ball showing swirling images of doom, tarot cards scattered on a velvet cloth, incense smoke',
          tags: ['crystal', 'fortune', 'vision'],
        ),
      ],
    ),
    PromptCategory(
      id: 'fantasy',
      name: 'Fantasy World',
      icon: '🧙‍♀️',
      description: 'Magical and mystical fantasy scenarios',
      prompts: [
        PromptItem(
          id: 'dragon_lair',
          title: 'Dragon\'s Lair',
          prompt:
              'A massive dragon sleeping on a pile of golden treasures in a cave, glowing gems and magical artifacts scattered around, epic fantasy lighting',
          isPopular: true,
          tags: ['dragon', 'treasure', 'cave'],
        ),
        PromptItem(
          id: 'magical_castle',
          title: 'Floating Castle',
          prompt:
              'A magnificent castle floating in the clouds, waterfalls cascading from its edges, rainbow bridges connecting to other floating islands',
          isPopular: true,
          tags: ['castle', 'floating', 'clouds'],
        ),
        PromptItem(
          id: 'wizard_tower',
          title: 'Wizard\'s Tower',
          prompt:
              'A tall stone tower with glowing windows, magical energy swirling around it, books and potions floating in the air',
          tags: ['wizard', 'tower', 'magic'],
        ),
        PromptItem(
          id: 'enchanted_forest',
          title: 'Enchanted Forest',
          prompt:
              'A mystical forest with glowing mushrooms, fairy lights, ancient trees with faces, magical creatures hidden in the shadows',
          tags: ['forest', 'fairy', 'enchanted'],
        ),
        PromptItem(
          id: 'phoenix_rebirth',
          title: 'Phoenix Rebirth',
          prompt:
              'A magnificent phoenix rising from flames, golden and crimson feathers glowing with inner fire, ash and embers swirling around, rebirth symbolism',
          isPopular: true,
          tags: ['phoenix', 'fire', 'rebirth'],
        ),
        PromptItem(
          id: 'unicorn_meadow',
          title: 'Unicorn Meadow',
          prompt:
              'A magical meadow with a pure white unicorn, rainbow-colored flowers blooming everywhere, sparkling dewdrops, ethereal morning light',
          tags: ['unicorn', 'meadow', 'rainbow'],
        ),
        PromptItem(
          id: 'ancient_dragon_temple',
          title: 'Ancient Dragon Temple',
          prompt:
              'A massive stone temple dedicated to dragons, carved dragon statues, ancient runes glowing with magical energy, mystical atmosphere',
          isPopular: true,
          tags: ['temple', 'dragon', 'ancient'],
        ),
        PromptItem(
          id: 'mermaid_cove',
          title: 'Mermaid Cove',
          prompt:
              'A hidden underwater cove with mermaids swimming, bioluminescent coral, treasure chests, sunbeams filtering through crystal-clear water',
          tags: ['mermaid', 'underwater', 'cove'],
        ),
        PromptItem(
          id: 'wizard_duel',
          title: 'Epic Wizard Duel',
          prompt:
              'Two powerful wizards engaged in magical combat, energy bolts colliding, spell circles glowing on the ground, dramatic magical effects',
          tags: ['wizard', 'duel', 'magic'],
        ),
      ],
    ),
    PromptCategory(
      id: 'horror',
      name: 'Horror & Thriller',
      icon: '👻',
      description: 'Chilling horror and thriller prompts',
      prompts: [
        PromptItem(
          id: 'creepy_clown',
          title: 'Creepy Clown',
          prompt:
              'A sinister clown with painted face in shadows, glowing red eyes, holding a balloon in a dark alley, psychological horror atmosphere',
          isPopular: true,
          tags: ['clown', 'horror', 'psychological'],
        ),
        PromptItem(
          id: 'abandoned_asylum',
          title: 'Abandoned Asylum',
          prompt:
              'A dilapidated mental asylum with broken windows, peeling paint, wheelchair in the hallway, eerie silence, horror movie atmosphere',
          isPopular: true,
          tags: ['asylum', 'abandoned', 'horror'],
        ),
        PromptItem(
          id: 'slasher_mask',
          title: 'Slasher Villain',
          prompt:
              'A masked killer standing in the shadows holding a weapon, dramatic horror lighting, blood splatters, intense atmosphere',
          tags: ['slasher', 'mask', 'weapon'],
        ),
        PromptItem(
          id: 'demon_portrait',
          title: 'Demon Portrait',
          prompt:
              'A terrifying demon with horns and glowing eyes, dark energy surrounding it, infernal background with flames',
          tags: ['demon', 'portrait', 'infernal'],
        ),
        PromptItem(
          id: 'cursed_mirror',
          title: 'Cursed Mirror',
          prompt:
              'An antique mirror reflecting a twisted version of reality, ghostly hands reaching through the glass, cracked frame with blood stains',
          isPopular: true,
          tags: ['mirror', 'cursed', 'ghost'],
        ),
        PromptItem(
          id: 'shadow_figure',
          title: 'Shadow Figure',
          prompt:
              'A tall, featureless shadow figure standing in a dark hallway, no face but glowing red eyes, reaching out with elongated fingers',
          tags: ['shadow', 'figure', 'hallway'],
        ),
        PromptItem(
          id: 'haunted_doll',
          title: 'Haunted Doll',
          prompt:
              'A porcelain doll with cracked face and empty eye sockets, sitting in a rocking chair, blood tears on its cheeks, creepy atmosphere',
          isPopular: true,
          tags: ['doll', 'haunted', 'porcelain'],
        ),
        PromptItem(
          id: 'basement_monster',
          title: 'Basement Monster',
          prompt:
              'A creature lurking in a dark basement, glowing eyes in the shadows, chains hanging from the ceiling, blood splatters on concrete floor',
          tags: ['basement', 'monster', 'chains'],
        ),
        PromptItem(
          id: 'psycho_killer',
          title: 'Psycho Killer',
          prompt:
              'A masked killer standing in the rain holding a bloody weapon, dramatic lighting from street lamps, intense psychological horror',
          tags: ['killer', 'mask', 'rain'],
        ),
      ],
    ),
    PromptCategory(
      id: 'sci_fi',
      name: 'Sci-Fi & Future',
      icon: '🚀',
      description: 'Futuristic and science fiction themes',
      prompts: [
        PromptItem(
          id: 'cyberpunk_city',
          title: 'Cyberpunk City',
          prompt:
              'A neon-lit cyberpunk cityscape at night, flying cars, holographic advertisements, rain reflecting neon lights on wet streets',
          isPopular: true,
          tags: ['cyberpunk', 'neon', 'city'],
        ),
        PromptItem(
          id: 'alien_planet',
          title: 'Alien Planet',
          prompt:
              'An alien landscape with multiple moons, strange vegetation, floating rocks, otherworldly atmosphere with vibrant colors',
          isPopular: true,
          tags: ['alien', 'planet', 'landscape'],
        ),
        PromptItem(
          id: 'robot_portrait',
          title: 'Humanoid Robot',
          prompt:
              'A sophisticated humanoid robot with glowing blue eyes, metallic skin, standing in a futuristic laboratory',
          tags: ['robot', 'futuristic', 'technology'],
        ),
        PromptItem(
          id: 'space_station',
          title: 'Space Station',
          prompt:
              'A massive space station orbiting Earth, with windows showing the planet below, astronauts floating in zero gravity',
          tags: ['space', 'station', 'earth'],
        ),
        PromptItem(
          id: 'time_travel_portal',
          title: 'Time Travel Portal',
          prompt:
              'A swirling vortex of energy and light, time fragments floating around it, futuristic technology controlling the portal, sci-fi atmosphere',
          isPopular: true,
          tags: ['time', 'portal', 'vortex'],
        ),
        PromptItem(
          id: 'android_awakening',
          title: 'Android Awakening',
          prompt:
              'A humanoid android with glowing circuits under its skin, awakening in a high-tech laboratory, consciousness emerging, futuristic setting',
          tags: ['android', 'awakening', 'consciousness'],
        ),
        PromptItem(
          id: 'alien_encounter',
          title: 'Alien Encounter',
          prompt:
              'A mysterious alien spacecraft landing in a forest clearing, bright lights illuminating the trees, human figures approaching cautiously',
          isPopular: true,
          tags: ['alien', 'spacecraft', 'encounter'],
        ),
        PromptItem(
          id: 'virtual_reality_matrix',
          title: 'Virtual Reality Matrix',
          prompt:
              'A person connected to a VR system, digital code raining around them, glitch effects, cyberpunk aesthetic with neon colors',
          tags: ['virtual', 'reality', 'matrix'],
        ),
        PromptItem(
          id: 'mars_colony',
          title: 'Mars Colony',
          prompt:
              'A futuristic colony on Mars with domed habitats, red dust storms outside, advanced technology, earth visible in the sky',
          tags: ['mars', 'colony', 'habitat'],
        ),
      ],
    ),
    PromptCategory(
      id: 'nature',
      name: 'Nature & Landscapes',
      icon: '🌙',
      description: 'Beautiful natural scenes with spooky twist',
      prompts: [
        PromptItem(
          id: 'moonlight_cemetery',
          title: 'Moonlit Cemetery',
          prompt:
              'An ancient cemetery under full moon, old tombstones casting long shadows, mist rising from the ground, gothic atmosphere',
          isPopular: true,
          tags: ['cemetery', 'moon', 'gothic'],
        ),
        PromptItem(
          id: 'stormy_sea',
          title: 'Stormy Sea',
          prompt:
              'A turbulent ocean during a thunderstorm, massive waves crashing against rocks, lightning illuminating the dark sky',
          tags: ['storm', 'ocean', 'lightning'],
        ),
        PromptItem(
          id: 'foggy_mountains',
          title: 'Foggy Mountains',
          prompt:
              'Mysterious mountains shrouded in thick fog, ancient stone ruins visible through the mist, ethereal lighting',
          tags: ['mountains', 'fog', 'ruins'],
        ),
        PromptItem(
          id: 'dark_forest_path',
          title: 'Dark Forest Path',
          prompt:
              'A winding path through a dark forest, twisted branches overhead, mysterious lights in the distance, horror atmosphere',
          tags: ['forest', 'path', 'dark'],
        ),
        PromptItem(
          id: 'aurora_ghosts',
          title: 'Aurora Ghosts',
          prompt:
              'Northern lights dancing in the sky above a frozen lake, ethereal ghost-like figures reflected in the ice, mystical atmosphere',
          isPopular: true,
          tags: ['aurora', 'ghosts', 'frozen'],
        ),
        PromptItem(
          id: 'volcano_eruption',
          title: 'Volcanic Apocalypse',
          prompt:
              'A massive volcano erupting with lava and ash clouds, lightning striking through the smoke, apocalyptic atmosphere with red sky',
          tags: ['volcano', 'eruption', 'apocalypse'],
        ),
        PromptItem(
          id: 'tornado_horror',
          title: 'Tornado Horror',
          prompt:
              'A massive tornado tearing through a landscape, debris flying, dark storm clouds, dramatic weather photography style',
          tags: ['tornado', 'storm', 'debris'],
        ),
        PromptItem(
          id: 'cursed_lake',
          title: 'Cursed Lake',
          prompt:
              'A still lake with dead trees protruding from the water, fog rising from the surface, eerie silence, supernatural atmosphere',
          isPopular: true,
          tags: ['lake', 'cursed', 'fog'],
        ),
        PromptItem(
          id: 'abandoned_cottage',
          title: 'Abandoned Cottage',
          prompt:
              'A small cottage overgrown with vines and moss, broken windows, smoke coming from the chimney, mysterious and haunting',
          tags: ['cottage', 'abandoned', 'overgrown'],
        ),
      ],
    ),
    PromptCategory(
      id: 'vintage',
      name: 'Vintage Horror',
      icon: '🎭',
      description: 'Classic vintage horror and retro themes',
      prompts: [
        PromptItem(
          id: 'vintage_carnival',
          title: 'Vintage Carnival',
          prompt:
              'An old abandoned carnival at night, broken Ferris wheel, vintage carousel, eerie silence, 1950s horror movie atmosphere',
          isPopular: true,
          tags: ['carnival', 'vintage', 'abandoned'],
        ),
        PromptItem(
          id: 'gothic_vampire',
          title: 'Gothic Vampire',
          prompt:
              'A elegant vampire in Victorian clothing, standing in a gothic mansion, dramatic shadows, classic horror aesthetic',
          isPopular: true,
          tags: ['vampire', 'gothic', 'victorian'],
        ),
        PromptItem(
          id: 'old_mansion',
          title: 'Victorian Mansion',
          prompt:
              'A grand Victorian mansion with gothic architecture, ornate windows, overgrown garden, classic horror movie setting',
          tags: ['mansion', 'victorian', 'gothic'],
        ),
        PromptItem(
          id: 'steampunk_horror',
          title: 'Steampunk Horror',
          prompt:
              'A steampunk laboratory with brass machinery, gears and pipes, mysterious experiments, Victorian horror aesthetic',
          tags: ['steampunk', 'laboratory', 'victorian'],
        ),
        PromptItem(
          id: 'vintage_seance',
          title: 'Vintage Séance',
          prompt:
              'A Victorian parlor with a medium conducting a séance, candles flickering, a spirit board on the table, dramatic shadows',
          isPopular: true,
          tags: ['seance', 'victorian', 'spirit'],
        ),
        PromptItem(
          id: 'old_photograph',
          title: 'Haunted Photograph',
          prompt:
              'An old sepia-toned photograph showing a family, but one person\'s face is blurred or distorted, vintage horror aesthetic',
          tags: ['photograph', 'haunted', 'sepia'],
        ),
        PromptItem(
          id: 'vintage_phantom',
          title: 'Vintage Phantom',
          prompt:
              'A ghostly figure in Victorian clothing walking through a ballroom, transparent and ethereal, classic horror movie style',
          isPopular: true,
          tags: ['phantom', 'victorian', 'ballroom'],
        ),
        PromptItem(
          id: 'antique_dollhouse',
          title: 'Haunted Dollhouse',
          prompt:
              'A detailed Victorian dollhouse with tiny furniture, but the dolls inside are moving on their own, creepy miniature setting',
          tags: ['dollhouse', 'haunted', 'miniature'],
        ),
        PromptItem(
          id: 'gaslight_horror',
          title: 'Gaslight Horror',
          prompt:
              'A Victorian street at night with gas lamps flickering, fog rolling in, a mysterious figure in the shadows, classic atmosphere',
          tags: ['gaslight', 'victorian', 'fog'],
        ),
      ],
    ),
    PromptCategory(
      id: 'dark_fantasy',
      name: 'Dark Fantasy',
      icon: '⚔️',
      description: 'Dark and mystical fantasy with supernatural elements',
      prompts: [
        PromptItem(
          id: 'shadow_dragon',
          title: 'Shadow Dragon',
          prompt:
              'A massive dragon made of pure darkness and shadows, glowing purple eyes, flying over a cursed kingdom, dark fantasy atmosphere',
          isPopular: true,
          tags: ['shadow', 'dragon', 'cursed'],
        ),
        PromptItem(
          id: 'necromancer_ritual',
          title: 'Necromancer Ritual',
          prompt:
              'A dark wizard raising the dead in a moonlit graveyard, skeletal hands emerging from graves, mystical energy swirling around',
          tags: ['necromancer', 'ritual', 'skeleton'],
        ),
        PromptItem(
          id: 'cursed_sword',
          title: 'Cursed Blade',
          prompt:
              'An ancient sword embedded in stone, dark energy emanating from it, runes glowing with evil power, legendary weapon',
          isPopular: true,
          tags: ['sword', 'cursed', 'legendary'],
        ),
        PromptItem(
          id: 'dark_elf_assassin',
          title: 'Dark Elf Assassin',
          prompt:
              'A mysterious dark elf assassin in black leather armor, dual daggers, standing in moonlit shadows, fantasy stealth',
          tags: ['elf', 'assassin', 'stealth'],
        ),
        PromptItem(
          id: 'vampire_lord',
          title: 'Vampire Lord',
          prompt:
              'A powerful vampire lord in ornate dark robes, crimson eyes, standing in his gothic castle throne room, fantasy horror',
          tags: ['vampire', 'lord', 'gothic'],
        ),
        PromptItem(
          id: 'shadow_realm',
          title: 'Shadow Realm',
          prompt:
              'A twisted dimension where shadows come to life, dark creatures lurking, ethereal lighting, otherworldly atmosphere',
          isPopular: true,
          tags: ['shadow', 'realm', 'dimension'],
        ),
      ],
    ),
  ];

  static List<PromptCategory> getAllCategories() {
    return _promptCategories;
  }

  static PromptCategory? getCategoryById(String id) {
    try {
      return _promptCategories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<PromptItem> getPopularPrompts() {
    final List<PromptItem> popularPrompts = [];
    for (final category in _promptCategories) {
      popularPrompts.addAll(
        category.prompts.where((prompt) => prompt.isPopular),
      );
    }
    return popularPrompts;
  }

  static List<PromptItem> searchPrompts(String query) {
    if (query.isEmpty) return [];

    final List<PromptItem> results = [];
    final lowercaseQuery = query.toLowerCase();

    for (final category in _promptCategories) {
      for (final prompt in category.prompts) {
        if (prompt.title.toLowerCase().contains(lowercaseQuery) ||
            prompt.prompt.toLowerCase().contains(lowercaseQuery)) {
          results.add(prompt);
        }
      }
    }

    return results;
  }

  static List<PromptItem> getPromptsByTag(String tag) {
    final List<PromptItem> results = [];
    final lowercaseTag = tag.toLowerCase();

    for (final category in _promptCategories) {
      for (final prompt in category.prompts) {
        if (prompt.tags.any(
          (promptTag) => promptTag.toLowerCase().contains(lowercaseTag),
        )) {
          results.add(prompt);
        }
      }
    }

    return results;
  }
}
