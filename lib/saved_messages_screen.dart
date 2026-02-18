import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class SavedMessagesScreen extends StatefulWidget {
  const SavedMessagesScreen({super.key});

  @override
  State<SavedMessagesScreen> createState() => _SavedMessagesScreenState();
}

class _SavedMessagesScreenState extends State<SavedMessagesScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> saved = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSaved();
  }

  Future<void> loadSaved() async {
    //  Get user email to load their specific data
    final userEmail = await _storage.read(key: "user_email") ?? "default";
    final storageKey = "saved_messages_$userEmail";

    final data = await _storage.read(key: storageKey);
    setState(() {
      saved = data == null ? [] : jsonDecode(data);
      loading = false;
    });
  }

  Future<void> remove(String id) async {
    saved.removeWhere((e) => e["id"] == id);

    //  Use user-specific key
    final userEmail = await _storage.read(key: "user_email") ?? "default";
    final storageKey = "saved_messages_$userEmail";

    await _storage.write(key: storageKey, value: jsonEncode(saved));
    setState(() {});
  }

  String formatDate(String raw) {
    try {
      return DateFormat("dd MMM yyyy • hh:mm a").format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  // Helper to rotate colors for the Bento look
  Color getBentoColor(int index) {
    List<Color> colors = [
      const Color(0xFFFDF0A0), // Cream Yellow
      const Color(0xFFFFC0D9), // Soft Pink
      const Color(0xFFB4F8C8), // Mint Green
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "SAVED GEMS",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : saved.isEmpty
          ? const _EmptySaved()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: saved.length,
              itemBuilder: (context, index) {
                final item = saved[index];
                final tileColor = getBentoColor(index);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              (item["type"] ?? "FLIRT")
                                  .toString()
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => remove(item["id"]),
                            child: const Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item["text"] ?? "",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            formatDate(item["created_at"] ?? ""),
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: item["text"]),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Copied ✨")),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.copy_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bookmark_border_rounded,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          const Text(
            "Nothing here yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your saved pickup lines will live here.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
