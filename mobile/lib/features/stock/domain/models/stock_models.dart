class StockItem {
  const StockItem({
    required this.productId,
    required this.name,
    this.internalCode,
    this.categoryName,
    required this.stockCurrent,
    required this.stockMinimum,
    required this.status,
    this.barcode,
    this.hasVariants = false,
    this.variants = const [],
  });

  final String productId;
  final String name;
  final String? internalCode;
  final String? categoryName;
  final double stockCurrent;
  final double stockMinimum;
  final String status;
  final String? barcode;
  final bool hasVariants;
  final List<StockVariant> variants;

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        productId: json['productId'] as String,
        name: json['name'] as String? ?? '-',
        internalCode: json['internalCode'] as String?,
        categoryName: json['categoryName'] as String?,
        stockCurrent: (json['stockCurrent'] as num?)?.toDouble() ?? 0,
        stockMinimum: (json['stockMinimum'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'normal',
        barcode: json['barcode'] as String?,
        hasVariants: json['hasVariants'] as bool? ?? false,
        variants: (json['variants'] as List<dynamic>? ?? [])
            .map((raw) => StockVariant.fromJson(raw as Map<String, dynamic>))
            .toList(),
      );
}

class StockVariant {
  const StockVariant({
    required this.id,
    required this.name,
    this.stock,
    required this.isActive,
  });

  final String id;
  final String name;
  final double? stock;
  final bool isActive;

  factory StockVariant.fromJson(Map<String, dynamic> json) => StockVariant(
        id: json['id'] as String,
        name: json['name'] as String? ?? '-',
        stock: (json['stock'] as num?)?.toDouble(),
        isActive: json['isActive'] as bool? ?? true,
      );
}

class StockMovement {
  const StockMovement({required this.id, required this.movementType, required this.quantity, required this.previousStock, required this.newStock, required this.reason, this.notes, this.userName, this.createdAt, this.productVariantId, this.productName});

  final String id;
  final String movementType;
  final double quantity;
  final double previousStock;
  final double newStock;
  final String reason;
  final String? notes;
  final String? userName;
  final DateTime? createdAt;
  final String? productVariantId;
  final String? productName;

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        id: json['id'] as String,
        movementType: json['movementType'] as String? ?? '-',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        previousStock: (json['previousStock'] as num?)?.toDouble() ?? 0,
        newStock: (json['newStock'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String? ?? '-',
        notes: json['notes'] as String?,
        userName: json['userName'] as String?,
        createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'] as String),
        productVariantId: json['productVariantId'] as String?,
        productName: json['productName'] as String?,
      );
}
