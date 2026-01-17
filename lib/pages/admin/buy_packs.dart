import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class BuyPacksPage extends StatefulWidget {
  @override
  _BuyPacksPageState createState() => _BuyPacksPageState();
}

class _BuyPacksPageState extends State<BuyPacksPage> {
  String? adminName;
  String? adminEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final name = await AdminService.getCurrentAdminName();
      final email = await AdminService.getCurrentAdminEmail();

      setState(() {
        adminName = name;
        adminEmail = email;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading admin data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String buildLemonSqueezyUrl() {
    final userId = AuthService.currentUser()?.id;
    final base =
        'https://luminamemorials.lemonsqueezy.com/buy/5a9d4848-1038-48ae-ba71-9c81412c9789';

    if (userId == null) return base;

    final params = <String>[];
    params.add('checkout[custom][admin_id]=$userId');

    if (adminEmail != null && adminEmail!.isNotEmpty) {
      params.add('checkout[email]=${Uri.encodeComponent(adminEmail!)}');
    }

    final name = adminName ?? 'Admin User';
    if (name.isNotEmpty) {
      params.add('checkout[name]=${Uri.encodeComponent(name)}');
    }

    return '$base?${params.join('&')}';
  }

  Future<void> _launchCheckout() async {
    final url = Uri.parse(buildLemonSqueezyUrl());
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packs = [
      {
        'title': 'Pack of 5 capsules',
        'description': 'Perfect to get started. Base price per capsule.',
        'price': '\$75',
        'capsules': 5,
        'savings': null,
      },
      {
        'title': 'Pack of 10 capsules',
        'description': 'Save 10% over the starter pack — ideal for your first few weeks with Lumina Memorials.',
        'price': '\$135',
        'capsules': 10,
        'savings': '10%',
      },
      {
        'title': 'Pack of 25 capsules',
        'description': 'Save 15% and make Lumina Memorials a natural part of every farewell you offer.',
        'price': '\$319',
        'capsules': 25,
        'savings': '15%',
      },
      {
        'title': 'Pack of 50 capsules',
        'description': 'Save 25%. Perfect for funeral homes with steady monthly demand.',
        'price': '\$562',
        'capsules': 50,
        'savings': '25%',
      },
      {
        'title': 'Pack of 100 capsules',
        'description': 'Save 35%. Boost your margin and bring Lumina Memorials to every farewell.',
        'price': '\$975',
        'capsules': 100,
        'savings': '35%',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: buildAppBar(context: context, title: 'Buy Packs'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section
                  Container(
                    decoration: AppDecorations.card,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryDark, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text('Capsule Packs', style: AppTextStyles.h3),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Get Lumina Memorials in packs tailored to your needs — from 5 to 100 capsules. For high volumes or continuous integration, contact us for a custom proposal.',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Packs section
                  Container(
                    decoration: AppDecorations.card,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryDark, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text('Available Packs', style: AppTextStyles.h3),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ...packs.map((pack) => _buildPackItem(
                          title: pack['title'] as String,
                          description: pack['description'] as String,
                          price: pack['price'] as String,
                          capsules: pack['capsules'] as int,
                          savings: pack['savings'] as String?,
                        )).toList(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _launchCheckout,
                            icon: const Icon(Icons.shopping_cart_rounded),
                            label: const Text(
                              'Buy Packs',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: primaryButtonStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Enterprise section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(Icons.business_rounded, color: AppColors.warning, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text('Enterprise', style: AppTextStyles.h3),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                'Packs +250',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                'Up to 50% off',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Need higher volume or continuous integration? Get in touch and unlock discounts of up to 50%.',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Add contact action
                            },
                            icon: const Icon(Icons.mail_outline_rounded),
                            label: const Text('Contact Us'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              side: BorderSide(color: AppColors.warning),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPackItem({
    required String title,
    required String description,
    required String price,
    required int capsules,
    String? savings,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                '$capsules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppTextStyles.subtitle),
                    ),
                    if (savings != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'Save $savings',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
