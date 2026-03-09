import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/enquiry_model.dart';
import '../../providers/enquiry_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import 'enquiry_detail_screen.dart';

class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({Key? key}) : super(key: key);

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnquiryProvider>().loadEnquiries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(isAdmin ? 'All Enquiries' : 'My Enquiries')),
      body: Consumer<EnquiryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.enquiries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.enquiries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => provider.loadEnquiries(), child: const Text('Retry')),
                ],
              ),
            );
          }
          if (provider.enquiries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text('No enquiries yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadEnquiries(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.enquiries.length,
              itemBuilder: (context, index) {
                final enquiry = provider.enquiries[index];
                return _EnquiryCard(
                  enquiry: enquiry,
                  isAdmin: isAdmin,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EnquiryDetailScreen(enquiryId: enquiry.id)),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEnquiryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Enquiry'),
      ),
    );
  }

  void _showCreateEnquiryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Enquiry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name *')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Customer Phone *'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Customer Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Customer Address'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and phone are required')));
                return;
              }
              Navigator.pop(ctx);
              final data = <String, dynamic>{
                'customerName': nameCtrl.text.trim(),
                'customerPhone': phoneCtrl.text.trim(),
              };
              if (emailCtrl.text.isNotEmpty) data['customerEmail'] = emailCtrl.text.trim();
              if (addressCtrl.text.isNotEmpty) data['customerAddress'] = addressCtrl.text.trim();
              if (notesCtrl.text.isNotEmpty) data['notes'] = notesCtrl.text.trim();

              final success = await context.read<EnquiryProvider>().createEnquiry(data);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry created')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  final Enquiry enquiry;
  final bool isAdmin;
  final VoidCallback onTap;
  const _EnquiryCard({required this.enquiry, required this.isAdmin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(enquiry.enquiryNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  _StatusBadge(status: enquiry.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(enquiry.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(enquiry.customerPhone, style: const TextStyle(color: AppColors.textMuted)),
              if (enquiry.assignedStaff != null) ...[
                const SizedBox(height: 4),
                Text('Staff: ${enquiry.assignedStaff}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _CountChip(icon: Icons.straighten, label: '${enquiry.measurementsCount}'),
                  const SizedBox(width: 8),
                  _CountChip(icon: Icons.description, label: '${enquiry.quotationsCount}'),
                ],
              ),
              if (isAdmin) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAssignDialog(context, enquiry),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Assign', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context, enquiry),
                      icon: const Icon(Icons.delete, size: 16, color: AppColors.danger),
                      label: const Text('Delete', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, Enquiry enquiry) {
    final staffProvider = context.read<StaffProvider>();
    staffProvider.loadStaff();
    String? selectedStaffId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Assign Staff'),
          content: Consumer<StaffProvider>(
            builder: (context, sp, _) {
              if (sp.isLoading) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
              if (sp.staffList.isEmpty) return const Text('No staff available');
              return DropdownButtonFormField<String>(
                value: selectedStaffId,
                decoration: const InputDecoration(labelText: 'Select Staff'),
                items: sp.staffList
                    .where((s) => s.isActive)
                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedStaffId = v),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedStaffId == null) return;
                Navigator.pop(ctx);
                final success = await staffProvider.assignEnquiry(enquiry.id, selectedStaffId!);
                if (success) {
                  context.read<EnquiryProvider>().loadEnquiries();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff assigned')));
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Enquiry enquiry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Enquiry'),
        content: Text('Delete ${enquiry.enquiryNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<EnquiryProvider>().deleteEnquiry(enquiry.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CountChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
