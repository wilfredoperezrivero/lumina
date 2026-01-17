import 'package:flutter/material.dart';
import '../../services/pdf_service.dart';
import '../../services/settings_service.dart';
import '../../models/settings.dart';
import '../../theme/app_theme.dart';

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

      await PdfService.downloadPdf(
        language: language,
        logoUrl: logoUrl,
        adminName: _adminSettings?.name,
      );

      setState(() {
        _isGeneratingPdf = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF downloaded successfully!'),
          backgroundColor: AppColors.success,
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

      await PdfService.downloadPng(
        language: language,
        logoUrl: logoUrl,
        adminName: _adminSettings?.name,
      );

      setState(() {
        _isGeneratingPng = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PNG downloaded successfully!'),
          backgroundColor: AppColors.success,
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
      backgroundColor: AppColors.surface,
      appBar: buildAppBar(context: context, title: 'Marketing Materials'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  _buildSectionCard(
                    title: 'Marketing Materials',
                    icon: Icons.campaign_outlined,
                    children: [
                      Text(
                        'Download marketing materials in different languages and formats.',
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 16),
                      if (_adminSettings?.logoImage != null)
                        _buildStatusRow(
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          text: 'Logo will be included: ${_adminSettings?.name ?? 'Your business'}',
                        )
                      else
                        _buildStatusRow(
                          icon: Icons.warning_rounded,
                          color: AppColors.warning,
                          text: 'No logo uploaded. Files will be generated without logo.',
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Download Options
                  _buildSectionCard(
                    title: 'Download Options',
                    icon: Icons.download_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildLanguageCard(
                              'English',
                              'Download English materials',
                              () => _showDownloadOptions('en'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildLanguageCard(
                              'Español',
                              'Descargar materiales en español',
                              () => _showDownloadOptions('es'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Available Files
                  _buildSectionCard(
                    title: 'Available Files',
                    icon: Icons.folder_outlined,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildFileRow(
                              'Leaflet EN.pdf & Leaflet EN.png',
                              'English marketing materials',
                            ),
                            const SizedBox(height: 16),
                            _buildFileRow(
                              'Folleto ES.pdf & Folleto ES.png',
                              'Spanish marketing materials',
                            ),
                            const SizedBox(height: 16),
                            buildInfoTip(
                              message: 'Your logo will be automatically added to the top right of each file when downloaded.',
                              icon: Icons.info_outline_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    buildAlertContainer(message: _errorMessage!, isError: true),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(String title, String subtitle, VoidCallback onTap) {
    final isLoading = _isGeneratingPdf || _isGeneratingPng;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.language_rounded,
                  size: 28,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.subtitle),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              if (isLoading) ...[
                const SizedBox(height: 12),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileRow(String title, String subtitle) {
    return Row(
      children: [
        Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.subtitle.copyWith(fontSize: 14)),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }

  void _showDownloadOptions(String language) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              language == 'es' ? 'Descargar Materiales' : 'Download Materials',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDownloadOption(
                    'PDF',
                    Icons.picture_as_pdf_rounded,
                    AppColors.error,
                    () {
                      Navigator.pop(context);
                      _downloadPdf(language);
                    },
                    _isGeneratingPdf,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDownloadOption(
                    'PNG',
                    Icons.image_rounded,
                    AppColors.info,
                    () {
                      Navigator.pop(context);
                      _downloadPng(language);
                    },
                    _isGeneratingPng,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: color),
              ),
              if (isLoading) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
