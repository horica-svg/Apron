class RecipeIngredient {
  final String name;
  final double amount;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
  });
}

/// Algoritm de aproximare a cantităților pentru a elimina valorile fracționare ciudate
double _approximateAmount(double amount) {
  if (amount <= 0) return 0.0;
  if (amount < 10) return (amount * 2).round() / 2.0; // la cel mai apropiat 0.5
  if (amount < 50) return amount.roundToDouble(); // la cel mai apropiat întreg
  if (amount < 100)
    return (amount / 5).round() * 5.0; // la cel mai apropiat multiplu de 5
  if (amount < 500)
    return (amount / 10).round() * 10.0; // la cel mai apropiat multiplu de 10
  return (amount / 50).round() * 50.0; // la cel mai apropiat multiplu de 50
}

class RecipeDetail {
  final int id;
  final String title;
  final String image;
  final int readyInMinutes;
  final int servings;
  final String summary;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;

  RecipeDetail({
    required this.id,
    required this.title,
    required this.image,
    required this.readyInMinutes,
    required this.servings,
    required this.summary,
    required this.ingredients,
    required this.instructions,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      id: json['id'],
      title: json['title'],
      image: json['image'] ?? '',
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 1,
      summary: json['summary'] ?? '',
      ingredients:
          (json['extendedIngredients'] as List<dynamic>?)?.map((e) {
            final metric = e['measures']?['metric'];
            final rawAmount = (metric?['amount'] as num?)?.toDouble() ?? 0.0;
            return RecipeIngredient(
              name: e['name'] as String? ?? e['original'] as String? ?? '',
              amount: _approximateAmount(rawAmount),
              unit: metric?['unitShort'] as String? ?? '',
            );
          }).toList() ??
          [],
      instructions:
          (json['analyzedInstructions'] as List<dynamic>?)
              ?.expand((e) => (e['steps'] as List<dynamic>))
              .map((s) => s['step'] as String)
              .toList() ??
          [],
    );
  }
}
