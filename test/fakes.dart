import 'dart:async';

import 'package:product_app/product.dart';
import 'package:product_app/product_api_client.dart';
import 'package:product_app/product_repository.dart';

// Маленький каталог в том виде, в каком его показывает приложение:
// русские названия, цены в рублях, категории приложения
List<Product> sampleProducts() {
  return const [
    Product(
      id: 1,
      title: 'Яблоки',
      category: 'fruits',
      price: 150,
      rating: 4.8,
      stock: 50,
      images: ['https://example.com/apple1.jpg', 'https://example.com/apple2.jpg'],
    ),
    Product(id: 2, title: 'Бананы', category: 'fruits', price: 90, rating: 4.6),
    Product(id: 3, title: 'Молоко', category: 'food', price: 120, rating: 4.5),
    Product(
      id: 4,
      title: 'Ноутбук Pro',
      category: 'laptops',
      price: 85000,
      rating: 4.2,
      brand: 'Acme',
    ),
    // у этого товара нет рейтинга: API его не прислал
    Product(id: 5, title: 'Смартфон X', category: 'phones', price: 50000),
    Product(id: 6, title: 'Крем для лица', category: 'beauty', price: 1050, rating: 3.9),
  ];
}

// Большой каталог для проверки длинного списка
List<Product> manyProducts(int count) {
  const categories = ['fruits', 'beauty', 'laptops'];
  return [
    for (var i = 1; i <= count; i++)
      Product(
        id: i,
        title: 'Товар $i',
        category: categories[i % categories.length],
        price: i * 10.0,
        rating: (i % 5) + 1.0,
      ),
  ];
}

// Репозиторий для тестов состояния: товары уже в нужном виде,
// поэтому перевод и пересчёт цен не нужны
ProductRepository testRepository(ProductApiClient api) {
  return ProductRepository(api, localizer: (product) => product);
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
