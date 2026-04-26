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
        number: _toInt(json['number']),
        date: (json['date'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'pendiente',
        driverId: json['driver_id'] as String?,
        driverName: json['driver_name'] as String?,
        notes: json['notes'] as String?,
        zone: json['zone'] as String?,
        totalOrders: _toInt(json['total_orders']),
        totalAmount: _toDouble(json['total_amount']),
        orders: (json['orders'] as List<dynamic>? ?? [])
            .map((item) => DeliveryOrderModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
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
        latitude: json['latitude'] == null ? null : _toDouble(json['latitude']),
        longitude: json['longitude'] == null ? null : _toDouble(json['longitude']),
        total: _toDouble(json['total']),
        paymentTerms: json['payment_terms'] as String?,
        currentBalance: json['current_balance'] == null ? null : _toDouble(json['current_balance']),
        visitOrder: json['visit_order'] == null ? null : _toInt(json['visit_order']),
      );

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
