import 'package:flutter_test/flutter_test.dart';
import 'package:product_app/product.dart';
import 'package:product_app/product_api_client.dart';
import 'package:product_app/product_localizer.dart';
import 'package:product_app/product_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Товар в том виде, в каком его присылает API: по-английски и в долларах
Product raw(String title, String category, [double price = 1.0]) {
  return Product(id: 1, title: title, category: category, price: price);
}

void main() {
  group('категории', () {
    test('еда делится на фрукты, овощи и остальное', () {
      expect(localizeProduct(raw('Apple', 'groceries'))!.category, 'fruits');
      expect(localizeProduct(raw('Kiwi', 'groceries'))!.category, 'fruits');
      expect(localizeProduct(raw('Cucumber', 'groceries'))!.category, 'vegetables');
      expect(localizeProduct(raw('Red Onions', 'groceries'))!.category, 'vegetables');
      expect(localizeProduct(raw('Milk', 'groceries'))!.category, 'food');
    });

    test('остальные категории API', () {
      expect(localizeProduct(raw('Football', 'sports-accessories'))!.category, 'sports');
      expect(localizeProduct(raw('Lipstick', 'beauty'))!.category, 'beauty');
      expect(localizeProduct(raw('Soap', 'skin-care'))!.category, 'beauty');
      expect(localizeProduct(raw('Perfume', 'fragrances'))!.category, 'beauty');
      expect(localizeProduct(raw('MacBook', 'laptops'))!.category, 'laptops');
      expect(localizeProduct(raw('iPhone X', 'smartphones'))!.category, 'phones');
      expect(localizeProduct(raw('iPad', 'tablets'))!.category, 'electronics');
      expect(localizeProduct(raw('Charger', 'mobile-accessories'))!.category, 'electronics');
      expect(localizeProduct(raw('Dress', 'womens-dresses'))!.category, 'women');
      expect(localizeProduct(raw('Top', 'tops'))!.category, 'women');
      expect(localizeProduct(raw('Shirt', 'mens-shirts'))!.category, 'men');
      expect(localizeProduct(raw('Sneakers', 'mens-shoes'))!.category, 'shoes');
      expect(localizeProduct(raw('Heels', 'womens-shoes'))!.category, 'shoes');
    });

    test('ненужные категории в каталог не попадают', () {
      expect(localizeProduct(raw('Sofa', 'furniture')), isNull);
      expect(localizeProduct(raw('Kawasaki', 'motorcycle')), isNull);
      expect(localizeProduct(raw('Rolex', 'mens-watches')), isNull);
      expect(localizeProduct(raw('Tissue Paper Box', 'groceries')), isNull);
      expect(localizeProduct(raw('Cat Food', 'groceries')), isNull);
    });
  });

  group('названия', () {
    test('известное название переводится', () {
      expect(localizeProduct(raw('Apple', 'groceries'))!.title, 'Яблоки');
      expect(localizeProduct(raw('Ice Cream', 'groceries'))!.title, 'Мороженое');
    });

    test('регистр и пробелы в названии не мешают', () {
      expect(localizeProduct(raw('  BEEF steak ', 'groceries'))!.title, 'Говяжий стейк');
    });

    test('у ноутбуков, смартфонов и планшетов добавляется тип', () {
      expect(
        localizeProduct(raw('Lenovo Yoga 920', 'laptops'))!.title,
        'Ноутбук Lenovo Yoga 920',
      );
      expect(
        localizeProduct(raw('iPhone 13 Pro', 'smartphones'))!.title,
        'Смартфон iPhone 13 Pro',
      );
      expect(
        localizeProduct(raw('iPad Mini', 'tablets'))!.title,
        'Планшет iPad Mini',
      );
    });

    test('незнакомое название остаётся как есть', () {
      expect(localizeProduct(raw('Something New', 'beauty'))!.title, 'Something New');
    });
  });

  group('цена', () {
    test('доллары пересчитываются в рубли и округляются', () {
      expect(localizeProduct(raw('Apple', 'groceries', 1.0))!.price, usdToRub);
      expect(
        localizeProduct(raw('Milk', 'groceries', 2.49))!.price,
        (2.49 * usdToRub).roundToDouble(),
      );
    });

    test('остальные поля сохраняются', () {
      const source = Product(
        id: 7,
        title: 'Apple',
        category: 'groceries',
        price: 2,
        rating: 4.5,
        stock: 10,
        brand: 'Farm',
        thumbnail: 'https://x/t.jpg',
      );

      final result = localizeProduct(source)!;

      expect(result.id, 7);
      expect(result.rating, 4.5);
      expect(result.stock, 10);
      expect(result.brand, 'Farm');
      expect(result.thumbnail, 'https://x/t.jpg');
    });
  });

  group('репозиторий', () {
    test('убирает лишние товары и переводит остальные', () async {
      const body = '''
{"products":[
 {"id":1,"title":"Apple","category":"groceries","price":1},
 {"id":2,"title":"Annibale Colombo Sofa","category":"furniture","price":100},
 {"id":3,"title":"Football","category":"sports-accessories","price":2}
]}
''';
      final api = ProductApiClient(
        client: MockClient((_) async => http.Response(
              body,
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );

      final products = await ProductRepository(api).getProducts();

      expect(products.map((p) => p.title), ['Яблоки', 'Футбольный мяч']);
      expect(products.map((p) => p.category), ['fruits', 'sports']);
      expect(products.first.price, usdToRub);
    });
  });
}
