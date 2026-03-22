import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ─── Products Provider ────────────────────────────────────────────────────────
final productsProvider = Provider<List<Product>>((ref) => sampleProducts);

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final category = ref.watch(selectedCategoryProvider);
  if (category == null || category == 'All') return products;
  return products.where((p) => p.category == category).toList();
});

final categoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productsProvider);
  final cats = products.map((p) => p.category).toSet().toList()..sort();
  return ['All', ...cats];
});

// ─── Cart Notifier ────────────────────────────────────────────────────────────
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            CartItem(product: state[i].product, quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          CartItem(product: item.product, quantity: quantity)
        else
          item,
    ];
  }

  void clearCart() => state = [];

  double get subtotal =>
      state.fold(0, (sum, item) => sum + item.total);

  double get tax => subtotal * 0.12;

  double get total => subtotal + tax;

  int get itemCount =>
      state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.notifier).itemCount;
});

final cartTotalProvider = Provider<double>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).total;
});
