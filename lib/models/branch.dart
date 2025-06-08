import 'package:json_annotation/json_annotation.dart';

part 'branch.g.dart';

@JsonSerializable()
class Branch {
  @JsonKey(name: 'id', defaultValue: 0)
  final int id;
  
  @JsonKey(name: 'client_id', defaultValue: 0)
  final int clientId;
  
  @JsonKey(name: 'name', defaultValue: 'Unknown Branch')
  final String name;
  
  @JsonKey(name: 'address')
  final String? address;
  
  @JsonKey(name: 'phone')
  final String? phone;
  
  @JsonKey(name: 'email')
  final String? email;
  
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson)
  final DateTime? updatedAt;

  Branch({
    this.id = 0,
    this.clientId = 0,
    this.name = 'Unknown Branch',
    this.address,
    this.phone,
    this.email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Branch.fromJson(Map<String, dynamic> json) {
    try {
      // Handle potential null or invalid values
      final id = json['id'] is int 
          ? json['id'] 
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
          
      final clientId = json['client_id'] is int
          ? json['client_id']
          : int.tryParse(json['client_id']?.toString() ?? '0') ?? 0;
          
      final name = json['name']?.toString() ?? 'Unknown Branch';
      
      return Branch(
        id: id,
        clientId: clientId,
        name: name,
        address: json['address']?.toString(),
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        createdAt: _dateTimeFromJson(json['created_at'] ?? DateTime.now()),
        updatedAt: _dateTimeFromJson(json['updated_at'] ?? DateTime.now()),
      );
    } catch (e, stackTrace) {
      print('Error parsing Branch from JSON: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'name': name,
    'address': address,
    'phone': phone,
    'email': email,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
  
  static DateTime _dateTimeFromJson(dynamic date) {
    try {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      if (date is String) {
        return DateTime.tryParse(date) ?? DateTime.now();
      }
      return DateTime.now();
    } catch (e) {
      print('Error parsing date: $e');
      return DateTime.now();
    }
  }

  // Copy with method for creating modified copies
  Branch copyWith({
    int? id,
    int? clientId,
    String? name,
    String? address,
    String? phone,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Client? client,
    // List<Request>? requests,
  }) {
    return Branch(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // client: client ?? this.client,
      // requests: requests ?? this.requests,
    );
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Branch &&
        other.id == id &&
        other.clientId == clientId &&
        other.name == name &&
        other.address == address &&
        other.phone == phone &&
        other.email == email &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      clientId,
      name,
      address,
      phone,
      email,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Branch(id: $id, clientId: $clientId, name: $name, address: $address, phone: $phone, email: $email, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}