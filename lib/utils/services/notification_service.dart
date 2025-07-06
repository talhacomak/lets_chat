import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY'; // 🔐 BURAYA kendi server key’ini yaz

  static Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    required String chatId,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverKey',
      };

      final payload = {
        "to": token,
        "notification": {
          "title": title,
          "body": body,
        },
        "data": {
          "chatId": chatId,
        }
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Bildirim gönderildi!');
      } else {
        print('❌ Bildirim başarısız: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('🔴 Bildirim hatası: $e');
    }
  }
}
