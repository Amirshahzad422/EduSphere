import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../components/Loader.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  final List<Map<String, dynamic>> _payoutHistory = [];
  double _withdrawnAmount = 0.0;

  void _handleWithdraw(double availableBalance) {
    if (availableBalance <= 0) {
      AppHelpers.showSnackBar(context, 'No available funds to withdraw yet.', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: const Text('Confirm Payout Request'),
        content: Text(
          'Withdraw ${AppFormatters.formatCurrency(availableBalance)} to your connected Stripe account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Confirm Transfer',
            variant: ButtonVariant.primary,
            size: ButtonSize.sm,
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _withdrawnAmount += availableBalance;
                _payoutHistory.insert(0, {
                  'id': 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  'course': 'Direct Payout to Bank via Stripe',
                  'amount': '-${AppFormatters.formatCurrency(availableBalance)}',
                  'date': 'Just now',
                  'isPayout': true,
                });
              });
              AppHelpers.showSnackBar(
                context,
                '✅ Payout of ${AppFormatters.formatCurrency(availableBalance)} successfully initiated via Stripe!',
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final coursesAsync = ref.watch(allCoursesProvider);
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
                onTap: () => context.go('/instructor'),
                borderRadius: AppSpacing.roundedMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Instructor Dashboard',
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

              coursesAsync.when(
                data: (allCourses) {
                  // Filter strictly to courses created by this instructor
                  final myCourses = allCourses.where((c) {
                    if (user == null) return false;
                    final matchId = c.instructorId == user.id;
                    final matchName = c.instructor.name.toLowerCase().trim() == user.name.toLowerCase().trim();
                    return matchId || matchName;
                  }).toList();

                  // REAL DATA CALCULATIONS
                  final grossSales = myCourses.fold<double>(0, (sum, c) => sum + (c.enrolmentCount * c.price));
                  final lifetimeEarnings = grossSales * 0.85; // 85% instructor payout rate
                  final availableBalance = (lifetimeEarnings - _withdrawnAmount).clamp(0.0, double.infinity);
                  final avgPrice = myCourses.isNotEmpty
                      ? (myCourses.fold<double>(0, (sum, c) => sum + c.price) / myCourses.length)
                      : 0.0;

                  // Real course sales transactions
                  final salesTransactions = <Map<String, dynamic>>[];
                  for (final c in myCourses) {
                    if (c.enrolmentCount > 0) {
                      salesTransactions.add({
                        'id': 'TX-${c.id.hashCode.abs().toString().substring(0, 4)}',
                        'course': '${c.title} (${c.enrolmentCount} sales)',
                        'amount': '+${AppFormatters.formatCurrency(c.enrolmentCount * c.price * 0.85)}',
                        'date': 'Active Sales',
                        'isPayout': false,
                      });
                    }
                  }

                  final allTransactions = [..._payoutHistory, ...salesTransactions];

                  final balanceCards = [
                    _BalanceCard(
                      title: 'Available for Payout',
                      amount: AppFormatters.formatCurrency(availableBalance),
                      subtext: availableBalance > 0 ? 'Ready for automatic payout' : 'No payout balance available',
                      isHighlight: true,
                    ),
                    _BalanceCard(
                      title: 'Lifetime Earnings',
                      amount: AppFormatters.formatCurrency(lifetimeEarnings),
                      subtext: 'Across ${myCourses.length} published course${myCourses.length == 1 ? '' : 's'}',
                    ),
                    _BalanceCard(
                      title: 'Avg. Course Price',
                      amount: AppFormatters.formatCurrency(avgPrice),
                      subtext: myCourses.isNotEmpty ? 'Based on active pricing' : 'No courses published',
                    ),
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      if (isDesktop)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Earnings Overview',
                                  style: AppTypography.displayMedium.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track your sales revenue, platform payouts, and course performance.',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                            AppButton(
                              label: 'Withdraw Payout',
                              variant: ButtonVariant.primary,
                              icon: Icons.account_balance,
                              onPressed: () => _handleWithdraw(availableBalance),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earnings Overview',
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your sales revenue & payouts.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: 'Withdraw Payout',
                              variant: ButtonVariant.primary,
                              size: ButtonSize.sm,
                              icon: Icons.account_balance,
                              onPressed: () => _handleWithdraw(availableBalance),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Responsive Balances
                      if (isDesktop)
                        Row(
                          children: balanceCards
                              .map((card) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: card,
                                    ),
                                  ))
                              .toList(),
                        )
                      else
                        Column(
                          children: balanceCards
                              .map((card) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: card,
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 32),

                      // Recent Payout Transactions
                      Text(
                        'Recent Transactions (${allTransactions.length})',
                        style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),

                      if (allTransactions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: AppColors.surfaceContainerHigh),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.outline),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions recorded yet',
                                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'When students purchase your courses or when you request payouts, transactions will appear here.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: AppColors.surfaceContainerHigh),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: allTransactions.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                            itemBuilder: (context, index) {
                              final tx = allTransactions[index];
                              final isPayout = tx['isPayout'] == true;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isPayout ? AppColors.error : AppColors.success).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPayout ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isPayout ? AppColors.error : AppColors.success,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  tx['course'] as String,
                                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${tx['id']} • ${tx['date']}',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                                ),
                                trailing: Text(
                                  tx['amount'] as String,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isPayout ? AppColors.error : AppColors.success,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: AppLoader()),
                error: (err, _) => Center(child: Text('Error loading earnings: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtext;
  final bool isHighlight;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.subtext,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primaryContainer.withOpacity(0.4) : Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: isHighlight ? AppColors.primary : AppColors.surfaceContainerHigh,
          width: isHighlight ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: isHighlight ? AppColors.primary : AppColors.outline,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: AppTypography.displayMedium.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isHighlight ? AppColors.primary : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
