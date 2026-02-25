import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meals/models/recipe.dart';
import 'package:meals/models/recipe_detail.dart';

// Export the model so it's available wherever the service is imported
export 'package:meals/models/recipe.dart';

class SpoonacularService {
  static const String _apiKey = '3a095194e47046fcaa46f01ea4ca51db';
  static const String _baseUrl = 'https://api.spoonacular.com/recipes';

  Future<List<SpoonacularRecipe>> getRecipesByIngredients(
    List<String> ingredients,
  ) async {
    if (ingredients.isEmpty) return [];

    // Join ingredients with comma
    final ingredientsString = ingredients.join(',');

    final uri = Uri.parse('$_baseUrl/findByIngredients').replace(
      queryParameters: {
        'apiKey': _apiKey,
        'ingredients': ingredientsString,
        'number': '10', // Limit to 10 results
        'ranking': '1', // Maximize used ingredients
        'ignorePantry': 'true',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => SpoonacularRecipe.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }
  }

  Future<RecipeDetail> getRecipeDetails(int recipeId) async {
    final uri = Uri.parse('$_baseUrl/$recipeId/information').replace(
      queryParameters: {'apiKey': _apiKey, 'includeNutrition': 'false'},
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return RecipeDetail.fromJson(data);
    } else {
      throw Exception('Failed to load recipe details: ${response.statusCode}');
    }
  }

  /// Calculează costul total estimat pentru o listă de ingrediente.
  /// Returnează valoarea în dolari (API-ul returnează default în cenți).
  Future<double> getIngredientsTotalCost(List<String> ingredients) async {
    if (ingredients.isEmpty) return 0.0;

    final uri = Uri.parse(
      '$_baseUrl/parseIngredients',
    ).replace(queryParameters: {'apiKey': _apiKey});

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'ingredientList': ingredients.join('\n'),
        'servings': '1',
        'includeNutrition': 'false',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      double totalCents = 0.0;

      for (var item in data) {
        final estimatedCost = item['estimatedCost'];
        if (estimatedCost != null) {
          totalCents += (estimatedCost['value'] as num).toDouble();
        }
      }
      // Spoonacular returns price in US Cents. Divide by 100 to get USD.
      // Converting to Euro (approx rate 0.92).
      return (totalCents / 100.0) * 0.92;
    } else {
      throw Exception('Failed to calculate cost: ${response.statusCode}');
    }
  }
}
