import 'package:equatable/equatable.dart';

class ClientModel extends Equatable {
  const ClientModel({
    required this.id,
    required this.internalCode,
    required this.businessName,
    required this.phone,
    required this.email,
    required this.taxId,
    required this.addressLine,
    required this.city,
    required this.province,
    required this.routeZone,
    required this.zoneId,
    required this.zoneName,
    required this.notes,
    required this.vatCondition,
    required this.creditLimit,
    required this.currentBalance,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String internalCode;
  final String businessName;
  final String phone;
  final String? email;
  final String? taxId;
  final String addressLine;
  final String city;
  final String province;
  final String routeZone;
  final String? zoneId;
  final String? zoneName;
  final String? notes;
  final String vatCondition;
  final double creditLimit;
  final double currentBalance;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime? createdAt;

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      internalCode: json['internalCode'] as String,
      businessName: json['businessName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      taxId: json['taxId'] as String?,
      addressLine: json['addressLine'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      routeZone: json['routeZone'] as String,
      zoneId: json['zoneId'] as String?,
      zoneName: json['zoneName'] as String?,
      notes: json['notes'] as String?,
      vatCondition: json['vatCondition'] as String? ?? 'No especificado',
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'internalCode': internalCode,
      'businessName': businessName,
      'phone': phone,
      'email': email,
      'taxId': taxId,
      'addressLine': addressLine,
      'city': city,
      'province': province,
      'routeZone': routeZone,
      'zoneId': zoneId,
      'notes': notes,
      'vatCondition': vatCondition,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  ClientModel copyWith({
    String? id,
    String? internalCode,
    String? businessName,
    String? phone,
    String? email,
    String? taxId,
    String? addressLine,
    String? city,
    String? province,
    String? routeZone,
    String? zoneId,
    String? zoneName,
    String? notes,
    String? vatCondition,
    double? creditLimit,
    double? currentBalance,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? createdAt,
    bool clearEmail = false,
    bool clearTaxId = false,
    bool clearZoneId = false,
    bool clearZoneName = false,
    bool clearNotes = false,
    bool clearLatitude = false,
    bool clearLongitude = false,
  }) {
    return ClientModel(
      id: id ?? this.id,
      internalCode: internalCode ?? this.internalCode,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      email: clearEmail ? null : (email ?? this.email),
      taxId: clearTaxId ? null : (taxId ?? this.taxId),
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      province: province ?? this.province,
      routeZone: routeZone ?? this.routeZone,
      zoneId: clearZoneId ? null : (zoneId ?? this.zoneId),
      zoneName: clearZoneName ? null : (zoneName ?? this.zoneName),
      notes: clearNotes ? null : (notes ?? this.notes),
      vatCondition: vatCondition ?? this.vatCondition,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      latitude: clearLatitude ? null : (latitude ?? this.latitude),
      longitude: clearLongitude ? null : (longitude ?? this.longitude),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        internalCode,
        businessName,
        phone,
        email,
        taxId,
        addressLine,
        city,
        province,
        routeZone,
        zoneId,
        zoneName,
        notes,
        vatCondition,
        creditLimit,
        currentBalance,
        latitude,
        longitude,
        isActive,
        createdAt,
      ];
}
