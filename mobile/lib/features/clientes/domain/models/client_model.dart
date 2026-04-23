import 'package:equatable/equatable.dart';

class ClientModel extends Equatable {
  const ClientModel({
    required this.id,
    required this.internalCode,
    required this.businessName,
    required this.contactName,
    required this.phone,
    required this.alternatePhone,
    required this.email,
    required this.taxId,
    required this.addressLine,
    required this.city,
    required this.province,
    required this.routeZone,
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
  final String contactName;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? taxId;
  final String addressLine;
  final String city;
  final String province;
  final String routeZone;
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
      contactName: json['contactName'] as String,
      phone: json['phone'] as String,
      alternatePhone: json['alternatePhone'] as String?,
      email: json['email'] as String?,
      taxId: json['taxId'] as String?,
      addressLine: json['addressLine'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      routeZone: json['routeZone'] as String,
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
      'contactName': contactName,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'email': email,
      'taxId': taxId,
      'addressLine': addressLine,
      'city': city,
      'province': province,
      'routeZone': routeZone,
      'notes': notes,
      'vatCondition': vatCondition,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [
        id,
        internalCode,
        businessName,
        contactName,
        phone,
        alternatePhone,
        email,
        taxId,
        addressLine,
        city,
        province,
        routeZone,
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
