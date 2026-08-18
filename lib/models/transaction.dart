import 'dart:convert';

/// أنواع العمليات المالية
enum TransactionType {
  credit,  // إيداع / استلام
  debit,   // سحب / إرسال
}

/// نموذج سجل العملية المالية
class Transaction {
  /// معرف العملية الفريد
  final String transactionId;

  /// معرف حساب المُرسِل
  final String senderId;

  /// معرف حساب المُستقبِل
  final String receiverId;

  /// اسم المستفيد المعروض
  final String receiverName;

  /// المبلغ
  final double amount;

  /// نوع العملية من منظور الحساب الحالي
  final TransactionType type;

  /// ملاحظات / وصف العملية
  final String? note;

  /// وقت العملية
  final DateTime timestamp;

  /// حالة العملية
  final TransactionStatus status;

  const Transaction({
    required this.transactionId,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
    required this.amount,
    required this.type,
    this.note,
    required this.timestamp,
    this.status = TransactionStatus.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'senderId': senderId,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'amount': amount,
      'type': type.name,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      transactionId: map['transactionId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      receiverName: map['receiverName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.debit,
      ),
      note: map['note'] as String?,
      timestamp: DateTime.parse(
        map['timestamp'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.completed,
      ),
    );
  }

  String toJson() => json.encode(toMap());
  factory Transaction.fromJson(String source) =>
      Transaction.fromMap(json.decode(source) as Map<String, dynamic>);
}

enum TransactionStatus {
  pending,    // قيد التنفيذ
  completed,  // مكتملة
  failed,     // فشلت
  cancelled,  // ملغاة
}
