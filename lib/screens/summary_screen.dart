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
  late DateTime _selectedMonth;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateFormat('yyyy-MM-dd').format(now);
  }

  String get _monthStart =>
      DateFormat('yyyy-MM-dd').format(_selectedMonth);

  String get _monthEnd => DateFormat('yyyy-MM-dd')
      .format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    if (_isCurrentMonth) return;
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monthLabel =
        DateFormat('MMMM yyyy', 'el_GR').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Μηνιαία Αναφορά'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Entry>>(
        stream: FirestoreService().entriesForMonth(_monthStart, _monthEnd),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allEntries = snap.data ?? [];

          // All dates in this month that have entries, sorted descending
          final dates = allEntries
              .map((e) => e.date)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          // If current selectedDate has no entries, reset to first available
          if (_selectedDate != null &&
              dates.isNotEmpty &&
              !dates.contains(_selectedDate)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selectedDate = dates.first);
            });
          }

          final dayEntries = _selectedDate == null
              ? <Entry>[]
              : allEntries
                  .where((e) => e.date == _selectedDate)
                  .toList();
          final grouped = _groupByClient(dayEntries);

          return Column(
            children: [
              // Month navigator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: scheme.surfaceContainerLow,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _prevMonth,
                    ),
                    Text(
                      monthLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: _isCurrentMonth
                            ? scheme.onSurface.withAlpha(60)
                            : null,
                      ),
                      onPressed: _isCurrentMonth ? null : _nextMonth,
                    ),
                  ],
                ),
              ),

              // Day selector chips
              if (dates.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: scheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'Δεν υπάρχουν καταχωρήσεις αυτόν τον μήνα.',
                          style: TextStyle(
                              color: scheme.outline, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _DaySelector(
                  dates: dates,
                  selectedDate: _selectedDate,
                  onSelected: (date) =>
                      setState(() => _selectedDate = date),
                ),
                const Divider(height: 1),
                // Client cards
                Expanded(
                  child: grouped.isEmpty
                      ? Center(
                          child: Text(
                            'Επιλέξτε μια μέρα για να δείτε τις καταχωρήσεις.',
                            style: TextStyle(color: scheme.outline),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : StreamBuilder<Set<String>>(
                          stream: FirestoreService()
                              .watchCheckoffs(_selectedDate!),
                          builder: (context, checkSnap) {
                            final checked = checkSnap.data ?? <String>{};
                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: grouped.length,
                              itemBuilder: (context, i) {
                                final client = grouped.keys.elementAt(i);
                                final done = checked.contains(client);
                                return _ClientCard(
                                  clientName: client,
                                  products: grouped[client]!,
                                  done: done,
                                  onToggle: () => FirestoreService()
                                      .setCheckoff(
                                          _selectedDate!, client, !done),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

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

class _DaySelector extends StatefulWidget {
  const _DaySelector({
    required this.dates,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<String> dates;
  final String? selectedDate;
  final ValueChanged<String> onSelected;

  @override
  State<_DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<_DaySelector> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _label(String dateKey) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parse(dateKey);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final d = DateTime(dt.year, dt.month, dt.day);
      if (d == today) return 'Σήμερα';
      if (d == today.subtract(const Duration(days: 1))) return 'Χθες';
      return DateFormat('EEE d', 'el_GR').format(dt);
    } catch (_) {
      return dateKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: widget.dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final date = widget.dates[i];
          final selected = date == widget.selectedDate;
          return ChoiceChip(
            label: Text(_label(date)),
            selected: selected,
            onSelected: (_) => widget.onSelected(date),
            selectedColor: scheme.primary,
            labelStyle: TextStyle(
              color: selected ? scheme.onPrimary : null,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.clientName,
    required this.products,
    required this.done,
    required this.onToggle,
  });

  final String clientName;
  final Map<String, int> products;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = products.values.fold(0, (s, q) => s + q);
    final strike = done ? TextDecoration.lineThrough : null;
    final muted = done ? scheme.outline : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: done
          ? scheme.surfaceContainerLowest
          : scheme.surfaceContainerLow,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: done ? scheme.outline : scheme.primary,
                    child: Text(
                      clientName[0].toUpperCase(),
                      style: TextStyle(
                          color: done ? scheme.surface : scheme.onPrimary,
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
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: strike,
                            color: muted,
                          ),
                    ),
                  ),
                  Chip(
                    label: Text('$total τεμ.'),
                    backgroundColor: done
                        ? scheme.surfaceContainerHighest
                        : scheme.secondaryContainer,
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const SizedBox(width: 4),
                  Checkbox(
                    value: done,
                    onChanged: (_) => onToggle(),
                    activeColor: scheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
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
                      Icon(Icons.fiber_manual_record,
                          size: 8, color: muted ?? Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.key,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(decoration: strike, color: muted),
                        ),
                      ),
                      Text(
                        '${p.value}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: strike,
                              color: muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
