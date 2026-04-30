import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  const ProductModel({
    required this.id,
    required this.internalCode,
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.brand,
    required this.categoryId,
    required this.categoryName,
    required this.barcode,
    required this.unitMeasure,
    required this.cost,
    required this.salePrice,
    required this.marginPercentage,
    required this.stockCurrent,
    required this.stockMinimum,
    required this.isActive,
    required this.isFeatured,
    required this.imageUrl,
    required this.taxRate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.lowStock,
    this.hasVariants = false,
    this.hasActivePromotion = false,
  });

  final String id;
  final String? internalCode;
  final String name;
  final String? shortDescription;
  final String? longDescription;
  final String? brand;
  final String? categoryId;
  final String? categoryName;
  final String? barcode;
  final String? unitMeasure;
  final double? cost;
  final double salePrice;
  final double? marginPercentage;
  final double stockCurrent;
  final double stockMinimum;
  final bool isActive;
  final bool isFeatured;
  final String? imageUrl;
  final double? taxRate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool lowStock;
  final bool hasVariants;
  final bool hasActivePromotion;
  bool get isVariantProduct => hasVariants;
  bool get canAdjustBaseStock => !hasVariants;
  String get displayStockLabel => hasVariants ? 'Stock por variantes' : stockCurrent.toStringAsFixed(2);

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      internalCode: json['internalCode'] as String?,
      name: json['name'] as String,
      shortDescription: json['shortDescription'] as String?,
      longDescription: json['longDescription'] as String?,
      brand: json['brand'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      barcode: json['barcode'] as String?,
      unitMeasure: json['unitMeasure'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      salePrice: ((json['salePrice'] as num?) ?? (json['wholesalePrice'] as num?) ?? 0).toDouble(),
      marginPercentage: (json['marginPercentage'] as num?)?.toDouble(),
      stockCurrent: (json['stockCurrent'] as num?)?.toDouble() ?? 0,
      stockMinimum: (json['stockMinimum'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      taxRate: (json['taxRate'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      lowStock: json['lowStock'] as bool? ?? false,
      hasVariants: json['hasVariants'] as bool? ?? false,
      hasActivePromotion: json['hasActivePromotion'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'internalCode': internalCode,
      'name': name,
      'shortDescription': shortDescription,
      'longDescription': longDescription,
      'brand': brand,
      'categoryId': categoryId,
      'barcode': barcode,
      'unitMeasure': unitMeasure,
      'cost': cost,
      'salePrice': salePrice,
      'marginPercentage': marginPercentage,
      'stockCurrent': stockCurrent,
      'stockMinimum': stockMinimum,
      'isFeatured': isFeatured,
      'imageUrl': imageUrl,
      'taxRate': taxRate,
      'notes': notes,
      'hasVariants': hasVariants,
    };
  }

  @override
  List<Object?> get props => [
        id,
        internalCode,
        name,
        categoryId,
        categoryName,
        salePrice,
        stockCurrent,
        stockMinimum,
        isActive,
        lowStock,
        hasVariants,
        hasActivePromotion,
      ];
}

class ProductActivePromotion {
  const ProductActivePromotion({
    required this.id,
    required this.name,
    required this.type,
    this.startDate,
    this.endDate,
    this.discountType,
    this.discountValue,
    this.fixedPrice,
    this.scope = 'product',
    this.variantId,
  });

  final String id;
  final String name;
  final String type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? discountType;
  final double? discountValue;
  final double? fixedPrice;
  final String scope;
  final String? variantId;

  factory ProductActivePromotion.fromJson(Map<String, dynamic> json) => ProductActivePromotion(
        id: '${json['id']}',
        name: (json['name'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        startDate: json['startDate'] == null ? null : DateTime.tryParse(json['startDate'].toString()),
        endDate: json['endDate'] == null ? null : DateTime.tryParse(json['endDate'].toString()),
        discountType: json['discountType']?.toString(),
        discountValue: (json['discountValue'] as num?)?.toDouble(),
        fixedPrice: (json['fixedPrice'] as num?)?.toDouble(),
        scope: (json['scope'] ?? 'product').toString(),
        variantId: json['variantId']?.toString(),
      );
}

class ProductCategory extends Equatable {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, description, isActive];
}


class ProductVariantModel extends Equatable {
  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.name,
    this.internalCode,
    this.barcode,
    this.price,
    this.cost,
    this.stock,
    required this.active,
    this.effectivePrice,
    this.effectiveStock,
  });

  final String id;
  final String productId;
  final String name;
  final String? internalCode;
  final String? barcode;
  final double? price;
  final double? cost;
  final double? stock;
  final bool active;
  final double? effectivePrice;
  final double? effectiveStock;

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) => ProductVariantModel(
        id: json['id'] as String,
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '-',
        internalCode: json['internalCode'] as String?,
        barcode: json['barcode'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        cost: (json['cost'] as num?)?.toDouble(),
        stock: (json['stock'] as num?)?.toDouble(),
        active: json['active'] as bool? ?? true,
        effectivePrice: (json['effectivePrice'] as num?)?.toDouble(),
        effectiveStock: (json['effectiveStock'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'internalCode': internalCode,
        'barcode': barcode,
        'price': price,
        'cost': cost,
        'stock': stock,
      };

  @override
  List<Object?> get props => [id, productId, name, internalCode, barcode, price, cost, stock, active];
}
