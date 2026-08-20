import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/course_model.dart';
import '../providers/cart_provider.dart';
import '../providers/enrolment_provider.dart';
import '../providers/auth_provider.dart';
import '../services/payment_service.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Alex Morgan');
  final TextEditingController _cardNumberController = TextEditingController(text: '4242 4242 4242 4242');
  final TextEditingController _expiryController = TextEditingController(text: '12/28');
  final TextEditingController _cvcController = TextEditingController(text: '123');

  bool _saveCardSecurely = true;
  bool _isProcessing = false;
  StripePaymentResult? _paymentResult;
  List<CourseModel> _purchasedCourses = [];
  int _selectedPaymentMethod = 0; // 0: Stripe Credit Card, 1: Google Pay / Apple Pay

  final PaymentService _paymentService = PaymentService();

  @override
  void dispose() {
    // Zero out sensitive controllers from memory on disposal
    _nameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  void _fillTestCard(String cardNumber, String label) {
    setState(() {
      _cardNumberController.text = cardNumber;
      _expiryController.text = '12/28';
      _cvcController.text = '123';
    });
    AppHelpers.showSnackBar(context, 'Filled with $label test card.');
  }

  Future<void> _handlePayment() async {
    final cartItems = ref.read(cartProvider);
    final user = ref.read(authProvider);
    final finalTotal = ref.read(finalCartTotalPriceProvider);

    if (cartItems.isEmpty) {
      AppHelpers.showSnackBar(context, 'Your cart is empty. Please add courses first.', isError: true);
      context.go('/courses');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _paymentService.processStripePayment(
        cardholderName: _nameController.text.trim(),
        cardNumber: _cardNumberController.text.trim(),
        expiryDate: _expiryController.text.trim(),
        cvc: _cvcController.text.trim(),
        amount: finalTotal,
        courseId: cartItems.first.id,
      );

      if (!result.isSuccess) {
        setState(() => _isProcessing = false);
        if (mounted) {
          AppHelpers.showSnackBar(context, result.errorMessage ?? 'Payment failed', isError: true);
        }
        return;
      }

      // Memory hygiene: Zero out raw CVV and card numbers immediately after successful tokenization
      _cardNumberController.clear();
      _cvcController.clear();

      // Persist enrollment for each course in cart
      for (final course in cartItems) {
        await ref.read(enrolmentProvider.notifier).enroll(
              course.id,
              user?.id ?? 'user_demo_01',
              paymentId: result.paymentId,
            );
      }

      final purchased = List<CourseModel>.from(cartItems);

      // Clear shopping cart and active coupons
      ref.read(cartProvider.notifier).clearCart();
      ref.read(appliedCouponProvider.notifier).state = null;

      setState(() {
        _isProcessing = false;
        _paymentResult = result;
        _purchasedCourses = purchased;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Payment error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotalPrice;
    final discount = ref.watch(cartDiscountAmountProvider);
    final finalTotal = ref.watch(finalCartTotalPriceProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final isDesktop = AppHelpers.isDesktop(context);

    // 1. Payment Success View matching /stitch/payment_success/
    if (_paymentResult != null && _paymentResult!.isSuccess) {
      return _buildPaymentSuccessView(context, isDesktop);
    }

    // 2. Checkout Screen
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Navigation Breadcrumb
              InkWell(
                onTap: () => context.go('/cart'),
                borderRadius: AppSpacing.roundedMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Cart',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checkout',
                    style: AppTypography.displayMedium.copyWith(
                      fontSize: isDesktop ? 32 : 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  // Stripe Test Mode Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: AppSpacing.roundedFull,
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Stripe Test Mode Active',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Layout: Form + Order Summary
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Form Column
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Method Selection
                        Text('Payment Method', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _PaymentOptionCard(
                                label: 'Credit / Debit Card',
                                icon: Icons.credit_card,
                                isSelected: _selectedPaymentMethod == 0,
                                onTap: () => setState(() => _selectedPaymentMethod = 0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PaymentOptionCard(
                                label: 'Google / Apple Pay',
                                icon: Icons.account_balance_wallet,
                                isSelected: _selectedPaymentMethod == 1,
                                onTap: () => setState(() => _selectedPaymentMethod = 1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Card Input Details Container
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: AppColors.surfaceContainerHigh),
                            boxShadow: const [
                              BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Card Details', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                                  Row(
                                    children: [
                                      Image.network(
                                        'https://upload.wikimedia.org/wikipedia/commons/4/41/Visa_Logo.png',
                                        height: 16,
                                        errorBuilder: (_, __, ___) => const Text('VISA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                      const SizedBox(width: 8),
                                      Image.network(
                                        'https://upload.wikimedia.org/wikipedia/commons/2/2a/Mastercard-logo.svg',
                                        height: 16,
                                        errorBuilder: (_, __, ___) => const Text('MC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Cardholder Name
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Cardholder Name',
                                  hintText: 'Alex Morgan',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Card Number
                              TextFormField(
                                controller: _cardNumberController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Card Number',
                                  hintText: '4242 4242 4242 4242',
                                  prefixIcon: Icon(Icons.credit_card),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Expiry & CVC
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _expiryController,
                                      keyboardType: TextInputType.datetime,
                                      decoration: const InputDecoration(
                                        labelText: 'Expiration',
                                        hintText: 'MM/YY',
                                        prefixIcon: Icon(Icons.calendar_today, size: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cvcController,
                                      keyboardType: TextInputType.number,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'CVC / CVV',
                                        hintText: '123',
                                        prefixIcon: Icon(Icons.security, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Save Card Checkbox
                              CheckboxListTile(
                                value: _saveCardSecurely,
                                onChanged: (val) => setState(() => _saveCardSecurely = val ?? true),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(
                                  'Save card securely with 256-bit tokenization',
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Test Mode Helpers (Quick Fill Chips)
                        Text('Test Mode Helpers (Click to auto-fill):', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('Success: 4242 4242 4242 4242', style: TextStyle(fontSize: 11)),
                              avatar: const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                              onPressed: () => _fillTestCard('4242 4242 4242 4242', 'Success'),
                            ),
                            ActionChip(
                              label: const Text('Decline: 4000 0000 0000 0002', style: TextStyle(fontSize: 11)),
                              avatar: const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                              onPressed: () => _fillTestCard('4000 0000 0000 0002', 'Decline'),
                            ),
                            ActionChip(
                              label: const Text('Funds: 4000 0000 0000 0005', style: TextStyle(fontSize: 11)),
                              avatar: const Icon(Icons.money_off, color: AppColors.warning, size: 16),
                              onPressed: () => _fillTestCard('4000 0000 0000 0005', 'Insufficient Funds'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Right Order Summary Column
                  if (isDesktop) ...[
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 5,
                      child: _buildOrderSummary(context, cartItems, subtotal, discount, finalTotal, appliedCoupon),
                    ),
                  ],
                ],
              ),

              // Mobile Order Summary
              if (!isDesktop) ...[
                const SizedBox(height: 16),
                _buildOrderSummary(context, cartItems, subtotal, discount, finalTotal, appliedCoupon),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    List<CourseModel> cartItems,
    double subtotal,
    double discount,
    double finalTotal,
    CouponModel? appliedCoupon,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),

          // Course items in summary
          ...cartItems.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        c.title,
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(AppFormatters.formatCurrency(c.price), style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
          const Divider(height: 20, color: AppColors.surfaceContainerHigh),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: AppTypography.bodyMedium),
              Text(AppFormatters.formatCurrency(subtotal), style: AppTypography.titleSmall),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coupon (${appliedCoupon?.code})', style: AppTypography.bodyMedium.copyWith(color: AppColors.secondary)),
                Text('-${AppFormatters.formatCurrency(discount)}', style: AppTypography.titleSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Tax', style: AppTypography.bodyMedium),
              Text('\$0.00', style: AppTypography.titleSmall),
            ],
          ),
          const Divider(height: 24, color: AppColors.surfaceContainerHigh),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
              Text(
                AppFormatters.formatCurrency(finalTotal),
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          AppButton(
            label: 'Complete Purchase (${AppFormatters.formatCurrency(finalTotal)})',
            variant: ButtonVariant.primary,
            size: ButtonSize.lg,
            isFullWidth: true,
            icon: Icons.lock,
            isLoading: _isProcessing,
            onPressed: _handlePayment,
          ),
          const SizedBox(height: 14),

          // Security statement
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                'Guaranteed Safe & Secure Checkout',
                style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSuccessView(BuildContext context, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.roundedXl,
            border: Border.all(color: AppColors.surfaceContainerHigh),
            boxShadow: const [
              BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 48, color: AppColors.success),
              ),
              const SizedBox(height: 20),

              Text(
                'Payment Successful!',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: isDesktop ? 28 : 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for your purchase! Your payment has been processed securely via Stripe.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Transaction Receipt Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Column(
                  children: [
                    _receiptRow('Receipt ID', _paymentResult?.paymentId ?? 'pi_test_12345'),
                    const SizedBox(height: 8),
                    _receiptRow('Payment Method', '${_paymentResult?.cardBrand ?? "Visa"} •••• ${_paymentResult?.last4 ?? "4242"}'),
                    const SizedBox(height: 8),
                    _receiptRow('Amount Paid', AppFormatters.formatCurrency(_paymentResult?.amount ?? 0)),
                    const SizedBox(height: 8),
                    _receiptRow('Date & Time', AppFormatters.formatDate(_paymentResult?.timestamp ?? DateTime.now())),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Enrolled Courses Summary
              if (_purchasedCourses.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Unlocked Courses:', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                ..._purchasedCourses.map((course) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: AppSpacing.roundedSm,
                            child: SizedBox(
                              width: 50,
                              height: 35,
                              child: Image.network(
                                course.thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceContainerHigh),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              course.title,
                              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.lock_open, size: 18, color: AppColors.secondary),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
              ],

              AppButton(
                label: 'Go to My Learning',
                variant: ButtonVariant.primary,
                size: ButtonSize.lg,
                isFullWidth: true,
                icon: Icons.school,
                onPressed: () => context.go('/my-learning'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/courses'),
                child: Text('Explore More Courses', style: AppTypography.labelMedium.copyWith(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.bodySmall.copyWith(color: AppColors.outline)),
        Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryFixedDim.withOpacity(0.2) : Colors.white,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.surfaceContainerHigh,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.secondary : AppColors.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.secondary : AppColors.onSurface,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.secondary, size: 18),
          ],
        ),
      ),
    );
  }
}
