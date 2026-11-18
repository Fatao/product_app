import 'product.dart';

// API отдаёт названия по-английски, цены в долларах, а категорий у него
// больше, чем нужно. Здесь товар приводится к виду, который показывает
// приложение: русское название, цена в рублях, наши категории.

// Курс доллара. Фиксированный и приблизительный.
const usdToRub = 84.0;

// Возвращает null, если товар не подходит ни под одну категорию приложения
Product? localizeProduct(Product raw) {
  final category = _appCategory(raw.category, raw.title);
  if (category == null) return null;

  return raw.copyWith(
    title: translateTitle(raw.title, raw.category),
    category: category,
    price: (raw.price * usdToRub).roundToDouble(),
  );
}

// Категория API -> категория приложения
String? _appCategory(String apiCategory, String title) {
  switch (apiCategory) {
    case 'sports-accessories':
      return 'sports';
    case 'groceries':
      return _groceryCategory(title);
    case 'beauty':
    case 'skin-care':
    case 'fragrances':
      return 'beauty';
    case 'laptops':
      return 'laptops';
    case 'smartphones':
      return 'phones';
    case 'tablets':
    case 'mobile-accessories':
      return 'electronics';
    case 'womens-dresses':
    case 'tops':
      return 'women';
    case 'mens-shirts':
      return 'men';
    case 'mens-shoes':
    case 'womens-shoes':
      return 'shoes';
    default:
      // мебель, мотоциклы, часы и прочее в каталог не попадает
      return null;
  }
}

const _fruitWords = [
  'apple', 'kiwi', 'lemon', 'mulberry', 'strawberry', 'banana', 'orange',
  'mango', 'grape', 'pear', 'peach', 'cherry', 'watermelon',
];

const _vegetableWords = [
  'cucumber', 'potato', 'onion', 'pepper', 'tomato', 'carrot', 'cabbage',
];

// В API все продукты лежат в одной категории groceries,
// поэтому фрукты и овощи отличаем по названию
String? _groceryCategory(String title) {
  final lower = title.toLowerCase();

  // корм для животных и бумажные салфетки — не еда
  if (lower.contains('tissue') || lower.contains('cat food') || lower.contains('dog food')) {
    return null;
  }
  if (_fruitWords.any((word) => lower.contains(word))) return 'fruits';
  if (_vegetableWords.any((word) => lower.contains(word))) return 'vegetables';
  return 'food';
}

// Русское название. Если перевода нет, оставляем как есть:
// названия вроде «iPhone 13 Pro» и так читаются без перевода.
String translateTitle(String title, String apiCategory) {
  final key = title.trim().toLowerCase();
  final known = _titles[key];
  if (known != null) return known;

  switch (apiCategory) {
    case 'laptops':
      return 'Ноутбук $title';
    case 'smartphones':
      return 'Смартфон $title';
    case 'tablets':
      return 'Планшет $title';
    default:
      return title;
  }
}

const _titles = {
  // еда
  'apple': 'Яблоки',
  'banana': 'Бананы',
  'beef steak': 'Говяжий стейк',
  'chicken meat': 'Куриное мясо',
  'cooking oil': 'Растительное масло',
  'cucumber': 'Огурцы',
  'eggs': 'Яйца',
  'fish steak': 'Рыбный стейк',
  'green bell pepper': 'Зелёный болгарский перец',
  'green chili pepper': 'Зелёный перец чили',
  'honey jar': 'Мёд в банке',
  'ice cream': 'Мороженое',
  'juice': 'Сок',
  'kiwi': 'Киви',
  'lemon': 'Лимоны',
  'milk': 'Молоко',
  'mulberry': 'Шелковица',
  'nescafe coffee': 'Кофе Nescafe',
  'potatoes': 'Картофель',
  'protein powder': 'Протеиновый порошок',
  'red onions': 'Красный лук',
  'rice': 'Рис',
  'soft drinks': 'Газированные напитки',
  'strawberry': 'Клубника',
  'water': 'Вода',

  // красота
  'essence mascara lash princess': 'Тушь Essence Lash Princess',
  'eyeshadow palette with mirror': 'Палетка теней с зеркалом',
  'powder canister': 'Рассыпчатая пудра',
  'red lipstick': 'Красная помада',
  'red nail polish': 'Красный лак для ногтей',
  'calvin klein ck one': 'Calvin Klein CK One',
  'chanel coco noir eau de': 'Chanel Coco Noir, парфюмерная вода',
  "dior j'adore": "Dior J'adore",
  'dolce shine eau de': 'Dolce Shine, парфюмерная вода',
  'gucci bloom eau de': 'Gucci Bloom, парфюмерная вода',
  'attitude super leaves hand soap': 'Жидкое мыло Attitude Super Leaves',
  'olay ultra moisturizing face wash': 'Средство для умывания Olay Ultra Moisturizing',
  'vaseline men body and face lotion': 'Лосьон для тела и лица Vaseline Men',

  // спорт
  'american football': 'Мяч для американского футбола',
  'baseball ball': 'Бейсбольный мяч',
  'baseball glove': 'Бейсбольная перчатка',
  'basketball': 'Баскетбольный мяч',
  'basketball rim': 'Баскетбольное кольцо',
  'cricket ball': 'Мяч для крикета',
  'cricket bat': 'Бита для крикета',
  'cricket helmet': 'Шлем для крикета',
  'cricket wicket': 'Воротца для крикета',
  'feather shuttlecock': 'Перьевой волан',
  'football': 'Футбольный мяч',
  'golf ball': 'Мяч для гольфа',
  'iron golf': 'Клюшка для гольфа',
  'metal baseball bat': 'Металлическая бейсбольная бита',
  'tennis ball': 'Теннисный мяч',
  'tennis racket': 'Теннисная ракетка',
  'volleyball': 'Волейбольный мяч',
  'yoga mat': 'Коврик для йоги',

  // одежда
  'blue & black check shirt': 'Клетчатая рубашка сине-чёрная',
  'gigabyte aorus men tshirt': 'Мужская футболка Gigabyte Aorus',
  'man plaid shirt': 'Мужская клетчатая рубашка',
  'man short sleeve shirt': 'Мужская рубашка с коротким рукавом',
  'men check shirt': 'Мужская рубашка в клетку',
  "black women's gown": 'Чёрное женское платье',
  'corset leather with skirt': 'Кожаный корсет с юбкой',
  'corset with black skirt': 'Корсет с чёрной юбкой',
  'dress pea': 'Платье «Горох»',
  'marni red & black suit': 'Костюм Marni красно-чёрный',
  'blue frock': 'Синее платье',

  // обувь
  'black & brown slipper': 'Чёрно-коричневые тапочки',
  'calvin klein heel shoes': 'Туфли на каблуке Calvin Klein',
  'golden shoes woman': 'Золотистые женские туфли',
  'pampi shoes': 'Туфли Pampi',
  'red shoes': 'Красные туфли',
  'nike air jordan 1 red and black': 'Кроссовки Nike Air Jordan 1 красно-чёрные',
  'nike baseball cleats': 'Бутсы Nike для бейсбола',
  'puma future rider trainers': 'Кроссовки Puma Future Rider',
  'sports sneakers off white & red': 'Спортивные кроссовки бело-красные',
  'sports sneakers off white red': 'Спортивные кроссовки бело-красные',

  // электроника
  'amazon echo plus': 'Умная колонка Amazon Echo Plus',
  'apple airpods': 'Наушники Apple AirPods',
  'apple airpods max silver': 'Наушники Apple AirPods Max Silver',
  'apple charger': 'Зарядное устройство Apple',
  'apple homepod mini cosmic grey': 'Умная колонка Apple HomePod Mini',
  'apple iphone charger': 'Зарядка для iPhone Apple',
  'apple magsafe battery pack': 'Внешний аккумулятор Apple MagSafe',
  'apple watch series 4 gold': 'Умные часы Apple Watch Series 4 Gold',
  'beats flex wireless earphones': 'Беспроводные наушники Beats Flex',
  'iphone 12 silicone case': 'Силиконовый чехол для iPhone 12',
};
