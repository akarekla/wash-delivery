import 'package:cloud_firestore/cloud_firestore.dart';

class Entry {
  final String id;
  final String employeeName;
  final String clientName;
  final String productName;
  final int quantity;
  final String date;

  const Entry({
    required this.id,
    required this.employeeName,
    required this.clientName,
    required this.productName,
    required this.quantity,
    required this.date,
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
    );
  }

  Map<String, dynamic> toFirestore() => {
        'employeeName': employeeName,
        'clientName': clientName,
        'productName': productName,
        'quantity': quantity,
        'date': date,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
