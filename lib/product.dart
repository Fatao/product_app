// Модель продукта. Поля, которых может не быть в ответе API, сделаны
// необязательными (rating, brand и т. д.).
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    this.description = '',
    this.discountPercentage,
    this.rating,
    this.stock,
    this.brand,
    this.thumbnail = '',
    this.images = const [],
    this.tags = const [],
  });

  final int id;
  final String title;
  final String category;
  final double price;
  final String description;
  final double? discountPercentage;
  final double? rating;
  final int? stock;
  final String? brand;
  final String thumbnail; // маленькая картинка для списка
  final List<String> images; // все картинки для экрана подробностей
  final List<String> tags;

  // Если в JSON нет обязательного поля (id, title, price) или оно другого типа,
  // тут вылетит ошибка. Её ловит ApiClient и показывает «некорректный ответ».
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'other',
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt(),
      brand: json['brand'] as String?,
      thumbnail: json['thumbnail'] as String? ?? '',
      images: _readStrings(json['images']),
      tags: _readStrings(json['tags']),
    );
  }

  static List<String> _readStrings(Object? value) {
    if (value is! List) return const [];
    return [for (final item in value) item as String];
  }
}
