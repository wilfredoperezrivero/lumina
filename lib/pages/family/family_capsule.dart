import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

      // Generate public URL
      _publicUrl = 'https://capsule.luminamemorials.com/${familyCapsule.id}';

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

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
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

  Widget _buildQRCode() {
    if (_publicUrl == null) return Container();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QR Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            Center(
              child: QrImageView(
                data: _publicUrl!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Scan to access capsule',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Public URL with copy button
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openUrl(_publicUrl!),
                      child: Text(
                        _publicUrl!,
                        style: TextStyle(
                          color: Colors.blue[600],
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _copyToClipboard(_publicUrl!),
                    icon: Icon(Icons.copy, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    tooltip: 'Copy URL',
                  ),
                ],
              ),
            ),
          ],
        ),
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
                      _buildQRCode(),
                      SizedBox(height: 16),
                      _buildActions(),
                    ],
                  ),
                ),
    );
  }
}
