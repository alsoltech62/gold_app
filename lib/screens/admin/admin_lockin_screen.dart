import 'package:flutter/material.dart';
import 'package:goldapp/core/api_client.dart';

class AdminLockinScreen extends StatefulWidget {
  const AdminLockinScreen({super.key});

  @override
  State<AdminLockinScreen> createState() => _AdminLockinScreenState();
}

class _AdminLockinScreenState extends State<AdminLockinScreen> {
  bool isLoading = true;
  List<dynamic> plans = [];
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    setState(() => isLoading = true);
    try {
      final res = await _apiClient.get('/api/admin/lockin_stats.php');
      if (res['success']) {
        setState(() {
          plans = res['data']['plans'] ?? [];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showPlanDialog({Map<String, dynamic>? plan}) {
    final bool isEdit = plan != null;
    final TextEditingController nameCtrl = TextEditingController(text: plan?['plan_name'] ?? '');
    final TextEditingController monthsCtrl = TextEditingController(text: plan?['months']?.toString() ?? '');
    final TextEditingController returnCtrl = TextEditingController(text: plan?['return_percentage']?.toString() ?? '');
    final TextEditingController minCtrl = TextEditingController(text: plan?['min_investment']?.toString() ?? '');
    final TextEditingController maxCtrl = TextEditingController(text: plan?['max_investment']?.toString() ?? '');
    final TextEditingController penaltyCtrl = TextEditingController(text: plan?['penalty_percentage']?.toString() ?? '');
    String metalType = plan?['metal_type'] ?? 'gold';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(isEdit ? 'Edit Plan' : 'Create Plan', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Plan Name (e.g. Basic)', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: metalType,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'gold', child: Text('Gold')),
                        DropdownMenuItem(value: 'silver', child: Text('Silver')),
                      ],
                      onChanged: (val) {
                        setDialogState(() => metalType = val!);
                      },
                      decoration: const InputDecoration(labelText: 'Metal Type', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: monthsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Duration (Months)', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: returnCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Extra Return (%)', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Min Investment', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Max Investment', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: penaltyCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Penalty (%)', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB08D57)),
                  onPressed: () async {
                    try {
                      final body = {
                        if (isEdit) 'id': plan['id'],
                        'plan_name': nameCtrl.text,
                        'months': int.tryParse(monthsCtrl.text) ?? 6,
                        'return_percentage': double.tryParse(returnCtrl.text) ?? 5.0,
                        'min_investment': double.tryParse(minCtrl.text) ?? 1.0,
                        'max_investment': double.tryParse(maxCtrl.text) ?? 999.0,
                        'penalty_percentage': double.tryParse(penaltyCtrl.text) ?? 0.0,
                        'metal_type': metalType,
                      };
                      final res = await _apiClient.post('/api/admin/lockin_plans.php', body);
                      if (!context.mounted) return;
                      if (res['success']) {
                        Navigator.pop(context);
                        fetchPlans();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                      }
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                  child: Text(isEdit ? 'Save' : 'Create', style: const TextStyle(color: Colors.black)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _deletePlan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this lock-in plan?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm == true) {
      try {
        final res = await _apiClient.delete('/api/admin/lockin_plans.php?id=$id');
        if (!mounted) return;
        if (res['success']) {
          fetchPlans();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lock-In Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPlanDialog(),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB08D57)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Card(
                  color: const Color(0xFF1A1A1A),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${plan['months']} Months (${plan['plan_name'] ?? 'Basic'})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Metal: ${(plan['metal_type'] ?? 'gold').toUpperCase()}', style: TextStyle(color: plan['metal_type'] == 'silver' ? Colors.grey : const Color(0xFFB08D57), fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('Return: +${plan['return_percentage']}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              Text('Min: ₹${plan['min_investment']} | Penalty: ${plan['penalty_percentage']}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => _showPlanDialog(plan: plan),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deletePlan(plan['id']),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
