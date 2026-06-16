import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/firestore_service.dart';
import 'add_entry_screen.dart';

class SelectEmployeeScreen extends StatelessWidget {
  const SelectEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminService().isAdmin,
      builder: (context, isAdmin, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ποιος είσαι;'),
            centerTitle: true,
          ),
          body: StreamBuilder<List<String>>(
            stream: FirestoreService().watchEmployees(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final employees = snapshot.data ?? [];
              return employees.isEmpty
                  ? _EmptyState(
                      isAdmin: isAdmin,
                      onAdd: () => _showAddDialog(context),
                    )
                  : _EmployeeGrid(employees: employees);
            },
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Νέος Υπάλληλος'),
                )
              : null,
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Προσθήκη Υπαλλήλου'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Όνομα',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ακύρωση')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Προσθήκη')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await FirestoreService().addEmployee(name);
    }
  }
}

class _EmployeeGrid extends StatelessWidget {
  const _EmployeeGrid({required this.employees});

  final List<String> employees;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: employees.length,
      itemBuilder: (context, i) => _EmployeeTile(name: employees[i]),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Card(
      color: scheme.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddEntryScreen(employeeName: name)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primary,
              child: Text(initials,
                  style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isAdmin, required this.onAdd});

  final bool isAdmin;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Δεν υπάρχουν υπάλληλοι ακόμα.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          if (isAdmin) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add),
            label: const Text('Προσθήκη Υπαλλήλου'),
          ),
          ],
        ],
      ),
    );
  }
}
