import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'select_employee_screen.dart';
import 'summary_screen.dart';
import 'manage_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final admin = AdminService();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: admin.isAdmin,
          builder: (context, isAdmin, _) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Admin lock button top-right
                  Align(
                    alignment: Alignment.centerRight,
                    child: isAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Admin',
                                  style: TextStyle(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: Icon(Icons.lock_open,
                                    color: scheme.primary),
                                tooltip: 'Αποσύνδεση Admin',
                                onPressed: admin.logout,
                              ),
                            ],
                          )
                        : IconButton(
                            icon: const Icon(Icons.lock_outline),
                            tooltip: 'Σύνδεση Admin',
                            onPressed: () => _showPinDialog(context),
                          ),
                  ),
                  Icon(Icons.local_laundry_service,
                      size: 64, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Wash Delivery',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Καθημερινή καταγραφή',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  _RoleCard(
                    icon: Icons.add_circle_outline,
                    title: 'Προσθήκη Προϊόντων',
                    subtitle: 'Καταγραφή ειδών για πελάτη',
                    color: scheme.primaryContainer,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SelectEmployeeScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.bar_chart,
                    title: 'Ημερήσια Αναφορά',
                    subtitle: 'Δες όλους τους πελάτες και τα είδη τους',
                    color: scheme.secondaryContainer,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SummaryScreen()),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    _RoleCard(
                      icon: Icons.manage_accounts,
                      title: 'Διαχείριση',
                      subtitle: 'Υπάλληλοι & πελάτες',
                      color: scheme.tertiaryContainer,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ManageScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.pin, size: 18),
                      label: const Text('Αλλαγή PIN Admin'),
                      onPressed: () => _showChangePinDialog(context),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showPinDialog(BuildContext context) async {
    final controller = TextEditingController();
    bool wrong = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Σύνδεση Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  border: const OutlineInputBorder(),
                  errorText: wrong ? 'Λάθος PIN' : null,
                ),
                onSubmitted: (_) async {
                  final ok =
                      await AdminService().verifyPin(controller.text);
                  if (ok) {
                    if (ctx.mounted) Navigator.pop(ctx);
                  } else {
                    setState(() => wrong = true);
                    controller.clear();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Ακύρωση')),
            FilledButton(
              onPressed: () async {
                final ok =
                    await AdminService().verifyPin(controller.text);
                if (ok) {
                  if (ctx.mounted) Navigator.pop(ctx);
                } else {
                  setState(() => wrong = true);
                  controller.clear();
                }
              },
              child: const Text('Σύνδεση'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePinDialog(BuildContext context) async {
    final controller = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Αλλαγή PIN'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Νέο PIN', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.length < 4) ? 'Τουλάχιστον 4 ψηφία' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Επιβεβαίωση PIN',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v != controller.text ? 'Τα PIN δεν ταιριάζουν' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ακύρωση')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await AdminService().changePin(controller.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN άλλαξε επιτυχώς'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Αποθήκευση'),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
