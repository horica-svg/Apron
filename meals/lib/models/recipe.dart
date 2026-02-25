class SpoonacularRecipe {
  final int id;
  final String title;
  final String image;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final List<String> missedIngredients;
  final List<String> usedIngredients;

  SpoonacularRecipe({
    required this.id,
    required this.title,
    required this.image,
    required this.usedIngredientCount,
    required this.missedIngredientCount,
    required this.missedIngredients,
    required this.usedIngredients,
  });

  factory SpoonacularRecipe.fromJson(Map<String, dynamic> json) {
    return SpoonacularRecipe(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      usedIngredientCount: json['usedIngredientCount'],
      missedIngredientCount: json['missedIngredientCount'],
      missedIngredients:
          (json['missedIngredients'] as List?)
              ?.map((e) => e['name'] as String)
              .toList() ??
          [],
      usedIngredients:
          (json['usedIngredients'] as List?)
              ?.map((e) => e['name'] as String)
              .toList() ??
          [],
    );
  }
}
