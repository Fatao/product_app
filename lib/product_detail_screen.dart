import 'package:flutter/material.dart';

import 'category_names.dart';
import 'product.dart';
import 'product_format.dart';
import 'product_image.dart';
import 'product_state.dart';

// Экран подробной информации. Продукт сюда передают целиком (объектом),
// а ProductState нужен только для кнопки «избранное».
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.productState,
  });

  final Product product;
  final ProductState productState;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImage = 0; // какая картинка показана крупно

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);
    final rating = product.rating;
    final stock = product.stock;
    final discount = product.discountPercentage;

    // у некоторых товаров нет списка картинок — тогда берём маленькую
    final images = product.images.isNotEmpty
        ? product.images
        : [if (product.thumbnail.isNotEmpty) product.thumbnail];
    final bigImage = images.isEmpty ? '' : images[_selectedImage];

    return Scaffold(
      appBar: AppBar(
        title: const Text('О продукте'),
        actions: [
          ListenableBuilder(
            listenable: widget.productState,
            builder: (context, _) {
              final isFavorite = widget.productState.isFavorite(product);
              return IconButton(
                key: const ValueKey('detail_favorite'),
                tooltip: 'В избранное',
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: () => widget.productState.toggleFavorite(product),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ProductImage(url: bigImage, size: 260, fit: BoxFit.contain),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedImage = index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: index == _selectedImage
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ProductImage(url: images[index], size: 56),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            product.title,
            key: const ValueKey('detail_title'),
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            categoryLabel(product.category),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                formatPrice(product.price),
                key: const ValueKey('detail_price'),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (discount != null && discount > 0) ...[
                const SizedBox(width: 12),
                Text(
                  'Скидка ${discount.round()}%',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
              const Spacer(),
              if (rating != null) ...[
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  formatRating(rating),
                  key: const ValueKey('detail_rating'),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ],
          ),
          if (stock != null) ...[
            const SizedBox(height: 8),
            Text(
              formatStock(stock),
              style: TextStyle(color: stock > 0 ? Colors.green : Colors.red),
            ),
          ],
          const Divider(height: 32),
          Text(
            'О товаре',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Категория', value: categoryLabel(product.category)),
          if (product.brand != null)
            _InfoRow(label: 'Бренд', value: product.brand!),
          _InfoRow(label: 'Код товара', value: '${product.id}'),
        ],
      ),
    );
  }
}

// Строка «название — значение» в блоке «О товаре»
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
