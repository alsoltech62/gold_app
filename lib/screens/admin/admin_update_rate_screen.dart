import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminUpdateRateScreen extends StatefulWidget {
  const AdminUpdateRateScreen({super.key});

  @override
  State<AdminUpdateRateScreen> createState() => _AdminUpdateRateScreenState();
}

class _AdminUpdateRateScreenState extends State<AdminUpdateRateScreen> {
  final _rateController = TextEditingController();

  void _handleUpdate() async {
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    if (rate <= 0) return;

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.updateGoldRate(rate);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gold rate updated successfully!')),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update rate.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UPDATE GOLD RATE')),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'New Rate (per gram)',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: Consumer<AdminProvider>(
                builder: (context, admin, child) {
                  return ElevatedButton(
                    onPressed: admin.isLoading ? null : _handleUpdate,
                    child: admin.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('UPDATE NOW'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
