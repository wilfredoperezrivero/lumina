import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/capsule.dart';
import '../../services/capsule_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FamilyCapsulePage extends StatefulWidget {
  @override
  _FamilyCapsulePageState createState() => _FamilyCapsulePageState();
}

class _FamilyCapsulePageState extends State<FamilyCapsulePage> {
  Capsule? _capsule;
  bool _isLoading = true;
  String? _errorMessage;
  String? _publicUrl;
  String? _qrUrl;
  bool _isGeneratingVideo = false;

  @override
  void initState() {
    super.initState();
    _loadCapsule();
  }

  Future<void> _loadCapsule() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get capsule assigned to this family user
      final capsules = await CapsuleService.getCapsules();
      final familyCapsule =
          capsules.where((c) => c.familyId == user.id).firstOrNull;

      if (familyCapsule == null) {
        throw Exception('No capsule assigned to this family');
      }

      // Generate URLs
      final baseUrl = 'https://luminamemorials.com';
      _publicUrl = '$baseUrl/capsule/${familyCapsule.id}';
      _qrUrl = '$baseUrl/qr/${familyCapsule.id}';

      setState(() {
        _capsule = familyCapsule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load capsule: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateVideo() async {
    if (_capsule == null) return;

    setState(() {
      _isGeneratingVideo = true;
    });

    try {
      // Call video generation API
      await CapsuleService.generateVideo(_capsule!.id);

      // Reload capsule to get updated status
      await _loadCapsule();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video generation started!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingVideo = false;
      });
    }
  }

  Future<void> _downloadQR() async {
    if (_qrUrl == null) return;

    try {
      final qrData = _qrUrl!;
      final qrImage = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/capsule_qr_${_capsule!.id}.png';

      final file = File(path);
      final byteData = await qrImage.toImageData(2048.0);
      final buffer = byteData!.buffer;
      await file.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR code saved to: $path'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download QR: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open URL'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCapsuleInfo() {
    if (_capsule == null) return Container();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capsule Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Name', _capsule!.name ?? 'Not specified'),
            _buildInfoRow('Status', _capsule!.status ?? 'Unknown'),
            if (_capsule!.dateOfBirth?.isNotEmpty == true)
              _buildInfoRow('Date of Birth', _capsule!.dateOfBirth!),
            if (_capsule!.dateOfDeath?.isNotEmpty == true)
              _buildInfoRow('Date of Death', _capsule!.dateOfDeath!),
            if (_capsule!.language?.isNotEmpty == true)
              _buildInfoRow('Language', _capsule!.language!),
            if (_capsule!.scheduledDate != null)
              _buildInfoRow('Scheduled Date',
                  '${_capsule!.scheduledDate!.day}/${_capsule!.scheduledDate!.month}/${_capsule!.scheduledDate!.year}'),
            if (_capsule!.expiresAt != null)
              _buildInfoRow('Expires',
                  '${_capsule!.expiresAt!.day}/${_capsule!.expiresAt!.month}/${_capsule!.expiresAt!.year}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      _publicUrl != null ? () => _openUrl(_publicUrl!) : null,
                  icon: Icon(Icons.link),
                  label: Text('Public URL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _qrUrl != null ? () => _openUrl(_qrUrl!) : null,
                  icon: Icon(Icons.qr_code),
                  label: Text('QR URL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _downloadQR,
                  icon: Icon(Icons.download),
                  label: Text('Download QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/family/messages'),
                  icon: Icon(Icons.message),
                  label: Text('Messages'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_capsule?.finalVideoUrl != null)
                  ElevatedButton.icon(
                    onPressed: () => _openUrl(_capsule!.finalVideoUrl!),
                    icon: Icon(Icons.play_arrow),
                    label: Text('Play Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  )
                else if (_capsule?.status == 'active' ||
                    _capsule?.status == 'draft')
                  ElevatedButton.icon(
                    onPressed: _isGeneratingVideo ? null : _generateVideo,
                    icon: _isGeneratingVideo
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.video_library),
                    label: Text(_isGeneratingVideo
                        ? 'Generating...'
                        : 'Generate Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Capsule'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCapsule,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCapsuleInfo(),
                      SizedBox(height: 16),
                      _buildActions(),
                    ],
                  ),
                ),
    );
  }
}
