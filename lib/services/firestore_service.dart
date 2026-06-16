import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/entry.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _db = FirebaseFirestore.instance;

  // ── Entries ───────────────────────────────────────────────────────────────

  Future<void> addEntry(Entry entry) async {
    await _db.collection('entries').add(entry.toFirestore());
  }

  Future<void> deleteEntry(String entryId) async {
    await _db.collection('entries').doc(entryId).delete();
  }

  // ── Products ──────────────────────────────────────────────────────────────

  static const List<String> _defaultProducts = [
    'Σεντόνια',
    'Πετσέτες',
    'Μαξιλαροθήκες',
    'Χαλάκι',
  ];

  Stream<List<String>> watchProducts() {
    return _db.collection('products').snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        _seedProducts(); // fire-and-forget on first run
        return List<String>.from(_defaultProducts);
      }
      final names = snap.docs.map((d) => d['name'] as String).toList();
      names.sort();
      return names;
    });
  }

  Future<void> _seedProducts() async {
    final batch = _db.batch();
    for (final name in _defaultProducts) {
      batch.set(_db.collection('products').doc(), {'name': name});
    }
    await batch.commit();
  }

  Future<void> addProduct(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final existing = await _db
        .collection('products')
        .where('name', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await _db.collection('products').add({'name': trimmed});
    }
  }

  Future<void> updateProduct(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final snap = await _db
        .collection('products')
        .where('name', isEqualTo: oldName)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'name': trimmed});
    }
  }

  Future<void> deleteProduct(String name) async {
    final snap = await _db
        .collection('products')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> updateEntry(
      String entryId, String clientName, String productName, int quantity) async {
    await _db.collection('entries').doc(entryId).update({
      'clientName': clientName,
      'productName': productName,
      'quantity': quantity,
    });
  }

  Stream<List<Entry>> entriesForDate(String date) {
    return _db
        .collection('entries')
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snap) {
      final entries = snap.docs.map(Entry.fromFirestore).toList();
      entries.sort((a, b) => a.id.compareTo(b.id));
      return entries;
    });
  }

  // Single where-clause only; employee filtered client-side to avoid
  // composite index requirement.
  Stream<List<Entry>> entriesForEmployeeAndDate(String employee, String date) {
    return _db
        .collection('entries')
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snap) {
      final entries = snap.docs
          .map(Entry.fromFirestore)
          .where((e) => e.employeeName == employee)
          .toList();
      entries.sort((a, b) => a.id.compareTo(b.id));
      return entries;
    });
  }

  // ── Employees ─────────────────────────────────────────────────────────────

  Stream<List<String>> watchEmployees() {
    return _db
        .collection('employees')
        .snapshots()
        .map((snap) {
      final names = snap.docs.map((d) => d['name'] as String).toList();
      names.sort();
      return names;
    });
  }

  Future<void> addEmployee(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final existing = await _db
        .collection('employees')
        .where('name', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await _db.collection('employees').add({'name': trimmed});
    }
  }

  Future<void> updateEmployee(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final snap = await _db
        .collection('employees')
        .where('name', isEqualTo: oldName)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'name': trimmed});
    }
  }

  Future<void> deleteEmployee(String name) async {
    final snap = await _db
        .collection('employees')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ── Clients ───────────────────────────────────────────────────────────────

  Stream<List<String>> watchClients() {
    return _db
        .collection('clients')
        .snapshots()
        .map((snap) {
      final names = snap.docs.map((d) => d['name'] as String).toList();
      names.sort();
      return names;
    });
  }

  Future<void> updateClient(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final snap = await _db
        .collection('clients')
        .where('name', isEqualTo: oldName)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'name': trimmed});
    }
  }

  Future<void> deleteClient(String name) async {
    final snap = await _db
        .collection('clients')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> ensureClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final existing = await _db
        .collection('clients')
        .where('name', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await _db.collection('clients').add({'name': trimmed});
    }
  }

}
