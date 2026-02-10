class PantryItem {
  PantryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String? id;
  final String name;
  final double quantity;
  final String unit;

  factory PantryItem.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return PantryItem(
      id: documentId,
      name: data['name'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'quantity': quantity, 'unit': unit};
  }
}
