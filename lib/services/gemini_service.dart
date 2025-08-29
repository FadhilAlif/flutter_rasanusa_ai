import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService({String? model})
    : _model = GenerativeModel(
        model: model ?? 'gemini-2.0-flash',
        apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
      );

  final GenerativeModel _model;

  Future<Map<String, dynamic>> analyzeBytes(Uint8List bytes) async {
    final prompt = _jsonPrompt();

    final content = [
      Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)]),
    ];

    final response = await _model.generateContent(content);
    final text = response.text ?? '';

    // Coba parse JSON langsung
    final parsed = _tryParseJson(text);
    if (parsed != null) return parsed;

    // Jika model menaruh JSON dalam fence ```json ... ```, ekstrak
    final fenced = _extractJsonFence(text);
    if (fenced != null) {
      final fencedParsed = _tryParseJson(fenced);
      if (fencedParsed != null) return fencedParsed;
    }

    // Fallback minimal
    return {
      'name': '-',
      'description': text.trim().isEmpty ? '-' : text.trim(),
      'origin': '-',
      'ingredients': <String>[],
      'recommendations': <Map<String, String>>[],
    };
  }

  String _jsonPrompt() {
    return '''Anda adalah asisten kuliner Indonesia. Analisis gambar makanan yang saya kirim.
      Kembalikan **hanya** JSON valid tanpa penjelasan tambahan dengan schema berikut:
      {
        "name": string, // nama makanan
        "description": string, // desk  ripsi singkat
        "origin": string, // asal daerah di Indonesia (jika non-Indonesia, jelaskan)
        "ingredients": string[], // daftar bahan/kandungan utama
        "recommendations": [ // 3-5 rekomendasi makanan serupa
        { "name": string, "reason": string }
        ]
      }
      Jika gambar tidak jelas, berikan best-guess dengan menyatakan ketidakpastian di description.''';
  }

  Map<String, dynamic>? _tryParseJson(String s) {
    try {
      final obj = json.decode(s);
      return Map<String, dynamic>.from(obj);
    } catch (_) {
      return null;
    }
  }

  String? _extractJsonFence(String s) {
    final regex = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```', multiLine: true);
    final m = regex.firstMatch(s);
    if (m != null) return m.group(1);
    final regex2 = RegExp(r'```\s*(\{[\s\S]*?\})\s*```', multiLine: true);
    final m2 = regex2.firstMatch(s);
    return m2?.group(1);
  }
}
