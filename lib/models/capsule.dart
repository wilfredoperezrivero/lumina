class Capsule {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final String? familyId;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final String status; // 'draft', 'active', 'completed'
  final Map<String, dynamic> settings;

  Capsule({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    this.familyId,
    required this.createdAt,
    this.scheduledDate,
    required this.status,
    required this.settings,
  });

  factory Capsule.fromJson(Map<String, dynamic> json) {
    return Capsule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      adminId: json['admin_id'],
      familyId: json['family_id'],
      createdAt: DateTime.parse(json['created_at']),
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      status: json['status'],
      settings: json['settings'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'admin_id': adminId,
      'family_id': familyId,
      'created_at': createdAt.toIso8601String(),
      'scheduled_date': scheduledDate?.toIso8601String(),
      'status': status,
      'settings': settings,
    };
  }
}

class CapsuleInvitation {
  final String id;
  final String capsuleId;
  final String inviteeEmail;
  final String? inviteeName;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String accessToken;

  CapsuleInvitation({
    required this.id,
    required this.capsuleId,
    required this.inviteeEmail,
    this.inviteeName,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    required this.accessToken,
  });

  factory CapsuleInvitation.fromJson(Map<String, dynamic> json) {
    return CapsuleInvitation(
      id: json['id'],
      capsuleId: json['capsule_id'],
      inviteeEmail: json['invitee_email'],
      inviteeName: json['invitee_name'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      accessToken: json['access_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capsule_id': capsuleId,
      'invitee_email': inviteeEmail,
      'invitee_name': inviteeName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'access_token': accessToken,
    };
  }
}

class CapsuleMessage {
  final String id;
  final String capsuleId;
  final String? inviteeId;
  final String message;
  final String? mediaUrl;
  final DateTime createdAt;
  final String status; // 'draft', 'submitted', 'approved'

  CapsuleMessage({
    required this.id,
    required this.capsuleId,
    this.inviteeId,
    required this.message,
    this.mediaUrl,
    required this.createdAt,
    required this.status,
  });

  factory CapsuleMessage.fromJson(Map<String, dynamic> json) {
    return CapsuleMessage(
      id: json['id'],
      capsuleId: json['capsule_id'],
      inviteeId: json['invitee_id'],
      message: json['message'],
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capsule_id': capsuleId,
      'invitee_id': inviteeId,
      'message': message,
      'media_url': mediaUrl,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
