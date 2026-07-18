import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'pro_service.dart';

class BillingService {
  static Future<String?> createCheckoutSession({String plan = 'pro', int seats = 1}) async {
    final idToken = await AuthService.getIdToken();
    if (idToken == null) return null;
    try {
      final response = await http
          .post(
            Uri.parse('${ProService.proBaseUrl}/billing/create-checkout-session'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'plan': plan, 'seats': seats}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['checkout_url'] as String?;
    } catch (_) {
      return null;
    }
  }
}
