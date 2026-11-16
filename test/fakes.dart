import 'dart:async';

import 'package:product_app/product.dart';
import 'package:product_app/product_api_client.dart';

// Маленький каталог с известными ценами и рейтингами
List<Product> sampleProducts() {
  return const [
    Product(
      id: 1,
      title: 'Apple',
      category: 'groceries',
      price: 1.99,
      rating: 4.8,
      stock: 50,
      description: 'Fresh apples',
      images: ['https://example.com/apple1.jpg', 'https://example.com/apple2.jpg'],
      tags: ['fruit'],
    ),
    Product(id: 2, title: 'Banana', category: 'groceries', price: 0.99, rating: 4.6),
    Product(id: 3, title: 'Milk', category: 'groceries', price: 2.49, rating: 4.5),
    Product(
      id: 4,
      title: 'Laptop Pro',
      category: 'laptops',
      price: 999.0,
      rating: 4.2,
      brand: 'Acme',
    ),
    // у этого товара нет рейтинга: API его не прислал
    Product(id: 5, title: 'Smartphone X', category: 'smartphones', price: 599.0),
    Product(id: 6, title: 'Face Cream', category: 'beauty', price: 12.5, rating: 3.9),
  ];
}

// Большой каталог для проверки длинного списка
List<Product> manyProducts(int count) {
  const categories = ['groceries', 'beauty', 'laptops'];
  return [
    for (var i = 1; i <= count; i++)
      Product(
        id: i,
        title: 'Item $i',
        category: categories[i % categories.length],
        price: i + 0.5,
        rating: (i % 5) + 1.0,
      ),
  ];
}

// Подмена настоящего клиента: сеть не нужна, ответом управляет тест
class FakeProductApi implements ProductApiClient {
  FakeProductApi({List<Product>? products})
      : products = products ?? sampleProducts();

  List<Product> products;
  ProductException? error; // если задана, запрос падает с ней
  Completer<void>? gate; // пока не завершён, запрос «висит»
  int requestCount = 0;

  @override
  Future<List<Product>> fetchProducts() async {
    requestCount++;
    await gate?.future;
    if (error != null) throw error!;
    return products;
  }
}
