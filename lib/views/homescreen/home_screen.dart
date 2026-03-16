import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/home_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/menu_card.dart';
import 'home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();

    // ✅ Set status bar color for Android 15+
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryLight,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              toolbarHeight: 0, // <-- no visible appbar, only status bar area
              elevation: 0,
              backgroundColor: AppColors.primaryLight,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: AppColors.primaryLight,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark, // iOS
              ),
            ),
            body: SafeArea(
              child: RefreshIndicator(
                color: AppColors.primaryLight,
                onRefresh: () => vm.refresh(context: context),
                child: CustomScrollView(
                  slivers: [
                    // ── Header always visible (company name from session) ──
                    SliverToBoxAdapter(
                      child: _HomeHeader(vm: vm),
                    ),

                    // ── Loading ────────────────────────────────────────────
                    if (vm.isLoading)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryLight),
                        ),
                      )

                    // ── Error ──────────────────────────────────────────────
                    else if (vm.hasError)
                      SliverFillRemaining(
                        child: _ErrorState(vm: vm),
                      )

                    // ── Loaded ─────────────────────────────────────────────
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // ── KPI Cards row ─────────────────────────
                            _KpiRow(kpi: vm.kpi!, vm: vm),
                            const SizedBox(height: 24),

                            // ── Promotional Banners ───────────────────
                            _SectionTitle(title: 'Promotions'),
                            const SizedBox(height: 12),
                            _PromoBannerCarousel(banners: vm.banners),
                            const SizedBox(height: 24),

                            // ── Quick Actions ─────────────────────────
                            _SectionTitle(title: 'Quick Actions'),
                            const SizedBox(height: 12),
                            _QuickActionsGrid(),
                            const SizedBox(height: 24),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final HomeViewModel vm;
  const _ErrorState({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 60, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              'Could not load dashboard',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onBackgroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Retry',
              onPressed: () => vm.refresh(context: context),
              backgroundColor: AppColors.primaryLight,
              textColor: AppColors.onPrimaryLight,
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final HomeViewModel vm;
  const _HomeHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          // Company logo placeholder + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onPrimaryLight.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => vm.goToProfile(context), // ✅ /profile
                  child: Text(
                    vm.companyName,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.onPrimaryLight,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Wallet balance chip
          GestureDetector(
            onTap: () => vm.topUpWallet(context),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 18, color: AppColors.onPrimaryLight),
                  const SizedBox(width: 6),
                  Text(
                    'SAR ${_fmt(vm.kpi?.walletBalance ?? 0)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Logout button
          GestureDetector(
            onTap: () => vm.logout(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 20, color: AppColors.onPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI Cards (4 in a row – horizontally scrollable on small screens)
// ─────────────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final HomeKpiData kpi;
  final HomeViewModel vm;
  const _KpiRow({required this.kpi, required this.vm});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCardData(
        title: 'Total Bookings',
        subtitle: 'This Year',
        value: kpi.totalBookingsThisYear.toString(),
        icon: Icons.calendar_today_outlined,
        iconColor: const Color(0xFF1565C0),
        iconBg: const Color(0xFFE3F2FD),
        onTap: () => vm.myBookings(context),
      ),
      _KpiCardData(
        title: 'This Month',
        subtitle: '${kpi.thisMonthBookings} Bookings',
        value: 'SAR ${_fmt(kpi.thisMonthSpent)}',
        icon: Icons.bar_chart_rounded,
        iconColor: const Color(0xFF6A1B9A),
        iconBg: const Color(0xFFF3E5F5),
      ),
      _KpiCardData(
        title: 'Total Spent',
        subtitle: '${kpi.savingsPercent.toInt()}% saved',
        value: 'SAR ${_fmt(kpi.totalSpent)}',
        icon: Icons.payments_outlined,
        iconColor: const Color(0xFF2E7D32),
        iconBg: const Color(0xFFE8F5E9),
      ),
      _KpiCardData(
        title: 'Wallet Bal.',
        subtitle: 'Top-up Now',
        value: 'SAR ${_fmt(kpi.walletBalance)}',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFFE65100),
        iconBg: const Color(0xFFFFF3E0),
        onTap: () => vm.topUpWallet(context),
      ),
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _KpiCard(data: cards[i]),
      ),
    );
  }
}

class _KpiCardData {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  const _KpiCardData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiCardData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon + title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: data.iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, size: 16, color: data.iconColor),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Value
            Text(
              data.value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onBackgroundLight,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),

            // Subtitle
            Text(
              data.subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Promotional Banners – horizontal scroll carousel
// ─────────────────────────────────────────────────────────────────────────────


// ── Color banner content (text + icon) ───────────────────────────────────────
class _ColorBannerContent extends StatelessWidget {
  final PromoBanner banner;
  final bool isDark;
  const _ColorBannerContent({required this.banner, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                banner.title,
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? Colors.white : AppColors.onPrimaryLight,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                banner.subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white70
                      : AppColors.onPrimaryLight.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.local_offer_outlined,
          size: 48,
          color: isDark
              ? Colors.white.withOpacity(0.25)
              : Colors.black.withOpacity(0.15),
        ),
      ],
    );
  }
}

class _PromoBannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  const _PromoBannerCarousel({required this.banners});

  @override
  State<_PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<_PromoBannerCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final banner = widget.banners[i];
              final isDark = banner.color.computeLuminance() < 0.4;

              // ── Image banner — network image + gradient title overlay ──
              if (banner.hasImage) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: banner.color,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image
                        Image.network(
                          banner.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _ColorBannerContent(
                              banner: banner, isDark: isDark),
                        ),
                        // Dark gradient from bottom so text is always readable
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.55),
                              ],
                              stops: const [0.35, 1.0],
                            ),
                          ),
                        ),
                        // Title + description pinned to bottom-left
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                banner.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (banner.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  banner.subtitle,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.88),
                                    fontSize: 11,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ── Color banner (local / fallback) ───────────────────────
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: banner.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _ColorBannerContent(banner: banner, isDark: isDark),
              );
            },
          ),
        ),

        // Page indicator dots — scrollable to handle any number of banners
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? AppColors.primaryLight
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions – 2×2 grid using MenuCard
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        title: 'New Booking',
        icon: Icons.add_circle_outline_rounded,
        route: '/new-booking',
        iconColor: const Color(0xFF1565C0),
        iconBg: const Color(0xFFE3F2FD),
      ),
      _ActionItem(
        title: 'Price Quotation',
        icon: Icons.request_quote_outlined,
        route: '/price-quotation',
        iconColor: const Color(0xFF6A1B9A),
        iconBg: const Color(0xFFF3E5F5),
      ),
      _ActionItem(
        title: 'My Vehicles',
        icon: Icons.directions_car_outlined,
        route: '/my-vehicles',
        iconColor: const Color(0xFF2E7D32),
        iconBg: const Color(0xFFE8F5E9),
      ),
      _ActionItem(
        title: 'Monthly Billing',
        icon: Icons.receipt_long_outlined,
        route: '/monthly-billing',
        iconColor: const Color(0xFFE65100),
        iconBg: const Color(0xFFFFF3E0),
      ),
      _ActionItem(
        title: 'Reports',
        icon: Icons.receipt,
        route: '/reports-landing',
        iconColor: const Color(0xFF1565C0),
        iconBg: const Color(0xFFE3F2FD),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: actions
          .map(
            (a) => MenuCard(
          title: a.title,
          icon: a.icon,
          iconBgColor: AppColors.secondaryDark,
          iconColor: AppColors.primaryLight,

          onTap: () => Navigator.pushNamed(context, a.route),
        ),
      )
          .toList(),
    );
  }
}

class _ActionItem {
  final String title;
  final IconData icon;
  final String route;
  final Color iconColor;
  final Color iconBg;

  const _ActionItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.iconColor,
    required this.iconBg,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.h3.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackgroundLight,
      ),
    );
  }
}

/// Format a number as e.g. 12,450
String _fmt(double value) {
  final parts = value.toStringAsFixed(0).split('');
  final buffer = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
    buffer.write(parts[i]);
  }
  return buffer.toString();
}