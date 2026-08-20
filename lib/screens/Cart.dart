import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final found = kValidCoupons.where((c) => c.code == code).toList();
    if (found.isNotEmpty) {
      ref.read(appliedCouponProvider.notifier).state = found.first;
      _couponController.clear();
      AppHelpers.showSnackBar(context, 'Coupon "${found.first.code}" applied! ${found.first.description}');
    } else {
      AppHelpers.showSnackBar(context, 'Invalid coupon code. Try EDUSPHERE20 or LEARN50', isError: true);
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

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Navigation Breadcrumb
              InkWell(
                onTap: () => context.go('/courses'),
                borderRadius: AppSpacing.roundedMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Explore Courses',
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

              Text(
                'Shopping Cart',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${cartItems.length} course${cartItems.length == 1 ? '' : 's'} in your cart',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              if (cartItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60.0),
                    child: Column(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.outline),
                        const SizedBox(height: 16),
                        Text('Your cart is empty', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text('Explore our catalog and find the best course for your career.', style: AppTypography.bodyMedium),
                        const SizedBox(height: 20),
                        AppButton(
                          label: 'Explore Courses',
                          variant: ButtonVariant.primary,
                          onPressed: () => context.go('/courses'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Items List + Coupon Input
                    Expanded(
                      flex: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cartItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final course = cartItems[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppSpacing.roundedLg,
                                  border: Border.all(color: AppColors.surfaceContainerHigh),
                                  boxShadow: const [
                                    BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: AppSpacing.roundedMd,
                                      child: SizedBox(
                                        width: isDesktop ? 110 : 78,
                                        height: isDesktop ? 70 : 52,
                                        child: Image.network(
                                          course.thumbnailUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceContainerLow),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course.title,
                                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'By ${course.instructor.name} • ${course.duration}',
                                            style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AppFormatters.formatCurrency(course.price),
                                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                          onPressed: () {
                                            ref.read(cartProvider.notifier).removeFromCart(course.id);
                                            AppHelpers.showSnackBar(context, 'Removed from cart.');
                                          },
                                          tooltip: 'Remove from cart',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // Promotions / Coupon Input Bar
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppSpacing.roundedLg,
                              border: Border.all(color: AppColors.surfaceContainerHigh),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Promotions & Vouchers', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _couponController,
                                        textCapitalization: TextCapitalization.characters,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter coupon code (e.g. EDUSPHERE20)',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    AppButton(
                                      label: 'Apply',
                                      variant: ButtonVariant.secondary,
                                      size: ButtonSize.sm,
                                      onPressed: _applyCoupon,
                                    ),
                                  ],
                                ),
                                if (appliedCoupon != null) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryFixedDim.withOpacity(0.25),
                                          borderRadius: AppSpacing.roundedFull,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${appliedCoupon.code} (${appliedCoupon.discountPercent.round()}% OFF)',
                                              style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () {
                                                ref.read(appliedCouponProvider.notifier).state = null;
                                                AppHelpers.showSnackBar(context, 'Coupon removed.');
                                              },
                                              child: const Icon(Icons.close, size: 14, color: AppColors.secondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Mobile Order Summary
                          if (!isDesktop) ...[
                            const SizedBox(height: 20),
                            _buildSummaryCard(context, subtotal, discount, finalTotal, appliedCoupon),
                          ],
                        ],
                      ),
                    ),

                    // Right Order Summary Sidebar (Desktop)
                    if (isDesktop) ...[
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 4,
                        child: _buildSummaryCard(context, subtotal, discount, finalTotal, appliedCoupon),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
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
          BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
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
                Text('Coupon Discount (${appliedCoupon?.code})', style: AppTypography.bodyMedium.copyWith(color: AppColors.secondary)),
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
            label: 'Proceed to Checkout',
            variant: ButtonVariant.primary,
            isFullWidth: true,
            onPressed: () => context.go('/checkout'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 14, color: AppColors.outline),
              const SizedBox(width: 6),
              Text('256-Bit SSL Encrypted Checkout', style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
