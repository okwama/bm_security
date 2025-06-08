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
  final String? imagePath;

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
    this.imagePath,
  });

  int get total => 
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

  factory CashCount.fromJson(Map<String, dynamic> json) => 
      _$CashCountFromJson(json);
      
  Map<String, dynamic> toJson() => _$CashCountToJson(this);
  
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
    String? imagePath,
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
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
