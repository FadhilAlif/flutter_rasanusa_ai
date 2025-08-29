import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/food_analysis.dart';
import 'services/gemini_service.dart';
import 'pages/live_scan_page.dart';

void main() {
  runApp(const RasaNusaApp());
}

class RasaNusaApp extends StatelessWidget {
  const RasaNusaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RasaNusa AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AnalyzerPage(),
    );
  }
}

class AnalyzerPage extends StatefulWidget {
  const AnalyzerPage({super.key});

  @override
  State<AnalyzerPage> createState() => _AnalyzerPageState();
}

class _AnalyzerPageState extends State<AnalyzerPage> {
  final _picker = ImagePicker();
  final _service = GeminiService();
  Uint8List? _imageBytes;
  FoodAnalysis? _result;
  bool _loading = false;
  String? _error;

  Future<void> _pickFromGallery() async {
    setState(() {
      _error = null;
    });
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    await _analyze(bytes);
  }

  Future<void> _takePhoto() async {
    setState(() {
      _error = null;
    });
    final xfile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    await _analyze(bytes);
  }

  Future<void> _analyze(Uint8List bytes) async {
    setState(() {
      _loading = true;
      _imageBytes = bytes;
      _result = null;
    });
    try {
      final json = await _service.analyzeBytes(bytes);
      final parsed = FoodAnalysis.fromJson(json);
      setState(() {
        _result = parsed;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal menganalisis: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RasaNusa – Analyze Food Image')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Ambil Foto'),
              ),
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pilih dari Galeri'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LiveScanPage()),
                  );
                },
                icon: const Icon(Icons.videocam),
                label: const Text('Live Preview (Beta)'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_imageBytes!, height: 220, fit: BoxFit.cover),
            ),
          if (_loading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_result != null) _ResultView(result: _result!),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});
  final FoodAnalysis result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(result.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(result.description),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place, size: 18),
            const SizedBox(width: 6),
            Text(result.origin.isEmpty ? '-' : result.origin),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Bahan/Ingredients',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: result.ingredients
              .map((e) => Chip(label: Text(e)))
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Rekomendasi Serupa',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        ...result.recommendations.map(
          (r) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restaurant),
            title: Text(r.name),
            subtitle: Text(r.reason),
          ),
        ),
      ],
    );
  }
}
