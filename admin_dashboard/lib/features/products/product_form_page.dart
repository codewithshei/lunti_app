import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_dashboard/models/admin_product.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/services/product_image_service.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_product_image.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';
import 'package:admin_dashboard/widgets/product_photo_preview.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  static const _categories = <(String, String)>[
    ('miniature', 'Miniature'),
    ('customized', 'Customized'),
    ('plaques', 'Plaques'),
    ('engraving', 'Engraving'),
  ];

  final AdminDatabase _database = AdminDatabase();
  final ProductImageService _imageService = ProductImageService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _engravingPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _imagePathController = TextEditingController();
  final _materialController = TextEditingController(text: 'Bamboo');
  final _originController = TextEditingController(
    text: 'Cardona, Rizal, Philippines',
  );
  final _careController = TextEditingController(text: 'Wipe gently; keep dry.');

  String _category = 'customized';
  bool _offersEngraving = false;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;
  DateTime? _createdAt;
  late final String _productId;

  PreparedImage? _preparedImage;
  Uint8List? _pendingBytes;
  String? _pendingFilename;
  int _pendingOriginalBytes = 0;
  bool _pendingWasCompressed = false;
  bool _processingImage = false;
  String? _imageError;

  /// The photo already stored on the product, kept so a save that never picks a
  /// new image does not wipe it.
  String? _existingImagePath;
  Uint8List? _existingImageBytes;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _productId = widget.productId ?? _database.newProductId();
    if (_isEditing) {
      _load();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _engravingPriceController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _imagePathController.dispose();
    _materialController.dispose();
    _originController.dispose();
    _careController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final product = await _database.getProduct(widget.productId!);
      if (!mounted) return;
      if (product == null) {
        setState(() => _loadError = 'This product no longer exists.');
        return;
      }
      _nameController.text = product.name;
      _priceController.text = '${product.price}';
      _stockController.text = '${product.stock}';
      _engravingPriceController.text = '${product.engravingPrice}';
      _descriptionController.text = product.description;
      _noteController.text = product.note;
      _imagePathController.text = product.imagePath;
      _materialController.text = product.material;
      _originController.text = product.origin;
      _careController.text = product.care;
      // A data URL is far too long for the text field; the preview shows it.
      _imagePathController.text = product.imagePath.startsWith('data:image/')
          ? ''
          : product.imagePath;
      _existingImagePath = product.imagePath;
      _existingImageBytes = decodeBase64Image(product.imagePath);
      setState(() {
        _category = _categories.any((entry) => entry.$1 == product.category)
            ? product.category
            : 'customized';
        _offersEngraving = product.supportsEngraving;
        _createdAt = product.createdAt;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = 'Could not load this product.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Opens the platform file picker, validates the size and compresses photos
  /// over 1MB before they are uploaded on save.
  Future<void> _pickImage() async {
    setState(() => _imageError = null);

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _imageError = 'Could not open the file picker.');
      return;
    }

    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      setState(
        () => _imageError = 'That file could not be read. Try another image.',
      );
      return;
    }

    setState(() {
      _processingImage = true;
      _pendingFilename = file.name;
      _pendingOriginalBytes = bytes.length;
      // The picked photo replaces any URL typed into the field.
      _imagePathController.clear();
    });

    try {
      final prepared = await _imageService.prepare(bytes);
      if (!mounted) return;
      setState(() {
        _preparedImage = prepared;
        _pendingBytes = prepared.bytes;
        _pendingOriginalBytes = prepared.originalBytes;
        _pendingWasCompressed = prepared.wasCompressed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _imageError = 'Could not process that image. Try another file.',
      );
    } finally {
      if (mounted) setState(() => _processingImage = false);
    }
  }

  void _clearImage() {
    setState(() {
      _preparedImage = null;
      _pendingBytes = null;
      _pendingFilename = null;
      _pendingOriginalBytes = 0;
      _pendingWasCompressed = false;
      _existingImagePath = null;
      _existingImageBytes = null;
      _imagePathController.clear();
      _imageError = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    var gallery = _preparedImage != null
        ? _imageService.toDataUrl(_preparedImage!)
        : (_imagePathController.text.trim().isNotEmpty
              ? _imagePathController.text.trim()
              : (_existingImagePath ?? ''));

    // Duplicating the base64 in `gallery` would double the document size; the
    // mobile app falls back to `imagePath` when the gallery is empty.
    final isEmbedded = gallery.startsWith('data:image/');

    final product = AdminProduct(
      id: _productId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      price: int.parse(_priceController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      engravingPrice: _offersEngraving
          ? int.tryParse(_engravingPriceController.text.trim()) ?? 0
          : 0,
      availableEngravings: _offersEngraving
          ? const ['Natural', 'Engraved']
          : const <String>[],
      imagePath: gallery,
      note: _noteController.text.trim(),
      eyebrow: 'Bamboo everyday',
      material: _materialController.text.trim(),
      origin: _originController.text.trim(),
      care: _careController.text.trim(),
      gallery: isEmbedded || gallery.isEmpty
          ? const <String>[]
          : <String>[gallery],
      createdAt: _createdAt,
    );

    try {
      await _database.saveProduct(product);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? '${product.name} updated.'
                  : '${product.name} added to the catalog.',
            ),
          ),
        );
      context.go('/products');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not save product. Please try again.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/products'),
              child: const Text('Back to products'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        children: [
          AdminPageHeader(
            title: _isEditing ? 'Edit product' : 'Add product',
            subtitle: _isEditing
                ? 'Changes publish to the mobile catalog immediately.'
                : 'Create a piece for the shared Firestore catalog.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: _saving ? null : () => context.go('/products'),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AdminColors.cream,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(_saving ? 'Saving...' : 'Save product'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Basics'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    hintText: 'e.g. Bamboo Tumbler',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a product name.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a short description.'
                      : null,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        dropdownColor: AdminColors.surface,
                        items: [
                          for (final (value, label) in _categories)
                            DropdownMenuItem(value: value, child: Text(label)),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (\u20B1)',
                          prefixText: '\u20B1 ',
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Card note',
                    hintText: 'e.g. Natural bamboo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Photo'),
                const SizedBox(height: 14),
                if (_preparedImage != null) ...[
                  ProductPhotoPreview(
                    bytes: _pendingBytes!,
                    filename: _pendingFilename ?? 'Selected image',
                    originalBytes: _pendingOriginalBytes,
                    preparedBytes: _preparedImage!.bytes.length,
                    wasCompressed: _pendingWasCompressed,
                  ),
                  const SizedBox(height: 14),
                ] else if (_existingImageBytes != null) ...[
                  ProductPhotoPreview(
                    bytes: _existingImageBytes!,
                    filename: 'Current photo',
                    originalBytes: _existingImageBytes!.length,
                    preparedBytes: _existingImageBytes!.length,
                    wasCompressed: false,
                  ),
                  const SizedBox(height: 14),
                ],
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _processingImage ? null : _pickImage,
                      icon: _processingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file, size: 18),
                      label: Text(
                        _processingImage ? 'Processing...' : 'Upload image',
                      ),
                    ),
                    if (_preparedImage != null ||
                        (_existingImagePath ?? '').isNotEmpty)
                      TextButton.icon(
                        onPressed: _processingImage ? null : _clearImage,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _imagePathController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL or asset path',
                    hintText: 'https://... or assets/images/prod_name.jpg',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload a photo to store it in Firebase Storage, or paste an '
                  'https:// URL. Bundled mobile asset paths continue to work '
                  'for the sample catalog.',
                  style: TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                if (_imageError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _imageError!,
                    style: const TextStyle(
                      color: AdminColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: _SectionLabel('Engraving')),
                    Switch(
                      value: _offersEngraving,
                      onChanged: (value) =>
                          setState(() => _offersEngraving = value),
                    ),
                  ],
                ),
                Text(
                  _offersEngraving
                      ? 'Customers can choose Natural or Engraved and enter '
                            'the text to engrave.'
                      : 'This piece is sold as-is with no engraving option.',
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                if (_offersEngraving) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 220,
                    child: TextFormField(
                      controller: _engravingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Engraving price (\u20B1)',
                        prefixText: '\u20B1 ',
                      ),
                      validator: (value) {
                        if (!_offersEngraving) return null;
                        final parsed = int.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid price.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Craft details'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _materialController,
                  decoration: const InputDecoration(labelText: 'Material'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _originController,
                  decoration: const InputDecoration(labelText: 'Origin'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _careController,
                  decoration: const InputDecoration(labelText: 'Care'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _numberValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Enter a number.';
    if (parsed < 0) return 'Must be zero or more.';
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        color: AdminColors.muted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
