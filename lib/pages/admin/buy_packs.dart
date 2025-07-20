import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';

class BuyPacksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser()?.id;
    String buildLemonSqueezyUrl(String productId) {
      final base = 'https://luminamemorials.lemonsqueezy.com/buy/';
      final url = '$base$productId?discount=0';
      if (userId == null) return url;
      return '$url&checkout[custom]=$userId';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Buy Packs'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Get Lumina in packs tailored to your needs — from 5 to 100 capsules. For high volumes or continuous integration, contact us for a custom proposal.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          _PackCard(
            title: 'Pack of 5 capsules',
            description: 'Perfect to get started. Base price per capsule.',
            price: ' \$75',
            checkoutUrl:
                buildLemonSqueezyUrl('bca48ea4-d904-4cdd-afab-4d3e104b8dfe'),
          ),
          SizedBox(height: 16),
          _PackCard(
            title: 'Pack of 10 capsules',
            description:
                'Save 10% over the starter pack — ideal for your first few weeks with Lumina.',
            price: ' \$135',
            checkoutUrl:
                buildLemonSqueezyUrl('bca48ea4-d904-4cdd-afab-4d3e104b8dfe'),
          ),
          SizedBox(height: 16),
          _PackCard(
            title: 'Pack of 20 capsules',
            description:
                'Save 15% and make Lumina a natural part of every farewell you offer.',
            price: ' \$319',
            checkoutUrl:
                buildLemonSqueezyUrl('bca48ea4-d904-4cdd-afab-4d3e104b8dfe'),
          ),
          SizedBox(height: 16),
          _PackCard(
            title: 'Pack of 50 capsules',
            description:
                'Save 25%. Perfect for funeral homes with steady monthly demand.',
            price: ' \$562',
            checkoutUrl:
                buildLemonSqueezyUrl('bca48ea4-d904-4cdd-afab-4d3e104b8dfe'),
          ),
          SizedBox(height: 16),
          _PackCard(
            title: 'Pack of 100 capsules',
            description:
                'Save 35%. Boost your margin and bring Lumina to every farewell.',
            price: ' \$975',
            checkoutUrl:
                buildLemonSqueezyUrl('bca48ea4-d904-4cdd-afab-4d3e104b8dfe'),
          ),
          SizedBox(height: 32),
          Card(
            color: Colors.yellow[50],
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Packs +250',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Need higher volume or continuous integration? Get in touch and unlock discounts of up to 50%.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Add contact action
                    },
                    child: Text('Contact Us'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final bool highlight;
  final String checkoutUrl;

  const _PackCard({
    required this.title,
    required this.description,
    required this.price,
    required this.checkoutUrl,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? Colors.blue[50] : null,
      elevation: highlight ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Text(description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text(price,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.blue[900])),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(checkoutUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }
}
