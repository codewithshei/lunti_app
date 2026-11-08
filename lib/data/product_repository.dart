import '../services/catalog_store.dart';
import 'sample_catalog.dart';

/// Seam for product data. The UI reads catalog content only through this
/// interface so screens never need to know whether products came from the
/// bundled sample data or from Firestore.
abstract class ProductRepository {
  Future<List<SampleCategory>> listCategories();

  Future<List<SampleProduct>> listProducts();

  Future<SampleProduct?> findById(String id);
}

class ProductRepositoryHolder {
  ProductRepositoryHolder._();

  static ProductRepository I = const CatalogProductRepository();
}

/// Firestore-backed implementation.
///
/// [CatalogStore] keeps a live `products` stream and falls back to the bundled
/// sample catalog whenever Firebase is unavailable (for example in widget
/// tests). Screens that need live updates listen to
/// `CatalogStore.instance.products` directly; this repository is the async
/// seam used by route builders.
class CatalogProductRepository implements ProductRepository {
  const CatalogProductRepository();

  @override
  Future<List<SampleCategory>> listCategories() async => sampleCategories;

  @override
  Future<List<SampleProduct>> listProducts() async =>
      List<SampleProduct>.unmodifiable(CatalogStore.instance.products.value);

  @override
  Future<SampleProduct?> findById(String id) async {
    for (final product in CatalogStore.instance.products.value) {
      if (product.id == id) return product;
    }
    return CatalogStore.instance.findById(id);
  }
}
