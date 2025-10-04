import 'package:equatable/equatable.dart';

class CashCountEntity extends Equatable {
  final int id;
  final int? requestId;
  final int? staffId;
  final int ones;
  final int fives;
  final int tens;
  final int twenties;
  final int forties;
  final int fifties;
  final int hundreds;
  final int twoHundreds;
  final int fiveHundreds;
  final int thousands;
  final double totalAmount;
  final String? sealNumber;
  final String? imagePath;
  final String? imageUrl;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CashCountEntity({
    required this.id,
    this.requestId,
    this.staffId,
    required this.ones,
    required this.fives,
    required this.tens,
    required this.twenties,
    required this.forties,
    required this.fifties,
    required this.hundreds,
    required this.twoHundreds,
    required this.fiveHundreds,
    required this.thousands,
    required this.totalAmount,
    this.sealNumber,
    this.imagePath,
    this.imageUrl,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory CashCountEntity.fromJson(Map<String, dynamic> json) {
    return CashCountEntity(
      id: json['id'] as int,
      requestId: json['requestId'] as int? ?? json['request_id'] as int?,
      staffId: json['staffId'] as int? ?? json['staff_id'] as int?,
      ones: json['ones'] as int? ?? 0,
      fives: json['fives'] as int? ?? 0,
      tens: json['tens'] as int? ?? 0,
      twenties: json['twenties'] as int? ?? 0,
      forties: json['forties'] as int? ?? 0,
      fifties: json['fifties'] as int? ?? 0,
      hundreds: json['hundreds'] as int? ?? 0,
      twoHundreds: json['twoHundreds'] as int? ?? json['two_hundreds'] as int? ?? 0,
      fiveHundreds: json['fiveHundreds'] as int? ?? json['five_hundreds'] as int? ?? 0,
      thousands: json['thousands'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? json['total_amount'] as double? ?? 0.0,
      sealNumber: json['sealNumber'] as String? ?? json['seal_number'] as String?,
      imagePath: json['imagePath'] as String? ?? json['image_path'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  // Calculate total amount from denominations
  double get calculatedTotal {
    return (ones * 1) +
        (fives * 5) +
        (tens * 10) +
        (twenties * 20) +
        (forties * 40) +
        (fifties * 50) +
        (hundreds * 100) +
        (twoHundreds * 200) +
        (fiveHundreds * 500) +
        (thousands * 1000);
  }

  // Check if this is an ATM cash count (no status field)
  bool get isAtmCashCount => status == null;

  @override
  List<Object?> get props => [
        id,
        requestId,
        staffId,
        ones,
        fives,
        tens,
        twenties,
        forties,
        fifties,
        hundreds,
        twoHundreds,
        fiveHundreds,
        thousands,
        totalAmount,
        sealNumber,
        imagePath,
        imageUrl,
        status,
        createdAt,
        updatedAt,
      ];

  CashCountEntity copyWith({
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
    return CashCountEntity(
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
