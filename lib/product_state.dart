import 'package:flutter/foundation.dart';

import 'favorites_store.dart';
import 'product.dart';
import 'product_api_client.dart';
import 'product_repository.dart';

enum LoadStatus { loading, success, error }

enum SortOrder { byDefault, nameAsc, priceAsc, priceDesc, ratingDesc }

// Что сейчас на экране: загрузка, ошибка или каталог, а также всё, что
// выбрал пользователь: поиск, категория, сортировка, избранное.
class ProductState extends ChangeNotifier {
  ProductState(this._repository, this._favoritesStore);

  final ProductRepository _repository;
  final FavoritesStore _favoritesStore;

  LoadStatus status = LoadStatus.loading;
  String? errorMessage;

  List<Product> allProducts = [];
  Set<int> favoriteIds = {};

  String searchQuery = '';
  String? selectedCategory; // null — показываем все категории
  bool onlyFavorites = false;
  SortOrder sortOrder = SortOrder.byDefault;

  bool _disposed = false;

  Future<void> load() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      favoriteIds = await _favoritesStore.load();
      allProducts = await _repository.getProducts();
      status = LoadStatus.success;
    } on ProductException catch (error) {
      errorMessage = error.message;
      status = LoadStatus.error;
    } catch (_) {
      errorMessage = 'Произошла непредвиденная ошибка.';
      status = LoadStatus.error;
    }

    if (_disposed) return;
    notifyListeners();
  }

  // Категории, которые есть в загруженных товарах
  List<String> get categories {
    final codes = allProducts.map((product) => product.category).toSet();
    return codes.toList()..sort();
  }

  // Список после поиска, фильтров и сортировки. Именно его рисует экран.
  List<Product> get visibleProducts {
    final query = searchQuery.trim().toLowerCase();

    final result = allProducts.where((product) {
      if (selectedCategory != null && product.category != selectedCategory) {
        return false;
      }
      if (onlyFavorites && !favoriteIds.contains(product.id)) {
        return false;
      }
      return product.title.toLowerCase().contains(query);
    }).toList();

    switch (sortOrder) {
      case SortOrder.byDefault:
        break; // оставляем порядок из API
      case SortOrder.nameAsc:
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case SortOrder.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOrder.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
      case SortOrder.ratingDesc:
        // у товаров без рейтинга -1, поэтому они оказываются в конце
        result.sort((a, b) => (b.rating ?? -1).compareTo(a.rating ?? -1));
    }
    return result;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    sortOrder = order;
    notifyListeners();
  }

  void toggleOnlyFavorites() {
    onlyFavorites = !onlyFavorites;
    notifyListeners();
  }

  bool isFavorite(Product product) => favoriteIds.contains(product.id);

  void toggleFavorite(Product product) {
    if (favoriteIds.contains(product.id)) {
      favoriteIds.remove(product.id);
    } else {
      favoriteIds.add(product.id);
    }
    notifyListeners();
    _favoritesStore.save(favoriteIds);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
