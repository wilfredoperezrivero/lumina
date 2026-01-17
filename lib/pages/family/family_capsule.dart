import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/capsule.dart';
import '../../services/capsule_service.dart';
import '../../theme/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

      final capsules = await CapsuleService.getCapsules();
      final familyCapsule = capsules.where((c) => c.familyId == user.id).firstOrNull;

      if (familyCapsule == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Welcome! You have successfully registered. However, no capsule has been assigned to you yet. Please contact the capsule administrator to get access to your family capsule.';
        });
        return;
      }

      final currentUrl = Uri.base.toString().replaceAll('/family/capsule', '');
      _publicUrl = '$currentUrl/capsule/${familyCapsule.id}';

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

  Future<void> _closeCapsuleAndGenerateVideo() async {
    if (_capsule == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Close Capsule', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to close this capsule?', style: AppTextStyles.body),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_rounded, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'This action is irreversible',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildWarningItem('The capsule will be permanently closed'),
                  _buildWarningItem('No new messages can be added'),
                  _buildWarningItem('Video generation will begin automatically'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Capsule'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isGeneratingVideo = true);

    try {
      await CapsuleService.closeCapsuleAndGenerateVideo(_capsule!.id);
      await _loadCapsule();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Capsule closed and video generation started!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to close capsule: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isGeneratingVideo = false);
    }
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600)),
          Expanded(child: Text(text, style: TextStyle(color: AppColors.warning, fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Could not open URL'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('URL copied to clipboard'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Family Capsule', style: AppTextStyles.h3.copyWith(fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.accent),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              },
              tooltip: 'Sign out',
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
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(Icons.info_outline_rounded, size: 48, color: AppColors.warning),
            ),
            const SizedBox(height: 24),
            Text('No Capsule Found', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCapsule,
              style: primaryButtonStyle,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              },
              child: Text('Sign Out', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCapsuleInfo(),
          const SizedBox(height: 20),
          _buildQRCode(),
          const SizedBox(height: 20),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildCapsuleInfo() {
    if (_capsule == null) return const SizedBox.shrink();

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
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Capsule Information', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Name', _capsule!.name ?? 'Not specified'),
          _buildInfoRow('Status', _capsule!.status ?? 'Unknown'),
          if (_capsule!.dateOfBirth?.isNotEmpty == true)
            _buildInfoRow('Date of Birth', _capsule!.dateOfBirth!),
          if (_capsule!.dateOfDeath?.isNotEmpty == true)
            _buildInfoRow('Date of Death', _capsule!.dateOfDeath!),
          if (_capsule!.language?.isNotEmpty == true)
            _buildInfoRow('Language', _capsule!.language!),
          if (_capsule!.scheduledDate != null)
            _buildInfoRow('Scheduled Date', '${_capsule!.scheduledDate!.day}/${_capsule!.scheduledDate!.month}/${_capsule!.scheduledDate!.year}'),
          if (_capsule!.expiresAt != null)
            _buildInfoRow('Expires', '${_capsule!.expiresAt!.day}/${_capsule!.expiresAt!.month}/${_capsule!.expiresAt!.year}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildQRCode() {
    if (_publicUrl == null) return const SizedBox.shrink();

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
                child: const Icon(Icons.qr_code_rounded, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Share Capsule', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: _publicUrl!,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Scan to access capsule', style: AppTextStyles.caption),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openUrl(_publicUrl!),
                    child: Text(
                      _publicUrl!,
                      style: TextStyle(
                        color: AppColors.info,
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(_publicUrl!),
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.accent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy URL',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go('/family/messages'),
                icon: const Icon(Icons.message_rounded),
                label: const Text('Review Messages'),
                style: primaryButtonStyle,
              ),
              if (_capsule?.finalVideoUrl != null)
                ElevatedButton.icon(
                  onPressed: () => _openUrl(_capsule!.finalVideoUrl!),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                )
              else if (_capsule?.status == 'active' || _capsule?.status == 'draft')
                ElevatedButton.icon(
                  onPressed: _isGeneratingVideo ? null : _closeCapsuleAndGenerateVideo,
                  icon: _isGeneratingVideo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.video_library_rounded),
                  label: Text(_isGeneratingVideo ? 'Generating...' : 'Close & Generate Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
