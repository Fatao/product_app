import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:product_app/category_names.dart';
import 'package:product_app/favorites_store.dart';
import 'package:product_app/product_api_client.dart';
import 'package:product_app/product_format.dart';
import 'package:product_app/product_repository.dart';
import 'package:product_app/product_state.dart';

import 'fakes.dart';

void main() {
  late FakeProductApi api;
  late MemoryFavoritesStore store;
  late ProductState state;

  ProductState makeState() {
    return ProductState(ProductRepository(api), store);
  }

  List<String> titles() => state.visibleProducts.map((p) => p.title).toList();

  setUp(() {
    api = FakeProductApi();
    store = MemoryFavoritesStore();
    state = makeState();
  });

  group('загрузка', () {
    test('список загружается', () async {
      await state.load();

      expect(state.status, LoadStatus.success);
      expect(state.allProducts.length, 6);
    });

    test('во время загрузки статус loading', () async {
      api.gate = Completer<void>();

      final future = state.load();
      expect(state.status, LoadStatus.loading);

      api.gate!.complete();
      await future;
      expect(state.status, LoadStatus.success);
    });

    test('ошибка сети', () async {
      api.error = const ProductException(
        ProductErrorType.noConnection,
        'Нет подключения к интернету.',
      );

      await state.load();

      expect(state.status, LoadStatus.error);
      expect(state.errorMessage, 'Нет подключения к интернету.');
    });

    test('после ошибки повторная загрузка может пройти', () async {
      api.error = const ProductException(ProductErrorType.timeout, 'Таймаут');
      await state.load();
      expect(state.status, LoadStatus.error);

      api.error = null;
      await state.load();

      expect(state.status, LoadStatus.success);
      expect(state.errorMessage, isNull);
    });

    test('уже загруженный список повторно из сети не берётся', () async {
      await state.load();
      await state.load();

      expect(api.requestCount, 1);
    });

    test('большой список', () async {
      api.products = manyProducts(500);

      await state.load();

      expect(state.visibleProducts.length, 500);
    });
  });

  group('поиск', () {
    setUp(() async {
      await state.load();
    });

    test('по части названия', () {
      state.setSearchQuery('ap');

      expect(titles(), ['Apple', 'Laptop Pro']);
    });

    test('регистр не важен', () {
      state.setSearchQuery('APPLE');

      expect(titles(), ['Apple']);
    });

    test('пробелы по краям не мешают', () {
      state.setSearchQuery('  milk ');

      expect(titles(), ['Milk']);
    });

    test('пустой результат: статус успешный, список пуст', () {
      state.setSearchQuery('zzz');

      expect(state.status, LoadStatus.success);
      expect(state.visibleProducts, isEmpty);
    });

    test('пустая строка поиска показывает всё', () {
      state.setSearchQuery('milk');
      state.setSearchQuery('');

      expect(state.visibleProducts.length, 6);
    });
  });

  group('категории', () {
    setUp(() async {
      await state.load();
    });

    test('список категорий без повторов, по алфавиту', () {
      expect(state.categories, ['beauty', 'groceries', 'laptops', 'smartphones']);
    });

    test('фильтр по категории', () {
      state.selectCategory('groceries');

      expect(titles(), ['Apple', 'Banana', 'Milk']);
    });

    test('«Все» сбрасывает фильтр', () {
      state.selectCategory('groceries');
      state.selectCategory(null);

      expect(state.visibleProducts.length, 6);
    });

    test('поиск работает вместе с категорией', () {
      state.selectCategory('groceries');
      state.setSearchQuery('a');

      expect(titles(), ['Apple', 'Banana']);
    });

    test('в категории может ничего не найтись', () {
      state.selectCategory('laptops');
      state.setSearchQuery('milk');

      expect(state.visibleProducts, isEmpty);
    });
  });

  group('сортировка', () {
    setUp(() async {
      await state.load();
    });

    test('по умолчанию порядок как в API', () {
      expect(titles().first, 'Apple');
      expect(titles().last, 'Face Cream');
    });

    test('по названию', () {
      state.setSortOrder(SortOrder.nameAsc);

      expect(titles(), [
        'Apple', 'Banana', 'Face Cream', 'Laptop Pro', 'Milk', 'Smartphone X',
      ]);
    });

    test('по цене: по возрастанию', () {
      state.setSortOrder(SortOrder.priceAsc);

      expect(titles(), [
        'Banana', 'Apple', 'Milk', 'Face Cream', 'Smartphone X', 'Laptop Pro',
      ]);
    });

    test('по цене: по убыванию', () {
      state.setSortOrder(SortOrder.priceDesc);

      expect(titles().first, 'Laptop Pro');
      expect(titles().last, 'Banana');
    });

    test('по рейтингу: товар без рейтинга в конце', () {
      state.setSortOrder(SortOrder.ratingDesc);

      expect(titles(), [
        'Apple', 'Banana', 'Milk', 'Laptop Pro', 'Face Cream', 'Smartphone X',
      ]);
    });

    test('сортировка работает вместе с фильтром', () {
      state.selectCategory('groceries');
      state.setSortOrder(SortOrder.priceDesc);

      expect(titles(), ['Milk', 'Apple', 'Banana']);
    });
  });

  group('избранное (дополнительное задание)', () {
    setUp(() async {
      await state.load();
    });

    test('добавление и удаление', () {
      final apple = state.allProducts.first;

      state.toggleFavorite(apple);
      expect(state.isFavorite(apple), isTrue);

      state.toggleFavorite(apple);
      expect(state.isFavorite(apple), isFalse);
    });

    test('показ только избранного', () {
      state.toggleFavorite(state.allProducts[2]); // Milk
      state.toggleOnlyFavorites();

      expect(titles(), ['Milk']);

      state.toggleOnlyFavorites();
      expect(state.visibleProducts.length, 6);
    });

    test('избранное сохраняется в хранилище', () async {
      state.toggleFavorite(state.allProducts.first);
      await Future<void>.delayed(Duration.zero);

      expect(await store.load(), {1});
    });

    test('при запуске избранное читается из хранилища', () async {
      final saved = MemoryFavoritesStore({2, 4});
      final newState = ProductState(ProductRepository(api), saved);

      await newState.load();

      expect(newState.favoriteIds, {2, 4});
    });
  });

  group('форматирование', () {
    test('цена', () {
      expect(formatPrice(1.9), '\$1.90');
      expect(formatPrice(999), '\$999.00');
    });

    test('рейтинг', () {
      expect(formatRating(4.8), '4.8');
      expect(formatRating(4), '4.0');
    });

    test('наличие', () {
      expect(formatStock(50), 'В наличии: 50 шт.');
      expect(formatStock(0), 'Нет в наличии');
    });

    test('названия категорий', () {
      expect(categoryLabel('groceries'), 'Еда');
      expect(categoryLabel('new-things'), 'New things');
    });
  });
}
