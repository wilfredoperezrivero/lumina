class Message {
  final String id;
  final String capsuleId;
  final String? contentText;
  final String? contentAudioUrl;
  final String? contentVideoUrl;
  final String? contentImageUrl;
  final DateTime? submittedAt;
  final bool hidden;
  final String? contributorName;
  final String? contributorEmail;
  final DateTime? createdAt;

  Message({
    required this.id,
    required this.capsuleId,
    this.contentText,
    this.contentAudioUrl,
    this.contentVideoUrl,
    this.contentImageUrl,
    this.submittedAt,
    this.hidden = false,
    this.contributorName,
    this.contributorEmail,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      capsuleId: json['capsule_id'],
      contentText: json['content_text'],
      contentAudioUrl: json['content_audio_url'],
      contentVideoUrl: json['content_video_url'],
      contentImageUrl: json['content_image_url'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'])
          : null,
      hidden: json['hidden'] ?? false,
      contributorName: json['contributor_name'],
      contributorEmail: json['contributor_email'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capsule_id': capsuleId,
      'content_text': contentText,
      'content_audio_url': contentAudioUrl,
      'content_video_url': contentVideoUrl,
      'content_image_url': contentImageUrl,
      'submitted_at': submittedAt?.toIso8601String(),
      'hidden': hidden,
      'contributor_name': contributorName,
      'contributor_email': contributorEmail,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
