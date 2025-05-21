enum VisitorStatus { pending, approved, rejected, completed, cancelled }

class Visitor {
  final int? id;
  final int userId;
  final String userName;
  final String userPhone;
  final String visitorName;
  final String visitorPhone;
  final String reasonForVisit;
  final String? idPhotoUrl;
  final DateTime scheduledVisitTime;
  final DateTime createdAt;
  final VisitorStatus status;
  final String? notes;
  final Map<String, dynamic>? user;

  Visitor({
    this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.visitorName,
    required this.visitorPhone,
    required this.reasonForVisit,
    this.idPhotoUrl,
    required this.scheduledVisitTime,
    required this.createdAt,
    required this.status,
    this.notes,
    this.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'visitorName': visitorName,
      'visitorPhone': visitorPhone,
      'reasonForVisit': reasonForVisit,
      'idPhotoUrl': idPhotoUrl,
      'scheduledVisitTime': scheduledVisitTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'user': user,
    };
  }

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      visitorName: json['visitorName'],
      visitorPhone: json['visitorPhone'],
      reasonForVisit: json['reasonForVisit'],
      idPhotoUrl: json['idPhotoUrl'],
      scheduledVisitTime: DateTime.parse(json['scheduledVisitTime']),
      createdAt: DateTime.parse(json['createdAt']),
      status: VisitorStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => VisitorStatus.pending,
      ),
      notes: json['notes'],
      user: json['user'],
    );
  }

  Visitor copyWith({
    int? id,
    int? userId,
    String? userName,
    String? userPhone,
    String? visitorName,
    String? visitorPhone,
    String? reasonForVisit,
    String? idPhotoUrl,
    DateTime? scheduledVisitTime,
    DateTime? createdAt,
    VisitorStatus? status,
    String? notes,
    Map<String, dynamic>? user,
  }) {
    return Visitor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      visitorName: visitorName ?? this.visitorName,
      visitorPhone: visitorPhone ?? this.visitorPhone,
      reasonForVisit: reasonForVisit ?? this.reasonForVisit,
      idPhotoUrl: idPhotoUrl ?? this.idPhotoUrl,
      scheduledVisitTime: scheduledVisitTime ?? this.scheduledVisitTime,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      user: user ?? this.user,
    );
  }
}
