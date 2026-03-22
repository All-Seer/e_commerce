import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () => cartNotifier.clearCart(),
              child: const Text('Clear',
                  style: TextStyle(color: AppTheme.error)),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = cartItems[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            // Product image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: Image.network(
                                  item.product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppTheme.surface,
                                    child: const Icon(Icons.image_outlined,
                                        color: AppTheme.textSecondary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${item.product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Quantity controls
                                  Row(
                                    children: [
                                      _QtyBtn(
                                        icon: Icons.remove,
                                        onTap: () =>
                                            cartNotifier.updateQuantity(
                                          item.product.id,
                                          item.quantity - 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      _QtyBtn(
                                        icon: Icons.add,
                                        onTap: () =>
                                            cartNotifier.updateQuantity(
                                          item.product.id,
                                          item.quantity + 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Subtotal + delete
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () =>
                                      cartNotifier.removeFromCart(
                                          item.product.id),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.error,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Order summary
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                          label: 'Subtotal',
                          value:
                              '\$${cartNotifier.subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _SummaryRow(
                          label: 'Tax (12%)',
                          value:
                              '\$${cartNotifier.tax.toStringAsFixed(2)}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppTheme.border),
                      ),
                      _SummaryRow(
                        label: 'Total',
                        value:
                            '\$${cartNotifier.total.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),
                      LoadingButton(
                        isLoading: false,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CheckoutScreen()),
                        ),
                        label: 'Proceed to Checkout',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                color: AppTheme.textSecondary, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Your cart is empty',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Add some products to get started',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 16),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: isTotal
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
              fontSize: isTotal ? 17 : 14,
              fontWeight:
                  isTotal ? FontWeight.w800 : FontWeight.w500,
            )),
        Text(value,
            style: TextStyle(
              color: isTotal
                  ? AppTheme.accent
                  : AppTheme.textPrimary,
              fontSize: isTotal ? 17 : 14,
              fontWeight:
                  isTotal ? FontWeight.w800 : FontWeight.w600,
            )),
      ],
    );
  }
}
