import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/food_analysis.dart';
import '../services/gemini_service.dart';

/// Duration constants
class _Constants {
  static const Duration autoScanInterval = Duration(seconds: 4);
  static const double smallScreenWidth = 400;
  static const EdgeInsets contentPadding = EdgeInsets.all(16);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 16);
}

/// LiveScanPage is a widget that provides real-time food analysis using camera
class LiveScanPage extends StatefulWidget {
  const LiveScanPage({super.key});

  @override
  State<LiveScanPage> createState() => _LiveScanPageState();
}

class _LiveScanPageState extends State<LiveScanPage>
    with WidgetsBindingObserver {
  late final GeminiService _service;
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  Timer? _timer;

  var _isInitializing = true;
  var _isAutoScanEnabled = false;
  var _isProcessing = false;
  FoodAnalysis? _lastAnalysis;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = GeminiService();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoScan();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopAutoScan();
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      final back = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;
      await controller.initialize();

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      _showError('Gagal menginisialisasi kamera: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _stopAutoScan() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() => _isAutoScanEnabled = false);
    }
  }

  Future<void> _scanOnce() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isProcessing) {
      return;
    }

    try {
      setState(() => _isProcessing = true);

      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final json = await _service.analyzeBytes(bytes);

      if (mounted) {
        setState(() => _lastAnalysis = FoodAnalysis.fromJson(json));
      }
    } catch (e) {
      _showError('Gagal melakukan scan: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _toggleAutoScan() {
    if (_isAutoScanEnabled) {
      _stopAutoScan();
    } else {
      _timer = Timer.periodic(_Constants.autoScanInterval, (_) => _scanOnce());
      setState(() => _isAutoScanEnabled = true);
    }
  }

  Widget _buildCameraPreview() {
    return Flexible(
      flex: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _controller?.value.isInitialized == true
              ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final buttons = [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _isProcessing ? null : _scanOnce,
          icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera),
          label: Text(_isProcessing ? 'Memproses...' : 'Scan Sekali'),
        ),
      ),
      SizedBox(
        width: constraints.maxWidth < _Constants.smallScreenWidth ? 8 : 12,
      ),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _toggleAutoScan,
          icon: Icon(_isAutoScanEnabled ? Icons.pause : Icons.play_arrow),
          label: Text(_isAutoScanEnabled ? 'Hentikan Auto' : 'Auto Scan'),
        ),
      ),
    ];

    return Padding(
      padding: _Constants.buttonPadding,
      child: constraints.maxWidth < _Constants.smallScreenWidth
          ? Column(
              children: buttons
                  .map((b) => SizedBox(width: double.infinity, child: b))
                  .toList(),
            )
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: buttons),
    );
  }

  Widget _buildAnalysisResults(BuildContext context) {
    if (_lastAnalysis == null) return const SizedBox.shrink();

    final analysis = _lastAnalysis!;
    final theme = Theme.of(context);

    return Expanded(
      child: SingleChildScrollView(
        padding: _Constants.contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analysis.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(analysis.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.place,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      analysis.origin,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.ingredients
                  .map(
                    (ingredient) => Chip(
                      label: Text(ingredient),
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            ...analysis.recommendations.map(
              (recommendation) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.restaurant,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    recommendation.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    recommendation.reason,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Preview (Beta)'), elevation: 0),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildCameraPreview(),
                  const SizedBox(height: 8),
                  LayoutBuilder(builder: _buildControlButtons),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  _buildAnalysisResults(context),
                ],
              ),
            ),
    );
  }
}
