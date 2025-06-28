import 'package:flutter/material.dart';
import '../../widgets/media_upload.dart';

class AddMessagePage extends StatelessWidget {
  final String capsuleId = "demo_capsule_id";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Your Message')),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Your Tribute Text'),
          ),
          MediaUploadWidget(capsuleId: capsuleId),
        ],
      ),
    );
  }
}