import '../models/prompt_category.dart';

class PromptService {
  static const List<PromptCategory> _promptCategories = [
    // Text to Image Prompts
    PromptCategory(
      id: 'text_to_image',
      name: 'Text to Image',
      icon: '🎨',
      description:
          'Generate Halloween scenes and characters from text descriptions',
      prompts: [
        // Halloween Scenes
        PromptItem(
          id: 'spooky_forest',
          title: 'Spooky Forest',
          prompt:
              'A dark, misty forest at night with twisted trees, glowing eyes in the shadows, and mysterious fog swirling between ancient oaks, cinematic horror lighting',
          isPopular: true,
          tags: ['forest', 'horror', 'atmosphere', 'scene'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'haunted_house',
          title: 'Haunted Mansion',
          prompt:
              'A grand Victorian mansion with broken windows, overgrown vines, lightning illuminating the facade, gothic architecture with eerie shadows',
          isPopular: true,
          tags: ['house', 'gothic', 'lightning', 'scene'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'haunted_graveyard',
          title: 'Haunted Graveyard',
          prompt:
              'An ancient cemetery with crumbling tombstones, ghostly figures emerging from graves, skeletal hands reaching from the earth, ethereal blue mist',
          isPopular: true,
          tags: ['graveyard', 'ghosts', 'skeletons', 'scene'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'cursed_pumpkin_patch',
          title: 'Cursed Pumpkin Patch',
          prompt:
              'A field of glowing jack-o-lanterns with sinister faces, each carved with different expressions of horror, mist swirling between them under a blood-red moon',
          isPopular: true,
          tags: ['pumpkin', 'cursed', 'moon', 'scene'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'trick_or_treat_block_party',
          title: 'Trick-or-Treat Block Party',
          prompt:
              'A lively Halloween neighborhood block party at dusk: rows of townhouses draped in fake cobwebs and paper bats, porches stacked with jack-o-lanterns carved in intricate patterns, strings of orange fairy lights zigzagging over the street. Children in elaborate costumes (witches with pointed hats, tiny vampires with capes, astronauts with reflective visors) dart between doorsteps, pumpkin pails swinging. Parents chat in small clusters holding steaming cups of cider. A fog machine wafts low-lying mist along the asphalt, reflective wet leaves glimmer in the glow. Warm porch light meets cool blue twilight; soft depth-of-field and cinematic grain, gentle lens flare from a streetlamp, cozy yet spooky atmosphere.',
          tags: [
            'street',
            'party',
            'kids',
            'pumpkins',
            'neighborhood',
            'scene',
          ],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'haunted_front_porch_row',
          title: 'Haunted Front Porch Row',
          prompt:
              'A row of vintage wooden porches decorated for Halloween on a narrow residential street: creaking steps, crepe-paper streamers fluttering in the breeze, witch silhouettes taped to windows, black-cat cutouts perched on railings. Carved pumpkins of all sizes emit flickering candlelight; a bowl of candy corn sits on a small table next to a brass door knocker shaped like a skull. Paper lanterns dangle overhead, gently swaying. Fallen maple leaves gather on the steps, their reds and oranges glowing under a warm porch bulb, while the background fades into cool twilight blue. Framing emphasizes the repeating porches; subtle film grain and shallow depth of field for a nostalgic seasonal vibe.',
          tags: [
            'porch',
            'pumpkins',
            'lanterns',
            'leaves',
            'nostalgic',
            'scene',
          ],
          promptType: PromptType.textToImage,
        ),

        // Fantasy Characters
        PromptItem(
          id: 'dragon_lair',
          title: 'Dragon\'s Lair',
          prompt:
              'A massive dragon sleeping on a pile of golden treasures in a cave, glowing gems and magical artifacts scattered around, epic fantasy lighting',
          isPopular: true,
          tags: ['dragon', 'treasure', 'cave', 'fantasy'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'magical_castle',
          title: 'Floating Castle',
          prompt:
              'A magnificent castle floating in the clouds, waterfalls cascading from its edges, rainbow bridges connecting to other floating islands',
          isPopular: true,
          tags: ['castle', 'floating', 'clouds', 'fantasy'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'wizard_tower',
          title: 'Wizard\'s Tower',
          prompt:
              'A tall stone tower with glowing windows, magical energy swirling around it, books and potions floating in the air',
          tags: ['wizard', 'tower', 'magic', 'fantasy'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'enchanted_forest',
          title: 'Enchanted Forest',
          prompt:
              'A mystical forest with glowing mushrooms, fairy lights, ancient trees with faces, magical creatures hidden in the shadows',
          tags: ['forest', 'fairy', 'enchanted', 'fantasy'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'phoenix_rebirth',
          title: 'Phoenix Rebirth',
          prompt:
              'A magnificent phoenix rising from flames, golden and crimson feathers glowing with inner fire, ash and embers swirling around, rebirth symbolism',
          isPopular: true,
          tags: ['phoenix', 'fire', 'rebirth', 'fantasy'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'unicorn_meadow',
          title: 'Unicorn Meadow',
          prompt:
              'A magical meadow with a pure white unicorn, rainbow-colored flowers blooming everywhere, sparkling dewdrops, ethereal morning light',
          tags: ['unicorn', 'meadow', 'rainbow', 'fantasy'],
          promptType: PromptType.textToImage,
        ),

        // Horror Characters
        PromptItem(
          id: 'zombie_apocalypse',
          title: 'Zombie Apocalypse',
          prompt:
              'Post-apocalyptic cityscape with abandoned buildings, dark clouds, zombies in the shadows, dramatic lighting with orange sky',
          tags: ['zombie', 'apocalypse', 'city', 'horror'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'witch_ritual',
          title: 'Witch Ritual',
          prompt:
              'A mysterious witch performing a ritual in a candlelit room, floating objects, magical symbols in the air, dark mystical atmosphere',
          tags: ['witch', 'ritual', 'magic', 'horror'],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: 'ghost_portrait',
          title: 'Ghost Portrait',
          prompt:
              'A translucent ghost figure with flowing ethereal clothing, glowing eyes, surrounded by floating orbs of light, dramatic dark background',
          isPopular: true,
          tags: ['ghost', 'portrait', 'ethereal', 'horror'],
          promptType: PromptType.textToImage,
        ),
      ],
    ),
    // Image to Image Prompts
    PromptCategory(
      id: 'image_to_image',
      name: 'Image to Image',
      icon: '👤',
      description:
          'Transform your face with Halloween themes while preserving your features',
      prompts: [
        // Classic Halloween Characters
        PromptItem(
          id: 'halloween_ghost',
          title: 'Halloween Ghost',
          prompt:
              'Transform into a stunning Halloween ghost with ethereal white glow, translucent skin, glowing eyes, supernatural aura, ghostly lighting, spectral effects, haunted graveyard background with ancient tombstones, misty fog, moonlight, supernatural atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          isPopular: false,
          tags: ['ghost', 'halloween', 'ethereal', 'supernatural', 'classic'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_vampire',
          title: 'Halloween Vampire',
          prompt:
              'Become a mesmerizing Halloween vampire with pale porcelain skin, crimson red eyes, sharp fangs, dark gothic clothing, elegant gothic atmosphere, gothic castle interior background with ornate furniture, candlelit chandeliers, red velvet curtains, mysterious shadows, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          isPopular: false,
          tags: ['vampire', 'halloween', 'gothic', 'elegant', 'classic'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_witch',
          title: 'Halloween Witch',
          prompt:
              'Transform into a captivating Halloween witch with pointed black hat, flowing dark robes, magical green aura, spell-casting hands, mystical forest background with ancient trees, floating magical orbs, glowing mushrooms, enchanted atmosphere, magical lighting, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          isPopular: false,
          tags: ['witch', 'halloween', 'magic', 'mystical', 'classic'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_zombie',
          title: 'Halloween Zombie',
          prompt:
              'Become a terrifying Halloween zombie with decaying skin, hollow eyes, torn clothing, bloodstains, horror atmosphere, post-apocalyptic cityscape background with destroyed buildings, smoke, debris, dark stormy sky, apocalyptic lighting, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['zombie', 'halloween', 'horror', 'decay', 'classic'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_skeleton',
          title: 'Halloween Skeleton',
          prompt:
              'Become a powerful Halloween skeleton with glowing white bones, dark mystical robes, floating magical orbs, necromantic lighting, arcane energy, ancient necromancer laboratory background with dark stone walls, glowing runes, floating skulls, mystical atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['skeleton', 'halloween', 'magic', 'mystical', 'classic'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_pumpkin',
          title: 'Halloween Pumpkin',
          prompt:
              'Transform into a spooky Halloween pumpkin with glowing orange skin, carved face, flickering candlelight, mystical aura, pumpkin patch background with glowing jack-o-lanterns, autumn leaves, spooky atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['pumpkin', 'halloween', 'spooky', 'autumn', 'classic'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_mummy',
          title: 'Halloween Mummy',
          prompt:
              'Become a terrifying Halloween mummy with ancient bandages, glowing eyes, mystical aura, Egyptian tomb background with hieroglyphs, golden artifacts, mystical lighting, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['mummy', 'halloween', 'ancient', 'mystical', 'classic'],
          promptType: PromptType.imageToImage,
        ),

        // Supernatural Beings
        PromptItem(
          id: 'halloween_demon',
          title: 'Halloween Demon',
          prompt:
              'Transform into a fearsome Halloween demon with curved horns, glowing red eyes, dark leather armor, battle scars, infernal lighting, menacing aura, hellish battlefield background with lava rivers, burning rocks, demonic architecture, infernal atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['demon', 'halloween', 'battle', 'powerful', 'supernatural'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_werewolf',
          title: 'Halloween Werewolf',
          prompt:
              'Transform into a savage Halloween werewolf with thick brown fur, razor-sharp claws, glowing yellow eyes, torn clothing, primal lighting, beastly aura, dark forest background with towering trees, full moon, howling wolves silhouette, primal wilderness atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['werewolf', 'halloween', 'fierce', 'beast', 'supernatural'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_phantom',
          title: 'Halloween Phantom',
          prompt:
              'Become an elegant Halloween phantom with ornate white mask, flowing black cape, ghostly white gloves, ethereal lighting, mysterious presence, grand opera house background with velvet curtains, ornate chandeliers, ghostly mist, theatrical atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: [
            'phantom',
            'halloween',
            'mysterious',
            'elegant',
            'supernatural',
          ],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_necromancer',
          title: 'Halloween Necromancer',
          prompt:
              'Transform into a sinister Halloween necromancer with black hooded robes, glowing purple staff, floating skulls, shadowy lighting, death magic aura, ancient dark temple background with stone altars, glowing purple crystals, shadowy corners, necromantic atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: [
            'necromancer',
            'halloween',
            'shadowy',
            'commanding',
            'supernatural',
          ],
          promptType: PromptType.imageToImage,
        ),

        // Royalty & Nobility
        PromptItem(
          id: 'halloween_royalty',
          title: 'Halloween Royalty',
          prompt:
              'Become cursed Halloween royalty with golden crown, regal purple robes, glowing cursed jewelry, gothic lighting, supernatural regal aura, gothic throne room background with ornate furniture, royal tapestries, cursed artifacts, regal supernatural atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['royalty', 'halloween', 'cursed', 'regal', 'nobility'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_knight',
          title: 'Halloween Knight',
          prompt:
              'Become a noble Halloween knight with armor, helmet, sword, medieval castle background with stone walls, torches, medieval atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['knight', 'halloween', 'medieval', 'noble', 'nobility'],
          promptType: PromptType.imageToImage,
        ),

        // Adventure & Action
        PromptItem(
          id: 'halloween_pirate',
          title: 'Halloween Pirate',
          prompt:
              'Transform into a swashbuckling Halloween pirate with tricorn hat, eye patch, pirate coat, wooden leg, treasure map, pirate ship deck background with sails, ocean waves, treasure chest, nautical atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['pirate', 'halloween', 'adventure', 'nautical', 'action'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_superhero',
          title: 'Halloween Superhero',
          prompt:
              'Become a powerful Halloween superhero with cape, mask, superhero costume, glowing powers, city skyline background with skyscrapers, night sky, superhero atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['superhero', 'halloween', 'powerful', 'heroic', 'action'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_ninja',
          title: 'Halloween Ninja',
          prompt:
              'Become a stealthy Halloween ninja with black outfit, mask, throwing stars, shadowy rooftop background with city lights, stealth atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['ninja', 'halloween', 'stealth', 'shadowy', 'action'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_samurai',
          title: 'Halloween Samurai',
          prompt:
              'Transform into a fierce Halloween samurai with armor, katana, traditional clothing, Japanese garden background with cherry blossoms, traditional architecture, martial arts atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: [
            'samurai',
            'halloween',
            'martial_arts',
            'traditional',
            'action',
          ],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_gladiator',
          title: 'Halloween Gladiator',
          prompt:
              'Transform into a powerful Halloween gladiator with armor, helmet, weapons, Roman colosseum background with arena, ancient architecture, gladiator atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['gladiator', 'halloween', 'ancient', 'powerful', 'action'],
          promptType: PromptType.imageToImage,
        ),

        // Sci-Fi & Futuristic
        PromptItem(
          id: 'halloween_robot',
          title: 'Halloween Robot',
          prompt:
              'Transform into a futuristic Halloween robot with metallic skin, glowing circuits, robotic armor, cybernetic enhancements, futuristic laboratory background with high-tech equipment, neon lights, sci-fi atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['robot', 'halloween', 'futuristic', 'cybernetic', 'scifi'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_alien',
          title: 'Halloween Alien',
          prompt:
              'Transform into a mysterious Halloween alien with green skin, antennae, space suit, spaceship interior background with control panels, stars, space atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['alien', 'halloween', 'space', 'mysterious', 'scifi'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_astronaut',
          title: 'Halloween Astronaut',
          prompt:
              'Transform into a space Halloween astronaut with space suit, helmet, oxygen tank, space station background with stars, planets, space atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['astronaut', 'halloween', 'space', 'futuristic', 'scifi'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_cyberpunk',
          title: 'Halloween Cyberpunk',
          prompt:
              'Transform into a futuristic Halloween cyberpunk with neon colors, cybernetic implants, futuristic clothing, neon-lit city background with holographic displays, cyberpunk atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['cyberpunk', 'halloween', 'futuristic', 'neon', 'scifi'],
          promptType: PromptType.imageToImage,
        ),

        // Steampunk & Vintage
        PromptItem(
          id: 'halloween_steampunk',
          title: 'Halloween Steampunk',
          prompt:
              'Become a Victorian Halloween steampunk with goggles, brass accessories, Victorian clothing, steam-powered machinery background with gears, steam, Victorian atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: [
            'steampunk',
            'halloween',
            'victorian',
            'mechanical',
            'vintage',
          ],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_detective',
          title: 'Halloween Detective',
          prompt:
              'Become a mysterious Halloween detective with trench coat, hat, magnifying glass, noir city background with streetlights, fog, detective atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['detective', 'halloween', 'noir', 'mysterious', 'vintage'],
          promptType: PromptType.imageToImage,
        ),

        // Fantasy & Magic
        PromptItem(
          id: 'halloween_sorcerer',
          title: 'Halloween Sorcerer',
          prompt:
              'Become a powerful Halloween sorcerer with wizard hat, robes, magical staff, spellbook, mystical tower background with magical artifacts, floating orbs, magical atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['sorcerer', 'halloween', 'magical', 'powerful', 'fantasy'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_fairy',
          title: 'Halloween Fairy',
          prompt:
              'Transform into a magical Halloween fairy with wings, fairy costume, magical sparkles, enchanted forest background with glowing mushrooms, fairy lights, magical atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['fairy', 'halloween', 'magical', 'enchanted', 'fantasy'],
          promptType: PromptType.imageToImage,
        ),

        // Circus & Entertainment
        PromptItem(
          id: 'halloween_clown',
          title: 'Halloween Clown',
          prompt:
              'Become a creepy Halloween clown with colorful makeup, oversized shoes, polka dot costume, circus tent background with carnival lights, circus atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['clown', 'halloween', 'circus', 'colorful', 'entertainment'],
          promptType: PromptType.imageToImage,
        ),

        // Western & Adventure
        PromptItem(
          id: 'halloween_cowboy',
          title: 'Halloween Cowboy',
          prompt:
              'Become a rugged Halloween cowboy with hat, boots, leather vest, wild west saloon background with wooden furniture, desert atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['cowboy', 'halloween', 'wild_west', 'rugged', 'western'],
          promptType: PromptType.imageToImage,
        ),

        // Professional & Modern
        PromptItem(
          id: 'halloween_doctor',
          title: 'Halloween Doctor',
          prompt:
              'Transform into a mad Halloween doctor with lab coat, stethoscope, medical equipment, laboratory background with test tubes, medical atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: [
            'doctor',
            'halloween',
            'medical',
            'scientific',
            'professional',
          ],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_chef',
          title: 'Halloween Chef',
          prompt:
              'Become a culinary Halloween chef with chef hat, apron, cooking utensils, kitchen background with cooking equipment, culinary atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['chef', 'halloween', 'culinary', 'cooking', 'professional'],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: 'halloween_artist',
          title: 'Halloween Artist',
          prompt:
              'Transform into a creative Halloween artist with paint-splattered clothes, paintbrush, easel, art studio background with canvases, artistic atmosphere, cinematic lighting, dramatic shadows, photorealistic, high quality, professional photography, keep exact same face, preserve facial features, maintain face identity, same person, identical face',
          tags: ['artist', 'halloween', 'creative', 'artistic', 'professional'],
          promptType: PromptType.imageToImage,
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

  static List<PromptItem> getTextToImagePrompts() {
    final textToImageCategory = _promptCategories.firstWhere(
      (category) => category.id == 'text_to_image',
    );
    return textToImageCategory.prompts;
  }

  static List<PromptItem> getImageToImagePrompts() {
    final imageToImageCategory = _promptCategories.firstWhere(
      (category) => category.id == 'image_to_image',
    );
    return imageToImageCategory.prompts;
  }

  // Get prompts by subcategory
  static List<PromptItem> getTextToImagePromptsBySubcategory(
    String subcategory,
  ) {
    return getTextToImagePrompts()
        .where((prompt) => prompt.tags.contains(subcategory))
        .toList();
  }

  static List<PromptItem> getImageToImagePromptsBySubcategory(
    String subcategory,
  ) {
    return getImageToImagePrompts()
        .where((prompt) => prompt.tags.contains(subcategory))
        .toList();
  }

  // Get available subcategories
  static List<String> getTextToImageSubcategories() {
    return ['scene', 'fantasy', 'horror'];
  }

  static List<String> getImageToImageSubcategories() {
    return [
      'classic',
      'supernatural',
      'nobility',
      'action',
      'scifi',
      'vintage',
      'fantasy',
      'entertainment',
      'western',
      'professional',
    ];
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
