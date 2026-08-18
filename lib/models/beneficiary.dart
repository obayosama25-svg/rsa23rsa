import 'dart:convert';

class Beneficiary {
  final String id;
  final String name;
  final String accountNumber;

  Beneficiary({
    required this.id,
    required this.name,
    required this.accountNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'accountNumber': accountNumber,
    };
  }

  factory Beneficiary.fromMap(Map<String, dynamic> map) {
    return Beneficiary(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Beneficiary.fromJson(String source) =>
      Beneficiary.fromMap(json.decode(source));
}
