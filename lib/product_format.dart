// Превращаем числа в текст для экрана.

// 129.9 -> $129.90 (API отдаёт цены в долларах)
String formatPrice(double price) {
  return '\$${price.toStringAsFixed(2)}';
}

// 4.8 -> 4.8
String formatRating(double rating) {
  return rating.toStringAsFixed(1);
}

String formatStock(int stock) {
  if (stock <= 0) return 'Нет в наличии';
  return 'В наличии: $stock шт.';
}
