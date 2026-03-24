import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ─── Compress + resize image bytes to a Firestore-safe size ──────────────────
// Resizes the longest edge to [maxDimension] px, then re-encodes as PNG.
// Keeping dimensions at ≤800 px keeps base64 well under 500 KB — safely
// inside Firestore's 1 MB per-document hard limit.
Future<Uint8List> _compressImage(
  Uint8List bytes, {
  int maxDimension = 800,
}) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: maxDimension,
    targetHeight: maxDimension,
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

// ─── Live Firestore product stream ────────────────────────────────────────────
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList());
});

final allProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList());
});

final categoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productsStreamProvider).value ?? [];
  final cats = products.map((p) => p.category).toSet().toList()..sort();
  return ['All', ...cats];
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsStreamProvider).value ?? [];
  final category = ref.watch(selectedCategoryProvider);
  if (category == null || category == 'All') return products;
  return products.where((p) => p.category == category).toList();
});

// ─── Image pick state — holds raw bytes for cropper + final base64 ────────────
class ImagePickState {
  final bool isLoading;
  final Uint8List? rawBytes;     // original picked bytes — fed into cropper
  final String? base64Image;    // final cropped base64 (saved to Firestore)
  final String? fileName;
  final String? error;

  const ImagePickState({
    this.isLoading = false,
    this.rawBytes,
    this.base64Image,
    this.fileName,
    this.error,
  });
}

class ImagePickNotifier extends StateNotifier<ImagePickState> {
  ImagePickNotifier() : super(const ImagePickState());

  Future<void> pickImage() async {
    state = const ImagePickState(isLoading: true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        state = const ImagePickState();
        return;
      }
      final file = result.files.first;
      final rawBytes = file.bytes!;

      // Compress before encoding — keeps base64 under ~500 KB so it fits
      // inside Firestore's 1 MB document limit.
      final compressed = await _compressImage(rawBytes);
      final dataUrl = 'data:image/png;base64,${base64Encode(compressed)}';

      // rawBytes keeps the original full-res for the cropper UI.
      // base64Image holds the compressed version that gets saved to Firestore.
      state = ImagePickState(
        rawBytes: rawBytes,
        base64Image: dataUrl,
        fileName: file.name,
      );
    } catch (e) {
      state = ImagePickState(error: 'Failed to pick image: $e');
    }
  }

  /// Called by the cropper after cropping — compresses then replaces base64
  Future<void> setCropped(Uint8List croppedBytes) async {
    final compressed = await _compressImage(croppedBytes);
    final dataUrl = 'data:image/png;base64,${base64Encode(compressed)}';
    state = ImagePickState(
      rawBytes: state.rawBytes,
      base64Image: dataUrl,
      fileName: state.fileName,
    );
  }

  void clear() => state = const ImagePickState();

  void setExisting(String base64) =>
      state = ImagePickState(base64Image: base64, fileName: 'existing');
}

final imagePickProvider =
    StateNotifierProvider.autoDispose<ImagePickNotifier, ImagePickState>(
        (ref) => ImagePickNotifier());

// ─── Product CRUD ─────────────────────────────────────────────────────────────
class ProductCrudState {
  final bool isLoading;
  final String? error;
  final bool success;
  const ProductCrudState(
      {this.isLoading = false, this.error, this.success = false});
}

class ProductCrudNotifier extends StateNotifier<ProductCrudState> {
  ProductCrudNotifier() : super(const ProductCrudState());
  final _db = FirebaseFirestore.instance;

  Future<bool> addProduct(Product product) async {
    state = const ProductCrudState(isLoading: true);
    try {
      await _db.collection('products').add(product.toMap());
      state = const ProductCrudState(success: true);
      return true;
    } catch (e) {
      state = ProductCrudState(error: 'Failed to add: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    state = const ProductCrudState(isLoading: true);
    try {
      await _db.collection('products').doc(product.id).update(product.toMap());
      state = const ProductCrudState(success: true);
      return true;
    } catch (e) {
      state = ProductCrudState(error: 'Failed to update: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    state = const ProductCrudState(isLoading: true);
    try {
      await _db.collection('products').doc(productId).delete();
      state = const ProductCrudState(success: true);
      return true;
    } catch (e) {
      state = ProductCrudState(error: 'Failed to delete: $e');
      return false;
    }
  }

  Future<bool> toggleActive(Product product) =>
      updateProduct(product.copyWith(isActive: !product.isActive));

  void reset() => state = const ProductCrudState();
}

final productCrudProvider =
    StateNotifierProvider<ProductCrudNotifier, ProductCrudState>(
        (ref) => ProductCrudNotifier());