import 'product.dart';
import 'product_api_client.dart';

// Состояние просит у репозитория список продуктов и не знает, откуда он берётся.
class ProductRepository {
  ProductRepository(this._api);

  final ProductApiClient _api;

  // Уже загруженный список. Если он есть, повторно в сеть не ходим.
  List<Product>? _loaded;

  Future<List<Product>> getProducts() async {
    final loaded = _loaded;
    if (loaded != null) return loaded;

    final products = await _api.fetchProducts();
    _loaded = products;
    return products;
  }
}
