import 'package:flutter/material.dart';

class FamilyDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Family Dashboard')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Edit Capsule'),
            onTap: () => Navigator.pushNamed(context, '/family/edit_capsule'),
          ),
          ListTile(
            title: Text('Share Link'),
            onTap: () => Navigator.pushNamed(context, '/family/share_link'),
          ),
          ListTile(
            title: Text('Generate Video'),
            onTap: () => Navigator.pushNamed(context, '/family/generate_video'),
          ),
          ListTile(
            title: Text('Invitees'),
            onTap: () => Navigator.pushNamed(context, '/family/invitees'),
          ),
        ],
      ),
    );
  }
}