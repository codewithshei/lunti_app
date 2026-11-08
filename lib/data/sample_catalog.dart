// SAMPLE DATA — mock catalog contents used only while Firebase is not connected.
// Prices, names and stock come from the Figma handoff note and are illustrative
// design data, not verified offers. Replace with a Firestore-backed repository.

class SampleCategory {
  const SampleCategory({
    required this.id,
    required this.label,
    required this.shopLabel,
    required this.tagline,
    required this.image,
  });

  final String id;
  final String label;
  final String shopLabel;
  final String tagline;
  final String image;
}

class SampleProduct {
  const SampleProduct({
    required this.id,
    required this.name,
    required this.pricePeso,
    required this.note,
    required this.image,
    required this.categoryId,
    required this.eyebrow,
    required this.description,
    required this.stockLeft,
    required this.material,
    required this.origin,
    required this.care,
    List<String>? gallery,
    this.variantLabel,
    this.variantPricePeso,
  }) : gallery = gallery ?? const [];

  final String id;
  final String name;
  final int pricePeso;
  final String note;
  final String image;
  final String categoryId;

  /// Small collection tag shown above the product title (SAMPLE copy).
  final String eyebrow;
  final String description;
  final int stockLeft;
  final String material;
  final String origin;
  final String care;

  /// SAMPLE: only one real photo exists per product so far, so the gallery
  /// repeats the hero image to mirror the Figma layout. Swap in real angle
  /// shots when photography is available.
  final List<String> gallery;
  final String? variantLabel;
  final int? variantPricePeso;

  List<String> get galleryImages =>
      gallery.isEmpty ? <String>[image] : gallery;

  String get priceLabel => '\u20B1$pricePeso';

  /// True when the current stock has run out.
  bool get isOutOfStock => stockLeft <= 0;

  /// Copy with a new stock count, keeping every other field unchanged.
  ///
  /// Stock is the only mutable value in the live catalog: it changes whenever
  /// an order is placed or the admin dashboard restocks a product.
  SampleProduct copyWith({int? stockLeft}) {
    return SampleProduct(
      id: id,
      name: name,
      pricePeso: pricePeso,
      note: note,
      image: image,
      categoryId: categoryId,
      eyebrow: eyebrow,
      description: description,
      stockLeft: stockLeft ?? this.stockLeft,
      material: material,
      origin: origin,
      care: care,
      gallery: gallery,
      variantLabel: variantLabel,
      variantPricePeso: variantPricePeso,
    );
  }
}

const sampleCategories = <SampleCategory>[
  SampleCategory(
    id: 'miniature',
    label: 'Miniature',
    shopLabel: 'Miniature',
    tagline: 'Gazebo, Drum Set & Truck',
    image: 'assets/images/cat_miniature.jpg',
  ),
  SampleCategory(
    id: 'customized',
    label: 'Customized',
    shopLabel: 'Customized Items',
    tagline: 'Personal pieces for home and gifting',
    image: 'assets/images/cat_customized.jpg',
  ),
  SampleCategory(
    id: 'plaques',
    label: 'Plaque',
    shopLabel: 'Plaques',
    tagline: 'Mark a moment worth remembering',
    image: 'assets/images/cat_plaque.jpg',
  ),
  SampleCategory(
    id: 'engraving',
    label: 'Engraving',
    shopLabel: 'Engraving',
    tagline: 'Names and messages on bamboo',
    image: 'assets/images/cat_engraving.jpg',
  ),
];

const sampleProducts = <SampleProduct>[
  SampleProduct(
    id: 'phone-speaker',
    name: 'Phone Speaker',
    pricePeso: 450,
    note: 'Natural bamboo',
    image: 'assets/images/prod_phone_speaker.jpg',
    categoryId: 'customized',
    eyebrow: 'Bamboo everyday',
    description: 'A handcrafted bamboo piece for your phone, with natural '
        'warmth for your desk or bedside.',
    stockLeft: 8,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: [
      'assets/images/prod_phone_speaker.jpg',
      'assets/images/prod_phone_speaker.jpg',
      'assets/images/prod_phone_speaker.jpg',
    ],
    variantLabel: 'Engraved',
    variantPricePeso: 550,
  ),
  SampleProduct(
    id: 'souvenir',
    name: 'Souvenir',
    pricePeso: 180,
    note: 'Customize or use your own design',
    image: 'assets/images/prod_souvenir.jpg',
    categoryId: 'engraving',
    eyebrow: 'Made personal',
    description: 'Souvenir magnets in classic Philippine motifs '
        '\u2014 customize our designs or send us your own.',
    stockLeft: 24,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_souvenir.jpg'],
  ),
  SampleProduct(
    id: 'table-bar-name',
    name: 'Table Bar Name',
    pricePeso: 650,
    note: 'Made personal',
    image: 'assets/images/prod_table_bar.jpg',
    categoryId: 'plaques',
    eyebrow: 'Table top style',
    description: 'A standing name piece for the table or bar, shaped and '
        'finished by hand.',
    stockLeft: 5,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_table_bar.jpg'],
  ),
  SampleProduct(
    id: 'coaster',
    name: 'Coaster',
    pricePeso: 140,
    note: 'For everyday rituals',
    image: 'assets/images/prod_coaster.jpg',
    categoryId: 'engraving',
    eyebrow: 'Everyday rituals',
    description: 'A simple bamboo coaster for coffee, tea and slow '
        'mornings.',
    stockLeft: 40,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_coaster.jpg'],
  ),
  // ---- SAMPLE catalog expansion: the remaining product photos in the
  // handoff. Names, prices and specs are illustrative sample data keyed
  // off the real product photography until a Firebase-backed catalog
  // replaces them.
  SampleProduct(
    id: 'hand-mirror',
    name: 'Pizza Board',
    pricePeso: 400,
    note: 'Round rolling & serving board',
    image: 'assets/images/prod_hand_mirror.jpg',
    categoryId: 'customized',
    eyebrow: 'Kitchen classics',
    description: 'A round bamboo board for rolling dough, slicing or '
        'serving.',
    stockLeft: 12,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Hand wash; dry at once.',
    gallery: ['assets/images/prod_hand_mirror.jpg'],
    variantLabel: 'Engraved',
    variantPricePeso: 500,
  ),
  SampleProduct(
    id: 'carved-trophy',
    name: 'Carved Trophy',
    pricePeso: 1300,
    note: 'Carved monogram stand',
    image: 'assets/images/prod_carved_trophy.jpg',
    categoryId: 'plaques',
    eyebrow: 'Made to honor',
    description: 'A stand-up bamboo piece with a carved monogram in '
        'swept bamboo panels.',
    stockLeft: 4,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_carved_trophy.jpg'],
  ),
  SampleProduct(
    id: 'tribal-plaque',
    name: 'Engraved Tribal Plaque',
    pricePeso: 550,
    note: 'Traditional patterns',
    image: 'assets/images/prod_tribal_plaque.jpg',
    categoryId: 'plaques',
    eyebrow: 'Made to honor',
    description: 'A freestanding plaque pairing traditional carved '
        'patterns with polished bamboo.',
    stockLeft: 3,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_tribal_plaque.jpg'],
  ),
  SampleProduct(
    id: 'capiz-lamp',
    name: 'Table Lamp',
    pricePeso: 2000,
    note: 'Bamboo & capiz lamp',
    image: 'assets/images/prod_capiz_lamp.jpg',
    categoryId: 'customized',
    eyebrow: 'Home accents',
    description: 'A table lamp with a bamboo body and capiz accents \u2014 '
        'a warm glow for any corner.',
    stockLeft: 5,
    material: 'Bamboo & capiz',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Dust with a dry cloth.',
    gallery: ['assets/images/prod_capiz_lamp.jpg'],
  ),
  SampleProduct(
    id: 'gazebo',
    name: 'Gazebo',
    pricePeso: 600,
    note: 'Miniature hut with benches',
    image: 'assets/images/prod_gazebo.jpg',
    categoryId: 'miniature',
    eyebrow: 'Handmade miniatures',
    description: 'A bamboo shelter miniature with benches, cut joinery '
        'and no glue or nails.',
    stockLeft: 6,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_gazebo.jpg'],
  ),
  SampleProduct(
    id: 'barangay-plate',
    name: 'Barangay Nameplate',
    pricePeso: 550,
    note: 'Engraved desk plaque',
    image: 'assets/images/prod_barangay_plate.jpg',
    categoryId: 'plaques',
    eyebrow: 'Made to honor',
    description: 'An office nameplate engraved and hand-colored per '
        'order.',
    stockLeft: 3,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_barangay_plate.jpg'],
  ),
  SampleProduct(
    id: 'bamboo-clock',
    name: 'Wall Clock',
    pricePeso: 1300,
    note: 'Quartz movement',
    image: 'assets/images/prod_bamboo_clock.jpg',
    categoryId: 'customized',
    eyebrow: 'Home accents',
    description: 'A woven bamboo-framed wall clock with bold markers.',
    stockLeft: 7,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_bamboo_clock.jpg'],
    variantLabel: 'Engraved',
    variantPricePeso: 1450,
  ),
  SampleProduct(
    id: 'carved-bowl',
    name: 'Trinket Dish',
    pricePeso: 250,
    note: 'Small dish for keepsakes',
    image: 'assets/images/prod_carved_bowl.jpg',
    categoryId: 'customized',
    eyebrow: 'Little keepsakes',
    description: 'A small bamboo dish for rings, keys and keepsakes '
        '\u2014 carved with a gentle foot.',
    stockLeft: 8,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_carved_bowl.jpg'],
    variantLabel: 'Engraved',
    variantPricePeso: 350,
  ),
  SampleProduct(
    id: 'display-rack',
    name: 'Eyewear Rack',
    pricePeso: 450,
    note: 'Holds sunglasses & frames',
    image: 'assets/images/prod_display_rack.jpg',
    categoryId: 'customized',
    eyebrow: 'Home accents',
    description: 'A tabletop bamboo rack that keeps sunglasses and '
        'frames on show and within reach.',
    stockLeft: 4,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_display_rack.jpg'],
  ),
  SampleProduct(
    id: 'recognition-plaque',
    name: 'Recognition Plaque',
    pricePeso: 550,
    note: 'Award plaque, made to order',
    image: 'assets/images/prod_recognition_plaque.jpg',
    categoryId: 'plaques',
    eyebrow: 'Made to honor',
    description: 'A double-curve award plaque engraved with your '
        'citation and seals.',
    stockLeft: 3,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_recognition_plaque.jpg'],
  ),
  SampleProduct(
    id: 'sail-plaque',
    name: 'Sail Plaque',
    pricePeso: 650,
    note: 'Layered award piece',
    image: 'assets/images/prod_sail_plaque.jpg',
    categoryId: 'plaques',
    eyebrow: 'Made to honor',
    description: 'Bamboo and acrylic layered like a sail for awards '
        'and milestones.',
    stockLeft: 2,
    material: 'Bamboo & acrylic',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_sail_plaque.jpg'],
  ),
  SampleProduct(
    id: 'last-supper',
    name: 'Last Supper Panel',
    pricePeso: 750,
    note: 'Carved wood art piece',
    image: 'assets/images/prod_last_supper.jpg',
    categoryId: 'plaques',
    eyebrow: 'Made to honor',
    description: 'A detailed wood panel with the Last Supper carved '
        'line by line, with its own stand.',
    stockLeft: 2,
    material: 'Wood',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_last_supper.jpg'],
  ),
  SampleProduct(
    id: 'wood-truck',
    name: 'Wooden Truck',
    pricePeso: 1300,
    note: 'Collector miniature',
    image: 'assets/images/prod_wood_truck.jpg',
    categoryId: 'miniature',
    eyebrow: 'Handmade miniatures',
    description: 'A hand-cut wooden truck miniature with rolling '
        'wheels and panel details.',
    stockLeft: 5,
    material: 'Wood',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_wood_truck.jpg'],
  ),
  SampleProduct(
    id: 'bead-necklace',
    name: 'Bamboo Bead Necklace',
    pricePeso: 150,
    note: 'Braided cord & beads',
    image: 'assets/images/prod_bead_necklace.jpg',
    categoryId: 'customized',
    eyebrow: 'Little keepsakes',
    description: 'A braided necklace strung with polished bamboo '
        'beads.',
    stockLeft: 15,
    material: 'Bamboo & cord',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Keep dry when not in use.',
    gallery: ['assets/images/prod_bead_necklace.jpg'],
  ),
  SampleProduct(
    id: 'coin-bank',
    name: 'Bamboo Coin Bank',
    pricePeso: 180,
    note: 'Savings jar, bamboo cut',
    image: 'assets/images/prod_coin_bank.jpg',
    categoryId: 'customized',
    eyebrow: 'Great with kids',
    description: 'A coin bank cut from a single bamboo culm \u2014 '
        'honest savings for small hands.',
    stockLeft: 20,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_coin_bank.jpg'],
    variantLabel: 'Engraved',
    variantPricePeso: 280,
  ),
  SampleProduct(
    id: 'drum-set',
    name: 'Drum Set',
    pricePeso: 700,
    note: 'Miniature drum kit',
    image: 'assets/images/prod_drum_set.jpg',
    categoryId: 'miniature',
    eyebrow: 'Handmade miniatures',
    description: 'A full bamboo drum set miniature on its own platform '
        '\u2014 every cymbal cut by hand.',
    stockLeft: 4,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_drum_set.jpg'],
  ),
  SampleProduct(
    id: 'pen-holder',
    name: 'Lamp Shade',
    pricePeso: 400,
    note: 'Hand-cut bamboo shade',
    image: 'assets/images/prod_pen_holder.jpg',
    categoryId: 'customized',
    eyebrow: 'Home accents',
    description: 'A bamboo shade cut and woven by hand \u2014 casts a '
        'warm, patterned light.',
    stockLeft: 18,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_pen_holder.jpg'],
  ),
  SampleProduct(
    id: 'bamboo-tumbler',
    name: 'Bamboo Tumbler',
    pricePeso: 380,
    note: 'Engraved steel-inside flask',
    image: 'assets/images/prod_bamboo_tumbler.jpg',
    categoryId: 'customized',
    eyebrow: 'Daily bamboo',
    description: 'A bamboo-shell tumbler you can have engraved with a '
        'name or place.',
    stockLeft: 10,
    material: 'Bamboo & steel',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Hand wash only; keep shell dry.',
    gallery: ['assets/images/prod_bamboo_tumbler.jpg'],
    variantLabel: 'Engraved',
    variantPricePeso: 480,
  ),
  SampleProduct(
    id: 'quote-boards',
    name: 'Quote Boards',
    pricePeso: 450,
    note: 'Carved message panels',
    image: 'assets/images/prod_quote_boards.jpg',
    categoryId: 'engraving',
    eyebrow: 'Words on wood',
    description: 'Wall panels carved with the words you choose to live '
        'by.',
    stockLeft: 6,
    material: 'Wood',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_quote_boards.jpg'],
  ),
  SampleProduct(
    id: 'bamboo-mugs',
    name: 'Bamboo Mugs',
    pricePeso: 300,
    note: 'Steel-rim travel mugs',
    image: 'assets/images/prod_bamboo_mugs.jpg',
    categoryId: 'customized',
    eyebrow: 'Daily bamboo',
    description: 'Bamboo mugs with steel rims and handles for coffee '
        'on the move.',
    stockLeft: 9,
    material: 'Bamboo & steel',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Hand wash only; keep shell dry.',
    gallery: ['assets/images/prod_bamboo_mugs.jpg'],
  ),
  SampleProduct(
    id: 'bamboo-notebook',
    name: 'Bamboo Notebook',
    pricePeso: 250,
    note: 'Engraved cover & pen',
    image: 'assets/images/prod_bamboo_notebook.jpg',
    categoryId: 'engraving',
    eyebrow: 'Made personal',
    description: 'A ring-bound notebook with a bamboo cover and pen, '
        'engraved with the owner\'s name.',
    stockLeft: 14,
    material: 'Bamboo & paper',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Avoid soaking the cover.',
    gallery: ['assets/images/prod_bamboo_notebook.jpg'],
    variantLabel: 'Engraved',
    variantPricePeso: 300,
  ),
  SampleProduct(
    id: 'mug-handle',
    name: 'Handled Bamboo Mug',
    pricePeso: 250,
    note: 'Lidded mug with handle',
    image: 'assets/images/prod_mug_handle.jpg',
    categoryId: 'customized',
    eyebrow: 'Daily bamboo',
    description: 'A bamboo-shell mug with a wooden handle and sipping '
        'lid for slow sips.',
    stockLeft: 8,
    material: 'Bamboo & steel',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Hand wash only; keep shell dry.',
    gallery: ['assets/images/prod_mug_handle.jpg'],
  ),
  SampleProduct(
    id: 'arc-holder',
    name: 'Small Speaker',
    pricePeso: 150,
    note: 'Compact phone speaker',
    image: 'assets/images/prod_arc_holder.jpg',
    categoryId: 'customized',
    eyebrow: 'Sound by bamboo',
    description: 'A compact bamboo passive speaker that amps up your '
        'phone with no wires.',
    stockLeft: 16,
    material: 'Bamboo',
    origin: 'Cardona, Rizal, Philippines',
    care: 'Wipe gently; keep dry.',
    gallery: ['assets/images/prod_arc_holder.jpg'],
    variantLabel: 'Engraved',
    variantPricePeso: 250,
  ),
];

const sampleSearchQuery = 'speaker';
const sampleRecentlySearched = <String>['speaker'];
const sampleExploreChips = <String>['Coaster', 'Souvenir', 'Engraving'];
