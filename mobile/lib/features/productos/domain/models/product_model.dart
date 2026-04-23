import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  const ProductModel({
    required this.id,
    required this.internalCode,
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.brand,
    required this.category,
    required this.segment,
    required this.barcode,
    required this.unitMeasure,
    required this.presentation,
    required this.cost,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.marginPercentage,
    required this.stockCurrent,
    required this.stockMinimum,
    required this.isActive,
    required this.isFeatured,
    required this.imageUrl,
    required this.taxRate,
    required this.createdAt,
    required this.updatedAt,
    required this.lowStock,
  });

  final String id;
  final String internalCode;
  final String name;
  final String shortDescription;
  final String? longDescription;
  final String brand;
  final String category;
  final String segment;
  final String? barcode;
  final String unitMeasure;
  final String presentation;
  final double? cost;
  final double? wholesalePrice;
  final double? retailPrice;
  final double? marginPercentage;
  final double stockCurrent;
  final double stockMinimum;
  final bool isActive;
  final bool isFeatured;
  final String? imageUrl;
  final double? taxRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool lowStock;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      internalCode: json['internalCode'] as String,
      name: json['name'] as String,
      shortDescription: json['shortDescription'] as String,
      longDescription: json['longDescription'] as String?,
      brand: json['brand'] as String,
      category: json['category'] as String,
      segment: json['segment'] as String,
      barcode: json['barcode'] as String?,
      unitMeasure: json['unitMeasure'] as String,
      presentation: json['presentation'] as String,
      cost: (json['cost'] as num?)?.toDouble(),
      wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble(),
      retailPrice: (json['retailPrice'] as num?)?.toDouble(),
      marginPercentage: (json['marginPercentage'] as num?)?.toDouble(),
      stockCurrent: (json['stockCurrent'] as num?)?.toDouble() ?? 0,
      stockMinimum: (json['stockMinimum'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      taxRate: (json['taxRate'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      lowStock: json['lowStock'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'internalCode': internalCode,
      'name': name,
      'shortDescription': shortDescription,
      'longDescription': longDescription,
      'brand': brand,
      'category': category,
      'segment': segment,
      'barcode': barcode,
      'unitMeasure': unitMeasure,
      'presentation': presentation,
      'cost': cost,
      'wholesalePrice': wholesalePrice,
      'retailPrice': retailPrice,
      'marginPercentage': marginPercentage,
      'stockCurrent': stockCurrent,
      'stockMinimum': stockMinimum,
      'isFeatured': isFeatured,
      'imageUrl': imageUrl,
      'taxRate': taxRate,
    };
  }

  @override
  List<Object?> get props => [
        id,
        internalCode,
        name,
        shortDescription,
        brand,
        category,
        segment,
        stockCurrent,
        stockMinimum,
        isActive,
        lowStock,
      ];
}
