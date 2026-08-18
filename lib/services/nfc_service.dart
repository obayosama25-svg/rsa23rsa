import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  // للتحقق من توفر الـ NFC على الجهاز
  static Future<bool> isNfcAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  // بدء قراءة الـ NFC
  static Future<void> startNfcSession({
    required Function(Map<String, dynamic> invoiceData) onInvoiceReceived,
    required Function(String error) onError,
  }) async {
    try {
      bool isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        onError('عذراً، تقنية NFC غير متوفرة أو مغلقة في جهازك.');
        return;
      }

      await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        // فحص ما إذا كانت البيانات بصيغة NDEF
        final ndef = Ndef.from(tag);
        
        if (ndef == null || ndef.cachedMessage == null) {
          onError('لم يتم التعرف على بيانات الفاتورة.');
          NfcManager.instance.stopSession();
          return;
        }

        try {
          // استخراج أول سجل من الـ NDEF Message
          final record = ndef.cachedMessage!.records.first;
          final payload = record.payload;
          
          // إزالة أول بت إذا كان نوع السجل نصياً Text
          String stringPayload = '';
          if (payload.isNotEmpty && record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
             final languageCodeLength = payload[0];
             // التحقق من طول اللغة حتى لا نتجاوز حجم المصفوفة
             if (payload.length > languageCodeLength + 1) {
               stringPayload = utf8.decode(payload.sublist(1 + languageCodeLength));
             } else {
               stringPayload = utf8.decode(payload);
             }
          } else {
             stringPayload = utf8.decode(payload);
          }

          // محاولة تحويل النص إلى JSON لمعرفة تفاصيل الفاتورة
          Map<String, dynamic> invoiceData = json.decode(stringPayload);
          
          // إيقاف الجلسة بعد القراءة بنجاح
          await NfcManager.instance.stopSession();
          
          // إرسال البيانات للواجهة
          onInvoiceReceived(invoiceData);
        } catch (e) {
          debugPrint('NFC Parse Error: $e');
          onError('حدث خطأ أثناء قراءة بيانات الفاتورة. يرجى التأكد من المصدر.');
          await NfcManager.instance.stopSession();
        }
      });
    } catch (e) {
      debugPrint('NFC Session Error: $e');
      onError('فشل في بدء جلسة الـ NFC.');
    }
  }

  // إيقاف الـ NFC يدوياً
  static Future<void> stopNfcSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('Error stopping NFC session: $e');
    }
  }
}
