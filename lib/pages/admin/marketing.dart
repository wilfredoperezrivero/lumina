import 'package:flutter/material.dart';
import '../../services/pdf_service.dart';
import '../../services/settings_service.dart';
import '../../models/settings.dart';
import 'dart:io';

class MarketingPage extends StatefulWidget {
  @override
  _MarketingPageState createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
  Settings? _adminSettings;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  bool _isGeneratingPng = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdminSettings();
  }

  Future<void> _loadAdminSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await SettingsService.getAdminSettings();
      setState(() {
        _adminSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load settings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf(String language) async {
    setState(() {
      _isGeneratingPdf = true;
      _errorMessage = null;
    });

    try {
      final logoUrl = _adminSettings?.logoImage;

      final filePath = await PdfService.downloadPdf(
        language: language,
        logoUrl: logoUrl,
        adminName: _adminSettings?.name,
      );

      setState(() {
        _isGeneratingPdf = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to download PDF: ${e.toString()}';
        _isGeneratingPdf = false;
      });
    }
  }

  Future<void> _downloadPng(String language) async {
    setState(() {
      _isGeneratingPng = true;
      _errorMessage = null;
    });

    try {
      final logoUrl = _adminSettings?.logoImage;

      final filePath = await PdfService.downloadPng(
        language: language,
        logoUrl: logoUrl,
        adminName: _adminSettings?.name,
      );

      setState(() {
        _isGeneratingPng = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PNG downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to download PNG: ${e.toString()}';
        _isGeneratingPng = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marketing Materials'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marketing Materials',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Download marketing materials in different languages and formats.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (_adminSettings?.logoImage != null) ...[
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Logo will be included: ${_adminSettings?.name ?? 'Your business'}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.warning,
                                    color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'No logo uploaded. Files will be generated without logo.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download Options',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLanguageCard(
                                  'English',
                                  'Download English materials',
                                  Icons.language,
                                  Colors.blue,
                                  () => _showDownloadOptions('en'),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildLanguageCard(
                                  'Español',
                                  'Descargar materiales en español',
                                  Icons.language,
                                  Colors.green,
                                  () => _showDownloadOptions('es'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Files',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf,
                                        color: Colors.red, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Leaflet EN.pdf & Leaflet EN.png',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'English marketing materials',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf,
                                        color: Colors.red, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Folleto ES.pdf & Folleto ES.png',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Spanish marketing materials',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.blue.shade700,
                                          size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Your logo will be automatically added to the top right of each file when downloaded.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 20),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildLanguageCard(
    String title,
    String subtitle,
    IconData icon,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: (_isGeneratingPdf || _isGeneratingPng) ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.shade50, color.shade100],
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color.shade700,
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isGeneratingPdf || _isGeneratingPng) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color.shade700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDownloadOptions(String language) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language == 'es' ? 'Descargar Materiales' : 'Download Materials',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDownloadOption(
                    'PDF',
                    Icons.picture_as_pdf,
                    Colors.red,
                    () {
                      Navigator.pop(context);
                      _downloadPdf(language);
                    },
                    _isGeneratingPdf,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildDownloadOption(
                    'PNG',
                    Icons.image,
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      _downloadPng(language);
                    },
                    _isGeneratingPng,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isLoading,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              if (isLoading) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
