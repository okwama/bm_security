import 'package:json_annotation/json_annotation.dart';

part 'cash_count.g.dart';

@JsonSerializable()
class CashCount {
  @JsonKey(defaultValue: 0)
  final int ones;

  @JsonKey(defaultValue: 0)
  final int fives;

  @JsonKey(defaultValue: 0)
  final int tens;

  @JsonKey(defaultValue: 0)
  final int twenties;

  @JsonKey(defaultValue: 0)
  final int forties;

  @JsonKey(defaultValue: 0)
  final int fifties;

  @JsonKey(defaultValue: 0)
  final int hundreds;

  @JsonKey(defaultValue: 0)
  final int twoHundreds;

  @JsonKey(name: 'fiveHundreds', defaultValue: 0)
  final int fiveHundreds;

  @JsonKey(defaultValue: 0)
  final int thousands;

  @JsonKey(includeIfNull: false)
  final String? sealNumber;

  @JsonKey(includeToJson: false, includeFromJson: false)
  final String? imageUrl;

  CashCount({
    this.ones = 0,
    this.fives = 0,
    this.tens = 0,
    this.twenties = 0,
    this.forties = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.twoHundreds = 0,
    this.fiveHundreds = 0,
    this.thousands = 0,
    this.sealNumber,
    this.imageUrl,
  });

  int get totalAmount =>
      (ones * 1) +
      (fives * 5) +
      (tens * 10) +
      (twenties * 20) +
      (forties * 40) +
      (fifties * 50) +
      (hundreds * 100) +
      (twoHundreds * 200) +
      (fiveHundreds * 500) +
      (thousands * 1000);

  factory CashCount.fromJson(Map<String, dynamic> json) {
    return CashCount(
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
      sealNumber: json['sealNumber'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      if (sealNumber != null) 'sealNumber': sealNumber,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return 'CashCount(totalAmount: $totalAmount, sealNumber: $sealNumber)';
  }

  // Add a method to create a copy with updated values
  CashCount copyWith({
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
    String? sealNumber,
    String? imageUrl,
  }) {
    return CashCount(
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
      sealNumber: sealNumber ?? this.sealNumber,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
