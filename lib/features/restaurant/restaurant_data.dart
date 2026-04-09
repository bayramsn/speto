import '../../core/constants/app_images.dart';

class RestaurantCardData {
  const RestaurantCardData({
    required this.id,
    required this.title,
    required this.image,
    required this.cuisine,
    required this.etaMin,
    required this.etaMax,
    required this.ratingValue,
    required this.promo,
    required this.studentFriendly,
  });

  final String id;
  final String title;
  final String image;
  final String cuisine;
  final int etaMin;
  final int etaMax;
  final double ratingValue;
  final String promo;
  final bool studentFriendly;

  String get etaLabel => '$etaMin-$etaMax dk';
  String get ratingLabel => ratingValue.toStringAsFixed(1);

  factory RestaurantCardData.fromJson(Map<String, Object?> json) {
    return RestaurantCardData(
      id: json['id']! as String,
      title: json['title']! as String,
      image: json['image']! as String,
      cuisine: json['cuisine']! as String,
      etaMin: json['etaMin']! as int,
      etaMax: json['etaMax']! as int,
      ratingValue: (json['ratingValue']! as num).toDouble(),
      promo: json['promo']! as String,
      studentFriendly: json['studentFriendly']! as bool,
    );
  }
}

class MenuListItem {
  const MenuListItem(this.title, this.description, this.price, this.image);

  final String title;
  final String description;
  final String price;
  final String image;
}

List<RestaurantCardData> defaultRestaurantCatalog() {
  return const <RestaurantCardData>[
    RestaurantCardData(
      id: 'restaurant-burger-yiyelim',
      title: 'Burger Yiyelim',
      image: AppImages.burger,
      cuisine: 'Burger',
      etaMin: 15,
      etaMax: 25,
      ratingValue: 4.8,
      promo: 'Öğrenci Dostu',
      studentFriendly: true,
    ),
    RestaurantCardData(
      id: 'restaurant-pizza-bulls',
      title: 'Pizza Bulls',
      image: AppImages.pizza,
      cuisine: 'Pizza',
      etaMin: 18,
      etaMax: 26,
      ratingValue: 4.7,
      promo: 'İnce Hamur',
      studentFriendly: true,
    ),
    RestaurantCardData(
      id: 'restaurant-tavuk-pilavci',
      title: 'Tavuk Pilavcı',
      image: AppImages.tavukPilav,
      cuisine: 'Tavuk Pilav',
      etaMin: 10,
      etaMax: 16,
      ratingValue: 4.8,
      promo: 'Gece Açık',
      studentFriendly: true,
    ),
    RestaurantCardData(
      id: 'restaurant-halil-usta-kebap',
      title: 'Halil Usta Kebap',
      image: AppImages.kebap,
      cuisine: 'Kebap',
      etaMin: 16,
      etaMax: 24,
      ratingValue: 4.9,
      promo: 'Izgara Ateşi',
      studentFriendly: false,
    ),
    RestaurantCardData(
      id: 'restaurant-firin-34',
      title: 'Fırın 34',
      image: AppImages.pide,
      cuisine: 'Pide & Lahmacun',
      etaMin: 14,
      etaMax: 22,
      ratingValue: 4.7,
      promo: 'Fırından Sıcak',
      studentFriendly: true,
    ),
    RestaurantCardData(
      id: 'restaurant-durum-point',
      title: 'Dürüm Point',
      image: AppImages.durum,
      cuisine: 'Dürüm',
      etaMin: 12,
      etaMax: 18,
      ratingValue: 4.6,
      promo: 'Acılı Sos',
      studentFriendly: true,
    ),
    RestaurantCardData(
      id: 'restaurant-sushi-co',
      title: 'Sushi Co',
      image: AppImages.sushi,
      cuisine: 'Sushi',
      etaMin: 25,
      etaMax: 35,
      ratingValue: 4.9,
      promo: 'Yeni Menü',
      studentFriendly: false,
    ),
    RestaurantCardData(
      id: 'restaurant-pasta-sanati',
      title: 'Pasta Sanatı',
      image: AppImages.dessert,
      cuisine: 'Tatlı',
      etaMin: 9,
      etaMax: 14,
      ratingValue: 4.8,
      promo: 'Soğuk Tatlı',
      studentFriendly: true,
    ),
  ];
}

List<MenuListItem> dedupeMarketItems(List<MenuListItem> items) {
  final Set<String> seenTitles = <String>{};
  final List<MenuListItem> deduped = <MenuListItem>[];
  for (final MenuListItem item in items) {
    if (seenTitles.add(item.title)) {
      deduped.add(item);
    }
  }
  return deduped;
}

const List<String> marketCategoryOrder = <String>[
  'Tümü',
  'Süt & Kahvaltılık',
  'Et & Şarküteri',
  'Manav',
  'Unlu Mamuller',
  'Hazır Gıda',
];

bool marketContainsAny(String value, List<String> patterns) {
  for (final String pattern in patterns) {
    if (value.contains(pattern)) {
      return true;
    }
  }
  return false;
}

String marketCategoryForItem(MenuListItem item, String sourceCategory) {
  if (marketCategoryOrder.contains(sourceCategory)) {
    return sourceCategory;
  }
  final String haystack = '$sourceCategory ${item.title} ${item.description}'
      .toLowerCase();
  if (marketContainsAny(haystack, <String>[
    'tavuk',
    'dana',
    'et',
    'kıyma',
    'kuşbaşı',
    'sosis',
    'salam',
    'sucuk',
    'füme',
    'pastırma',
    'kavurma',
    'nugget',
    'şinitzel',
    'döner',
    'köfte',
  ])) {
    return 'Et & Şarküteri';
  }
  if (marketContainsAny(haystack, <String>[
    'mantar',
    'maydanoz',
    'dereotu',
    'roka',
    'nane',
    'soğan',
    'ıspanak',
    'biber',
    'domates',
    'salatalık',
    'çilek',
    'marul',
    'brokoli',
    'semizotu',
  ])) {
    return 'Manav';
  }
  if (marketContainsAny(haystack, <String>[
    'yufka',
    'ekmek',
    'lavaş',
    'tortilla',
    'milföy',
    'simit',
    'pasta',
    'ekler',
    'sütlaç',
    'supangle',
    'puding',
  ])) {
    return 'Unlu Mamuller';
  }
  if (marketContainsAny(haystack, <String>[
    'humus',
    'haydari',
    'amerikan salatası',
    'rus salatası',
    'şakşuka',
    'çiğ köfte',
    'makarna',
    'sandviç',
  ])) {
    return 'Hazır Gıda';
  }
  return 'Süt & Kahvaltılık';
}

Map<String, List<MenuListItem>> restaurantMenuSectionsFor(
  RestaurantCardData restaurant,
) {
  switch (restaurant.id) {
    case 'restaurant-pizza-bulls':
      return const <String, List<MenuListItem>>{
        'Popüler': <MenuListItem>[
          MenuListItem(
            'Margherita Pizza',
            'Mozzarella, domates sosu ve taze fesleğen ile hazırlanır.',
            '189 TL',
            AppImages.pizza,
          ),
          MenuListItem(
            'Pepperoni Pizza',
            'Bol pepperoni, mozzarella ve fırın kenarlı ince hamur.',
            '219 TL',
            AppImages.pizza,
          ),
        ],
        'Pizzalar': <MenuListItem>[
          MenuListItem(
            'Karışık Pizza',
            'Sucuk, mantar, mısır ve zeytin ile dolu aile favorisi.',
            '229 TL',
            AppImages.pizza,
          ),
          MenuListItem(
            '4 Peynirli Pizza',
            'Mozzarella, parmesan, cheddar ve rokfor uyumuyla hazırlanır.',
            '239 TL',
            AppImages.pizza,
          ),
        ],
        'Yan Ürünler': <MenuListItem>[
          MenuListItem(
            'Sarımsaklı Ekmek',
            'Fırından sıcak çıkan tereyağlı sarımsak ekmekleri.',
            '69 TL',
            AppImages.pide,
          ),
          MenuListItem(
            'Patates Topları',
            'Çıtır dış yüzeyli, peynir dolgulu sıcak atıştırmalık.',
            '79 TL',
            AppImages.burgerHero,
          ),
        ],
        'İçecekler': <MenuListItem>[
          MenuListItem(
            'Kutu Kola',
            'Buz gibi servis edilen klasik içecek.',
            '39 TL',
            MarketImages.cola,
          ),
          MenuListItem(
            'Ev Yapımı Limonata',
            'Taze limonla hazırlanan serinletici içecek.',
            '49 TL',
            MarketImages.lemonade,
          ),
        ],
      };
    case 'restaurant-tavuk-pilavci':
      return const <String, List<MenuListItem>>{
        'Popüler': <MenuListItem>[
          MenuListItem(
            'Klasik Tavuk Pilav',
            'Bol tavuk, tereyağlı pilav ve nohut ile hazırlanır.',
            '119 TL',
            AppImages.tavukPilav,
          ),
          MenuListItem(
            'Dubla Tavuk Pilav',
            'Ekstra tavuk ve büyük porsiyon pilavla servis edilir.',
            '149 TL',
            AppImages.tavukPilav,
          ),
        ],
        'Pilavlar': <MenuListItem>[
          MenuListItem(
            'Tereyağlı Nohutlu Pilav',
            'Tek başına pilav sevenler için klasik eşlikçi.',
            '69 TL',
            AppImages.tavukPilav,
          ),
          MenuListItem(
            'Acılı Tavuk Pilav',
            'Özel acı soslu tavuk parçalarıyla hazırlanan sıcak tabak.',
            '129 TL',
            AppImages.tavukPilav,
          ),
        ],
        'Çorbalar': <MenuListItem>[
          MenuListItem(
            'Tavuk Suyu Çorba',
            'Limonla tamamlanan sıcak başlangıç çorbası.',
            '49 TL',
            AppImages.tavukPilav,
          ),
          MenuListItem(
            'Mercimek Çorbası',
            'Kıvamlı ve baharat dengeli klasik çorba.',
            '45 TL',
            AppImages.tavukPilav,
          ),
        ],
        'İçecekler': <MenuListItem>[
          MenuListItem(
            'Ayran',
            'Pilav menülerine eşlik eden soğuk ayran.',
            '24 TL',
            MarketImages.milk,
          ),
          MenuListItem(
            'Şalgam',
            'Acılı veya acısız tercih edilebilen tamamlayıcı içecek.',
            '29 TL',
            MarketImages.icedTea,
          ),
        ],
      };
    case 'restaurant-halil-usta-kebap':
      return const <String, List<MenuListItem>>{
        'Popüler': <MenuListItem>[
          MenuListItem(
            'Adana Kebap',
            'Közlenmiş biber, lavaş ve sumaklı soğanla servis edilir.',
            '239 TL',
            AppImages.kebap,
          ),
          MenuListItem(
            'Urfa Kebap',
            'Baharat dengesi hafif, bol garnitürlü klasik kebap.',
            '239 TL',
            AppImages.kebap,
          ),
        ],
        'Kebaplar': <MenuListItem>[
          MenuListItem(
            'Patlıcanlı Kebap',
            'Köz patlıcan ile şişte pişirilen özel yorum.',
            '269 TL',
            AppImages.kebap,
          ),
          MenuListItem(
            'Tavuk Şiş',
            'Marine edilmiş tavuk, lavaş ve köz domates ile gelir.',
            '219 TL',
            AppImages.kebap,
          ),
        ],
        'Dürümler': <MenuListItem>[
          MenuListItem(
            'Adana Dürüm',
            'Lavaşta sarılan bol garnitürlü adana dürüm.',
            '179 TL',
            AppImages.durum,
          ),
          MenuListItem(
            'Tavuk Dürüm',
            'Köz tavuk ve özel sosla hazırlanan dürüm.',
            '159 TL',
            AppImages.durum,
          ),
        ],
        'İçecekler': <MenuListItem>[
          MenuListItem(
            'Ayran',
            'Kebapla klasikleşen köpüklü eşlikçi.',
            '24 TL',
            MarketImages.milk,
          ),
          MenuListItem(
            'Şalgam',
            'Kebap sofralarının vazgeçilmez acılı içeceği.',
            '29 TL',
            MarketImages.icedTea,
          ),
        ],
      };
    case 'restaurant-firin-34':
      return const <String, List<MenuListItem>>{
        'Popüler': <MenuListItem>[
          MenuListItem(
            'Kıymalı Pide',
            'Fırından yeni çıkan ince hamur ve bol iç harçla hazırlanır.',
            '149 TL',
            AppImages.pide,
          ),
          MenuListItem(
            'Kaşarlı Lahmacun',
            'Çift pişim taş fırın lahmacun ve ekstra kaşar ile sunulur.',
            '79 TL',
            AppImages.pide,
          ),
        ],
        'Pideler': <MenuListItem>[
          MenuListItem(
            'Kuşbaşılı Pide',
            'Kuşbaşı et ve fırın kenarlı çıtır hamur uyumuyla hazırlanır.',
            '189 TL',
            AppImages.pide,
          ),
          MenuListItem(
            'Karışık Pide',
            'Sucuk, kaşar ve kıyma ile hazırlanan dolu dolu fırın lezzeti.',
            '199 TL',
            AppImages.pide,
          ),
        ],
        'Lahmacun': <MenuListItem>[
          MenuListItem(
            'Klasik Lahmacun',
            'Bol maydanoz ve limonla servis edilen ince lahmacun.',
            '59 TL',
            AppImages.pide,
          ),
          MenuListItem(
            'Acılı Lahmacun',
            'Köz aromalı ve acı baharatlı fırın lahmacun.',
            '64 TL',
            AppImages.pide,
          ),
        ],
        'İçecekler': <MenuListItem>[
          MenuListItem(
            'Ayran',
            'Fırın ürünlerinin klasik içecek eşliği.',
            '24 TL',
            MarketImages.milk,
          ),
          MenuListItem(
            'Şalgam',
            'Baharatlı fırın menülerini dengeleyen soğuk içecek.',
            '29 TL',
            MarketImages.icedTea,
          ),
        ],
      };
    case 'restaurant-durum-point':
      return const <String, List<MenuListItem>>{
        'Popüler': <MenuListItem>[
          MenuListItem(
            'Et Dürüm',
            'İnce lavaş, bol et ve özel sarımsaklı sosla hazırlanır.',
            '169 TL',
            AppImages.durum,
          ),
          MenuListItem(
            'Tavuk Dürüm',
            'Marine tavuk, turşu ve köz sebzelerle servis edilir.',
            '149 TL',
            AppImages.durum,
          ),
        ],
        'Dürümler': <MenuListItem>[
          MenuListItem(
            'Atom Dürüm',
            'Ekstra et, cheddar ve acı sosla güçlendirilmiş özel dürüm.',
            '189 TL',
            AppImages.durum,
          ),
          MenuListItem(
            'Falafel Dürüm',
            'Nohut köftesi ve tahinli sosla hazırlanan vejetaryen seçenek.',
            '139 TL',
            AppImages.durum,
          ),
        ],
        'Tabaklar': <MenuListItem>[
          MenuListItem(
            'Et Tantuni Tabak',
            'Tantuni, patates ve salata ile hazırlanan doyurucu tabak.',
            '199 TL',
            AppImages.durum,
          ),
          MenuListItem(
            'Tavuk Şiş Tabak',
            'Pilav ve köz biber eşliğinde servis edilen sıcak tabak.',
            '189 TL',
            AppImages.kebap,
          ),
        ],
        'İçecekler': <MenuListItem>[
          MenuListItem(
            'Kutu Kola',
            'Dürüm menülerine eşlik eden soğuk içecek.',
            '39 TL',
            MarketImages.cola,
          ),
          MenuListItem(
            'Ayran',
            'Dürüme klasik eşlik eden soğuk ayran.',
            '24 TL',
            MarketImages.milk,
          ),
        ],
      };
    case 'restaurant-sushi-co':
      return const <String, List<MenuListItem>>{
        'Popüler': <MenuListItem>[
          MenuListItem(
            'California Roll',
            'Yengeç, avokado ve salatalıkla hazırlanan klasik 8 parça roll.',
            '229 TL',
            AppImages.sushi,
          ),
          MenuListItem(
            'Philadelphia Roll',
            'Somon, labne ve avokado ile hazırlanan yumuşak içimli roll.',
            '249 TL',
            AppImages.sushi,
          ),
        ],
        'Roll': <MenuListItem>[
          MenuListItem(
            'Spicy Tuna Roll',
            'Acılı ton balığı dolgulu, susam kaplı özel roll.',
            '259 TL',
            AppImages.sushi,
          ),
          MenuListItem(
            'Ebi Tempura Roll',
            'Tempura karides ve tatlı sosla hazırlanan sıcak roll.',
            '279 TL',
            AppImages.sushi,
          ),
        ],
        'Sıcaklar': <MenuListItem>[
          MenuListItem(
            'Tavuk Gyoza',
            'Izgara tabanlı, buharda pişmiş Japon mantısı.',
            '109 TL',
            AppImages.sushi,
          ),
          MenuListItem(
            'Miso Çorbası',
            'Tofu ve taze soğanla hazırlanan hafif başlangıç.',
            '79 TL',
            AppImages.sushi,
          ),
        ],
        'İçecekler': <MenuListItem>[
          MenuListItem(
            'Yeşil Çay',
            'Japon mutfağıyla uyumlu sıcak çay.',
            '39 TL',
            MarketImages.icedTea,
          ),
          MenuListItem(
            'Limonlu Soda',
            'Sushi menülerini dengeleyen hafif içecek.',
            '34 TL',
            MarketImages.mineralWater,
          ),
        ],
      };
    case 'restaurant-pasta-sanati':
      return const <String, List<MenuListItem>>{
        'Popüler': <MenuListItem>[
          MenuListItem(
            'San Sebastian',
            'Akışkan iç dokulu, yanık yüzeyli özel cheesecake dilimi.',
            '109 TL',
            AppImages.dessert,
          ),
          MenuListItem(
            'Çilekli Magnolia',
            'Hafif krema, bisküvi ve taze çilekle hazırlanır.',
            '99 TL',
            AppImages.dessert,
          ),
        ],
        'Sütlü Tatlı': <MenuListItem>[
          MenuListItem(
            'Supangle',
            'Yoğun çikolatalı, soğuk servis edilen klasik sütlü tatlı.',
            '89 TL',
            AppImages.dessert,
          ),
          MenuListItem(
            'Tiramisu Cup',
            'Kahveli kremasıyla katmanlı hazırlanmış hafif tatlı.',
            '104 TL',
            AppImages.dessert,
          ),
        ],
        'Soğuk Tatlı': <MenuListItem>[
          MenuListItem(
            'Lotuslu Parfe',
            'Lotus sos ve bisküvi kırıklarıyla soğuk sunulan özel tatlı.',
            '114 TL',
            AppImages.dessert,
          ),
          MenuListItem(
            'Profiterol Box',
            'Bol çikolata soslu mini toplardan oluşan kutu tatlı.',
            '119 TL',
            AppImages.dessert,
          ),
        ],
        'İçecekler': <MenuListItem>[
          MenuListItem(
            'Soğuk Americano',
            'Tatlılarla uyumlu sert içimli kahve.',
            '59 TL',
            MarketImages.coldBrew,
          ),
          MenuListItem(
            'Çilekli Milkshake',
            'Tatlı yanında tercih edilen soğuk içecek.',
            '74 TL',
            MarketImages.milk,
          ),
        ],
      };
    default:
      return const <String, List<MenuListItem>>{
        'Popüler': <MenuListItem>[
          MenuListItem(
            'Double Whopper Menü',
            'Alevde ızgaralanmış dana köftesi, taze sebzeler ve çıtır patates ile servis edilir.',
            '179 TL',
            AppImages.burger,
          ),
          MenuListItem(
            'Tavuk Royale',
            'Çıtır tavuk göğsü, mayonez ve yumuşak briyoş ekmek ile hazırlanır.',
            '149 TL',
            AppImages.burgerHero,
          ),
        ],
        'Burgerler': <MenuListItem>[
          MenuListItem(
            'Steakhouse Burger',
            'Özel dana köftesi, füme bacon ve yoğun barbekü sos ile servis edilir.',
            '189 TL',
            AppImages.burger,
          ),
          MenuListItem(
            'Cheddar Melt Burger',
            'Çift cheddar, karamelize soğan ve burger sos ile hazırlanır.',
            '199 TL',
            AppImages.burgerHero,
          ),
        ],
        'Yan Lezzetler': <MenuListItem>[
          MenuListItem(
            'Cheddar Patates',
            'Erimiş cheddar ve özel baharatla tamamlanan çıtır patates.',
            '79 TL',
            AppImages.burgerHero,
          ),
          MenuListItem(
            'Soğan Halkası',
            'İnce kaplamalı, çıtır dış yüzeyli sıcak yan ürün.',
            '69 TL',
            AppImages.burgerHero,
          ),
        ],
        'İçecekler': <MenuListItem>[
          MenuListItem(
            'Soğuk Kola',
            'Buz gibi kola, lime ve özel servis dokunuşu ile gelir.',
            '49 TL',
            MarketImages.cola,
          ),
          MenuListItem(
            'Tropik Buzlu Çay',
            'Şeftali, mango ve limon notalı ev yapımı buzlu çay.',
            '55 TL',
            MarketImages.icedTea,
          ),
        ],
      };
  }
}
