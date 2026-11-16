// API отдаёт категории английскими кодами («home-decoration»).
// Здесь переводим их в названия для экрана.

const _categoryNames = {
  'beauty': 'Красота',
  'fragrances': 'Духи',
  'furniture': 'Мебель',
  'groceries': 'Еда',
  'home-decoration': 'Декор для дома',
  'kitchen-accessories': 'Кухня',
  'laptops': 'Ноутбуки',
  'mens-shirts': 'Мужские рубашки',
  'mens-shoes': 'Мужская обувь',
  'mens-watches': 'Мужские часы',
  'mobile-accessories': 'Аксессуары',
  'motorcycle': 'Мотоциклы',
  'skin-care': 'Уход за кожей',
  'smartphones': 'Смартфоны',
  'sports-accessories': 'Спорт',
  'sunglasses': 'Очки',
  'tablets': 'Планшеты',
  'tops': 'Топы',
  'vehicle': 'Транспорт',
  'womens-bags': 'Женские сумки',
  'womens-dresses': 'Платья',
  'womens-jewellery': 'Украшения',
  'womens-shoes': 'Женская обувь',
  'womens-watches': 'Женские часы',
};

String categoryLabel(String code) {
  final known = _categoryNames[code];
  if (known != null) return known;

  // незнакомая категория: «new-things» -> «New things»
  final text = code.replaceAll('-', ' ');
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
