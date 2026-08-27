import 'dart:convert';

class Invoice {
  final String invoiceId;
  final String creatorAccountNumber;
  final String creatorName;
  final double amount;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Invoice({
    required this.invoiceId,
    required this.creatorAccountNumber,
    required this.creatorName,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isValid => status == 'pending' && DateTime.now().toUtc().isBefore(expiresAt);

  Map<String, dynamic> toMap() => {
        'invoiceId': invoiceId,
        'creatorAccountNumber': creatorAccountNumber,
        'creatorName': creatorName,
        'amount': amount,
        'description': description,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory Invoice.fromMap(Map<String, dynamic> map) => Invoice(
        invoiceId: map['invoiceId'] as String? ?? '',
        creatorAccountNumber: map['creatorAccountNumber'] as String? ?? '',
        creatorName: map['creatorName'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        description: map['description'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
        expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : DateTime.now(),
      );

  String toJson() => json.encode(toMap());
  factory Invoice.fromJson(String source) =>
      Invoice.fromMap(json.decode(source) as Map<String, dynamic>);

  String toDeepLink() {
    return 'sudacard://invoice?id=$invoiceId';
  }

  static String? extractIdFromDeepLink(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('INV-')) return text;
    try {
      final invMatch = RegExp(r'INV-\d+').firstMatch(text);
      if (invMatch != null) {
        return invMatch.group(0);
      }
      if (text.contains('id=')) {
        final parsed = Uri.parse(text);
        if (parsed.queryParameters['id'] != null) {
          return parsed.queryParameters['id'];
        }
      }
      final parsed = Uri.parse(text);
      if (parsed.pathSegments.isNotEmpty) {
        final last = parsed.pathSegments.last;
        if (last.startsWith('INV-')) return last;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
