// ─── Product Model ────────────────────────────────────────────────────────────
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageBase64; // base64 string stored in Firestore
  final String category;
  final double rating;
  final int reviewCount;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageBase64,
    required this.category,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.isActive = true,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageBase64: map['imageBase64'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'imageBase64': imageBase64,
    'category': category,
    'rating': rating,
    'reviewCount': reviewCount,
    'isActive': isActive,
  };

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? imageBase64,
    String? category,
    double? rating,
    int? reviewCount,
    bool? isActive,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageBase64: imageBase64 ?? this.imageBase64,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ─── Cart Item Model ──────────────────────────────────────────────────────────
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

// ─── Order Model ──────────────────────────────────────────────────────────────
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

// ─── Billing Info Model ───────────────────────────────────────────────────────
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

  String get cardLast4 {
    final clean = cardNumber.replaceAll(' ', '');
    return clean.length >= 4 ? clean.substring(clean.length - 4) : '****';
  }
}

// ─── Admin Role ───────────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String name;
  final String email;
  final bool isAdmin;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.isAdmin = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      isAdmin: map['isAdmin'] as bool? ?? false,
    );
  }
}