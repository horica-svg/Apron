class ShoppingListItem {
  ShoppingListItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
  });

  final String? id;
  final String name;
  final double quantity;
  final String unit;
  final bool isChecked;

  factory ShoppingListItem.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return ShoppingListItem(
      id: documentId,
      name: data['name'],
      quantity: (data['quantity'] as num).toDouble(),
      unit: data['unit'],
      isChecked: data['isChecked'] ?? false,
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked,
    };
  }
}
