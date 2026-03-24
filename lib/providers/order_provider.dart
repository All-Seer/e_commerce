import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class OrderState {
  final bool isLoading;
  final String? error;
  const OrderState({this.isLoading = false, this.error});
}

class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier() : super(const OrderState());

  final _db = FirebaseFirestore.instance;

  Future<bool> placeOrder({
    required List<CartItem> items,
    required double total,
    required BillingInfo billingInfo,
  }) async {
    state = const OrderState(isLoading: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final orderId = _db.collection('orders').doc().id;
      final order = Order(
        id: orderId,
        items: items,
        total: total,
        createdAt: DateTime.now(),
        status: 'confirmed',
        billingInfo: billingInfo,
      );

      // Only store safe fields — never persist full card details
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .set({
        ...order.toMap(),
        'items': items.map((i) => {
          'productId': i.product.id,
          'productName': i.product.name,
          'quantity': i.quantity,
          'price': i.product.price,
        }).toList(),
      });

      state = const OrderState();
      return true;
    } catch (e) {
      state = OrderState(error: 'Failed to place order: $e');
      return false;
    }
  }

  void reset() => state = const OrderState();
}

final orderProvider =
    StateNotifierProvider<OrderNotifier, OrderState>((ref) => OrderNotifier());

// ─── Order history stream for current user ────────────────────────────────────
final orderHistoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
});