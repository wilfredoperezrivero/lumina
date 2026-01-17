import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/capsule.dart';
import '../../services/capsule_service.dart';
import '../../services/media_upload_service.dart';
import '../../services/message_service.dart';
import '../../theme/app_theme.dart';

class CapsulePage extends StatefulWidget {
  final String capsuleId;

  const CapsulePage({Key? key, required this.capsuleId}) : super(key: key);

  @override
  _CapsulePageState createState() => _CapsulePageState();
}

class _CapsulePageState extends State<CapsulePage> {
  Capsule? _capsule;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isUploadingVideo = false;
  bool _isUploadingAudio = false;
  bool _isRecordingAudio = false;
  bool _isUploadingImage = false;
  bool _messageSubmitted = false;

  // Message form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  // Uploaded media URLs
  String? _uploadedVideoUrl;
  String? _uploadedAudioUrl;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCapsule();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCapsule() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final capsule = await CapsuleService.getCapsuleById(widget.capsuleId);

      setState(() {
        _capsule = capsule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load capsule: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadVideo() async {
    setState(() => _isUploadingVideo = true);

    try {
      final videoUrl = await MediaUploadService.pickAndUploadFile(
        widget.capsuleId,
        'video',
      );

      if (videoUrl != null) {
        setState(() => _uploadedVideoUrl = videoUrl);
        _showSuccessSnackBar('Video uploaded successfully!');
      } else {
        _showErrorSnackBar('Failed to upload video');
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading video: ${e.toString()}');
    } finally {
      setState(() => _isUploadingVideo = false);
    }
  }

  Future<void> _uploadImage() async {
    setState(() => _isUploadingImage = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${timestamp}_${pickedFile.name}';

        String imageUrl;

        if (pickedFile.bytes != null) {
          final webImageUrl = await MediaUploadService.uploadImageBytes(
              pickedFile.bytes!, fileName, widget.capsuleId);
          if (webImageUrl != null) {
            imageUrl = webImageUrl;
          } else {
            throw Exception('Failed to upload image. Please try again.');
          }
        } else {
          if (kIsWeb) {
            throw Exception('Could not read file data on web. Please try again.');
          }

          try {
            if (pickedFile.path != null) {
              final file = File(pickedFile.path!);
              imageUrl = await MediaUploadService.uploadImage(
                  file, fileName, widget.capsuleId);
            } else {
              throw Exception('Could not access file data. Please try again.');
            }
          } catch (pathError) {
            throw Exception('Could not access file data. Please try again.');
          }
        }

        setState(() => _uploadedImageUrl = imageUrl);
        _showSuccessSnackBar('Image uploaded successfully!');
      }
    } catch (e) {
      String errorMessage = 'Error uploading image';

      if (e.toString().contains('File too large')) {
        errorMessage = 'Image file is too large. Please select a smaller image (max 10MB).';
      } else if (e.toString().contains('File does not exist')) {
        errorMessage = 'Could not access the selected file. Please try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please allow access to your photos.';
      } else if (e.toString().contains('path is unavailable')) {
        errorMessage = 'File access error. Please try selecting the image again.';
      } else {
        errorMessage = 'Error uploading image: ${e.toString()}';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _uploadAudio() async {
    setState(() => _isUploadingAudio = true);

    try {
      final audioUrl = await MediaUploadService.pickAndUploadFile(
        widget.capsuleId,
        'audio',
      );

      if (audioUrl != null) {
        setState(() => _uploadedAudioUrl = audioUrl);
        _showSuccessSnackBar('Audio uploaded successfully!');
      } else {
        _showErrorSnackBar('Failed to upload audio');
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading audio: ${e.toString()}');
    } finally {
      setState(() => _isUploadingAudio = false);
    }
  }

  Future<void> _recordAudio() async {
    setState(() => _isRecordingAudio = true);

    try {
      final audioUrl = await MediaUploadService.pickAndUploadFile(
        widget.capsuleId,
        'audio',
      );

      if (audioUrl != null) {
        setState(() => _uploadedAudioUrl = audioUrl);
        _showSuccessSnackBar('Audio recorded and uploaded successfully!');
      } else {
        _showErrorSnackBar('Failed to record audio');
      }
    } catch (e) {
      _showErrorSnackBar('Error recording audio: ${e.toString()}');
    } finally {
      setState(() => _isRecordingAudio = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _submitMessage() async {
    final hasText = _messageController.text.trim().isNotEmpty;
    final hasVideo = _uploadedVideoUrl != null;
    final hasAudio = _uploadedAudioUrl != null;
    final hasImage = _uploadedImageUrl != null;

    if (!hasText && !hasVideo && !hasAudio && !hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please provide a message, video, audio, or image'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await MessageService.createMessage(
        capsuleId: widget.capsuleId,
        contentText: hasText ? _messageController.text.trim() : null,
        contributorName: _nameController.text.trim(),
        contributorEmail: null,
        contentAudioUrl: hasAudio ? _uploadedAudioUrl : null,
        contentVideoUrl: hasVideo ? _uploadedVideoUrl : null,
        contentImageUrl: hasImage ? _uploadedImageUrl : null,
      );

      _nameController.clear();
      _messageController.clear();
      setState(() {
        _uploadedVideoUrl = null;
        _uploadedAudioUrl = null;
        _uploadedImageUrl = null;
        _messageSubmitted = true;
      });

      _showSuccessSnackBar('Message submitted successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to submit message: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
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
        title: Text('In Memory', style: AppTextStyles.h3.copyWith(fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
          : _errorMessage != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCapsuleInfo(),
                      const SizedBox(height: 20),
                      _messageSubmitted ? _buildThankYouMessage() : _buildMessageForm(),
                    ],
                  ),
                ),
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
            Text('Error', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCapsule,
              style: primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapsuleInfo() {
    if (_capsule == null) return const SizedBox.shrink();

    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, size: 32, color: AppColors.error),
          ),
          const SizedBox(height: 20),
          Text(
            'In Loving Memory of',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 8),
          Text(
            _capsule!.name ?? 'Unknown',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          if (_capsule!.dateOfBirth?.isNotEmpty == true ||
              _capsule!.dateOfDeath?.isNotEmpty == true ||
              _capsule!.language?.isNotEmpty == true ||
              _capsule!.scheduledDate != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (_capsule!.dateOfBirth?.isNotEmpty == true)
                    _buildInfoRow('Date of Birth', _capsule!.dateOfBirth!),
                  if (_capsule!.dateOfDeath?.isNotEmpty == true)
                    _buildInfoRow('Date of Death', _capsule!.dateOfDeath!),
                  if (_capsule!.language?.isNotEmpty == true)
                    _buildInfoRow('Language', _capsule!.language!),
                  if (_capsule!.scheduledDate != null)
                    _buildInfoRow('Scheduled Date',
                        '${_capsule!.scheduledDate!.day}/${_capsule!.scheduledDate!.month}/${_capsule!.scheduledDate!.year}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageForm() {
    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
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
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primaryDark, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Share Your Memory', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: AppDecorations.inputDecoration(
                label: 'Your Name *',
                hint: 'Enter your full name',
                prefixIcon: Icons.person_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: AppDecorations.inputDecoration(
                label: 'Your Message (Optional)',
                hint: 'Share your memories, thoughts, or condolences...',
              ).copyWith(alignLabelWithHint: true),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            Text('Or share media:', style: AppTextStyles.label),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;

                if (isSmallScreen) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildUploadButton(
                              icon: Icons.image_rounded,
                              label: 'Image',
                              color: AppColors.success,
                              isLoading: _isUploadingImage,
                              onPressed: _uploadImage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildUploadButton(
                              icon: Icons.videocam_rounded,
                              label: 'Video',
                              color: AppColors.error,
                              isLoading: _isUploadingVideo,
                              onPressed: _uploadVideo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildUploadButton(
                              icon: Icons.audiotrack_rounded,
                              label: 'Audio',
                              color: AppColors.info,
                              isLoading: _isUploadingAudio,
                              onPressed: _uploadAudio,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildUploadButton(
                              icon: Icons.mic_rounded,
                              label: 'Record',
                              color: AppColors.warning,
                              isLoading: _isRecordingAudio,
                              onPressed: _recordAudio,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildUploadButton(
                          icon: Icons.image_rounded,
                          label: 'Image',
                          color: AppColors.success,
                          isLoading: _isUploadingImage,
                          onPressed: _uploadImage,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildUploadButton(
                          icon: Icons.videocam_rounded,
                          label: 'Video',
                          color: AppColors.error,
                          isLoading: _isUploadingVideo,
                          onPressed: _uploadVideo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildUploadButton(
                          icon: Icons.audiotrack_rounded,
                          label: 'Audio',
                          color: AppColors.info,
                          isLoading: _isUploadingAudio,
                          onPressed: _uploadAudio,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildUploadButton(
                          icon: Icons.mic_rounded,
                          label: 'Record',
                          color: AppColors.warning,
                          isLoading: _isRecordingAudio,
                          onPressed: _recordAudio,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            if (_uploadedVideoUrl != null || _uploadedAudioUrl != null || _uploadedImageUrl != null) ...[
              const SizedBox(height: 16),
              _buildUploadedMediaPreview(),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitMessage,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Message',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: primaryButtonStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 24, color: color),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedMediaPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uploaded Media:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          if (_uploadedVideoUrl != null) _buildMediaItem(Icons.videocam_rounded, 'Video uploaded', () {
            setState(() => _uploadedVideoUrl = null);
          }),
          if (_uploadedImageUrl != null) _buildMediaItem(Icons.image_rounded, 'Image uploaded', () {
            setState(() => _uploadedImageUrl = null);
          }),
          if (_uploadedAudioUrl != null) _buildMediaItem(Icons.audiotrack_rounded, 'Audio uploaded', () {
            setState(() => _uploadedAudioUrl = null);
          }),
        ],
      ),
    );
  }

  Widget _buildMediaItem(IconData icon, String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.success),
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouMessage() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success),
          ),
          const SizedBox(height: 20),
          Text(
            'Thank You!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your message has been submitted successfully.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your memories and thoughts will be cherished.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
