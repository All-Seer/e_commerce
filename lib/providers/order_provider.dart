import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class OrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  OrderNotifier() : super(const AsyncValue.data([]));

  final _firestore = FirebaseFirestore.instance;

  Future<bool> placeOrder({
    required List<CartItem> items,
    required double total,
    required BillingInfo billingInfo,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final orderId = _firestore.collection('orders').doc().id;
      final order = Order(
        id: orderId,
        items: items,
        total: total,
        createdAt: DateTime.now(),
        status: 'confirmed',
        billingInfo: billingInfo,
      );

      // Save order to Firestore (only safe fields — never store full card)
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .set({
        ...order.toMap(),
        'items': items
            .map((i) => {
                  'productId': i.product.id,
                  'productName': i.product.name,
                  'quantity': i.quantity,
                  'price': i.product.price,
                })
            .toList(),
      });

      state = AsyncValue.data([...state.value ?? [], order]);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final orderProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderNotifier();
});
