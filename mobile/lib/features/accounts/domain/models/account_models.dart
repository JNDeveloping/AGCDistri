class ClientAccount {
  const ClientAccount({required this.clientId, required this.businessName, required this.currentBalance, required this.creditLimit, required this.status, this.lastMovementAt, this.recentMovements = const []});
  final String clientId;
  final String businessName;
  final double currentBalance;
  final double creditLimit;
  final String status;
  final DateTime? lastMovementAt;
  final List<AccountMovement> recentMovements;

  factory ClientAccount.fromJson(Map<String, dynamic> json) => ClientAccount(
        clientId: json['clientId'] as String,
        businessName: json['businessName'] as String? ?? '-',
        currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'al_dia',
        lastMovementAt: json['lastMovementAt'] == null ? null : DateTime.tryParse(json['lastMovementAt'] as String),
        recentMovements: (json['recentMovements'] as List<dynamic>? ?? []).map((e) => AccountMovement.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class AccountMovement {
  const AccountMovement({required this.id, required this.movementType, required this.amount, required this.newBalance, required this.description, this.createdAt, this.referenceType, this.referenceId});
  final String id;
  final String movementType;
  final double amount;
  final double newBalance;
  final String description;
  final DateTime? createdAt;
  final String? referenceType;
  final String? referenceId;

  factory AccountMovement.fromJson(Map<String, dynamic> json) => AccountMovement(
        id: json['id'] as String,
        movementType: json['movementType'] as String? ?? '-',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        newBalance: (json['newBalance'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String? ?? '-',
        createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'] as String),
        referenceType: json['referenceType'] as String?,
        referenceId: json['referenceId'] as String?,
      );
}

class ClientPayment {
  const ClientPayment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    this.userName,
    this.createdAt,
  });

  final String id;
  final String clientId;
  final String clientName;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final String? userName;
  final DateTime? createdAt;

  factory ClientPayment.fromJson(Map<String, dynamic> json) => ClientPayment(
        id: json['id'] as String? ?? '',
        clientId: json['clientId'] as String? ?? '',
        clientName: json['clientName'] as String? ?? '-',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paymentMethod: json['paymentMethod'] as String? ?? '-',
        notes: json['notes'] as String?,
        userName: json['userName'] as String?,
        createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'] as String),
      );
}
