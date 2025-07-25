class Settings {
  final String adminId;
  final String? name;
  final String? email;
  final String? phone;
  final String? contactName;
  final String? address;
  final String? language;
  final String? logoImage;
  final Map<String, dynamic>? info;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Settings({
    required this.adminId,
    this.name,
    this.email,
    this.phone,
    this.contactName,
    this.address,
    this.language,
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
      contactName: json['contact_name'],
      address: json['address'],
      language: json['language'],
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
      if (contactName != null) 'contact_name': contactName,
      if (address != null) 'address': address,
      if (language != null) 'language': language,
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
    String? contactName,
    String? address,
    String? language,
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
      contactName: contactName ?? this.contactName,
      address: address ?? this.address,
      language: language ?? this.language,
      logoImage: logoImage ?? this.logoImage,
      info: info ?? this.info,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
