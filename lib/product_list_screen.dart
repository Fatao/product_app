import 'package:flutter/material.dart';

import 'category_names.dart';
import 'product.dart';
import 'product_detail_screen.dart';
import 'product_format.dart';
import 'product_image.dart';
import 'product_state.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.productState});

  final ProductState productState;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.productState.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetails(Product product) {
    // На экран подробностей передаём сам объект продукта
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          productState: widget.productState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.productState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Продукты',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                key: const ValueKey('favorites_filter'),
                tooltip: 'Только избранное',
                icon: Icon(
                  state.onlyFavorites ? Icons.favorite : Icons.favorite_border,
                  color: state.onlyFavorites ? Colors.red : null,
                ),
                onPressed: state.toggleOnlyFavorites,
              ),
              _SortMenu(state: state),
            ],
          ),
          body: Column(
            children: [
              _SearchField(controller: _searchController, state: state),
              _CategoryChips(state: state),
              Expanded(child: _buildBody(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ProductState state) {
    switch (state.status) {
      case LoadStatus.loading:
        return const Center(
          child: CircularProgressIndicator(key: ValueKey('loading')),
        );

      case LoadStatus.error:
        return _ErrorMessage(
          message: state.errorMessage ?? 'Ошибка',
          onRetry: state.load,
        );

      case LoadStatus.success:
        final products = state.visibleProducts;
        if (products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Ничего не найдено',
                key: ValueKey('empty_message'),
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        return ListView.builder(
          key: const ValueKey('product_list'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              isFavorite: state.isFavorite(product),
              onTap: () => _openDetails(product),
              onFavoriteTap: () => state.toggleFavorite(product),
            );
          },
        );
    }
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.state});

  final ProductState state;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOrder>(
      key: const ValueKey('sort_menu'),
      tooltip: 'Сортировка',
      icon: const Icon(Icons.sort),
      initialValue: state.sortOrder,
      onSelected: state.setSortOrder,
      itemBuilder: (context) => [
        _item(SortOrder.byDefault, 'По умолчанию'),
        _item(SortOrder.nameAsc, 'Название: A–Z'),
        _item(SortOrder.priceAsc, 'Цена: по возрастанию'),
        _item(SortOrder.priceDesc, 'Цена: по убыванию'),
        _item(SortOrder.ratingDesc, 'Рейтинг: сначала высокий'),
      ],
    );
  }

  PopupMenuItem<SortOrder> _item(SortOrder order, String text) {
    return CheckedPopupMenuItem(
      value: order,
      checked: state.sortOrder == order,
      child: Text(text),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.state});

  final TextEditingController controller;
  final ProductState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        key: const ValueKey('search_field'),
        controller: controller,
        onChanged: state.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Поиск продуктов...',
          prefixIcon: const Icon(Icons.search),
          // крестик появляется, когда в поле что-то введено
          suffixIcon: state.searchQuery.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('clear_search'),
                  tooltip: 'Очистить',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    state.setSearchQuery('');
                  },
                ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.state});

  final ProductState state;

  @override
  Widget build(BuildContext context) {
    // Пока товары не загрузились, категорий нет — показываем только «Все»
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _chip(
            key: 'category_all',
            label: 'Все',
            selected: state.selectedCategory == null,
            onTap: () => state.selectCategory(null),
          ),
          for (final code in state.categories)
            _chip(
              key: 'category_$code',
              label: categoryLabel(code),
              selected: state.selectedCategory == code,
              onTap: () => state.selectCategory(code),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: ValueKey(key),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: Colors.blue,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
        shape: const StadiumBorder(),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final Product product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final rating = product.rating;

    return InkWell(
      key: ValueKey('product_${product.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ProductImage(url: product.thumbnail, size: 72),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    categoryLabel(product.category),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatPrice(product.price),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // рейтинг показываем, только если API его прислал
                      if (rating != null) ...[
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(formatRating(rating)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('favorite_${product.id}'),
              tooltip: 'В избранное',
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: onFavoriteTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              key: const ValueKey('error_message'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('retry_button'),
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
