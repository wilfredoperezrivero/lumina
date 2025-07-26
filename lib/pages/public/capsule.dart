import 'package:flutter/material.dart';
import '../../models/capsule.dart';
import '../../services/capsule_service.dart';
import '../../services/media_upload_service.dart';
import '../../services/message_service.dart';

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
  bool _messageSubmitted = false;

  // Message form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  // Uploaded media URLs
  String? _uploadedVideoUrl;
  String? _uploadedAudioUrl;

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

      // Load capsule details
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
    setState(() {
      _isUploadingVideo = true;
    });

    try {
      final videoUrl = await MediaUploadService.pickAndUploadFile(
        widget.capsuleId,
        'video',
      );

      if (videoUrl != null) {
        setState(() {
          _uploadedVideoUrl = videoUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingVideo = false;
      });
    }
  }

  Future<void> _uploadAudio() async {
    setState(() {
      _isUploadingAudio = true;
    });

    try {
      final audioUrl = await MediaUploadService.pickAndUploadFile(
        widget.capsuleId,
        'audio',
      );

      if (audioUrl != null) {
        setState(() {
          _uploadedAudioUrl = audioUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingAudio = false;
      });
    }
  }

  Future<void> _recordAudio() async {
    setState(() {
      _isRecordingAudio = true;
    });

    try {
      // For now, we'll use the file picker for audio recording
      // In a real implementation, you'd use a recording package
      final audioUrl = await MediaUploadService.pickAndUploadFile(
        widget.capsuleId,
        'audio',
      );

      if (audioUrl != null) {
        setState(() {
          _uploadedAudioUrl = audioUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio recorded and uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRecordingAudio = false;
      });
    }
  }

  Future<void> _submitMessage() async {
    // Check if at least one content type is provided
    final hasText = _messageController.text.trim().isNotEmpty;
    final hasVideo = _uploadedVideoUrl != null;
    final hasAudio = _uploadedAudioUrl != null;

    if (!hasText && !hasVideo && !hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a message, video, or audio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await MessageService.createMessage(
        capsuleId: widget.capsuleId,
        contentText: hasText ? _messageController.text.trim() : null,
        contributorName: _nameController.text.trim(),
        contributorEmail: null, // No email field
        contentAudioUrl: hasAudio ? _uploadedAudioUrl : null,
        contentVideoUrl: hasVideo ? _uploadedVideoUrl : null,
      );

      // Clear form and uploaded media
      _nameController.clear();
      _messageController.clear();
      setState(() {
        _uploadedVideoUrl = null;
        _uploadedAudioUrl = null;
        _messageSubmitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildCapsuleInfo() {
    if (_capsule == null) return Container();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite,
              size: 32,
              color: Colors.red[400],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'In Loving Memory of',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _capsule!.name ?? 'Unknown',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageForm() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Share Your Memory',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name *',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Your Message (Optional)',
                hintText: 'Share your memories, thoughts, or condolences...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            SizedBox(height: 20),
            Text(
              'Or share media:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildUploadButton(
                    icon: Icons.videocam,
                    label: 'Upload Video',
                    color: Colors.red,
                    isLoading: _isUploadingVideo,
                    onPressed: _uploadVideo,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildUploadButton(
                    icon: Icons.audiotrack,
                    label: 'Upload Audio',
                    color: Colors.blue,
                    isLoading: _isUploadingAudio,
                    onPressed: _uploadAudio,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildUploadButton(
                    icon: Icons.mic,
                    label: 'Record Audio',
                    color: Colors.green,
                    isLoading: _isRecordingAudio,
                    onPressed: _recordAudio,
                  ),
                ),
              ],
            ),
            if (_uploadedVideoUrl != null || _uploadedAudioUrl != null) ...[
              SizedBox(height: 16),
              _buildUploadedMediaPreview(),
            ],
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMessage,
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Submit Message',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedMediaPreview() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uploaded Media:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 8),
          if (_uploadedVideoUrl != null)
            Row(
              children: [
                Icon(Icons.videocam, size: 16, color: Colors.green[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Video uploaded',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _uploadedVideoUrl = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          if (_uploadedAudioUrl != null)
            Row(
              children: [
                Icon(Icons.audiotrack, size: 16, color: Colors.green[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio uploaded',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _uploadedAudioUrl = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required MaterialColor color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color[50],
          foregroundColor: color[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color[200]!),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color[700]!),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildThankYouMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[50]!, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Thank You!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Your message has been submitted successfully.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Your memories and thoughts will be cherished.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('In Memory'),
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
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
                      _messageSubmitted
                          ? _buildThankYouMessage()
                          : _buildMessageForm(),
                    ],
                  ),
                ),
    );
  }
}
