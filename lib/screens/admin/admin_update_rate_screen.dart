import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminUpdateRateScreen extends StatefulWidget {
  const AdminUpdateRateScreen({super.key});

  @override
  State<AdminUpdateRateScreen> createState() => _AdminUpdateRateScreenState();
}

class _AdminUpdateRateScreenState extends State<AdminUpdateRateScreen> {
  final _goldMarkupController = TextEditingController();
  final _silverMarkupController = TextEditingController();
  
  String _goldMarkupType = 'fixed';
  String _silverMarkupType = 'fixed';
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.fetchSettings().then((_) {
        if (mounted) {
          setState(() {
            _goldMarkupController.text = admin.settings['gold_markup_value']?.toString() ?? '0';
            _goldMarkupType = admin.settings['gold_markup_type'] ?? 'fixed';
            
            _silverMarkupController.text = admin.settings['silver_markup_value']?.toString() ?? '0';
            _silverMarkupType = admin.settings['silver_markup_type'] ?? 'fixed';
          });
        }
      });
      _isInit = true;
    }
  }

  void _handleUpdate() async {
    final gValue = double.tryParse(_goldMarkupController.text) ?? 0.0;
    final sValue = double.tryParse(_silverMarkupController.text) ?? 0.0;

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.updateSettings({
      'gold_markup_value': gValue.toString(),
      'gold_markup_type': _goldMarkupType,
      'silver_markup_value': sValue.toString(),
      'silver_markup_type': _silverMarkupType,
    });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Markup settings saved successfully! Live rate will be updated shortly.')),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save settings.')),
      );
    }
  }

  Widget _buildMarkupSection(String title, TextEditingController controller, String type, Function(String?) onChangedType) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Markup Value',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed (₹)')),
                    DropdownMenuItem(value: 'percent', child: Text('Percent (%)')),
                  ],
                  onChanged: onChangedType,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DYNAMIC LIVE RATE MARKUP')),
      body: Consumer<AdminProvider>(
        builder: (context, admin, child) {
          if (admin.isLoading && _goldMarkupController.text.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Set the markup to be applied dynamically on the GoldAPI live prices.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildMarkupSection('Gold Rate Markup', _goldMarkupController, _goldMarkupType, (v) {
                  setState(() => _goldMarkupType = v!);
                }),
                _buildMarkupSection('Silver Rate Markup', _silverMarkupController, _silverMarkupType, (v) {
                  setState(() => _silverMarkupType = v!);
                }),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: admin.isLoading ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: admin.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('SAVE SETTINGS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
