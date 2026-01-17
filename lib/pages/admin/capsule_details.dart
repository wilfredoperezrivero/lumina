import 'package:flutter/material.dart';
import '../../models/capsule.dart';
import 'package:go_router/go_router.dart';
import '../../services/pdf_service.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class CapsuleDetailsPage extends StatefulWidget {
  final Capsule capsule;
  const CapsuleDetailsPage({Key? key, required this.capsule}) : super(key: key);

  @override
  _CapsuleDetailsPageState createState() => _CapsuleDetailsPageState();
}

class _CapsuleDetailsPageState extends State<CapsuleDetailsPage> {
  Capsule? _capsule;
  bool _isLoading = true;
  bool _isSendingMagicLink = false;

  @override
  void initState() {
    super.initState();
    _capsule = widget.capsule;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.accent),
          onPressed: () => context.go('/admin/list_capsules'),
        ),
        title: Text('Capsule Details', style: AppTextStyles.h3.copyWith(fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.accent),
              onPressed: _editCapsule,
              tooltip: 'Edit',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.home_rounded, color: AppColors.accent),
              onPressed: () => context.go('/admin/dashboard'),
              tooltip: 'Dashboard',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
          : _capsule == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 20),
                      _buildInfoSection(),
                      const SizedBox(height: 20),
                      _buildActionsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.accent),
          ),
          const SizedBox(height: 24),
          Text('Capsule not found', style: AppTextStyles.h3),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryDark, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capsule!.name ?? '(No Name)',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 8),
                buildStatusBadge(_capsule!.status ?? 'Unknown'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
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
                child: const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Information', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),
          if (_capsule!.dateOfBirth?.isNotEmpty == true)
            _buildInfoRow('Date of Birth', _capsule!.dateOfBirth!, Icons.cake_outlined),
          if (_capsule!.dateOfDeath?.isNotEmpty == true)
            _buildInfoRow('Date of Death', _capsule!.dateOfDeath!, Icons.event_outlined),
          if (_capsule!.language?.isNotEmpty == true)
            _buildInfoRow('Language', _capsule!.language!, Icons.language_rounded),
          if (_capsule!.familyEmail?.isNotEmpty == true)
            _buildInfoRow('Family Email', _capsule!.familyEmail!, Icons.email_outlined),
          if (_capsule!.scheduledDate != null)
            _buildInfoRow(
              'Scheduled Date',
              '${_capsule!.scheduledDate!.day}/${_capsule!.scheduledDate!.month}/${_capsule!.scheduledDate!.year}',
              Icons.schedule_rounded,
            ),
          if (_capsule!.createdAt != null)
            _buildInfoRow(
              'Created',
              '${_capsule!.createdAt!.day}/${_capsule!.createdAt!.month}/${_capsule!.createdAt!.year}',
              Icons.calendar_today_rounded,
            ),
          if (_capsule!.expiresAt != null)
            _buildInfoRow(
              'Expires',
              '${_capsule!.expiresAt!.day}/${_capsule!.expiresAt!.month}/${_capsule!.expiresAt!.year}',
              Icons.access_time_rounded,
            ),
          if (_capsule!.finalVideoUrl?.isNotEmpty == true)
            _buildInfoRow('Final Video', 'Available', Icons.video_library_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.label),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
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
                child: const Icon(Icons.touch_app_rounded, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Actions', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),
          if (_capsule!.familyEmail?.isNotEmpty == true) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSendingMagicLink ? null : _resendMagicLink,
                icon: _isSendingMagicLink
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.email_rounded),
                label: Text(_isSendingMagicLink ? 'Sending...' : 'Resend Login Link to Family'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateMemorialPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Generate Memorial PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editCapsule() {
    context.push('/admin/edit-capsule', extra: _capsule);
  }

  Future<void> _resendMagicLink() async {
    if (_capsule?.familyEmail == null || _capsule!.familyEmail!.isEmpty) return;

    setState(() => _isSendingMagicLink = true);

    try {
      await AuthService.sendMagicLink(
        _capsule!.familyEmail!,
        redirectUrl: 'https://app.luminamemorials.com/family/capsule',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login link sent to ${_capsule!.familyEmail}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send login link: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingMagicLink = false);
      }
    }
  }

  Future<void> _generateMemorialPdf() async {
    if (_capsule == null) return;

    final publicUrl = 'https://app.luminamemorials.com/#/capsule/${_capsule!.id}';

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
            content: const Text('Memorial PDF generated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
