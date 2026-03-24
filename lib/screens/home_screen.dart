import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme.dart';
import '../widgets/base64_image.dart';
import '../widgets/common_widgets.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'admin/admin_shell.dart';

final activeTabProvider = StateProvider<int>((ref) => 0);

// ─── Main Shell ───────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);

    const screens = [
      _ShopTab(),
      SearchScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: activeTab, children: screens),
      bottomNavigationBar: _BottomNav(activeTab: activeTab),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
class _BottomNav extends ConsumerWidget {
  final int activeTab;
  const _BottomNav({required this.activeTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _NavItem(icon: Icons.store_outlined, activeIcon: Icons.store,
                  label: 'Shop', isActive: activeTab == 0,
                  onTap: () => ref.read(activeTabProvider.notifier).state = 0),
              _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search,
                  label: 'Search', isActive: activeTab == 1,
                  onTap: () => ref.read(activeTabProvider.notifier).state = 1),
              // Cart center button
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: AppTheme.primary, size: 22),
                          ),
                          if (cartCount > 0)
                            Positioned(
                              top: -5, right: -5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: AppTheme.error,
                                    shape: BoxShape.circle),
                                child: Text('$cartCount',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Cart',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person,
                  label: 'Profile', isActive: activeTab == 2,
                  onTap: () => ref.read(activeTabProvider.notifier).state = 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon,
      required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? AppTheme.accent : AppTheme.textSecondary,
                size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? AppTheme.accent : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Shop Tab ─────────────────────────────────────────────────────────────────
class _ShopTab extends ConsumerWidget {
  const _ShopTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final cartCount = ref.watch(cartCountProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.value?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bolt, color: AppTheme.accent, size: 22),
            SizedBox(width: 6),
            Text('VOLTEX'),
          ],
        ),
        actions: [
          // Admin panel button — only visible to admins
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminShell())),
                icon: const Icon(Icons.admin_panel_settings_outlined,
                    color: AppTheme.accent, size: 18),
                label: const Text('Admin',
                    style: TextStyle(
                        color: AppTheme.accent, fontWeight: FontWeight.w700)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () =>
                ref.read(activeTabProvider.notifier).state = 1,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero banner
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tech, refined.',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Premium gear for serious work.',
                              style: TextStyle(
                                  color: AppTheme.primary.withOpacity(0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const Icon(Icons.devices, color: AppTheme.primary, size: 48),
                  ],
                ),
              ),
            ),
          ),

          // Category chips
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final isSelected = cat == (selectedCategory ?? 'All');
                    return GestureDetector(
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = cat == 'All' ? null : cat,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accent : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected
                                  ? AppTheme.accent
                                  : AppTheme.border),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeader(title: 'Products'),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Product grid
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent)),
              error: (e, _) => Center(
                  child: Text('Error loading products',
                      style: const TextStyle(color: AppTheme.error))),
              data: (_) {
                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('No products available.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final w = MediaQuery.of(context).size.width;
                    final isMobile = w < 600;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 2 : 5,
                            mainAxisExtent: isMobile ? 200 : 230,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, i) =>
                              _ProductCard(product: filteredProducts[i]),
                        ),
                      ),
                    );
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

// ─── Product Card ─────────────────────────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Base64Image(
                  base64: product.imageBase64,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.category,
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(product.name,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        GestureDetector(
                          onTap: () {
                            ref.read(cartProvider.notifier).addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${product.name} added to cart',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              backgroundColor: const Color(0xFF2C2C2C),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(12),
                            ));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(7)),
                            child: const Icon(Icons.add,
                                color: AppTheme.primary, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}