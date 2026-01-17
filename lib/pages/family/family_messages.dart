import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/capsule.dart';
import '../../services/capsule_service.dart';
import '../../services/message_service.dart';
import '../../models/message.dart';
import '../../theme/app_theme.dart';

class FamilyMessagesPage extends StatefulWidget {
  @override
  _FamilyMessagesPageState createState() => _FamilyMessagesPageState();
}

class _FamilyMessagesPageState extends State<FamilyMessagesPage> {
  Capsule? _capsule;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  int _totalMessages = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 0;
        _hasMoreMessages = true;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final capsules = await CapsuleService.getCapsules();
      final familyCapsule = capsules.where((c) => c.familyId == user.id).firstOrNull;

      if (familyCapsule == null) {
        throw Exception('No capsule assigned to this family');
      }

      final totalCount = await MessageService.getMessagesCount(familyCapsule.id);
      final messages = await MessageService.getMessagesForCapsulePaginated(
        familyCapsule.id,
        page: 0,
        pageSize: _pageSize,
      );

      setState(() {
        _capsule = familyCapsule;
        _messages = messages;
        _totalMessages = totalCount;
        _isLoading = false;
        _hasMoreMessages = messages.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _capsule == null) return;

    try {
      setState(() => _isLoadingMore = true);

      final nextPage = _currentPage + 1;
      final moreMessages = await MessageService.getMessagesForCapsulePaginated(
        _capsule!.id,
        page: nextPage,
        pageSize: _pageSize,
      );

      setState(() {
        _messages.addAll(moreMessages);
        _currentPage = nextPage;
        _hasMoreMessages = moreMessages.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refreshMessages() async {
    await _loadData();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Could not open URL'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _toggleMessageVisibility(Message message) async {
    try {
      await MessageService.updateMessageVisibility(message.id, !message.hidden);

      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(hidden: !message.hidden);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.hidden ? 'Message shown' : 'Message hidden'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating message: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
          onPressed: () => context.go('/family/capsule'),
        ),
        title: Text('Messages', style: AppTextStyles.h3.copyWith(fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
              onPressed: _refreshMessages,
              tooltip: 'Refresh',
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
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text('Something went wrong', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Header
        if (_capsule != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card,
              child: Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_capsule!.name ?? 'Unnamed', style: AppTextStyles.subtitle),
                        const SizedBox(height: 2),
                        Text(
                          '$_totalMessages message${_totalMessages == 1 ? '' : 's'}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshMessages,
                  color: AppColors.primaryDark,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: AppColors.primaryDark),
                          ),
                        );
                      }
                      return _buildMessageCard(_messages[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              child: const Icon(Icons.message_outlined, size: 48, color: AppColors.accent),
            ),
            const SizedBox(height: 24),
            Text('No messages yet', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Messages from friends and family will appear here',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: message.hidden ? AppColors.surface : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: message.hidden ? null : AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      (message.contributorName?.isNotEmpty == true ? message.contributorName![0] : 'A').toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.contributorName ?? 'Anonymous',
                        style: AppTextStyles.subtitle.copyWith(
                          color: message.hidden ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      if (message.contributorEmail?.isNotEmpty == true)
                        Text(message.contributorEmail!, style: AppTextStyles.caption),
                    ],
                  ),
                ),

                // Date and visibility button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatDate(message.submittedAt), style: AppTextStyles.caption),
                    const SizedBox(height: 8),
                    _buildVisibilityButton(message),
                  ],
                ),
              ],
            ),

            // Hidden badge
            if (message.hidden) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Hidden',
                  style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],

            // Message text
            if (message.contentText?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                message.contentText!,
                style: AppTextStyles.body.copyWith(
                  color: message.hidden ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ],

            // Media buttons
            if (message.contentAudioUrl?.isNotEmpty == true ||
                message.contentVideoUrl?.isNotEmpty == true ||
                message.contentImageUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (message.contentAudioUrl?.isNotEmpty == true)
                    _buildMediaButton(
                      icon: Icons.audiotrack_rounded,
                      label: 'Audio',
                      color: AppColors.info,
                      onTap: () => _openUrl(message.contentAudioUrl!),
                    ),
                  if (message.contentVideoUrl?.isNotEmpty == true)
                    _buildMediaButton(
                      icon: Icons.play_circle_rounded,
                      label: 'Video',
                      color: AppColors.error,
                      onTap: () => _openUrl(message.contentVideoUrl!),
                    ),
                  if (message.contentImageUrl?.isNotEmpty == true)
                    _buildMediaButton(
                      icon: Icons.image_rounded,
                      label: 'Image',
                      color: AppColors.success,
                      onTap: () => _openUrl(message.contentImageUrl!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityButton(Message message) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleMessageVisibility(message),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: message.hidden ? AppColors.warningLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: message.hidden ? AppColors.warning.withValues(alpha: 0.3) : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                message.hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 14,
                color: message.hidden ? AppColors.warning : AppColors.accent,
              ),
              const SizedBox(width: 4),
              Text(
                message.hidden ? 'Show' : 'Hide',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: message.hidden ? AppColors.warning : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
