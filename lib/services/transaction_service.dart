import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/transaction.dart';
import 'session_manager.dart';

class TransactionService {
  
  /// يجلب تفاصيل المستخدم لتحديث الرصيد
  static Future<bool> fetchAndUpdateBalance() async {
    try {
      final response = await ApiService.get('/users/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final balance = (data['user']['balance'] as num).toDouble();
          SessionManager().updateBalanceLocally(balance);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[TransactionService] error fetching balance: $e');
      return false;
    }
  }

  /// يجلب آخر العمليات مع تحديد هل هي إيداع أم سحب
  static Future<List<Transaction>> getRecentTransactions({int limit = 5}) async {
    try {
      final response = await ApiService.get('/users/me/transactions?limit=$limit');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['transactions'];
          final currentUserId = SessionManager().currentUser?.id;
          
          return list.map((json) {
            final senderObj = json['senderId'];
            final receiverObj = json['receiverId'];
            
            String sId = '';
            String sAcc = '';
            String rId = '';
            String rAcc = '';

            if (senderObj is Map) {
              sId = senderObj['_id']?.toString() ?? '';
              sAcc = senderObj['accountNumber']?.toString() ?? '';
            } else {
              sId = senderObj?.toString() ?? '';
            }

            if (receiverObj is Map) {
              rId = receiverObj['_id']?.toString() ?? '';
              rAcc = receiverObj['accountNumber']?.toString() ?? '';
            } else {
              rId = receiverObj?.toString() ?? '';
            }
            
            // تحديد نوع العملية بالنسبة للمستخدم الحالي
            final currentUser = SessionManager().currentUser;
            bool isSender = false;
            if (currentUser != null) {
              if (sAcc == currentUser.accountNumber || sId == currentUser.id || sId == currentUser.accountNumber) {
                isSender = true;
              }
            }

            final type = isSender ? TransactionType.debit : TransactionType.credit;
            
            // تحديد اسم الطرف الآخر لعرضه
            String otherPartyName = 'غير معروف';
            if (isSender) {
              if (receiverObj is Map) {
                otherPartyName = '${receiverObj['firstName'] ?? ''} ${receiverObj['lastName'] ?? ''}'.trim();
              } else {
                otherPartyName = json['receiverName'] ?? 'جهة نظامية';
              }
            } else {
              if (senderObj is Map) {
                otherPartyName = '${senderObj['firstName'] ?? ''} ${senderObj['lastName'] ?? ''}'.trim();
              } else {
                otherPartyName = json['senderName'] ?? 'جهة نظامية';
              }
            }
            if (otherPartyName.isEmpty) {
              otherPartyName = 'عملية نظام';
            }

            return Transaction(
              transactionId: json['transactionId'] ?? json['_id'] ?? '',
              senderId: sId,
              receiverId: rId,
              receiverName: otherPartyName,
              amount: (json['amount'] as num?)?.toDouble() ?? (json['baseAmount'] as num?)?.toDouble() ?? (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
              type: type,
              note: json['note'] ?? json['description'] ?? json['category'] ?? json['type'],
              timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
              status: TransactionStatus.values.firstWhere(
                (e) => e.name == json['status'],
                orElse: () => TransactionStatus.completed,
              ),
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[TransactionService] error fetching transactions: $e');
      return [];
    }
  }

  /// إرسال الأموال لحساب آخر (P2P Transfer)
  static Future<bool> transferMoney({
    required String receiverAccountNumber,
    required double amount,
    String? note,
  }) async {
    try {
      final response = await ApiService.post('/transactions/transfer', {
        'receiverAccountNumber': receiverAccountNumber,
        'amount': amount,
        'note': note,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // تحديث الرصيد بعد نجاح التحويل
          await fetchAndUpdateBalance();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[TransactionService] error in transferMoney: $e');
      return false;
    }
  }

  /// البحث عن حساب قبل التحويل للتأكد من هويته
  static Future<Map<String, dynamic>?> searchAccount(String accountNumber) async {
    try {
      final response = await ApiService.get('/users/search/$accountNumber');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('[TransactionService] error searching account: $e');
      return null;
    }
  }
}
