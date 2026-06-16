import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../services/firestore_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _dayOffset = 0; // 0 = today, 1 = yesterday, etc.

  DateTime get _selectedDate =>
      DateTime.now().subtract(Duration(days: _dayOffset));

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  String _chipLabel(int offset) {
    if (offset == 0) return 'Σήμερα';
    if (offset == 1) return 'Χθες';
    final date = DateTime.now().subtract(Duration(days: offset));
    return DateFormat('d MMM', 'el_GR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ημερήσια Αναφορά'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 4-day selector
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(4, (i) {
                  final selected = _dayOffset == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_chipLabel(i)),
                      selected: selected,
                      onSelected: (_) => setState(() => _dayOffset = i),
                      selectedColor: scheme.primaryContainer,
                      checkmarkColor: scheme.primary,
                      labelStyle: TextStyle(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: StreamBuilder<List<Entry>>(
              stream: FirestoreService().entriesForDate(_dateKey),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snap.data ?? [];
                if (entries.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Δεν υπάρχουν καταχωρήσεις για αυτή την ημέρα.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                final grouped = _groupByClient(entries);
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: grouped.length,
                  itemBuilder: (context, i) {
                    final client = grouped.keys.elementAt(i);
                    return _ClientCard(
                      clientName: client,
                      products: grouped[client]!,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Groups entries by client, then sums quantities by product name.
  Map<String, Map<String, int>> _groupByClient(List<Entry> entries) {
    final result = <String, Map<String, int>>{};
    for (final e in entries) {
      result.putIfAbsent(e.clientName, () => {});
      result[e.clientName]![e.productName] =
          (result[e.clientName]![e.productName] ?? 0) + e.quantity;
    }
    return Map.fromEntries(
        result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.clientName, required this.products});

  final String clientName;
  final Map<String, int> products;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = products.values.fold(0, (sum, q) => sum + q);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primary,
                  child: Text(
                    clientName[0].toUpperCase(),
                    style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    clientName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text('$total τεμ.'),
                  backgroundColor: scheme.secondaryContainer,
                  padding: EdgeInsets.zero,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...products.entries.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        size: 8, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(p.key,
                            style: Theme.of(context).textTheme.bodyLarge)),
                    Text(
                      '${p.value}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
