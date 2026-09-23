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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productSearchProvider);
    final notifier = ref.read(productSearchProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Search products')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setQueryText,
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                error: error,
                onRetry: notifier.retry,
              ),
              data: (data) {
                final result = data.result;
                if (result == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    _CategoryFilterList(
                      categoryCounts: result.categoryCounts,
                      selectedSlug: data.selectedCategorySlug,
                      onSelected: notifier.selectCategory,
                    ),
                    Expanded(
                      child: result.paged.items.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: result.paged.items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) => _ProductRow(
                                product: result.paged.items[index],
                              ),
                            ),
                    ),
                    _PaginationBar(
                      page: result.paged.page,
                      hasNext: result.paged.hasNext,
                      total: result.paged.total,
                      onPrevious: result.paged.page > 1
                          ? () => notifier.goToPage(result.paged.page - 1)
                          : null,
                      onNext: result.paged.hasNext
                          ? () => notifier.goToPage(result.paged.page + 1)
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterList extends StatelessWidget {
  const _CategoryFilterList({
    required this.categoryCounts,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<CategoryCount> categoryCounts;
  final String? selectedSlug;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedSlug == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final categoryCount in categoryCounts)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  '${categoryCount.category.name} (${categoryCount.count})',
                ),
                selected: selectedSlug == categoryCount.category.slug,
                onSelected: (_) => onSelected(categoryCount.category.slug),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.hasNext,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final bool hasNext;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page $page · $total results'),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
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
