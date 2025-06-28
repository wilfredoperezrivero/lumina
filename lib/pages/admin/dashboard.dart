import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // Add logout functionality
              await AuthService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Buy Packs'),
            onTap: () => context.go('/admin/buy_packs'),
          ),
          ListTile(
            title: Text('Create Capsule'),
            onTap: () => context.go('/admin/create_capsule'),
          ),
          ListTile(
            title: Text('List/Browse Capsules'),
            onTap: () => context.go('/admin/list_capsules'),
          ),
          ListTile(
            title: Text('Send Capsule to Families'),
            onTap: () => context.go('/admin/send_capsule'),
          ),
        ],
      ),
    );
  }
}
