import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/product.dart';
import 'products_repository.dart';

final productDetailProvider =
    FutureProvider.family<Product, String>((ref, id) {
  return ref.watch(productsRepositoryProvider).detail(id);
});

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('Could not load the product.'),
          ),
        ),
        data: (product) => _Content(product: product),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(product.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(product.sku, style: theme.textTheme.bodySmall),
        const SizedBox(height: 24),
        Text(
          Format.price(product.price),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        _DataRow(label: 'Category', value: product.category.name),
        _DataRow(
          label: 'Stock',
          value: product.inStock
              ? '${product.stock} units'
              : 'Out of stock',
        ),
        const SizedBox(height: 24),
        Text('Description', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(product.description, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}
