import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItem {
  PantryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.expiryDate,
  });

  final String? id;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final DateTime? expiryDate;

  factory PantryItem.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return PantryItem(
      id: documentId,
      name: data['name'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? '',
      category: data['category'] ?? 'Other',
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'expiryDate': expiryDate,
    };
  }
}
