class SimilarDish {
  final String name;
  final String reason;

  SimilarDish({required this.name, required this.reason});

  factory SimilarDish.fromJson(Map<String, dynamic> json) => SimilarDish(
    name: json['name']?.toString() ?? '-',
    reason: json['reason']?.toString() ?? '-',
  );
}

class FoodAnalysis {
  final String name;
  final String description;
  final String origin;
  final List<String> ingredients;
  final List<SimilarDish> recommendations;

  FoodAnalysis({
    required this.name,
    required this.description,
    required this.origin,
    required this.ingredients,
    required this.recommendations,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    final recs =
        (json['recommendations'] as List?)
            ?.map((e) => SimilarDish.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        <SimilarDish>[];

    final ings =
        (json['ingredients'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];

    return FoodAnalysis(
      name: json['name']?.toString() ?? '-',
      description: json['description']?.toString() ?? '-',
      origin: json['origin']?.toString() ?? '-',
      ingredients: ings,
      recommendations: recs,
    );
  }
}
