import 'package:equatable/equatable.dart';

class CreditNoteItemInput extends Equatable {
  const CreditNoteItemInput({
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.unitPrice,
    this.returnToStock = false,
    this.reason,
  });

  final String productId;
  final String productNameSnapshot;
  final double quantity;
  final double unitPrice;
  final bool returnToStock;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productNameSnapshot': productNameSnapshot,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'returnToStock': returnToStock,
        'reason': reason,
      };

  @override
  List<Object?> get props => [productId, productNameSnapshot, quantity, unitPrice, returnToStock, reason];
}

class CreditNoteModel extends Equatable {
  const CreditNoteModel({
    required this.id,
    required this.number,
    required this.orderId,
    required this.clientId,
    required this.clientName,
    required this.userName,
    required this.reason,
    required this.totalAmount,
    required this.affectsStock,
    required this.affectsAccount,
    required this.createdAt,
    this.notes,
    this.items = const [],
  });

  final String id;
  final int number;
  final String orderId;
  final String clientId;
  final String clientName;
  final String userName;
  final String reason;
  final String? notes;
  final double totalAmount;
  final bool affectsStock;
  final bool affectsAccount;
  final DateTime? createdAt;
  final List<CreditNoteItemModel> items;

  factory CreditNoteModel.fromJson(Map<String, dynamic> json) => CreditNoteModel(
        id: json['id'] as String,
        number: (json['number'] as num?)?.toInt() ?? 0,
        orderId: json['orderId'] as String? ?? '',
        clientId: json['clientId'] as String? ?? '',
        clientName: json['clientName'] as String? ?? '-',
        userName: json['userName'] as String? ?? '-',
        reason: json['reason'] as String? ?? '-',
        notes: json['notes'] as String?,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        affectsStock: json['affectsStock'] as bool? ?? false,
        affectsAccount: json['affectsAccount'] as bool? ?? false,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => CreditNoteItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, number, orderId, totalAmount, createdAt, items.length];
}

class CreditNoteItemModel extends Equatable {
  const CreditNoteItemModel({
    required this.id,
    required this.creditNoteId,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.returnToStock,
    this.reason,
  });

  final String id;
  final String creditNoteId;
  final String productId;
  final String productNameSnapshot;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final bool returnToStock;
  final String? reason;

  factory CreditNoteItemModel.fromJson(Map<String, dynamic> json) => CreditNoteItemModel(
        id: json['id'] as String? ?? '',
        creditNoteId: json['creditNoteId'] as String? ?? '',
        productId: json['productId'] as String? ?? '',
        productNameSnapshot: json['productNameSnapshot'] as String? ?? '-',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        returnToStock: json['returnToStock'] as bool? ?? false,
        reason: json['reason'] as String?,
      );

  @override
  List<Object?> get props => [id, productId, quantity, unitPrice, subtotal, returnToStock, reason];
}
