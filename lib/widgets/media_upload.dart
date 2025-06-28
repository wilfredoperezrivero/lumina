import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaUploadWidget extends StatelessWidget {
  final String capsuleId;

  MediaUploadWidget({required this.capsuleId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text('Upload Media'),
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles();
        if (result != null) {
          final file = result.files.first;
          final storage = Supabase.instance.client.storage;
          final path = 'capsules/\$capsuleId/\${file.name}';
          await storage.from('media').uploadBinary(path, file.bytes!);
        }
      },
    );
  }
}