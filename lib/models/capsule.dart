class Capsule {
  final String id;
  final String? adminId;
  final String? familyId;
  final String? name;
  final String? dateOfBirth;
  final String? dateOfDeath;
  final String? language;
  final String? image;
  final DateTime? expiresAt;
  final String? finalVideoUrl;
  final String? status;
  final String? familyEmail;
  final DateTime? createdAt;
  final DateTime? scheduledDate;

  Capsule({
    required this.id,
    this.adminId,
    this.familyId,
    this.name,
    this.dateOfBirth,
    this.dateOfDeath,
    this.language,
    this.image,
    this.expiresAt,
    this.finalVideoUrl,
    this.status,
    this.familyEmail,
    this.createdAt,
    this.scheduledDate,
  });

  factory Capsule.fromJson(Map<String, dynamic> json) {
    return Capsule(
      id: json['id'],
      adminId: json['admin_id'],
      familyId: json['family_id'],
      name: json['name'],
      dateOfBirth: json['date_of_birth'],
      dateOfDeath: json['date_of_death'],
      language: json['language'],
      image: json['image'],
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      finalVideoUrl: json['final_video_url'],
      status: json['status'],
      familyEmail: json['family_email'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'family_id': familyId,
      'name': name,
      'date_of_birth': dateOfBirth,
      'date_of_death': dateOfDeath,
      'language': language,
      'image': image,
      'expires_at': expiresAt?.toIso8601String(),
      'final_video_url': finalVideoUrl,
      'status': status,
      'family_email': familyEmail,
      'created_at': createdAt?.toIso8601String(),
      'scheduled_date': scheduledDate?.toIso8601String(),
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
