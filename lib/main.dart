import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'constants/strings.dart';
import 'pages/live_scan_page.dart';
import 'pages/image_preview_page.dart';
import 'widgets/dishcovery_app_bar.dart';

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

enum CaptureMode { single, gallery, live }

class AnalyzerPage extends StatefulWidget {
  const AnalyzerPage({super.key});

  @override
  State<AnalyzerPage> createState() => _AnalyzerPageState();
}

class _AnalyzerPageState extends State<AnalyzerPage> {
  final _picker = ImagePicker();

  Future<void> _openCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        _navigateToPreview(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
      }
    }
  }

  Future<void> _openGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        _navigateToPreview(image.path, isFromGallery: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih foto: $e')));
      }
    }
  }

  void _navigateToPreview(String imagePath, {bool isFromGallery = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewPage(
          imagePath: imagePath,
          isFromGallery: isFromGallery,
        ),
      ),
    );
  }

  void _openLivePreview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LiveScanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DishcoveryAppBar(
        onLanguageChanged: () {
          // TODO: Implement language change
        },
        onProfileTapped: () {
          // TODO: Implement profile
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                Strings.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text(Strings.titleCapture),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text(Strings.titleGallery),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openLivePreview,
                icon: const Icon(Icons.videocam),
                label: const Text(Strings.titleLivePreview),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
