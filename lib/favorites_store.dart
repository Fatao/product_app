import 'package:shared_preferences/shared_preferences.dart';

// Дополнительное задание: избранное.
// Здесь хранятся только номера (id) избранных продуктов.
abstract class FavoritesStore {
  Future<Set<int>> load();
  Future<void> save(Set<int> ids);
}

// Сохраняет на устройстве, поэтому избранное остаётся после перезапуска
class SharedPrefsFavoritesStore implements FavoritesStore {
  static const _key = 'favorite_ids';

  @override
  Future<Set<int>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_key) ?? [];
      return saved.map(int.parse).toSet();
    } catch (_) {
      // сломанные данные не должны ломать приложение
      return {};
    }
  }

  @override
  Future<void> save(Set<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, ids.map((id) => '$id').toList());
    } catch (_) {
      // не получилось сохранить — ничего страшного
    }
  }
}

// Хранит в памяти, нужен для тестов
class MemoryFavoritesStore implements FavoritesStore {
  MemoryFavoritesStore([Set<int> initial = const {}]) : _ids = {...initial};

  Set<int> _ids;

  @override
  Future<Set<int>> load() async => {..._ids};

  @override
  Future<void> save(Set<int> ids) async {
    _ids = {...ids};
  }
}
