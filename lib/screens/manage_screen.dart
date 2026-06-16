import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/firestore_service.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Διαχείριση'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: 'Αποσύνδεση Admin',
              onPressed: () {
                AdminService().logout();
                Navigator.pop(context);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Υπάλληλοι'),
              Tab(icon: Icon(Icons.business), text: 'Πελάτες'),
              Tab(icon: Icon(Icons.category_outlined), text: 'Προϊόντα'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _EmployeesTab(),
            _ClientsTab(),
            _ProductsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Employees tab ──────────────────────────────────────────────────────────

class _EmployeesTab extends StatelessWidget {
  const _EmployeesTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: FirestoreService().watchEmployees(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final employees = snap.data ?? [];
        return Stack(
          children: [
            employees.isEmpty
                ? const Center(
                    child: Text('Δεν υπάρχουν υπάλληλοι.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: employees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) =>
                        _EmployeeRow(name: employees[i]),
                  ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'add_employee',
                icon: const Icon(Icons.person_add),
                label: const Text('Νέος Υπάλληλος'),
                onPressed: () => _showAddDialog(context),
              ),
            ),
          ],
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
              labelText: 'Όνομα', border: OutlineInputBorder()),
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

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.name});

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
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primary,
          child: Text(initials,
              style: TextStyle(
                  color: scheme.onPrimary, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Επεξεργασία',
              onPressed: () => _editName(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Αφαίρεση',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Επεξεργασία Ονόματος'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Όνομα', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ακύρωση')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Αποθήκευση')),
        ],
      ),
    );
    if (newName != null &&
        newName.trim().isNotEmpty &&
        newName.trim() != name) {
      await FirestoreService().updateEmployee(name, newName);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Αφαίρεση Υπαλλήλου'),
        content: Text('Να αφαιρεθεί ο/η "$name";'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ακύρωση')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Αφαίρεση')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService().deleteEmployee(name);
    }
  }
}

// ── Clients tab ────────────────────────────────────────────────────────────

class _ClientsTab extends StatelessWidget {
  const _ClientsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: FirestoreService().watchClients(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final clients = snap.data ?? [];
        return Stack(
          children: [
            clients.isEmpty
                ? const Center(
                    child: Text('Δεν υπάρχουν πελάτες.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: clients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) => _ClientRow(name: clients[i]),
                  ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'add_client',
                icon: const Icon(Icons.add_business),
                label: const Text('Νέος Πελάτης'),
                onPressed: () => _showAddDialog(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Προσθήκη Πελάτη'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Όνομα', border: OutlineInputBorder()),
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
      await FirestoreService().ensureClient(name);
    }
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondary,
          child: Text(name[0].toUpperCase(),
              style: TextStyle(
                  color: scheme.onSecondary, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Επεξεργασία',
              onPressed: () => _editName(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Αφαίρεση',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Επεξεργασία Πελάτη'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Όνομα', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ακύρωση')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Αποθήκευση')),
        ],
      ),
    );
    if (newName != null &&
        newName.trim().isNotEmpty &&
        newName.trim() != name) {
      await FirestoreService().updateClient(name, newName);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Αφαίρεση Πελάτη'),
        content: Text('Να αφαιρεθεί ο πελάτης "$name";'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ακύρωση')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Αφαίρεση')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService().deleteClient(name);
    }
  }
}

// ── Products tab ───────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: FirestoreService().watchProducts(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snap.data ?? [];
        return Stack(
          children: [
            products.isEmpty
                ? const Center(
                    child: Text('Δεν υπάρχουν προϊόντα.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) =>
                        _ProductRow(name: products[i]),
                  ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'add_product',
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Νέο Προϊόν'),
                onPressed: () => _showAddDialog(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Προσθήκη Προϊόντος'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Προϊόν', border: OutlineInputBorder()),
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
      await FirestoreService().addProduct(name);
    }
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.tertiary,
          child: Text(name[0].toUpperCase(),
              style: TextStyle(
                  color: scheme.onTertiary, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Επεξεργασία',
              onPressed: () => _editName(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Αφαίρεση',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Επεξεργασία Προϊόντος'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Όνομα', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ακύρωση')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Αποθήκευση')),
        ],
      ),
    );
    if (newName != null &&
        newName.trim().isNotEmpty &&
        newName.trim() != name) {
      await FirestoreService().updateProduct(name, newName);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Αφαίρεση Προϊόντος'),
        content: Text('Να αφαιρεθεί το προϊόν "$name";'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ακύρωση')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Αφαίρεση')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService().deleteProduct(name);
    }
  }
}
