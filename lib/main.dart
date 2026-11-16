import 'package:flutter/material.dart';

import 'favorites_store.dart';
import 'product_api_client.dart';
import 'product_list_screen.dart';
import 'product_repository.dart';
import 'product_state.dart';

void main() {
  final repository = ProductRepository(ProductApiClient());
  final state = ProductState(repository, SharedPrefsFavoritesStore());
  runApp(ProductApp(productState: state));
}

class ProductApp extends StatelessWidget {
  const ProductApp({super.key, required this.productState});

  final ProductState productState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Справочник продуктов',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: ProductListScreen(productState: productState),
    );
  }
}
