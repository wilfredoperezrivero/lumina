import 'package:flutter/material.dart';
import '../../models/capsule.dart';

class CapsuleDetailsPage extends StatefulWidget {
  @override
  _CapsuleDetailsPageState createState() => _CapsuleDetailsPageState();
}

class _CapsuleDetailsPageState extends State<CapsuleDetailsPage> {
  Capsule? _capsule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCapsule();
    });
  }

  void _loadCapsule() {
    final capsule = ModalRoute.of(context)!.settings.arguments as Capsule;
    setState(() {
      _capsule = capsule;
      _isLoading = false;
    });
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

                      // Dates
                      if (_capsule!.dateOfBirth?.isNotEmpty == true ||
                          _capsule!.dateOfDeath?.isNotEmpty == true) ...[
                        _buildDatesCard(),
                        SizedBox(height: 16),
                      ],

                      // Language
                      if (_capsule!.language?.isNotEmpty == true) ...[
                        _buildInfoCard(
                          'Language',
                          _capsule!.language!,
                          Icons.language,
                        ),
                        SizedBox(height: 16),
                      ],

                      // Family Email
                      if (_capsule!.familyEmail?.isNotEmpty == true) ...[
                        _buildInfoCard(
                          'Family Email',
                          _capsule!.familyEmail!,
                          Icons.email,
                        ),
                        SizedBox(height: 16),
                      ],

                      // Scheduled Date
                      if (_capsule!.scheduledDate != null) ...[
                        _buildInfoCard(
                          'Scheduled Date',
                          '${_capsule!.scheduledDate!.day}/${_capsule!.scheduledDate!.month}/${_capsule!.scheduledDate!.year}',
                          Icons.schedule,
                        ),
                        SizedBox(height: 16),
                      ],

                      // Created Date
                      if (_capsule!.createdAt != null) ...[
                        _buildInfoCard(
                          'Created',
                          '${_capsule!.createdAt!.day}/${_capsule!.createdAt!.month}/${_capsule!.createdAt!.year}',
                          Icons.calendar_today,
                        ),
                        SizedBox(height: 16),
                      ],

                      // Expires Date
                      if (_capsule!.expiresAt != null) ...[
                        _buildInfoCard(
                          'Expires',
                          '${_capsule!.expiresAt!.day}/${_capsule!.expiresAt!.month}/${_capsule!.expiresAt!.year}',
                          Icons.access_time,
                        ),
                        SizedBox(height: 16),
                      ],

                      // Final Video URL
                      if (_capsule!.finalVideoUrl?.isNotEmpty == true) ...[
                        _buildInfoCard(
                          'Final Video',
                          _capsule!.finalVideoUrl!,
                          Icons.video_library,
                        ),
                        SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade600),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cake, color: Colors.blue.shade600),
                SizedBox(width: 12),
                Text(
                  'Important Dates',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_capsule!.dateOfBirth?.isNotEmpty == true) ...[
              Row(
                children: [
                  Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text('Birth: ${_capsule!.dateOfBirth}'),
                ],
              ),
              SizedBox(height: 8),
            ],
            if (_capsule!.dateOfDeath?.isNotEmpty == true) ...[
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text('Death: ${_capsule!.dateOfDeath}'),
                ],
              ),
            ],
          ],
        ),
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
    Navigator.pushNamed(context, '/admin/edit-capsule', arguments: _capsule);
  }
}
