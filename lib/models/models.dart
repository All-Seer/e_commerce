// ─── Product Model ───────────────────────────────────────────────────────────
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int reviewCount;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating = 4.5,
    this.reviewCount = 128,
  });
}

// ─── Cart Item Model ─────────────────────────────────────────────────────────
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

// ─── Order Model ─────────────────────────────────────────────────────────────
class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;
  final String status;
  final BillingInfo billingInfo;

  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.status,
    required this.billingInfo,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'itemCount': items.length,
    'cardLast4': billingInfo.cardLast4,
  };
}

// ─── Billing Info Model ──────────────────────────────────────────────────────
class BillingInfo {
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv;

  const BillingInfo({
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
  });

  String get cardLast4 =>
      cardNumber.replaceAll(' ', '').length >= 4
          ? cardNumber.replaceAll(' ', '').substring(
              cardNumber.replaceAll(' ', '').length - 4)
          : '****';
}

// ─── Sample Products ─────────────────────────────────────────────────────────
final sampleProducts = [
  const Product(
    id: '1',
    name: 'Wireless Headphones',
    description: 'Premium noise-cancelling over-ear headphones with 30-hour battery life and spatial audio.',
    price: 299.99,
    imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80',
    category: 'Audio',
    rating: 4.8,
    reviewCount: 342,
  ),
  const Product(
    id: '2',
    name: 'Mechanical Keyboard',
    description: 'Compact 75% layout with tactile switches, per-key RGB, and aluminum chassis.',
    price: 189.99,
    imageUrl: 'https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?w=400&q=80',
    category: 'Peripherals',
    rating: 4.7,
    reviewCount: 215,
  ),
  const Product(
    id: '3',
    name: 'Smart Watch',
    description: 'Health-focused smartwatch with ECG, SpO2 tracking, and 7-day battery.',
    price: 399.99,
    imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
    category: 'Wearables',
    rating: 4.6,
    reviewCount: 487,
  ),
  const Product(
    id: '4',
    name: 'USB-C Hub',
    description: '10-in-1 hub with 4K HDMI, 100W PD charging, SD card reader, and Gigabit Ethernet.',
    price: 79.99,
    imageUrl: 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=400&q=80',
    category: 'Accessories',
    rating: 4.5,
    reviewCount: 198,
  ),
  const Product(
    id: '5',
    name: 'Ergonomic Mouse',
    description: 'Vertical ergonomic design with 6 programmable buttons and silent clicks.',
    price: 59.99,
    imageUrl: 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=400&q=80',
    category: 'Peripherals',
    rating: 4.4,
    reviewCount: 156,
  ),
  const Product(
    id: '6',
    name: 'Portable SSD',
    description: '2TB NVMe portable SSD with 1,050 MB/s read speed in a rugged aluminum case.',
    price: 149.99,
    imageUrl: 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=400&q=80',
    category: 'Storage',
    rating: 4.9,
    reviewCount: 623,
  ),
];
