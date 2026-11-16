import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'product.dart';

enum ProductErrorType {
  noConnection,
  timeout,
  notFound, // сервер ответил 404
  rateLimited,
  server,
  badResponse,
}

// Ошибка с текстом, который можно сразу показать пользователю
class ProductException implements Exception {
  const ProductException(this.type, this.message);

  final ProductErrorType type;
  final String message;

  @override
  String toString() => 'ProductException($type): $message';
}

// Здесь все запросы в сеть. Адрес API лежит только в этом файле.
// Ключ не нужен: DummyJSON работает без него.
class ProductApiClient {
  ProductApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // В каталоге около 200 товаров, поэтому просим сразу много
  static const _productsUrl = 'https://dummyjson.com/products?limit=200';
  static const _timeout = Duration(seconds: 10);

  Future<List<Product>> fetchProducts() async {
    final json = await _getJson(Uri.parse(_productsUrl));

    try {
      final rawProducts = json['products'] as List;
      return [
        for (final item in rawProducts)
          Product.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      // не хватает поля или оно другого типа
      throw const ProductException(
        ProductErrorType.badResponse,
        'Сервер вернул непонятный ответ.',
      );
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _get(uri);
    final status = response.statusCode;

    if (status == 404) {
      throw const ProductException(
        ProductErrorType.notFound,
        'Сервер не нашёл данные (ошибка 404).',
      );
    }
    if (status == 429) {
      throw const ProductException(
        ProductErrorType.rateLimited,
        'Слишком много запросов. Подождите немного.',
      );
    }
    if (status >= 500) {
      throw ProductException(
        ProductErrorType.server,
        'Ошибка сервера (код $status). Попробуйте позже.',
      );
    }
    if (status != 200) {
      throw ProductException(
        ProductErrorType.server,
        'Не удалось получить данные (код $status).',
      );
    }

    try {
      // читаем байты как UTF-8, чтобы не портились символы
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // пришёл не JSON — ниже выбросим ошибку
    }
    throw const ProductException(
      ProductErrorType.badResponse,
      'Сервер вернул непонятный ответ.',
    );
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const ProductException(
        ProductErrorType.timeout,
        'Сервер слишком долго отвечает. Попробуйте ещё раз.',
      );
    } on http.ClientException {
      // нет интернета, не нашёлся сервер или оборвалось соединение
      throw const ProductException(
        ProductErrorType.noConnection,
        'Нет подключения к интернету.',
      );
    }
  }
}
