import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/product_provider.dart';
import '../../theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_cropper.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Products'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showProductDialog(context, ref, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppTheme.error))),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('No products yet. Add your first product!',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ProductRow(product: products[i]),
          );
        },
      ),
    );
  }

  void _showProductDialog(
      BuildContext context, WidgetRef ref, Product? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _ProductDialog(existing: existing),
      ),
    );
  }
}

// ─── Product Row ──────────────────────────────────────────────────────────────
class _ProductRow extends ConsumerWidget {
  final Product product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: product.imageBase64.isNotEmpty
                  ? _Base64Image(base64: product.imageBase64)
                  : Container(
                      color: AppTheme.surface,
                      child: const Icon(Icons.image_outlined,
                          color: AppTheme.textSecondary),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(width: 8),
                    if (!product.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('HIDDEN',
                            style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(product.category,
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),

          Row(
            children: [
              _ActionBtn(
                icon: product.isActive
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: product.isActive
                    ? AppTheme.textSecondary
                    : AppTheme.error,
                tooltip: product.isActive ? 'Hide' : 'Show',
                onTap: () => ref
                    .read(productCrudProvider.notifier)
                    .toggleActive(product),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.edit_outlined,
                color: AppTheme.accent,
                tooltip: 'Edit',
                onTap: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ProviderScope(
                    parent: ProviderScope.containerOf(context),
                    child: _ProductDialog(existing: product),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.delete_outline,
                color: AppTheme.error,
                tooltip: 'Delete',
                onTap: () => _confirmDelete(context, ref, product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete product?',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700)),
        content: Text('This will permanently delete "${product.name}".',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(productCrudProvider.notifier)
                  .deleteProduct(product.id);
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

// ─── Add / Edit Product Dialog ────────────────────────────────────────────────
class _ProductDialog extends ConsumerStatefulWidget {
  final Product? existing;
  const _ProductDialog({this.existing});

  @override
  ConsumerState<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _categoryCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');

    if (p != null && p.imageBase64.isNotEmpty) {
      Future.microtask(() =>
          ref.read(imagePickProvider.notifier).setExisting(p.imageBase64));
    } else {
      Future.microtask(() => ref.read(imagePickProvider.notifier).clear());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  // ── Pick image then immediately open cropper ───────────────────────────────
  Future<void> _pickAndCrop() async {
    await ref.read(imagePickProvider.notifier).pickImage();
    if (!mounted) return;
    final imageState = ref.read(imagePickProvider);
    if (imageState.rawBytes == null) return;
    await _openCropper(imageState.rawBytes!);
  }

  // ── Open cropper with existing bytes ──────────────────────────────────────
  Future<void> _openCropper(Uint8List bytes) async {
    final result = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageCropperScreen(imageBytes: bytes),
      ),
    );
    if (result != null && mounted) {
      await ref.read(imagePickProvider.notifier).setCropped(result);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final imageState = ref.read(imagePickProvider);
    if (imageState.base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final product = Product(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      imageBase64: imageState.base64Image!,
      category: _categoryCtrl.text.trim(),
      isActive: widget.existing?.isActive ?? true,
    );

    bool success;
    if (widget.existing == null) {
      success =
          await ref.read(productCrudProvider.notifier).addProduct(product);
    } else {
      success =
          await ref.read(productCrudProvider.notifier).updateProduct(product);
    }

    if (!mounted) return;
    if (success) {
      ref.read(imagePickProvider.notifier).clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          widget.existing == null ? 'Product added!' : 'Product updated!',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(imagePickProvider);
    final crudState = ref.watch(productCrudProvider);
    final isEditing = widget.existing != null;

    return Dialog(
      backgroundColor: AppTheme.cardBg,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Product' : 'Add Product',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(imagePickProvider.notifier).clear();
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.close,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Image area ────────────────────────────────────────
                GestureDetector(
                  onTap: imageState.base64Image == null
                      ? _pickAndCrop
                      : null,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: imageState.base64Image != null
                            ? AppTheme.accent
                            : AppTheme.border,
                        width: imageState.base64Image != null ? 1.5 : 1,
                      ),
                    ),
                    child: imageState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.accent))
                        : imageState.base64Image != null
                            ? Stack(
                                children: [
                                  // Preview
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(13),
                                    child: _Base64Image(
                                      base64: imageState.base64Image!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),

                                  // ── Action buttons overlay ─────────
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Row(
                                      children: [
                                        // Crop button
                                        if (imageState.rawBytes != null)
                                          _OverlayBtn(
                                            icon: Icons.crop,
                                            label: 'Crop',
                                            color: AppTheme.accent,
                                            onTap: () => _openCropper(
                                                imageState.rawBytes!),
                                          ),
                                        const SizedBox(width: 6),
                                        // Change button
                                        _OverlayBtn(
                                          icon: Icons.photo_library_outlined,
                                          label: 'Change',
                                          color: AppTheme.textPrimary,
                                          onTap: _pickAndCrop,
                                        ),
                                        const SizedBox(width: 6),
                                        // Remove button
                                        _OverlayBtn(
                                          icon: Icons.delete_outline,
                                          label: 'Remove',
                                          color: AppTheme.error,
                                          onTap: () => ref
                                              .read(imagePickProvider.notifier)
                                              .clear(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_upload_outlined,
                                      color: AppTheme.accent, size: 36),
                                  const SizedBox(height: 8),
                                  const Text('Click to upload image',
                                      style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PNG, JPG, WEBP — crop after upload',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary
                                            .withOpacity(0.7),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                  ),
                ),

                // Crop hint
                if (imageState.base64Image != null &&
                    imageState.rawBytes != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openCropper(imageState.rawBytes!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.crop, color: AppTheme.accent, size: 15),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap to open crop editor — pan, zoom, resize, and choose aspect ratio',
                              style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppTheme.accent, size: 15),
                        ],
                      ),
                    ),
                  ),
                ],

                if (imageState.error != null) ...[
                  const SizedBox(height: 6),
                  Text(imageState.error!,
                      style: const TextStyle(
                          color: AppTheme.error, fontSize: 12)),
                ],
                const SizedBox(height: 16),

                // ── Fields ────────────────────────────────────────────
                AppTextField(
                  label: 'Product name',
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Description',
                  controller: _descCtrl,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Price (USD)',
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Invalid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Category',
                        controller: _categoryCtrl,
                        textInputAction: TextInputAction.done,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (crudState.error != null) ...[
                  ErrorBanner(message: crudState.error!),
                  const SizedBox(height: 12),
                ],

                LoadingButton(
                  isLoading: crudState.isLoading,
                  onPressed: _save,
                  label: isEditing ? 'Save Changes' : 'Add Product',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small overlay action button ─────────────────────────────────────────────
class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OverlayBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Base64 image widget (local to admin screen) ──────────────────────────────
class _Base64Image extends StatelessWidget {
  final String base64;
  final BoxFit fit;
  final double? width;
  final double? height;

  const _Base64Image({
    required this.base64,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final data = base64.contains(',') ? base64.split(',').last : base64;
      final bytes = base64Decode(data);
      return Image.memory(bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _placeholder());
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppTheme.surface,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: AppTheme.textSecondary),
        ),
      );
}