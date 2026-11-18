import 'product.dart';
import 'product_api_client.dart';
import 'product_localizer.dart';

// Состояние просит у репозитория список продуктов и не знает, откуда он берётся
// и как выглядит ответ API. Репозиторий приводит товары к виду для экрана:
// русские названия, цены в рублях, категории приложения.
class ProductRepository {
  ProductRepository(
    this._api, {
    Product? Function(Product)? localizer,
  }) : _localizer = localizer ?? localizeProduct; // в тестах можно подменить

  final ProductApiClient _api;
  final Product? Function(Product) _localizer;

  // Уже загруженный список. Если он есть, повторно в сеть не ходим.
  List<Product>? _loaded;

  Future<List<Product>> getProducts() async {
    final loaded = _loaded;
    if (loaded != null) return loaded;

    final rawProducts = await _api.fetchProducts();

    final products = <Product>[];
    for (final raw in rawProducts) {
      final product = _localizer(raw);
      // null — товар не подходит ни под одну нашу категорию
      if (product != null) products.add(product);
    }

    _loaded = products;
    return products;
  }
}
