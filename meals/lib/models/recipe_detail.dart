class RecipeDetail {
  final int id;
  final String title;
  final String image;
  final int readyInMinutes;
  final int servings;
  final String summary;
  final List<String> ingredients;
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
          (json['extendedIngredients'] as List<dynamic>?)
              ?.map((e) => e['original'] as String)
              .toList() ??
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
