import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_app/product_api_client.dart';

const productsBody = '''
{"products":[
 {"id":1,"title":"Apple","description":"Fresh apples","category":"groceries",
  "price":1.99,"discountPercentage":7.5,"rating":4.8,"stock":50,
  "tags":["fruit","fresh"],"brand":"Farm","images":["https://x/1.jpg","https://x/2.jpg"],
  "thumbnail":"https://x/thumb.jpg"},
 {"id":2,"title":"Bread","category":"groceries","price":1}
],"total":2,"skip":0,"limit":200}
''';

http.Response jsonResponse(String body, [int status = 200]) {
  return http.Response(
    body,
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

ProductApiClient clientWith(MockClientHandler handler) {
  return ProductApiClient(client: MockClient(handler));
}

Matcher throwsProductError(ProductErrorType type) {
  return throwsA(
    isA<ProductException>().having((e) => e.type, 'type', type),
  );
}

void main() {
  group('разбор списка', () {
    test('читает все поля продукта', () async {
      final api = clientWith((_) async => jsonResponse(productsBody));

      final products = await api.fetchProducts();

      expect(products.length, 2);
      final apple = products.first;
      expect(apple.id, 1);
      expect(apple.title, 'Apple');
      expect(apple.category, 'groceries');
      expect(apple.price, 1.99);
      expect(apple.rating, 4.8);
      expect(apple.stock, 50);
      expect(apple.brand, 'Farm');
      expect(apple.discountPercentage, 7.5);
      expect(apple.images.length, 2);
      expect(apple.tags, ['fruit', 'fresh']);
      expect(apple.thumbnail, 'https://x/thumb.jpg');
    });

    test('необязательных полей может не быть', () async {
      final api = clientWith((_) async => jsonResponse(productsBody));

      final bread = (await api.fetchProducts())[1];

      expect(bread.rating, isNull);
      expect(bread.brand, isNull);
      expect(bread.stock, isNull);
      expect(bread.description, '');
      expect(bread.images, isEmpty);
      expect(bread.price, 1.0); // целое число из JSON тоже подходит
    });

    test('пустой список — это не ошибка', () async {
      final api = clientWith((_) async => jsonResponse('{"products":[]}'));

      expect(await api.fetchProducts(), isEmpty);
    });

    test('в запросе просим много товаров', () async {
      Uri? sent;
      final api = clientWith((request) async {
        sent = request.url;
        return jsonResponse(productsBody);
      });

      await api.fetchProducts();

      expect(sent!.host, 'dummyjson.com');
      expect(sent!.queryParameters['limit'], '200');
    });

    test('нет обязательного поля — некорректный ответ', () async {
      final api = clientWith(
        (_) async => jsonResponse('{"products":[{"id":1}]}'),
      );

      expect(api.fetchProducts(), throwsProductError(ProductErrorType.badResponse));
    });

    test('нет поля products — некорректный ответ', () async {
      final api = clientWith((_) async => jsonResponse('{"total":0}'));

      expect(api.fetchProducts(), throwsProductError(ProductErrorType.badResponse));
    });
  });

  group('ошибки сети и HTTP', () {
    test('404', () async {
      final api = clientWith((_) async => jsonResponse('', 404));

      expect(api.fetchProducts(), throwsProductError(ProductErrorType.notFound));
    });

    test('500 с кодом в сообщении', () async {
      final api = clientWith((_) async => jsonResponse('oops', 500));

      expect(
        api.fetchProducts(),
        throwsA(isA<ProductException>()
            .having((e) => e.type, 'type', ProductErrorType.server)
            .having((e) => e.message, 'message', contains('500'))),
      );
    });

    test('429', () async {
      final api = clientWith((_) async => jsonResponse('', 429));

      expect(api.fetchProducts(), throwsProductError(ProductErrorType.rateLimited));
    });

    test('в ответе не JSON', () async {
      final api = clientWith((_) async => jsonResponse('<html>'));

      expect(api.fetchProducts(), throwsProductError(ProductErrorType.badResponse));
    });

    test('нет интернета', () async {
      final api = clientWith((_) async => throw http.ClientException('offline'));

      expect(api.fetchProducts(), throwsProductError(ProductErrorType.noConnection));
    });
  });
}
