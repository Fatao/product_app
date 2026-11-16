import 'package:flutter/material.dart';

// Картинка продукта. Пока грузится — индикатор, если не загрузилась
// или адреса нет — серая заглушка, чтобы экран не ломался.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.size,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );

    if (url.isEmpty) return placeholder;

    return Image.network(
      url,
      width: size,
      height: size,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: size,
          height: size,
          color: Colors.grey.shade100,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
