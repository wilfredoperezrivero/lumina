import 'package:flutter/material.dart';
import '../../models/capsule.dart';
import 'package:go_router/go_router.dart';
import '../../services/pdf_service.dart';
import '../../services/settings_service.dart';

class CapsuleDetailsPage extends StatefulWidget {
  final Capsule capsule;
  const CapsuleDetailsPage({Key? key, required this.capsule}) : super(key: key);

  @override
  _CapsuleDetailsPageState createState() => _CapsuleDetailsPageState();
}

class _CapsuleDetailsPageState extends State<CapsuleDetailsPage> {
  Capsule? _capsule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _capsule = widget.capsule;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capsule Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editCapsule(),
            tooltip: 'Edit Capsule',
          ),
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Go Back',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _capsule == null
              ? Center(child: Text('Capsule not found'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with name and status
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _capsule!.name ?? '(No Name)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            _capsule!.status ?? ''),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _capsule!.status ?? 'Unknown',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // --- Combined Info Section ---
                      _buildInfoSection(),

                      SizedBox(height: 24),

                      // Generate PDF Button at bottom
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _generateMemorialPdf,
                            icon: Icon(Icons.picture_as_pdf),
                            label: Text('Generate Memorial PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // New unified info section card
  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capsule Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            if (_capsule!.dateOfBirth?.isNotEmpty == true)
              _buildInfoRow(
                  'Date of Birth', _capsule!.dateOfBirth!, Icons.cake),
            if (_capsule!.dateOfDeath?.isNotEmpty == true)
              _buildInfoRow(
                  'Date of Death', _capsule!.dateOfDeath!, Icons.event),
            if (_capsule!.language?.isNotEmpty == true)
              _buildInfoRow('Language', _capsule!.language!, Icons.language),
            if (_capsule!.familyEmail?.isNotEmpty == true)
              _buildInfoRow(
                  'Family Email', _capsule!.familyEmail!, Icons.email),
            if (_capsule!.scheduledDate != null)
              _buildInfoRow(
                'Scheduled Date',
                '${_capsule!.scheduledDate!.day}/${_capsule!.scheduledDate!.month}/${_capsule!.scheduledDate!.year}',
                Icons.schedule,
              ),
            if (_capsule!.createdAt != null)
              _buildInfoRow(
                'Created',
                '${_capsule!.createdAt!.day}/${_capsule!.createdAt!.month}/${_capsule!.createdAt!.year}',
                Icons.calendar_today,
              ),
            if (_capsule!.expiresAt != null)
              _buildInfoRow(
                'Expires',
                '${_capsule!.expiresAt!.day}/${_capsule!.expiresAt!.month}/${_capsule!.expiresAt!.year}',
                Icons.access_time,
              ),
            if (_capsule!.finalVideoUrl?.isNotEmpty == true)
              _buildInfoRow(
                  'Final Video', _capsule!.finalVideoUrl!, Icons.video_library),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade600),
          SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _editCapsule() {
    context.push('/admin/edit-capsule', extra: _capsule);
  }

  Future<void> _generateMemorialPdf() async {
    if (_capsule == null) return;

    // Build public URL similar to family capsule page logic
    final origin = Uri.base.origin;
    final publicUrl = '$origin/capsule/${_capsule!.id}';

    try {
      String? logoUrl;
      try {
        final settings = await SettingsService.getAdminSettings();
        logoUrl = settings?.logoImage;
      } catch (_) {}

      await PdfService.downloadMemorialPdf(
        capsuleName: _capsule!.name ?? 'Capsule',
        qrData: publicUrl,
        logoUrl: logoUrl,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Memorial PDF generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
