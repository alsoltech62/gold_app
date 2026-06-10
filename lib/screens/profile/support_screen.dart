import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gold_provider.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoldProvider>(context, listen: false).fetchTickets();
    });
  }

  void _handleSubmit() async {
    final subject = _subjectController.text.trim();
    final desc = _descriptionController.text.trim();
    if (subject.isEmpty || desc.isEmpty) return;

    final provider = Provider.of<GoldProvider>(context, listen: false);
    final result = await provider.createTicket(subject, desc);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket created successfully')));
      setState(() {
        _showForm = false;
        _subjectController.clear();
        _descriptionController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to create ticket'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'closed': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SUPPORT TICKETS'),
        centerTitle: true,
      ),
      body: Consumer<GoldProvider>(
        builder: (context, provider, child) {
          final tickets = provider.tickets;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Need help? Raise a ticket here.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showForm = !_showForm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: Icon(_showForm ? Icons.close : Icons.add_circle_outline, size: 18),
                      label: Text(_showForm ? 'Cancel' : 'New Ticket'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_showForm) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _subjectController,
                          decoration: const InputDecoration(labelText: 'Subject', hintText: 'Brief description'),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Description', hintText: 'Provide all details here...'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: provider.isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: provider.isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Text('Submit Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                if (provider.isLoading && tickets.isEmpty)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                else if (tickets.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('No tickets found.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final t = tickets[index];
                      final statusColor = _getStatusColor(t['status'] ?? 'open');
                      return Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.confirmation_num, size: 16, color: Colors.orange),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(t['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (t['status'] ?? 'OPEN').toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(t['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(t['created_at'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
