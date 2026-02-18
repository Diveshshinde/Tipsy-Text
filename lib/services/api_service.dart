import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = "https://tipsytext.prod.outsidebox.net";

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ================= TOKEN =================

  static Future<String> _getToken() async {
    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) {
      throw Exception("JWT missing");
    }
    return token;
  }

  static void _validate(http.Response res, String label) {
    debugPrint("--- API RESPONSE: $label | Status: ${res.statusCode} ---");

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }

    debugPrint("Body: ${res.body}");
    throw Exception("CODE:${res.statusCode}");
  }

  // ================= GOOGLE LOGIN =================

  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/google"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"credential": idToken}),
    );

    _validate(res, "Google Login");

    return jsonDecode(res.body);
  }

  // ================= REFRESH TOKEN =================

  static Future<Map<String, dynamic>> refreshToken() async {
    final res = await http.post(Uri.parse("$baseUrl/auth/refresh"));

    _validate(res, "Refresh Token");

    return jsonDecode(res.body);
  }

  // ================= LOGOUT =================

  static Future<void> logout() async {
    final token = await _getToken();

    final res = await http.post(
      Uri.parse("$baseUrl/auth/logout"),
      headers: {"Authorization": "Bearer $token"},
    );

    _validate(res, "Logout");

    await _storage.deleteAll();
  }

  // ================= VERIFY TOKEN =================

  static Future<Map<String, dynamic>> verifyToken(String token) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/verify"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": token}),
    );

    _validate(res, "Verify Token");

    return jsonDecode(res.body);
  }

  // ================= PRESIGNED URL =================

  static Future<Map<String, dynamic>> getPresignedUrl({
    required String filename,
    required String contentType,
  }) async {
    final token = await _getToken();

    final res = await http.post(
      Uri.parse("$baseUrl/upload/presigned-url"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "filename": filename,
        "content_type": contentType,
        "expires_in": 3600,
      }),
    );

    _validate(res, "Get Presigned URL");

    return jsonDecode(res.body);
  }

  static Future<void> uploadToPresignedUrl({
    required String uploadUrl,
    required File file,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();

    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {"Content-Type": contentType},
      body: bytes,
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception("UPLOAD_FAILED");
    }
  }

  // ================= GENERATE FLIRT =================

  static Future<Map<String, dynamic>> generateFlirt({
    required String context,
    required String targetGender,
    required String relationshipStage,
    required String vibe,
    required String tone,
    required String language,
    String? imageUrl,
  }) async {
    final token = await _getToken();

    final body = {
      "context": context,
      "targetGender": targetGender,
      "relationshipStage": relationshipStage,
      "vibe": vibe,
      "specificInterest": "",
      "options": {
        "tone": tone,
        "length": tone,
        "style": "playful",
        "targetAudience": targetGender,
        "keywords": [],
        "language": language,
      },
      if (imageUrl != null) "imageUrl": imageUrl,
    };

    final res = await http.post(
      Uri.parse("$baseUrl/generate/flirt"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    _validate(res, "Generate Flirt");

    return jsonDecode(res.body);
  }

  // ================= USER =================

  static Future<Map<String, dynamic>> getUserStats() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/user/stats"),
      headers: {"Authorization": "Bearer $token"},
    );

    _validate(res, "Get Stats");

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/user/profile"),
      headers: {"Authorization": "Bearer $token"},
    );

    _validate(res, "Get Profile");

    return jsonDecode(res.body);
  }
}
