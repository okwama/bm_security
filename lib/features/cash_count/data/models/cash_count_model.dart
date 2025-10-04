import '../../domain/entities/cash_count_entity.dart';

class CashCountModel extends CashCountEntity {
  const CashCountModel({
    required super.id,
    super.requestId,
    super.staffId,
    required super.ones,
    required super.fives,
    required super.tens,
    required super.twenties,
    required super.forties,
    required super.fifties,
    required super.hundreds,
    required super.twoHundreds,
    required super.fiveHundreds,
    required super.thousands,
    required super.totalAmount,
    super.sealNumber,
    super.imagePath,
    super.imageUrl,
    super.status,
    super.createdAt,
    super.updatedAt,
  });

  factory CashCountModel.fromJson(Map<String, dynamic> json, {bool isAtmCashCount = false}) {
    return CashCountModel(
      id: json['id'] as int,
      requestId: json['request_id'] as int?,
      staffId: json['staff_id'] as int?,
      ones: json['ones'] as int? ?? 0,
      fives: json['fives'] as int? ?? 0,
      tens: json['tens'] as int? ?? 0,
      twenties: json['twenties'] as int? ?? 0,
      forties: json['forties'] as int? ?? 0,
      fifties: json['fifties'] as int? ?? 0,
      hundreds: json['hundreds'] as int? ?? 0,
      twoHundreds: json['twoHundreds'] as int? ?? 0,
      fiveHundreds: json['fiveHundreds'] as int? ?? 0,
      thousands: json['thousands'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      sealNumber: json['sealNumber'] as String?,
      imagePath: json['imagePath'] as String?,
      imageUrl: json['image_url'] as String?,
      status: isAtmCashCount ? null : (json['status'] as String?),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool isAtmCashCount = false}) {
    final json = {
      'id': id,
      'request_id': requestId,
      'staff_id': staffId,
      'ones': ones,
      'fives': fives,
      'tens': tens,
      'twenties': twenties,
      'forties': forties,
      'fifties': fifties,
      'hundreds': hundreds,
      'twoHundreds': twoHundreds,
      'fiveHundreds': fiveHundreds,
      'thousands': thousands,
      'totalAmount': totalAmount,
      'sealNumber': sealNumber,
      'imagePath': imagePath,
      'image_url': imageUrl,
    };

    // Only include status for non-ATM cash counts
    if (!isAtmCashCount && status != null) {
      json['status'] = status;
    }

    return json;
  }

  @override
  CashCountModel copyWith({
    int? id,
    int? requestId,
    int? staffId,
    int? ones,
    int? fives,
    int? tens,
    int? twenties,
    int? forties,
    int? fifties,
    int? hundreds,
    int? twoHundreds,
    int? fiveHundreds,
    int? thousands,
    double? totalAmount,
    String? sealNumber,
    String? imagePath,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashCountModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      staffId: staffId ?? this.staffId,
      ones: ones ?? this.ones,
      fives: fives ?? this.fives,
      tens: tens ?? this.tens,
      twenties: twenties ?? this.twenties,
      forties: forties ?? this.forties,
      fifties: fifties ?? this.fifties,
      hundreds: hundreds ?? this.hundreds,
      twoHundreds: twoHundreds ?? this.twoHundreds,
      fiveHundreds: fiveHundreds ?? this.fiveHundreds,
      thousands: thousands ?? this.thousands,
      totalAmount: totalAmount ?? this.totalAmount,
      sealNumber: sealNumber ?? this.sealNumber,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
