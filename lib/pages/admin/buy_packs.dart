import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';

class BuyPacksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser()?.id;
    String buildLemonSqueezyUrl() {
      final base =
          'https://luminamemorials.lemonsqueezy.com/buy/5a9d4848-1038-48ae-ba71-9c81412c9789';
      if (userId == null) return base;
      return '$base?checkout[custom][admin_id]=$userId';
    }

    final packs = [
      {
        'title': 'Pack of 5 capsules',
        'description': 'Perfect to get started. Base price per capsule.',
        'price': '\$75',
        'capsules': 5,
      },
      {
        'title': 'Pack of 10 capsules',
        'description':
            'Save 10% over the starter pack — ideal for your first few weeks with Lumina.',
        'price': '\$135',
        'capsules': 10,
      },
      {
        'title': 'Pack of 25 capsules',
        'description':
            'Save 15% and make Lumina a natural part of every farewell you offer.',
        'price': '\$319',
        'capsules': 25,
      },
      {
        'title': 'Pack of 50 capsules',
        'description':
            'Save 25%. Perfect for funeral homes with steady monthly demand.',
        'price': '\$562',
        'capsules': 50,
      },
      {
        'title': 'Pack of 100 capsules',
        'description':
            'Save 35%. Boost your margin and bring Lumina to every farewell.',
        'price': '\$975',
        'capsules': 100,
      },
    ];

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
          SizedBox(height: 32),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Packs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 16),
                  ...packs
                      .map((pack) => _PackListItem(
                            title: pack['title'] as String,
                            description: pack['description'] as String,
                            price: pack['price'] as String,
                            capsules: pack['capsules'] as int,
                          ))
                      .toList(),
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final url = Uri.parse(buildLemonSqueezyUrl());
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: Text('Buy Packs'),
                    ),
                  ),
                ],
              ),
            ),
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

class _PackListItem extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final int capsules;

  const _PackListItem({
    required this.title,
    required this.description,
    required this.price,
    required this.capsules,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$capsules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
