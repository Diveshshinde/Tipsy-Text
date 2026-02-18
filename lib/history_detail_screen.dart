import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class HistoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const HistoryDetailScreen({super.key, required this.item});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final _storage = const FlutterSecureStorage();
  bool saved = false;
  late String message;

  @override
  void initState() {
    super.initState();
    message = widget.item["text"] ?? widget.item["message"] ?? "";
    checkSaved();
  }

  Future<void> checkSaved() async {
    //  Get user email for user-specific storage
    final userEmail = await _storage.read(key: "user_email") ?? "default";
    final storageKey = "saved_messages_$userEmail";

    final data = await _storage.read(key: storageKey);
    if (data == null) return;
    final list = jsonDecode(data) as List;
    setState(() => saved = list.any((e) => e["text"] == message));
  }

  //  UPDATED: Toggle save with user-specific storage
  Future<void> toggleSave() async {
    //  Get user email for user-specific storage
    final userEmail = await _storage.read(key: "user_email") ?? "default";
    final storageKey = "saved_messages_$userEmail";

    final data = await _storage.read(key: storageKey);
    List<dynamic> list = data == null ? [] : jsonDecode(data);

    if (saved) {
      // Remove it
      list.removeWhere((e) => e["text"] == message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Removed from Saved")));
    } else {
      // Add it
      list.insert(0, {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "type": widget.item["type"] ?? "FLIRT",
        "text": message,
        "created_at": DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved to Gems ✨")));
    }

    //  Save with user-specific key
    await _storage.write(key: storageKey, value: jsonEncode(list));
    setState(() => saved = !saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.format_quote_rounded,
              color: Color(0xFFFFC0D9), // Updated to Tipsy Pink
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight:
                    FontWeight.w900, // Thicker font to match Bento style
                height: 1.4,
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _roundBtn(Icons.copy_rounded, () {
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Copied to clipboard ✨")),
                  );
                }),
                const SizedBox(width: 20),
                _roundBtn(
                  saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  toggleSave, // Calling the new toggle function here
                  isHighlight: saved,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(
    IconData icon,
    VoidCallback onTap, {
    bool isHighlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHighlight
              ? const Color(0xFFFFC0D9)
              : const Color(0xFF1A1A1A),
          border: isHighlight
              ? null
              : Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(
          icon,
          color: isHighlight ? Colors.black : Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

