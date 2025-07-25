class Settings {
  final String adminId;
  final String? name;
  final String? email;
  final String? phone;
  final String? logoImage;
  final Map<String, dynamic>? info;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Settings({
    required this.adminId,
    this.name,
    this.email,
    this.phone,
    this.logoImage,
    this.info,
    this.createdAt,
    this.updatedAt,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      adminId: json['admin_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      logoImage: json['logo_image'],
      info:
          json['info'] != null ? Map<String, dynamic>.from(json['info']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin_id': adminId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (logoImage != null) 'logo_image': logoImage,
      if (info != null) 'info': info,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Settings copyWith({
    String? adminId,
    String? name,
    String? email,
    String? phone,
    String? logoImage,
    Map<String, dynamic>? info,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Settings(
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      logoImage: logoImage ?? this.logoImage,
      info: info ?? this.info,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
