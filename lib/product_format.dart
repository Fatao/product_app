// Превращаем числа в текст для экрана.

// 1790 -> «1 790 ₽» (пробелы неразрывные, чтобы цена не переносилась)
String formatPrice(double price) {
  final digits = price.round().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ' ',
  );
  return '$grouped ₽';
}

// 4.8 -> 4.8
String formatRating(double rating) {
  return rating.toStringAsFixed(1);
}

String formatStock(int stock) {
  if (stock <= 0) return 'Нет в наличии';
  return 'В наличии: $stock шт.';
}
