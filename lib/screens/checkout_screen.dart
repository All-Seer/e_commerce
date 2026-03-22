import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Billing controllers
  final _cardNumberCtrl = TextEditingController();
  final _cardHolderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  // Shipping controllers
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();

  String _cardType = '';
  String? _error;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardHolderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  String _detectCardType(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.startsWith('4')) return 'Visa';
    if (clean.startsWith('5') || clean.startsWith('2')) return 'Mastercard';
    if (clean.startsWith('3')) return 'Amex';
    return '';
  }

  String _formatCardNumber(String value) {
    final clean = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final cartItems = ref.read(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final billing = BillingInfo(
      cardNumber: _cardNumberCtrl.text,
      cardHolder: _cardHolderCtrl.text,
      expiryDate: _expiryCtrl.text,
      cvv: _cvvCtrl.text,
    );

    final success = await ref.read(orderProvider.notifier).placeOrder(
          items: cartItems,
          total: cartNotifier.total,
          billingInfo: billing,
        );

    if (!mounted) return;

    if (success) {
      cartNotifier.clearCart();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        (route) => route.isFirst,
      );
    } else {
      setState(
          () => _error = 'Failed to place order. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final orderState = ref.watch(orderProvider);
    final isLoading = orderState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],

              // ── Shipping Address ─────────────────────────────────────
              _SectionCard(
                title: 'Shipping Address',
                icon: Icons.location_on_outlined,
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Street address',
                      controller: _addressCtrl,
                      prefixIcon: const Icon(Icons.home_outlined, size: 20),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Address is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            label: 'City',
                            controller: _cityCtrl,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'ZIP',
                            controller: _zipCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Payment Details ──────────────────────────────────────
              _SectionCard(
                title: 'Payment Details',
                icon: Icons.credit_card_outlined,
                child: Column(
                  children: [
                    // Card number
                    TextFormField(
                      controller: _cardNumberCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 19, // 16 digits + 3 spaces
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _CardNumberFormatter(),
                      ],
                      onChanged: (v) => setState(
                          () => _cardType = _detectCardType(v)),
                      decoration: InputDecoration(
                        labelText: 'Card number',
                        hintText: '0000 0000 0000 0000',
                        counterText: '',
                        filled: true,
                        fillColor: AppTheme.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.accent, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.credit_card,
                            size: 20, color: AppTheme.textSecondary),
                        suffixIcon: _cardType.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _cardType,
                                  style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      validator: (v) {
                        final clean =
                            v?.replaceAll(' ', '') ?? '';
                        if (clean.isEmpty) return 'Card number required';
                        if (clean.length < 13) return 'Invalid card number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Card holder
                    AppTextField(
                      label: 'Cardholder name',
                      controller: _cardHolderCtrl,
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Cardholder name required'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Expiry + CVV
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _ExpiryDateFormatter(),
                            ],
                            style: const TextStyle(
                                color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'MM/YY',
                              hintText: '12/27',
                              counterText: '',
                              filled: true,
                              fillColor: AppTheme.cardBg,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(
                                    color: AppTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(
                                    color: AppTheme.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(
                                    color: AppTheme.accent,
                                    width: 1.5),
                              ),
                              prefixIcon: Icon(Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppTheme.textSecondary),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) {
                                return 'MM/YY format';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                                color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              hintText: '···',
                              counterText: '',
                              filled: true,
                              fillColor: AppTheme.cardBg,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(
                                    color: AppTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(
                                    color: AppTheme.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(
                                    color: AppTheme.accent,
                                    width: 1.5),
                              ),
                              prefixIcon: Icon(Icons.lock_outline,
                                  size: 18,
                                  color: AppTheme.textSecondary),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              if (v.length < 3) return 'Invalid CVV';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    // Security note
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: AppTheme.accent, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your payment information is handled securely.',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Order Summary ────────────────────────────────────────
              _SectionCard(
                title: 'Order Summary',
                icon: Icons.receipt_outlined,
                child: Column(
                  children: [
                    _Row('Subtotal',
                        '\$${cartNotifier.subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _Row('Tax (12%)',
                        '\$${cartNotifier.tax.toStringAsFixed(2)}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppTheme.border),
                    ),
                    _Row(
                      'Total',
                      '\$${cartNotifier.total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              LoadingButton(
                isLoading: isLoading,
                onPressed: _placeOrder,
                label: 'Place Order',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _Row(this.label, this.value, {this.isTotal = false});

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
              fontWeight:
                  isTotal ? FontWeight.w800 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            )),
        Text(value,
            style: TextStyle(
              color: isTotal ? AppTheme.accent : AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: isTotal ? 16 : 14,
            )),
      ],
    );
  }
}

// ─── Input Formatters ─────────────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection:
          TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection:
          TextSelection.collapsed(offset: formatted.length),
    );
  }
}
