import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class AdminDashboardPage extends StatelessWidget {
  // Color palette - Professional & sober
  static const Color _primaryDark = Color(0xFF1A1A2E);
  static const Color _accentColor = Color(0xFF4A5568);
  static const Color _surfaceColor = Color(0xFFFAFAFA);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1A202C);
  static const Color _textSecondary = Color(0xFF718096);
  static const Color _borderColor = Color(0xFFE2E8F0);

  String _formatDate(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.diamond_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Lumina Memorials',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: _accentColor),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.logout_rounded, color: _accentColor),
              onPressed: () async {
                await AuthService.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              tooltip: 'Sign out',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: _borderColor,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            letterSpacing: -1,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(now),
                          style: TextStyle(
                            fontSize: 15,
                            color: _textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Quick actions label
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Action cards grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 600
                      ? 2
                      : constraints.maxWidth < 900
                          ? 3
                          : 5;
                  final childAspectRatio = constraints.maxWidth < 600 ? 1.0 : 1.1;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _DashboardCard(
                        title: 'New Capsule',
                        subtitle: 'Create a memory',
                        icon: Icons.add_rounded,
                        onTap: () => context.go('/admin/create_capsule'),
                      ),
                      _DashboardCard(
                        title: 'Capsules',
                        subtitle: 'View & manage',
                        icon: Icons.inventory_2_outlined,
                        onTap: () => context.go('/admin/list_capsules'),
                      ),
                      _DashboardCard(
                        title: 'Buy Packs',
                        subtitle: 'Get more capsules',
                        icon: Icons.shopping_bag_outlined,
                        onTap: () => context.go('/admin/buy_packs'),
                      ),
                      _DashboardCard(
                        title: 'Settings',
                        subtitle: 'Preferences',
                        icon: Icons.tune_rounded,
                        onTap: () => context.go('/admin/settings'),
                      ),
                      _DashboardCard(
                        title: 'Marketing',
                        subtitle: 'Resources',
                        icon: Icons.campaign_outlined,
                        onTap: () => context.go('/admin/marketing'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),

              // Info section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: _accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tip of the day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share your capsule link with family members so they can contribute their memories.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _isHovered = false;

  static const Color _primaryDark = Color(0xFF1A1A2E);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1A202C);
  static const Color _textSecondary = Color(0xFF718096);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _surfaceColor = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        child: Material(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered ? _primaryDark.withValues(alpha: 0.2) : _borderColor,
                  width: _isHovered ? 1.5 : 1,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: _primaryDark.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isHovered ? _primaryDark : _surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: _isHovered ? Colors.white : _primaryDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
