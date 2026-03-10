import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';

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
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnquiryProvider>().loadEnquiries();
      context.read<StaffProvider>().loadStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>().user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Create/Assign'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_showCreateForm ? Icons.list : Icons.add),
            onPressed: () => setState(() => _showCreateForm = !_showCreateForm),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showCreateForm) ...[
              // Description header with lock icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Description', style: Theme.of(context).textTheme.titleLarge),
                  const Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 16),
              _CreateEnquiryForm(
                onCreated: () {
                  setState(() => _showCreateForm = false);
                  context.read<EnquiryProvider>().loadEnquiries();
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Enquiry List Table
            Consumer<EnquiryProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.enquiries.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }
                if (provider.error != null && provider.enquiries.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Text(provider.error!, style: const TextStyle(color: AppColors.danger)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: () => provider.loadEnquiries(), child: const Text('Retry')),
                      ],
                    ),
                  );
                }
                if (provider.enquiries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          const Text('No enquiries yet', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 36, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        ],
                      ),
                    ),
                    // Table rows
                    ...provider.enquiries.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final e = entry.value;
                      return InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EnquiryDetailScreen(enquiryId: e.id)));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 36, child: Text('$idx', style: const TextStyle(fontSize: 13))),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    Text(e.customerPhone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(e.status.replaceAll('_', ' '), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${e.createdAt.day.toString().padLeft(2, '0')}/${e.createdAt.month.toString().padLeft(2, '0')}/${e.createdAt.year.toString().substring(2)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: !_showCreateForm
          ? FloatingActionButton(
              onPressed: () => setState(() => _showCreateForm = true),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ========== CREATE ENQUIRY FORM ==========
class _CreateEnquiryForm extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateEnquiryForm({required this.onCreated});

  @override
  State<_CreateEnquiryForm> createState() => _CreateEnquiryFormState();
}

class _CreateEnquiryFormState extends State<_CreateEnquiryForm> {
  final _titleCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedStaffId;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _contactCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Package Title', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Enter package title')),
        const SizedBox(height: 12),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
        const SizedBox(height: 12),
        TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Contact'), keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        TextField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Contact Email'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
        const SizedBox(height: 16),

        // Assign Staff Dropdown
        Text('Assign Staff', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Consumer<StaffProvider>(
          builder: (context, sp, _) {
            if (sp.staffList.isEmpty) {
              return const TextField(
                enabled: false,
                decoration: InputDecoration(hintText: 'No staff available'),
              );
            }
            return DropdownButtonFormField<String>(
              value: _selectedStaffId,
              decoration: const InputDecoration(hintText: 'Select staff member'),
              items: sp.staffList
                  .where((s) => s.isActive)
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedStaffId = v),
            );
          },
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _create,
            child: const Text('Create Enquiry'),
          ),
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer name and contact are required')));
      return;
    }
    final data = <String, dynamic>{
      'customerName': _nameCtrl.text.trim(),
      'customerPhone': _phoneCtrl.text.trim(),
    };
    if (_contactCtrl.text.isNotEmpty) data['customerEmail'] = _contactCtrl.text.trim();
    if (_descCtrl.text.isNotEmpty) data['notes'] = _descCtrl.text.trim();
    if (_titleCtrl.text.isNotEmpty) data['packageTitle'] = _titleCtrl.text.trim();

    final success = await context.read<EnquiryProvider>().createEnquiry(data);
    if (success && mounted) {
      // If staff is selected, assign them
      if (_selectedStaffId != null) {
        final enquiries = context.read<EnquiryProvider>().enquiries;
        if (enquiries.isNotEmpty) {
          await context.read<StaffProvider>().assignEnquiry(enquiries.last.id, _selectedStaffId!);
        }
      }
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry created')));
    }
  }
}
