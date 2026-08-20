import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';

class CouponModel {
  final String code;
  final double discountPercent; // e.g. 20.0 for 20%
  final String description;

  const CouponModel({
    required this.code,
    required this.discountPercent,
    required this.description,
  });
}

const List<CouponModel> kValidCoupons = [
  CouponModel(
    code: 'EDUSPHERE20',
    discountPercent: 20.0,
    description: '20% off your entire order',
  ),
  CouponModel(
    code: 'LEARN50',
    discountPercent: 50.0,
    description: '50% Summer Learning flash discount',
  ),
  CouponModel(
    code: 'WELCOME100',
    discountPercent: 100.0,
    description: '100% Scholarship voucher (Free access)',
  ),
];

final appliedCouponProvider = StateProvider<CouponModel?>((ref) => null);

class CartNotifier extends StateNotifier<List<CourseModel>> {
  CartNotifier() : super([]);

  void addToCart(CourseModel course) {
    if (!state.any((c) => c.id == course.id)) {
      state = [...state, course];
    }
  }

  void removeFromCart(String courseId) {
    state = state.where((c) => c.id != courseId).toList();
  }

  void clearCart() {
    state = [];
  }

  bool isInCart(String courseId) {
    return state.any((c) => c.id == courseId);
  }

  double get subtotalPrice => state.fold(0.0, (sum, c) => sum + c.price);
  double get totalPrice => subtotalPrice;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CourseModel>>((ref) {
  return CartNotifier();
});

/// Computes the exact discount in dollars from the active coupon
final cartDiscountAmountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final subtotal = cart.fold(0.0, (sum, c) => sum + c.price);
  final coupon = ref.watch(appliedCouponProvider);
  if (coupon == null || subtotal <= 0) return 0.0;
  return subtotal * (coupon.discountPercent / 100.0);
});

/// Computes the final payable amount after coupon discount
final finalCartTotalPriceProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final subtotal = cart.fold(0.0, (sum, c) => sum + c.price);
  final discount = ref.watch(cartDiscountAmountProvider);
  final total = subtotal - discount;
  return total < 0 ? 0.0 : total;
});

class WishlistNotifier extends StateNotifier<List<CourseModel>> {
  WishlistNotifier() : super([]);

  void toggleWishlist(CourseModel course) {
    if (state.any((c) => c.id == course.id)) {
      state = state.where((c) => c.id != course.id).toList();
    } else {
      state = [...state, course];
    }
  }

  bool isInWishlist(String courseId) {
    return state.any((c) => c.id == courseId);
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<CourseModel>>((ref) {
  return WishlistNotifier();
});
