import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_dashboard/models/admin_product.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_data_table.dart';
import 'package:admin_dashboard/widgets/admin_product_image.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _database = AdminDatabase();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminProduct> _filter(List<AdminProduct> products) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _delete(AdminProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          '"${product.name}" will be removed from the shared Firestore '
          'catalog. Existing orders are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _database.deleteProduct(product.id);
      if (!mounted) return;
      _showMessage('${product.name} deleted.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not delete product. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminProduct>>(
      stream: _database.watchProducts(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <AdminProduct>[];
        final products = _filter(all);
        final loading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          children: [
            AdminPageHeader(
              title: 'Products',
              subtitle: 'The catalog customers see in the LUNTI mobile app.',
              trailing: FilledButton.icon(
                onPressed: () => context.go('/products/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add product'),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Search by name or category',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${products.length} of ${all.length} products',
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (snapshot.hasError)
              _ErrorCard(message: snapshot.error.toString())
            else if (loading)
              const AdminCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (products.isEmpty)
              AdminEmptyState(
                icon: Icons.inventory_2_outlined,
                title: all.isEmpty ? 'No products yet' : 'No matching products',
                message: all.isEmpty
                    ? 'Add your first bamboo piece to publish it to the shop.'
                    : 'Try a different name or category.',
              )
            else
              AdminCard(
                padding: EdgeInsets.zero,
                child: AdminDataTable(
                  columns: const [
                    AdminTableColumn('Product'),
                    AdminTableColumn('Category'),
                    AdminTableColumn('Price'),
                    AdminTableColumn('Stock'),
                    AdminTableColumn('Engraving'),
                    AdminTableColumn('Actions'),
                  ],
                  rows: [
                    for (final product in products)
                      AdminTableRow([
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Row(
                            children: [
                              _ProductThumb(product: product),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (product.note.isNotEmpty)
                                      Text(
                                        product.note,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AdminColors.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CategoryBadge(category: product.category),
                        Text(formatPeso(product.price)),
                        _StockLabel(stock: product.stock),
                        product.supportsEngraving
                            ? Text(
                                '+${formatPeso(product.engravingPrice)}',
                                style: const TextStyle(
                                  color: AdminColors.success,
                                ),
                              )
                            : const Text(
                                'Not offered',
                                style: TextStyle(
                                  color: AdminColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit ${product.name}',
                              onPressed: () =>
                                  context.go('/products/edit/${product.id}'),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Delete ${product.name}',
                              onPressed: () => _delete(product),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AdminColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ]),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});

  final AdminProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdminProductImage(
        image: product.imagePath,
        fallbackIcon: Icons.spa_outlined,
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final label = category.isEmpty
        ? 'Uncategorised'
        : category[0].toUpperCase() + category.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _StockLabel extends StatelessWidget {
  const _StockLabel({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final low = stock <= 5;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: low ? AdminColors.warning : AdminColors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$stock',
          style: TextStyle(
            color: low ? AdminColors.warning : AdminColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load products',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
