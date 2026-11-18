import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:product_app/category_names.dart';
import 'package:product_app/favorites_store.dart';
import 'package:product_app/product_api_client.dart';
import 'package:product_app/product_format.dart';
import 'package:product_app/product_state.dart';

import 'fakes.dart';

void main() {
  late FakeProductApi api;
  late MemoryFavoritesStore store;
  late ProductState state;

  List<String> titles() => state.visibleProducts.map((p) => p.title).toList();

  setUp(() {
    api = FakeProductApi();
    store = MemoryFavoritesStore();
    state = ProductState(testRepository(api), store);
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
      state.setSearchQuery('ок');

      expect(titles(), ['Яблоки', 'Молоко']);
    });

    test('регистр не важен', () {
      state.setSearchQuery('ЯБЛОКИ');

      expect(titles(), ['Яблоки']);
    });

    test('пробелы по краям не мешают', () {
      state.setSearchQuery('  молоко ');

      expect(titles(), ['Молоко']);
    });

    test('пустой результат: статус успешный, список пуст', () {
      state.setSearchQuery('zzz');

      expect(state.status, LoadStatus.success);
      expect(state.visibleProducts, isEmpty);
    });

    test('пустая строка поиска показывает всё', () {
      state.setSearchQuery('молоко');
      state.setSearchQuery('');

      expect(state.visibleProducts.length, 6);
    });
  });

  group('категории', () {
    setUp(() async {
      await state.load();
    });

    test('чипы только для непустых категорий, в заданном порядке', () {
      expect(state.categories, ['fruits', 'beauty', 'food', 'laptops', 'phones']);
    });

    test('фильтр по категории', () {
      state.selectCategory('fruits');

      expect(titles(), ['Яблоки', 'Бананы']);
    });

    test('«Все» сбрасывает фильтр', () {
      state.selectCategory('fruits');
      state.selectCategory(null);

      expect(state.visibleProducts.length, 6);
    });

    test('поиск работает вместе с категорией', () {
      state.selectCategory('fruits');
      state.setSearchQuery('бан');

      expect(titles(), ['Бананы']);
    });

    test('в категории может ничего не найтись', () {
      state.selectCategory('laptops');
      state.setSearchQuery('молоко');

      expect(state.visibleProducts, isEmpty);
    });
  });

  group('сортировка', () {
    setUp(() async {
      await state.load();
    });

    test('по умолчанию порядок как в API', () {
      expect(titles().first, 'Яблоки');
      expect(titles().last, 'Крем для лица');
    });

    test('по названию', () {
      state.setSortOrder(SortOrder.nameAsc);

      expect(titles(), [
        'Бананы', 'Крем для лица', 'Молоко', 'Ноутбук Pro', 'Смартфон X', 'Яблоки',
      ]);
    });

    test('по цене: по возрастанию', () {
      state.setSortOrder(SortOrder.priceAsc);

      expect(titles(), [
        'Бананы', 'Молоко', 'Яблоки', 'Крем для лица', 'Смартфон X', 'Ноутбук Pro',
      ]);
    });

    test('по цене: по убыванию', () {
      state.setSortOrder(SortOrder.priceDesc);

      expect(titles().first, 'Ноутбук Pro');
      expect(titles().last, 'Бананы');
    });

    test('по рейтингу: товар без рейтинга в конце', () {
      state.setSortOrder(SortOrder.ratingDesc);

      expect(titles(), [
        'Яблоки', 'Бананы', 'Молоко', 'Ноутбук Pro', 'Крем для лица', 'Смартфон X',
      ]);
    });

    test('сортировка работает вместе с фильтром', () {
      state.selectCategory('fruits');
      state.setSortOrder(SortOrder.priceAsc);

      expect(titles(), ['Бананы', 'Яблоки']);
    });
  });

  group('избранное (дополнительное задание)', () {
    setUp(() async {
      await state.load();
    });

    test('добавление и удаление', () {
      final apples = state.allProducts.first;

      state.toggleFavorite(apples);
      expect(state.isFavorite(apples), isTrue);

      state.toggleFavorite(apples);
      expect(state.isFavorite(apples), isFalse);
    });

    test('показ только избранного', () {
      state.toggleFavorite(state.allProducts[2]); // Молоко
      state.toggleOnlyFavorites();

      expect(titles(), ['Молоко']);

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
      final newState = ProductState(testRepository(api), saved);

      await newState.load();

      expect(newState.favoriteIds, {2, 4});
    });
  });

  group('форматирование', () {
    test('цена в рублях с пробелами между тысячами', () {
      expect(formatPrice(150), '150 ₽');
      expect(formatPrice(1790), '1 790 ₽');
      expect(formatPrice(85000), '85 000 ₽');
    });

    test('цена округляется до рубля', () {
      expect(formatPrice(83.6), '84 ₽');
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
      expect(categoryLabel('fruits'), 'Фрукты');
      expect(categoryLabel('women'), 'Женская одежда');
      expect(categoryLabel('phones'), 'Телефоны');
    });
  });
}
