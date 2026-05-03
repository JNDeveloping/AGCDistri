import 'package:equatable/equatable.dart';

class OrderItemInput extends Equatable {
  const OrderItemInput({
    required this.productId,
    this.productVariantId,
    required this.quantity,
    this.discountType = 'amount',
    this.discountValue = 0,
  });

  final String productId;
  final String? productVariantId;
  final double quantity;
  final String discountType;
  final double discountValue;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productVariantId': productVariantId,
        'quantity': quantity,
        'discountType': discountType,
        'discountValue': discountValue,
      };

  @override
  List<Object?> get props => [productId, productVariantId, quantity, discountType, discountValue];
}

class OrderModel extends Equatable {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    this.zoneName,
    this.zoneId,
    required this.sellerId,
    required this.sellerName,
    required this.orderDate,
    required this.status,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    required this.estimatedMargin,
    required this.itemsCount,
    required this.totalUnits,
    required this.paymentTerms,
    required this.deliveryAddress,
    required this.notes,
    this.items = const [],
    this.creditNotes = const [],
    this.totalCredited = 0,
    this.netTotal = 0,
    this.hasCreditNotes = false,
  });

  final String id;
  final int orderNumber;
  final String clientId;
  final String clientName;
  final String? clientPhone;
  final String? zoneName;
  final String? zoneId;
  final String sellerId;
  final String sellerName;
  final DateTime? orderDate;
  final String status;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double total;
  final double estimatedMargin;
  final int itemsCount;
  final double totalUnits;
  final String? paymentTerms;
  final String? deliveryAddress;
  final String? notes;
  final List<OrderItemModel> items;
  final List<OrderCreditNoteSummary> creditNotes;
  final double totalCredited;
  final double netTotal;
  final bool hasCreditNotes;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        orderNumber: _asInt(json['orderNumber']) ?? 0,
        clientId: json['clientId'] as String,
        clientName: json['clientName'] as String? ?? '-',
        clientPhone: json['clientPhone'] as String?,
        zoneName: json['zoneName'] as String?,
        zoneId: json['zoneId'] as String?,
        sellerId: json['sellerId'] as String,
        sellerName: json['sellerName'] as String? ?? '-',
        orderDate: json['orderDate'] != null ? DateTime.tryParse(json['orderDate'] as String) : null,
        status: json['status'] as String? ?? 'pendiente',
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0,
        taxTotal: (json['taxTotal'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        estimatedMargin: (json['estimatedMargin'] as num?)?.toDouble() ?? 0,
        itemsCount: _asInt(json['itemsCount'] ?? json['items_count']) ?? 0,
        totalUnits: (json['totalUnits'] as num?)?.toDouble()
            ?? (json['total_units'] as num?)?.toDouble()
            ?? ((json['items'] as List<dynamic>? ?? []).fold<num>(0, (acc, raw) => acc + (((raw as Map<String, dynamic>)['quantity'] as num?) ?? 0))).toDouble(),
        paymentTerms: json['paymentTerms'] as String?,
        deliveryAddress: json['deliveryAddress'] as String?,
        notes: json['notes'] as String?,
        items: (json['items'] as List<dynamic>? ?? []).map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList(),
        creditNotes: (json['creditNotes'] as List<dynamic>? ?? []).map((e) => OrderCreditNoteSummary.fromJson(e as Map<String, dynamic>)).toList(),
        totalCredited: (json['totalCredited'] as num?)?.toDouble() ?? 0,
        netTotal: (json['netTotal'] as num?)?.toDouble() ?? ((json['total'] as num?)?.toDouble() ?? 0),
        hasCreditNotes: json['hasCreditNotes'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, orderNumber, clientId, status, total, totalCredited, netTotal, hasCreditNotes, itemsCount, totalUnits, clientPhone, zoneName, zoneId];
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class OrderItemModel extends Equatable {
  const OrderItemModel({
    required this.productId,
    this.productVariantId,
    required this.productName,
    this.variantNameSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.originalUnitPrice,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.subtotal,
    required this.estimatedMargin,
    this.appliedPromotions = const [],
  });

  final String productId;
  final String? productVariantId;
  final String productName;
  final String? variantNameSnapshot;
  final double quantity;
  final double unitPrice;
  final double originalUnitPrice;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double subtotal;
  final double estimatedMargin;
  final List<dynamic> appliedPromotions;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        productId: json['productId'] as String,
        productVariantId: json['productVariantId'] as String?,
        productName: json['productName'] as String? ?? '-',
        variantNameSnapshot: json['variantNameSnapshot'] as String?,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        originalUnitPrice: (json['originalUnitPrice'] as num?)?.toDouble() ?? (json['unitPrice'] as num?)?.toDouble() ?? 0,
        discountType: json['discountType'] as String? ?? 'amount',
        discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        estimatedMargin: (json['estimatedMargin'] as num?)?.toDouble() ?? 0,
        appliedPromotions: json['appliedPromotions'] as List<dynamic>? ?? const [],
      );

  @override
  List<Object?> get props => [productId, productVariantId, quantity, unitPrice, discountType, discountValue, discountAmount, subtotal];
}

class OrderCreditNoteSummary {
  const OrderCreditNoteSummary({required this.id, required this.number, required this.reason, required this.totalAmount, this.createdAt});

  final String id;
  final int number;
  final String reason;
  final double totalAmount;
  final DateTime? createdAt;

  factory OrderCreditNoteSummary.fromJson(Map<String, dynamic> json) => OrderCreditNoteSummary(
        id: json['id'] as String,
        number: (json['number'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String? ?? '-',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      );
}

class OrderClientLookup {
  const OrderClientLookup({required this.id, required this.businessName, this.currentBalance = 0, this.creditLimit = 0});
  final String id;
  final String businessName;
  final double currentBalance;
  final double creditLimit;

  factory OrderClientLookup.fromJson(Map<String, dynamic> json) => OrderClientLookup(
        id: json['id'] as String,
        businessName: json['businessName'] as String,
        currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      );
}

class OrderProductLookup {
  const OrderProductLookup({required this.id, required this.name, this.internalCode, this.barcode, this.brand, this.categoryName, required this.salePrice, this.stockCurrent = 0, this.hasVariants = false, this.hasActivePromotion = false, this.variantId, this.variantName});
  final String id;
  final String name;
  final String? internalCode;
  final String? barcode;
  final String? brand;
  final String? categoryName;
  final double salePrice;
  final double stockCurrent;
  final bool hasVariants;
  final bool hasActivePromotion;
  final String? variantId;
  final String? variantName;

  factory OrderProductLookup.fromJson(Map<String, dynamic> json) => OrderProductLookup(
        id: (json['id'] ?? json['productId']) as String,
        name: (json['name'] ?? json['productName']) as String,
        internalCode: (json['internalCode'] ?? json['variantInternalCode']) as String?,
        barcode: (json['barcode'] ?? json['variantBarcode']) as String?,
        brand: json['brand'] as String?,
        categoryName: json['categoryName'] as String?,
        salePrice: ((json['salePrice'] ?? json['effectivePrice']) as num?)?.toDouble() ?? 0,
        stockCurrent: (json['effectiveStock'] as num?)?.toDouble() ?? (json['stockCurrent'] as num?)?.toDouble() ?? 0,
        hasVariants: json['hasVariants'] as bool? ?? false,
        hasActivePromotion: json['hasActivePromotion'] as bool? ?? false,
        variantId: json['variantId'] as String?,
        variantName: json['variantName'] as String?,
      );
}


class ClientPurchaseHistoryItem {
  const ClientPurchaseHistoryItem({
    required this.productId,
    required this.productName,
    this.productVariantId,
    this.variantName,
    this.lastPurchaseDate,
    required this.averageQuantity,
    required this.lastPrice,
    required this.frequency,
    required this.purchaseCount,
  });

  final String productId;
  final String productName;
  final String? productVariantId;
  final String? variantName;
  final DateTime? lastPurchaseDate;
  final double averageQuantity;
  final double lastPrice;
  final String frequency;
  final int purchaseCount;

  factory ClientPurchaseHistoryItem.fromJson(Map<String, dynamic> json) => ClientPurchaseHistoryItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String? ?? '-',
        productVariantId: json['productVariantId'] as String?,
        variantName: json['variantName'] as String?,
        lastPurchaseDate: json['lastPurchaseDate'] != null ? DateTime.tryParse(json['lastPurchaseDate'] as String) : null,
        averageQuantity: (json['averageQuantity'] as num?)?.toDouble() ?? 0,
        lastPrice: (json['lastPrice'] as num?)?.toDouble() ?? 0,
        frequency: json['frequency'] as String? ?? 'ocasional',
        purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
      );
}

class SuggestedProductItem {
  const SuggestedProductItem({
    required this.productId,
    required this.productName,
    this.productVariantId,
    this.variantName,
    required this.hasVariants,
    this.hasActivePromotion = false,
    required this.stockAvailable,
    required this.currentPrice,
    this.lastPrice,
    this.averageQuantity,
    required this.relevanceReason,
    required this.relevanceScore,
  });

  final String productId;
  final String productName;
  final String? productVariantId;
  final String? variantName;
  final bool hasVariants;
  final bool hasActivePromotion;
  final double stockAvailable;
  final double currentPrice;
  final double? lastPrice;
  final double? averageQuantity;
  final String relevanceReason;
  final int relevanceScore;

  factory SuggestedProductItem.fromJson(Map<String, dynamic> json) => SuggestedProductItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String? ?? '-',
        productVariantId: json['productVariantId'] as String?,
        variantName: json['variantName'] as String?,
        hasVariants: json['hasVariants'] as bool? ?? false,
        hasActivePromotion: json['hasActivePromotion'] as bool? ?? false,
        stockAvailable: (json['stockAvailable'] as num?)?.toDouble() ?? 0,
        currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
        lastPrice: (json['lastPrice'] as num?)?.toDouble(),
        averageQuantity: (json['averageQuantity'] as num?)?.toDouble(),
        relevanceReason: json['relevanceReason'] as String? ?? 'sugerido',
        relevanceScore: (json['relevanceScore'] as num?)?.toInt() ?? 0,
      );
}

class ClientLastOrderSuggestion {
  const ClientLastOrderSuggestion({required this.order, required this.items});

  final ClientLastOrderHeader? order;
  final List<ClientLastOrderItem> items;

  factory ClientLastOrderSuggestion.fromJson(Map<String, dynamic> json) => ClientLastOrderSuggestion(
        order: json['order'] == null ? null : ClientLastOrderHeader.fromJson(json['order'] as Map<String, dynamic>),
        items: (json['items'] as List<dynamic>? ?? []).map((e) => ClientLastOrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class ClientLastOrderHeader {
  const ClientLastOrderHeader({required this.id, required this.orderNumber, this.orderDate, required this.total, this.paymentTerms});

  final String id;
  final int orderNumber;
  final DateTime? orderDate;
  final double total;
  final String? paymentTerms;

  factory ClientLastOrderHeader.fromJson(Map<String, dynamic> json) => ClientLastOrderHeader(
        id: json['id'] as String,
        orderNumber: (json['orderNumber'] as num?)?.toInt() ?? 0,
        orderDate: json['orderDate'] != null ? DateTime.tryParse(json['orderDate'] as String) : null,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        paymentTerms: json['paymentTerms'] as String?,
      );
}

class ClientLastOrderItem {
  const ClientLastOrderItem({
    required this.productId,
    required this.productName,
    this.productVariantId,
    this.variantName,
    required this.quantity,
    required this.previousPrice,
    required this.currentPrice,
    required this.priceChanged,
    required this.stockAvailable,
    required this.hasStock,
    required this.hasVariants,
    this.hasActivePromotion = false,
  });

  final String productId;
  final String productName;
  final String? productVariantId;
  final String? variantName;
  final double quantity;
  final double previousPrice;
  final double currentPrice;
  final bool priceChanged;
  final double stockAvailable;
  final bool hasStock;
  final bool hasVariants;
  final bool hasActivePromotion;

  factory ClientLastOrderItem.fromJson(Map<String, dynamic> json) => ClientLastOrderItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String? ?? '-',
        productVariantId: json['productVariantId'] as String?,
        variantName: json['variantName'] as String?,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        previousPrice: (json['previousPrice'] as num?)?.toDouble() ?? 0,
        currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
        priceChanged: json['priceChanged'] as bool? ?? false,
        stockAvailable: (json['stockAvailable'] as num?)?.toDouble() ?? 0,
        hasStock: json['hasStock'] as bool? ?? false,
        hasVariants: json['hasVariants'] as bool? ?? false,
        hasActivePromotion: json['hasActivePromotion'] as bool? ?? false,
      );
}

class OrderStockValidation {
  const OrderStockValidation({required this.hasInsufficientStock, required this.items});

  final bool hasInsufficientStock;
  final List<OrderStockValidationItem> items;

  factory OrderStockValidation.fromJson(Map<String, dynamic> json) => OrderStockValidation(
        hasInsufficientStock: json['hasInsufficientStock'] as bool? ?? false,
        items: (json['items'] as List<dynamic>? ?? []).map((item) => OrderStockValidationItem.fromJson(item as Map<String, dynamic>)).toList(),
      );
}

class OrderStockValidationItem {
  const OrderStockValidationItem({required this.productId, required this.productName, required this.requiredQuantity, required this.availableStock, required this.hasStock});

  final String productId;
  final String productName;
  final double requiredQuantity;
  final double availableStock;
  final bool hasStock;

  factory OrderStockValidationItem.fromJson(Map<String, dynamic> json) => OrderStockValidationItem(
        productId: json['productId'] as String? ?? '',
        productName: json['productName'] as String? ?? '-',
        requiredQuantity: (json['requiredQuantity'] as num?)?.toDouble() ?? 0,
        availableStock: (json['availableStock'] as num?)?.toDouble() ?? 0,
        hasStock: json['hasStock'] as bool? ?? false,
      );
}

class OrderProductVariantLookup {
  const OrderProductVariantLookup({required this.id, required this.productId, required this.name, this.price, this.stock, required this.active, this.effectivePrice, this.effectiveStock});

  final String id;
  final String productId;
  final String name;
  final double? price;
  final double? stock;
  final bool active;
  final double? effectivePrice;
  final double? effectiveStock;

  factory OrderProductVariantLookup.fromJson(Map<String, dynamic> json) => OrderProductVariantLookup(
        id: json['id'] as String,
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '-',
        price: (json['price'] as num?)?.toDouble(),
        stock: (json['stock'] as num?)?.toDouble(),
        active: json['active'] as bool? ?? true,
        effectivePrice: (json['effectivePrice'] as num?)?.toDouble(),
        effectiveStock: (json['effectiveStock'] as num?)?.toDouble(),
      );
}

class OrderProductSelection {
  const OrderProductSelection({required this.product, this.variant, this.initialQuantity = 1});

  final OrderProductLookup product;
  final OrderProductVariantLookup? variant;
  final double initialQuantity;

  String get cartKey => variant == null ? product.id : '${product.id}::${variant!.id}';
  String get displayName => variant == null ? product.name : '${product.name} - ${variant!.name}';
  double get effectivePrice => variant?.effectivePrice ?? product.salePrice;
  double get effectiveStock => variant?.effectiveStock ?? product.stockCurrent;
}
