// Категории приложения. Их порядок здесь — это порядок чипов на экране.
const shopCategoryOrder = [
  'sports',
  'books',
  'fruits',
  'vegetables',
  'electronics',
  'women',
  'men',
  'kids',
  'shoes',
  'beauty',
  'food',
  'laptops',
  'phones',
];

const _categoryNames = {
  'sports': 'Спорт',
  'books': 'Книги',
  'fruits': 'Фрукты',
  'vegetables': 'Овощи',
  'electronics': 'Электроника',
  'women': 'Женская одежда',
  'men': 'Мужская одежда',
  'kids': 'Детская одежда',
  'shoes': 'Обувь',
  'beauty': 'Красота',
  'food': 'Еда',
  'laptops': 'Ноутбуки',
  'phones': 'Телефоны',
};

String categoryLabel(String code) {
  return _categoryNames[code] ?? code;
}
