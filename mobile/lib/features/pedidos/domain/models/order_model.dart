import 'package:equatable/equatable.dart';

class OrderItemInput extends Equatable {
  const OrderItemInput({
    required this.productId,
    required this.quantity,
    this.discountType = 'amount',
    this.discountValue = 0,
  });

  final String productId;
  final double quantity;
  final String discountType;
  final double discountValue;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        'discountType': discountType,
        'discountValue': discountValue,
      };

  @override
  List<Object?> get props => [productId, quantity, discountType, discountValue];
}

class OrderModel extends Equatable {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.clientId,
    required this.clientName,
    required this.sellerId,
    required this.sellerName,
    required this.orderDate,
    required this.status,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    required this.estimatedMargin,
    required this.paymentTerms,
    required this.deliveryAddress,
    required this.notes,
    this.items = const [],
  });

  final String id;
  final int orderNumber;
  final String clientId;
  final String clientName;
  final String sellerId;
  final String sellerName;
  final DateTime? orderDate;
  final String status;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double total;
  final double estimatedMargin;
  final String? paymentTerms;
  final String? deliveryAddress;
  final String? notes;
  final List<OrderItemModel> items;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as int? ?? 0,
        clientId: json['clientId'] as String,
        clientName: json['clientName'] as String? ?? '-',
        sellerId: json['sellerId'] as String,
        sellerName: json['sellerName'] as String? ?? '-',
        orderDate: json['orderDate'] != null ? DateTime.tryParse(json['orderDate'] as String) : null,
        status: json['status'] as String? ?? 'pendiente',
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0,
        taxTotal: (json['taxTotal'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        estimatedMargin: (json['estimatedMargin'] as num?)?.toDouble() ?? 0,
        paymentTerms: json['paymentTerms'] as String?,
        deliveryAddress: json['deliveryAddress'] as String?,
        notes: json['notes'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, orderNumber, clientId, status, total];
}

class OrderItemModel extends Equatable {
  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.estimatedMargin,
  });

  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final double estimatedMargin;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        productId: json['productId'] as String,
        productName: json['productName'] as String? ?? '-',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        estimatedMargin: (json['estimatedMargin'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [productId, quantity, unitPrice, subtotal];
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
  const OrderProductLookup({required this.id, required this.name, this.internalCode, this.barcode, required this.salePrice, this.stockCurrent = 0});
  final String id;
  final String name;
  final String? internalCode;
  final String? barcode;
  final double salePrice;
  final double stockCurrent;

  factory OrderProductLookup.fromJson(Map<String, dynamic> json) => OrderProductLookup(
        id: json['id'] as String,
        name: json['name'] as String,
        internalCode: json['internalCode'] as String?,
        barcode: json['barcode'] as String?,
        salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0,
        stockCurrent: (json['stockCurrent'] as num?)?.toDouble() ?? 0,
      );
}
