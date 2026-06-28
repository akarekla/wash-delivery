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
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar: admin status / lock
                  SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: isAdmin
                          ? Container(
                              padding: const EdgeInsets.only(left: 14),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Admin',
                                      style: TextStyle(
                                          color: scheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w600)),
                                  IconButton(
                                    icon: Icon(Icons.lock_open,
                                        size: 20,
                                        color: scheme.onPrimaryContainer),
                                    tooltip: 'Αποσύνδεση Admin',
                                    onPressed: admin.logout,
                                  ),
                                ],
                              ),
                            )
                          : IconButton.filledTonal(
                              icon: const Icon(Icons.lock_outline, size: 20),
                              tooltip: 'Σύνδεση Admin',
                              onPressed: () => _showPinDialog(context),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Logo (transparent background) on the page surface
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, _, __) => Icon(
                        Icons.local_laundry_service,
                        size: 64,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ΚΑΘΗΜΕΡΙΝΗ ΚΑΤΑΓΡΑΦΗ',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                  ),
                  const SizedBox(height: 28),

                  _RoleCard(
                    icon: Icons.add_circle_outline,
                    title: 'Προσθήκη Προϊόντων',
                    subtitle: 'Καταγραφή ειδών για πελάτη',
                    accent: scheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SelectEmployeeScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Ημερήσια Αναφορά',
                    subtitle: 'Δες όλους τους πελάτες και τα είδη τους',
                    accent: scheme.tertiary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SummaryScreen()),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 14),
                    _RoleCard(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Διαχείριση',
                      subtitle: 'Υπάλληλοι & πελάτες',
                      accent: scheme.secondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ManageScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.pin, size: 18),
                      label: const Text('Αλλαγή PIN Admin'),
                      onPressed: () => _showChangePinDialog(context),
                    ),
                  ],
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
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant.withAlpha(120)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(28),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 26, color: accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                ),
              ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
