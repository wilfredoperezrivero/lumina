import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Buy Packs'),
            onTap: () => Navigator.pushNamed(context, '/admin/buy_packs'),
          ),
          ListTile(
            title: Text('Create Capsule'),
            onTap: () => Navigator.pushNamed(context, '/admin/create_capsule'),
          ),
          ListTile(
            title: Text('List/Browse Capsules'),
            onTap: () => Navigator.pushNamed(context, '/admin/list_capsules'),
          ),
          ListTile(
            title: Text('Send Capsule to Families'),
            onTap: () => Navigator.pushNamed(context, '/admin/send_capsule'),
          ),
        ],
      ),
    );
  }
}