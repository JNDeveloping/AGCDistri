import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CompanySettingsModel extends Equatable {
  const CompanySettingsModel({
    required this.companyName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.buttonColor,
    required this.backgroundColor,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.province,
    required this.taxId,
    required this.slogan,
    required this.defaultProfitPercentage,
    required this.priceRoundingEnabled,
    required this.priceRoundingMultiple,
  });

  final String companyName;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final String buttonColor;
  final String backgroundColor;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? province;
  final String? taxId;
  final String? slogan;
  final double defaultProfitPercentage;
  final bool priceRoundingEnabled;
  final int priceRoundingMultiple;

  static const defaults = CompanySettingsModel(
    companyName: 'AGC Distribuidora',
    logoUrl: null,
    primaryColor: '#1E4D6B',
    secondaryColor: '#2FA37F',
    buttonColor: '#1E4D6B',
    backgroundColor: '#F2F5F8',
    phone: null,
    email: null,
    address: null,
    city: null,
    province: null,
    taxId: null,
    slogan: null,
    defaultProfitPercentage: 45,
    priceRoundingEnabled: true,
    priceRoundingMultiple: 10,
  );

  factory CompanySettingsModel.fromJson(Map<String, dynamic> json) {
    return CompanySettingsModel(
      companyName: (json['companyName'] as String?) ?? defaults.companyName,
      logoUrl: json['logoUrl'] as String?,
      primaryColor: (json['primaryColor'] as String?) ?? defaults.primaryColor,
      secondaryColor: (json['secondaryColor'] as String?) ?? defaults.secondaryColor,
      buttonColor: (json['buttonColor'] as String?) ?? defaults.buttonColor,
      backgroundColor: (json['backgroundColor'] as String?) ?? defaults.backgroundColor,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      taxId: json['taxId'] as String?,
      slogan: json['slogan'] as String?,
      defaultProfitPercentage: (json['defaultProfitPercentage'] as num?)?.toDouble() ?? defaults.defaultProfitPercentage,
      priceRoundingEnabled: json['priceRoundingEnabled'] as bool? ?? defaults.priceRoundingEnabled,
      priceRoundingMultiple: (json['priceRoundingMultiple'] as num?)?.toInt() ?? defaults.priceRoundingMultiple,
    );
  }

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'logoUrl': logoUrl,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'buttonColor': buttonColor,
        'backgroundColor': backgroundColor,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'province': province,
        'taxId': taxId,
        'slogan': slogan,
        'defaultProfitPercentage': defaultProfitPercentage,
        'priceRoundingEnabled': priceRoundingEnabled,
        'priceRoundingMultiple': priceRoundingMultiple,
      };

  static Color parseColor(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  @override
  List<Object?> get props => [
        companyName,
        logoUrl,
        primaryColor,
        secondaryColor,
        buttonColor,
        backgroundColor,
        phone,
        email,
        address,
        city,
        province,
        taxId,
        slogan,
        defaultProfitPercentage,
        priceRoundingEnabled,
        priceRoundingMultiple,
      ];
}
