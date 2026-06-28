import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../services/admin_service.dart';
import '../services/firestore_service.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key, required this.employeeName});

  final String employeeName;

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  static const _newClientSentinel = '__new__';
  static const _otherProduct = 'Άλλο';

  final _formKey = GlobalKey<FormState>();
  final _newClientController = TextEditingController();
  final _customProductController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedClient;
  String? _selectedProduct;
  bool _saving = false;

  final _service = FirestoreService();

  // Uses device local time — set device timezone to Greece (EET/EEST).
  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String get _effectiveClient => _selectedClient == _newClientSentinel
      ? _newClientController.text.trim()
      : (_selectedClient ?? '');

  String get _effectiveProduct => _selectedProduct == _otherProduct
      ? _customProductController.text.trim()
      : (_selectedProduct ?? '');

  @override
  void dispose() {
    _newClientController.dispose();
    _customProductController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final client = _effectiveClient;
      final product = _effectiveProduct;
      final qty = int.parse(_quantityController.text);

      await _service.ensureClient(client);
      await _service.addEntry(Entry(
        id: '',
        employeeName: widget.employeeName,
        clientName: client,
        productName: product,
        quantity: qty,
        date: _today,
      ));

      setState(() => _selectedProduct = null);
      _customProductController.clear();
      _quantityController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Καταχωρήθηκαν $qty × $product για $client'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Σφάλμα αποθήκευσης: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _clientDropdown(),
                  if (_selectedClient == _newClientSentinel) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newClientController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Όνομα νέου πελάτη',
                        prefixIcon: Icon(Icons.person_add),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Απαιτείται' : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  StreamBuilder<List<String>>(
                    stream: _service.watchProducts(),
                    builder: (context, pSnap) {
                      final products = [
                        ...pSnap.data ?? [],
                        _otherProduct,
                      ];
                      // ignore: deprecated_member_use
                      return DropdownButtonFormField<String>(
                        value: products.contains(_selectedProduct)
                            ? _selectedProduct
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Προϊόν',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: products
                            .map((p) =>
                                DropdownMenuItem<String>(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedProduct = v),
                        validator: (v) => v == null ? 'Απαιτείται' : null,
                      );
                    },
                  ),
                  if (_selectedProduct == _otherProduct) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customProductController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Περιγραφή προϊόντος',
                        prefixIcon: Icon(Icons.edit_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Απαιτείται' : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Ποσότητα',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Απαιτείται';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Πρέπει να είναι > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add),
                    label: const Text('Καταχώρηση'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Σημερινές καταχωρήσεις — ${widget.employeeName}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Entry>>(
              stream: _service.entriesForEmployeeAndDate(
                  widget.employeeName, _today),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snap.data ?? [];
                if (entries.isEmpty) {
                  return const Center(
                    child: Text(
                      'Δεν υπάρχουν καταχωρήσεις σήμερα.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      tileColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text('${e.quantity}',
                            style: const TextStyle(fontSize: 12)),
                      ),
                      title: Text(e.productName),
                      subtitle: Text(e.clientName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showEditEntry(context, e),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _service.deleteEntry(e.id),
                          ),
                        ],
                      ),
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

  Future<void> _showEditEntry(BuildContext context, Entry entry) async {
    String? editClient = entry.clientName;
    // will be set once the products stream loads
    String? editProduct;
    List<String> loadedProducts = [];
    final customProductCtrl = TextEditingController();
    final quantityCtrl =
        TextEditingController(text: entry.quantity.toString());
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Επεξεργασία Καταχώρησης',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                StreamBuilder<List<String>>(
                  stream: _service.watchClients(),
                  builder: (_, snap) {
                    final clients = snap.data ?? [];
                    // ignore: deprecated_member_use
                    return DropdownButtonFormField<String>(
                      value: clients.contains(editClient) ? editClient : null,
                      decoration: const InputDecoration(
                          labelText: 'Πελάτης',
                          border: OutlineInputBorder()),
                      items: clients
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setModalState(() => editClient = v),
                      validator: (v) => v == null ? 'Απαιτείται' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<String>>(
                  stream: _service.watchProducts(),
                  builder: (_, pSnap) {
                    loadedProducts = [
                      ...pSnap.data ?? [],
                      _otherProduct,
                    ];
                    // initialise editProduct once list is available
                    editProduct ??= loadedProducts.contains(entry.productName)
                        ? entry.productName
                        : _otherProduct;
                    if (editProduct == _otherProduct &&
                        customProductCtrl.text.isEmpty &&
                        !loadedProducts
                            .contains(entry.productName)) {
                      customProductCtrl.text = entry.productName;
                    }
                    // ignore: deprecated_member_use
                    return DropdownButtonFormField<String>(
                      value: loadedProducts.contains(editProduct)
                          ? editProduct
                          : null,
                      decoration: const InputDecoration(
                          labelText: 'Προϊόν',
                          border: OutlineInputBorder()),
                      items: loadedProducts
                          .map((p) =>
                              DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => editProduct = v),
                      validator: (v) => v == null ? 'Απαιτείται' : null,
                    );
                  },
                ),
                if (editProduct == _otherProduct) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: customProductCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Περιγραφή',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Απαιτείται' : null,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Ποσότητα', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Απαιτείται';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Πρέπει να είναι > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final product = editProduct == _otherProduct
                        ? customProductCtrl.text.trim()
                        : editProduct!;
                    await _service.updateEntry(
                      entry.id,
                      editClient!,
                      product,
                      int.parse(quantityCtrl.text),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Αποθήκευση'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _clientDropdown() {
    return StreamBuilder<List<String>>(
      stream: _service.watchClients(),
      builder: (context, snap) {
        final clients = snap.data ?? [];
        // Keep the current value valid when the list changes
        final validValue = (clients.contains(_selectedClient) ||
                _selectedClient == _newClientSentinel)
            ? _selectedClient
            : null;
        if (validValue != _selectedClient) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _selectedClient = validValue));
        }
        // ignore: deprecated_member_use
        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: const InputDecoration(
            labelText: 'Πελάτης',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
          ),
          items: [
            ...clients.map(
              (c) => DropdownMenuItem(value: c, child: Text(c)),
            ),
            if (AdminService().isAdmin.value)
              const DropdownMenuItem(
                value: _newClientSentinel,
                child: Row(
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Νέος πελάτης...'),
                  ],
                ),
              ),
          ],
          onChanged: (v) => setState(() => _selectedClient = v),
          validator: (v) => v == null ? 'Απαιτείται' : null,
        );
      },
    );
  }
}
