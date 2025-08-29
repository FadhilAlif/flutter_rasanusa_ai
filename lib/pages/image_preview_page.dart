import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/strings.dart';
import '../models/food_analysis.dart';
import '../services/gemini_service.dart';
import '../widgets/analysis_loading_skeleton.dart';
import '../widgets/dishcovery_app_bar.dart';

class ImagePreviewPage extends StatefulWidget {
  final String imagePath;
  final bool isFromGallery;

  const ImagePreviewPage({
    super.key,
    required this.imagePath,
    this.isFromGallery = false,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  final _geminiService = GeminiService();
  bool _isAnalyzing = false;
  FoodAnalysis? _analysis;
  String? _error;

  Future<void> _analyzeImage() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final result = await _geminiService.analyzeBytes(bytes);

      if (mounted) {
        setState(() {
          _analysis = FoodAnalysis.fromJson(result);
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DishcoveryAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Image Preview
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
                ),
              ),
            ),

            // Analyze Button
            if (_analysis == null && !_isAnalyzing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _analyzeImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(Strings.buttonViewDetails),
                  ),
                ),
              ),

            // Error Message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

            // Analysis Results or Loading
            Expanded(
              child: _isAnalyzing
                  ? const AnalysisLoadingSkeleton()
                  : _analysis != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _analysis!.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(_analysis!.description),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.place,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _analysis!.origin,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _analysis!.ingredients
                                .map(
                                  (ingredient) => Chip(label: Text(ingredient)),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          ..._analysis!.recommendations.map(
                            (recommendation) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.restaurant),
                                title: Text(recommendation.name),
                                subtitle: Text(recommendation.reason),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
