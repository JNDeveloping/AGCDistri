class DeliveryModel {
  const DeliveryModel({
    required this.id,
    required this.number,
    required this.date,
    required this.status,
    this.driverId,
    this.driverName,
    this.notes,
    this.zone,
    required this.totalOrders,
    required this.totalAmount,
    this.orders = const [],
  });

  final String id;
  final int number;
  final String date;
  final String status;
  final String? driverId;
  final String? driverName;
  final String? notes;
  final String? zone;
  final int totalOrders;
  final double totalAmount;
  final List<DeliveryOrderModel> orders;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) => DeliveryModel(
        id: json['id'] as String,
        number: (json['number'] as num?)?.toInt() ?? 0,
        date: (json['date'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'pendiente',
        driverId: json['driver_id'] as String?,
        driverName: json['driver_name'] as String?,
        notes: json['notes'] as String?,
        zone: json['zone'] as String?,
        totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        orders: (json['orders'] as List<dynamic>? ?? [])
            .map((item) => DeliveryOrderModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class DeliveryOrderModel {
  const DeliveryOrderModel({
    required this.id,
    required this.deliveryId,
    required this.orderId,
    required this.status,
    required this.clientName,
    this.clientPhone,
    this.addressLine,
    this.city,
    this.latitude,
    this.longitude,
    required this.total,
    this.paymentTerms,
    this.currentBalance,
    this.visitOrder,
  });

  final String id;
  final String deliveryId;
  final String orderId;
  final String status;
  final String clientName;
  final String? clientPhone;
  final String? addressLine;
  final String? city;
  final double? latitude;
  final double? longitude;
  final double total;
  final String? paymentTerms;
  final double? currentBalance;
  final int? visitOrder;

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) => DeliveryOrderModel(
        id: json['id'] as String,
        deliveryId: (json['delivery_id'] as String?) ?? '',
        orderId: (json['order_id'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'pendiente',
        clientName: (json['client_name'] as String?) ?? '-',
        clientPhone: json['client_phone'] as String?,
        addressLine: json['address_line'] as String?,
        city: json['city'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        total: (json['total'] as num?)?.toDouble() ?? 0,
        paymentTerms: json['payment_terms'] as String?,
        currentBalance: (json['current_balance'] as num?)?.toDouble(),
        visitOrder: (json['visit_order'] as num?)?.toInt(),
      );
}
