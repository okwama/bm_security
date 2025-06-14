class DeliveryCompletion {
  final int id;
  final int completedById;
  final String completedByName;
  final DateTime? completedAt;
  final String? photoUrl;
  final Map<String, dynamic>? bankDetails;
  final double? latitude;
  final double? longitude;
  final String? sealNumber;
  final String? receivingOfficerName;
  final int? receivingOfficerId;
  final String? status;
  final bool? isVaultOfficer;
  final String? notes;

  DeliveryCompletion({
    required this.id,
    required this.completedById,
    required this.completedByName,
    this.completedAt,
    this.photoUrl,
    this.bankDetails,
    this.latitude,
    this.longitude,
    this.sealNumber,
    this.receivingOfficerName,
    this.receivingOfficerId,
    this.status,
    this.isVaultOfficer,
    this.notes,
  });

  factory DeliveryCompletion.fromJson(Map<String, dynamic> json) {
    return DeliveryCompletion(
      id: json['id'] as int,
      completedById: json['completedById'] as int,
      completedByName: json['completedByName'] as String,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      photoUrl: json['photoUrl'] as String?,
      bankDetails: json['bankDetails'] as Map<String, dynamic>?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sealNumber: json['sealNumber'] as String?,
      receivingOfficerName: json['receivingOfficerName'] as String?,
      receivingOfficerId: json['receivingOfficerId'] as int?,
      status: json['status'] as String?,
      isVaultOfficer: json['isVaultOfficer'] as bool?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedById': completedById,
      'completedByName': completedByName,
      'completedAt': completedAt?.toIso8601String(),
      'photoUrl': photoUrl,
      'bankDetails': bankDetails,
      'latitude': latitude,
      'longitude': longitude,
      'sealNumber': sealNumber,
      'receivingOfficerName': receivingOfficerName,
      'receivingOfficerId': receivingOfficerId,
      'status': status,
      'isVaultOfficer': isVaultOfficer,
      'notes': notes,
    };
  }
}
