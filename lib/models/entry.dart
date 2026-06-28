import 'package:cloud_firestore/cloud_firestore.dart';

class Entry {
  final String id;
  final String employeeName;
  final String clientName;
  final String productName;
  final int quantity;
  final String date;
  final int createdAtMs; // client-side ms timestamp for reliable sort

  const Entry({
    required this.id,
    required this.employeeName,
    required this.clientName,
    required this.productName,
    required this.quantity,
    required this.date,
    this.createdAtMs = 0,
  });

  factory Entry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Entry(
      id: doc.id,
      employeeName: data['employeeName'] as String,
      clientName: data['clientName'] as String,
      productName: data['productName'] as String,
      quantity: (data['quantity'] as num).toInt(),
      date: data['date'] as String,
      createdAtMs: (data['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'employeeName': employeeName,
        'clientName': clientName,
        'productName': productName,
        'quantity': quantity,
        'date': date,
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
