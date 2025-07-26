class Pack {
  final String id;
  final String? adminId;
  final String? packType;
  final DateTime? purchasedAt;
  final int? capsulesAllowed;
  final int? capsulesUsed;
  final String? paymentStatus;

  Pack({
    required this.id,
    this.adminId,
    this.packType,
    this.purchasedAt,
    this.capsulesAllowed,
    this.capsulesUsed,
    this.paymentStatus,
  });

  factory Pack.fromJson(Map<String, dynamic> json) {
    return Pack(
      id: json['id'],
      adminId: json['admin_id'],
      packType: json['pack_type'],
      purchasedAt: json['purchased_at'] != null
          ? DateTime.tryParse(json['purchased_at'])
          : null,
      capsulesAllowed: json['capsules_allowed'],
      capsulesUsed: json['capsules_used'],
      paymentStatus: json['payment_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (adminId != null) 'admin_id': adminId,
      if (packType != null) 'pack_type': packType,
      if (purchasedAt != null) 'purchased_at': purchasedAt!.toIso8601String(),
      if (capsulesAllowed != null) 'capsules_allowed': capsulesAllowed,
      if (capsulesUsed != null) 'capsules_used': capsulesUsed,
      if (paymentStatus != null) 'payment_status': paymentStatus,
    };
  }

  Pack copyWith({
    String? id,
    String? adminId,
    String? packType,
    DateTime? purchasedAt,
    int? capsulesAllowed,
    int? capsulesUsed,
    String? paymentStatus,
  }) {
    return Pack(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      packType: packType ?? this.packType,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      capsulesAllowed: capsulesAllowed ?? this.capsulesAllowed,
      capsulesUsed: capsulesUsed ?? this.capsulesUsed,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  @override
  String toString() {
    return 'Pack(id: $id, adminId: $adminId, packType: $packType, purchasedAt: $purchasedAt, capsulesAllowed: $capsulesAllowed, capsulesUsed: $capsulesUsed, paymentStatus: $paymentStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pack &&
        other.id == id &&
        other.adminId == adminId &&
        other.packType == packType &&
        other.purchasedAt == purchasedAt &&
        other.capsulesAllowed == capsulesAllowed &&
        other.capsulesUsed == capsulesUsed &&
        other.paymentStatus == paymentStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        adminId.hashCode ^
        packType.hashCode ^
        purchasedAt.hashCode ^
        capsulesAllowed.hashCode ^
        capsulesUsed.hashCode ^
        paymentStatus.hashCode;
  }
}
