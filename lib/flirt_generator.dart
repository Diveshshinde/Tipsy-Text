import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';

class FlirtGeneratorScreen extends StatefulWidget {
  final bool canGenerate;
  const FlirtGeneratorScreen({super.key, required this.canGenerate});

  @override
  State<FlirtGeneratorScreen> createState() => _FlirtGeneratorScreenState();
}

class _FlirtGeneratorScreenState extends State<FlirtGeneratorScreen> {
  final TextEditingController contextCtrl = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  String gender = "female";
  String stage = "crush";
  String vibe = "playful";
  String tone = "short";
  String language = "en";

  bool loading = false;
  bool generated = false;
  bool limitReached = false;
  String result = "";
  File? selectedImage;

  final Map<String, String> languages = {
    "en": "English 🇺🇸",
    "es": "Spanish 🇪🇸",
    "fr": "French 🇫🇷",
    "de": "German 🇩🇪",
    "it": "Italian 🇮🇹",
    "pt": "Portuguese 🇧🇷",
  };

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> _persistFlirt(String text) async {
    final now = DateTime.now().toIso8601String();

    //  Get user email to make storage unique per user
    final userEmail = await _storage.read(key: "user_email") ?? "default";
    final storageKey = "local_history_$userEmail";

    final historyRaw = await _storage.read(key: storageKey);
    final List history = historyRaw == null ? [] : jsonDecode(historyRaw);

    history.insert(0, {
      "id": now,
      "type": "FLIRT",
      "text": text,
      "created_at": now,
    });

    await _storage.write(key: storageKey, value: jsonEncode(history));
  }

  // ================= PRESIGNED URL + GENERATE =================
  Future<void> generate() async {
    if (!widget.canGenerate || contextCtrl.text.trim().isEmpty) return;

    setState(() {
      loading = true;
      result = "";
      limitReached = false;
    });

    try {
      String? imageUrl;

      //  PRESIGNED URL IMAGE UPLOAD
      if (selectedImage != null) {
        final filename = selectedImage!.path.split('/').last;
        final contentType = "image/jpeg"; // safe default

        final presigned = await ApiService.getPresignedUrl(
          filename: filename,
          contentType: contentType,
        );

        await ApiService.uploadToPresignedUrl(
          uploadUrl: presigned["upload_url"],
          file: selectedImage!,
          contentType: contentType,
        );

        imageUrl = presigned["public_url"];
      }

      final res = await ApiService.generateFlirt(
        context: contextCtrl.text.trim(),
        targetGender: gender,
        relationshipStage: stage,
        vibe: vibe,
        tone: tone,
        language: language,
        imageUrl: imageUrl,
      );

      final message = res["message"] ?? res["text"] ?? "Success!";

      await _persistFlirt(message);

      setState(() {
        result = message;
        generated = true;
      });
    } catch (e) {
      final error = e.toString();

      if (error.contains("403")) {
        setState(() {
          limitReached = true;
          result =
              "🚫 GENERATIONS OVER FOR YOUR DAILY FREE TRIAL.\nUpgrade to Growth Plan for unlimited magic!";
        });
      } else {
        setState(() {
          result = "Something went wrong 😢\nPlease try again.";
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, generated);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "TIPSY TEXT",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context, generated),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("What's the context?"),
              _buildMultilineInput(
                contextCtrl,
                "Ex: She just posted a story with her dog...",
                const Color(0xFFE8E7E2),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Fine-tune the vibe"),
              _buildBentoSettings(),
              const SizedBox(height: 24),
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildGenerateButton(),
              if (result.isNotEmpty) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  Widget _buildBentoSettings() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildSelectionRow(
            "Target",
            gender,
            ["female", "male"],
            const Color(0xFFFFC0D9),
            (v) => setState(() => gender = v),
          ),
          _buildDivider(),
          _buildSelectionRow(
            "Stage",
            stage,
            ["crush", "dating", "long_term"],
            const Color(0xFFB4F8C8),
            (v) => setState(() => stage = v),
          ),
          _buildDivider(),
          _buildSelectionRow(
            "Vibe",
            vibe,
            ["playful", "romantic", "bold"],
            const Color(0xFFFDF0A0),
            (v) => setState(() => vibe = v),
          ),
          _buildDivider(),
          _buildSelectionRow(
            "Length",
            tone,
            ["short", "medium", "long"],
            Colors.white,
            (v) => setState(() => tone = v),
          ),
          _buildDivider(),
          _buildLanguageRow(),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return GestureDetector(
      onTap: (loading || limitReached) ? null : generate,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: limitReached
              ? const LinearGradient(colors: [Colors.grey, Colors.black])
              : const LinearGradient(
                  colors: [Color(0xFFE2C4FF), Color(0xFF8E54E9)],
                ),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  limitReached ? "LIMIT REACHED" : "GENERATE MAGIC ✨",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFC0D9).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            result,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (!limitReached)
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Copied!")));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC0D9),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text(
                "COPY TEXT",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionRow(
    String label,
    String value,
    List<String> items,
    Color accent,
    ValueChanged<String> onSelect,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white38),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          e.toUpperCase(),
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => onSelect(v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Language",
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: language,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white38),
              items: languages.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          e.value.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => language = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _buildMultilineInput(
    TextEditingController c,
    String hint,
    Color bgColor,
  ) => TextField(
    controller: c,
    maxLines: 3,
    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: bgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _buildDivider() =>
      Divider(color: Colors.white.withOpacity(0.05), height: 1);

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(
              selectedImage == null
                  ? Icons.add_a_photo_rounded
                  : Icons.check_circle_rounded,
              color: selectedImage == null
                  ? Colors.white38
                  : const Color(0xFFB4F8C8),
            ),
            const SizedBox(width: 15),
            Text(
              selectedImage == null ? "Reference Screenshot" : "Image Attached",
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (selectedImage != null)
              IconButton(
                onPressed: () => setState(() => selectedImage = null),
                icon: const Icon(
                  Icons.close,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
