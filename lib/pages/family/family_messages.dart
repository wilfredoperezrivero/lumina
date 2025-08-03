import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/capsule.dart';
import '../../services/capsule_service.dart';
import '../../services/message_service.dart';
import '../../models/message.dart';

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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

      // Get capsule assigned to this family user
      final capsules = await CapsuleService.getCapsules();
      final familyCapsule =
          capsules.where((c) => c.familyId == user.id).firstOrNull;

      if (familyCapsule == null) {
        throw Exception('No capsule assigned to this family');
      }

      // Get total count and first page of messages
      final totalCount =
          await MessageService.getMessagesCount(familyCapsule.id);
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
      setState(() {
        _isLoadingMore = true;
      });

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
      setState(() {
        _isLoadingMore = false;
      });
      // Don't show error for loading more, just silently fail
      print('Failed to load more messages: ${e.toString()}');
    }
  }

  Future<void> _refreshMessages() async {
    await _loadData();
  }

  Widget _buildMessageCard(Message message) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: message.hidden ? Colors.grey[100] : null,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.contributorName ?? 'Anonymous',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (message.contributorEmail?.isNotEmpty == true) ...[
                        SizedBox(height: 4),
                        Text(
                          message.contributorEmail!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _formatDate(message.submittedAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _toggleMessageVisibility(message),
                      icon: Icon(
                        message.hidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 16,
                      ),
                      label: Text(message.hidden ? 'Show' : 'Hide'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            message.hidden ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size(0, 28),
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (message.hidden) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Hidden',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
            if (message.contentText?.isNotEmpty == true) ...[
              Text(
                message.contentText!,
                style: TextStyle(
                  fontSize: 14,
                  color: message.hidden ? Colors.grey[600] : null,
                ),
              ),
              SizedBox(height: 8),
            ],
            // Media buttons on the left
            if (message.contentAudioUrl?.isNotEmpty == true ||
                message.contentVideoUrl?.isNotEmpty == true ||
                message.contentImageUrl?.isNotEmpty == true) ...[
              Row(
                children: [
                  if (message.contentAudioUrl?.isNotEmpty == true) ...[
                    ElevatedButton.icon(
                      onPressed: () => _openAudio(message.contentAudioUrl!),
                      icon: Icon(Icons.play_arrow, size: 16),
                      label: Text('Audio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size(0, 24),
                        textStyle: TextStyle(fontSize: 11),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (message.contentVideoUrl?.isNotEmpty == true) ...[
                    ElevatedButton.icon(
                      onPressed: () => _openVideo(message.contentVideoUrl!),
                      icon: Icon(Icons.play_arrow, size: 16),
                      label: Text('Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size(0, 24),
                        textStyle: TextStyle(fontSize: 11),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (message.contentImageUrl?.isNotEmpty == true) ...[
                    ElevatedButton.icon(
                      onPressed: () => _openImage(message.contentImageUrl!),
                      icon: Icon(Icons.open_in_new, size: 16),
                      label: Text('Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size(0, 24),
                        textStyle: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _openVideo(String videoUrl) async {
    try {
      final uri = Uri.parse(videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleMessageVisibility(Message message) async {
    try {
      // Update the message in the database
      await MessageService.updateMessageVisibility(message.id, !message.hidden);

      // Update the local state
      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(hidden: !message.hidden);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.hidden ? 'Message shown' : 'Message hidden'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openAudio(String audioUrl) async {
    try {
      final uri = Uri.parse(audioUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/family/capsule'),
        ),
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
                        onPressed: _loadData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        if (_capsule != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            color: Colors.blue[50],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Capsule: ${_capsule!.name ?? 'Unnamed'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Total: $_totalMessages message${_totalMessages == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: _messages.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.message,
                                          size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No messages yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Messages from friends and family will appear here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _refreshMessages,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: EdgeInsets.all(16),
                                    itemCount: _messages.length +
                                        (_isLoadingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _messages.length) {
                                        return Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      return _buildMessageCard(
                                          _messages[index]);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
