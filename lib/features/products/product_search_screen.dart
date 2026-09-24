import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/category_count.dart';
import '../../models/product.dart';
import 'product_detail_screen.dart';
import 'products_repository.dart';

class ProductSearchScreen extends ConsumerStatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  ConsumerState<ProductSearchScreen> createState() =>
      _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final nearEnd =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 400;
    if (nearEnd) {
      ref.read(productSearchProvider.notifier).loadMore();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(productSearchProvider.notifier).search(
            q: value,
            category: _selectedCategory,
          );
    });
  }

  void _onCategorySelected(String? slug) {
    setState(() {
      _selectedCategory = _selectedCategory == slug ? null : slug;
    });
    ref.read(productSearchProvider.notifier).search(
          q: _queryController.text,
          category: _selectedCategory,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search products…',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleMedium,
          onChanged: _onQueryChanged,
        ),
      ),
      body: Column(
        children: [
          _CategoryFilterRow(
            categoryCounts: state.valueOrNull?.categoryCounts ?? const [],
            selected: _selectedCategory,
            onSelected: _onCategorySelected,
          ),
          Expanded(
            child: state.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                error: error,
                onRetry: () => ref.read(productSearchProvider.notifier).search(
                      q: _queryController.text,
                      category: _selectedCategory,
                    ),
              ),
              data: (data) {
                if (data.products.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: data.products.length + (data.loadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index >= data.products.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return _ProductRow(product: data.products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterRow extends ConsumerWidget {
  const _CategoryFilterRow({
    required this.categoryCounts,
    required this.selected,
    required this.onSelected,
  });

  final List<CategoryCount> categoryCounts;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return categories.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        final counts = {
          for (final c in categoryCounts) c.category.slug: c.count,
        };

        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = list[index];
              final count = counts[category.slug];
              final label = count != null
                  ? '${category.name} ($count)'
                  : category.name;

              return ChoiceChip(
                label: Text(label),
                selected: selected == category.slug,
                onSelected: (_) => onSelected(category.slug),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(product.name, style: theme.textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(product.category.name, style: theme.textTheme.bodySmall),
            const SizedBox(width: 8),
            if (!product.inStock)
              Text(
                'Out of stock',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
      trailing: Text(
        Format.price(product.price),
        style: theme.textTheme.titleMedium,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No products match your search.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  String get _message {
    if (error is NetworkException) {
      return 'Could not connect to the server.\n'
          'Check that pulpe-api is running.';
    }
    if (error is ApiException) {
      return (error as ApiException).message;
    }
    return 'An unexpected error occurred.';
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}
