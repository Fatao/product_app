import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_app/favorites_store.dart';
import 'package:product_app/main.dart';
import 'package:product_app/product_api_client.dart';
import 'package:product_app/product_state.dart';

import 'fakes.dart';

void main() {
  late FakeProductApi api;
  late ProductState state;

  setUp(() {
    api = FakeProductApi();
    state = ProductState(testRepository(api), MemoryFavoritesStore());
  });

  Future<void> openApp(WidgetTester tester) async {
    // размер как у телефона
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProductApp(productState: state));
    await tester.pumpAndSettle();
  }

  testWidgets('показывает заголовок, категории и продукты', (tester) async {
    await openApp(tester);

    expect(find.text('Продукты'), findsOneWidget);
    expect(find.byKey(const ValueKey('category_all')), findsOneWidget);
    expect(find.byKey(const ValueKey('category_fruits')), findsOneWidget);
    expect(find.text('Яблоки'), findsOneWidget);
    expect(find.text('Ноутбук Pro'), findsOneWidget);
    expect(find.text('150 ₽'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
  });

  testWidgets('во время загрузки виден индикатор', (tester) async {
    api.gate = Completer<void>();

    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProductApp(productState: state));
    await tester.pump();

    expect(find.byKey(const ValueKey('loading')), findsOneWidget);

    api.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('loading')), findsNothing);
    expect(find.text('Яблоки'), findsOneWidget);
  });

  testWidgets('поиск по названию', (tester) async {
    await openApp(tester);

    await tester.enterText(find.byKey(const ValueKey('search_field')), 'молоко');
    await tester.pump();

    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('Яблоки'), findsNothing);

    // крестик очищает поиск
    await tester.tap(find.byKey(const ValueKey('clear_search')));
    await tester.pump();
    expect(find.text('Яблоки'), findsOneWidget);
  });

  testWidgets('пустой результат поиска', (tester) async {
    await openApp(tester);

    await tester.enterText(find.byKey(const ValueKey('search_field')), 'zzz');
    await tester.pump();

    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(find.text('Яблоки'), findsNothing);
  });

  testWidgets('фильтр по категории', (tester) async {
    await openApp(tester);

    await tester.tap(find.byKey(const ValueKey('category_fruits')));
    await tester.pump();

    expect(find.text('Яблоки'), findsOneWidget);
    expect(find.text('Ноутбук Pro'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('category_all')));
    await tester.pump();
    expect(find.text('Ноутбук Pro'), findsOneWidget);
  });

  testWidgets('сортировка по цене', (tester) async {
    await openApp(tester);

    await tester.tap(find.byKey(const ValueKey('sort_menu')));
    await tester.pumpAndSettle();
    // нажимаем на сам пункт меню, а не на текст внутри него
    await tester.tap(find.widgetWithText(
      CheckedPopupMenuItem<SortOrder>,
      'Цена: по возрастанию',
    ));
    await tester.pumpAndSettle();

    // Бананы (90 ₽) теперь выше Яблок (150 ₽)
    final bananaTop = tester.getTopLeft(find.text('Бананы')).dy;
    final appleTop = tester.getTopLeft(find.text('Яблоки')).dy;
    expect(bananaTop, lessThan(appleTop));
  });

  testWidgets('открытие подробной информации', (tester) async {
    await openApp(tester);

    await tester.tap(find.byKey(const ValueKey('product_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('detail_title')), findsOneWidget);
    expect(find.text('Фрукты'), findsWidgets);
    expect(find.text('150 ₽'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('В наличии: 50 шт.'), findsOneWidget);

    // назад к каталогу
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('product_list')), findsOneWidget);
  });

  testWidgets('товар без рейтинга показывается без звезды', (tester) async {
    await openApp(tester);

    final phoneCard = find.byKey(const ValueKey('product_5'));
    expect(phoneCard, findsOneWidget);
    expect(
      find.descendant(of: phoneCard, matching: find.byIcon(Icons.star)),
      findsNothing,
    );
  });

  testWidgets('ошибка сети: сообщение и кнопка «Повторить»', (tester) async {
    api.error = const ProductException(
      ProductErrorType.noConnection,
      'Нет подключения к интернету.',
    );
    await openApp(tester);

    expect(find.text('Нет подключения к интернету.'), findsOneWidget);
    expect(find.byKey(const ValueKey('retry_button')), findsOneWidget);

    // интернет появился — нажимаем «Повторить»
    api.error = null;
    await tester.tap(find.byKey(const ValueKey('retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('retry_button')), findsNothing);
    expect(find.text('Яблоки'), findsOneWidget);
  });

  testWidgets('избранное: сердечко на карточке и фильтр', (tester) async {
    await openApp(tester);

    await tester.tap(find.byKey(const ValueKey('favorite_3')));
    await tester.pump();
    expect(state.favoriteIds, {3});

    await tester.tap(find.byKey(const ValueKey('favorites_filter')));
    await tester.pump();

    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('Яблоки'), findsNothing);
  });

  testWidgets('большой список прокручивается до конца', (tester) async {
    api.products = manyProducts(300);
    await openApp(tester);

    await tester.scrollUntilVisible(
      find.text('Товар 300'),
      600,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('product_list')),
        matching: find.byType(Scrollable),
      ),
      maxScrolls: 200,
    );

    expect(find.text('Товар 300'), findsOneWidget);
  });
}
