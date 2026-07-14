import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gold_provider.dart';
import '../gold/lock_in_modal.dart';

class DeliveryScreen extends StatefulWidget {
  final String? initialMetalType;
  const DeliveryScreen({super.key, this.initialMetalType});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  late String _selectedMetal;
  final _gramsController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMetal = widget.initialMetalType ?? 'gold';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<GoldProvider>(context, listen: false);
      p.fetchDeliveries();
      p.fetchSettings();
    });
  }

  void _handleRequest() async {
    final grams = double.tryParse(_gramsController.text) ?? 0;
    if (grams < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum 1 gram required')));
      return;
    }
    
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();
    
    if (street.isEmpty || city.isEmpty || state.isEmpty || pincode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete the full shipping address')));
      return;
    }

    _submitRequest(grams, street, city, state, pincode);
  }

  void _submitRequest(double grams, String street, String city, String state, String pincode) async {

    final provider = Provider.of<GoldProvider>(context, listen: false);
    final address = '$street, $city, $state - $pincode';
    final result = await provider.requestDelivery(grams, address, city, state, pincode, _selectedMetal);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Physical $_selectedMetal delivery request submitted!')));
      _gramsController.clear();
      _streetController.clear();
      _cityController.clear();
      _stateController.clear();
      _pincodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit request.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoldProvider>(context);
    final balance = _selectedMetal == 'silver' 
        ? (provider.dashboardData?['total_silver_grams'] ?? 0.0) 
        : (provider.dashboardData?['total_gold_grams'] ?? 0.0);
    final deliveries = provider.deliveries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PHYSICAL CLAIM'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Request secure delivery of your ${_selectedMetal == 'silver' ? '999 silver' : '24K gold'} assets', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMetalToggle('gold', '24K Gold'),
                const SizedBox(width: 15),
                _buildMetalToggle('silver', '999 Silver'),
              ],
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Redeemable Balance', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('${balance.toStringAsFixed(4)} gms', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _selectedMetal == 'silver' ? Colors.grey.shade300 : const Color(0xFFB08D57))),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Text('${_selectedMetal == 'silver' ? 'Silver' : 'Gold'} Quantity (min 1g)', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _gramsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Grams', suffixText: ' gms'),
            ),
            const SizedBox(height: 20),

            const Text('Shipping Destination', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street Address / House No.'),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'State'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pincode'),
            ),
            const SizedBox(height: 30),

            _buildChargesBreakdown(provider),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: provider.isLoading ? null : _handleRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: provider.isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirm Delivery Request'),
            ),
            const SizedBox(height: 40),

            const Text('Past Shipments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            if (deliveries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No physical claims recorded', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  final d = deliveries[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping, color: Colors.blue),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${d['gold_grams'] ?? d['grams']}g Shipment', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(d['created_at'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              if (d['metal_type'] != null) Text(d['metal_type'].toString().toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (d['status'] ?? 'pending').toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargesBreakdown(GoldProvider provider) {
    final s = provider.settings ?? {};
    final double deliveryCharge = (s['delivery_charge'] ?? 150).toDouble();
    final double packageCharge = (s['package_charge'] ?? 50).toDouble();
    final double forwardingCharge = (s['forwarding_charge'] ?? 100).toDouble();
    final double total = deliveryCharge + packageCharge + forwardingCharge;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHARGES BREAKDOWN', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 15),
          _buildChargeRow('Delivery Charge', deliveryCharge),
          const SizedBox(height: 10),
          _buildChargeRow('Forwarding Charge', forwardingCharge),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Estimated Cost', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₹$total', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB08D57))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChargeRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text('₹$amount', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMetalToggle(String type, String label) {
    bool isSelected = _selectedMetal == type;
    return InkWell(
      onTap: () => setState(() => _selectedMetal = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB08D57) : Colors.transparent,
          border: Border.all(color: const Color(0xFFB08D57)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFFB08D57),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
