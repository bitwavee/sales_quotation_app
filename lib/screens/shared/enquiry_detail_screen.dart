import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../models/enquiry_model.dart';
import '../../models/enquiry_progress_model.dart';
import '../../models/measurement_model.dart';
import '../../models/quotation_model.dart';

import '../../providers/enquiry_provider.dart';
import '../../providers/enquiry_progress_provider.dart';
import '../../providers/measurement_provider.dart';
import '../../providers/quotation_provider.dart';
import '../../providers/file_provider.dart';

class EnquiryDetailScreen extends StatefulWidget {
  final String enquiryId;
  const EnquiryDetailScreen({Key? key, required this.enquiryId}) : super(key: key);

  @override
  State<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends State<EnquiryDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  void _loadAll() {
    context.read<EnquiryProvider>().loadEnquiryDetails(widget.enquiryId);
    context.read<EnquiryProgressProvider>().loadProgress(widget.enquiryId);
    context.read<EnquiryProgressProvider>().loadStatusConfigs();
    context.read<MeasurementProvider>().loadMeasurements(widget.enquiryId);
    context.read<QuotationProvider>().loadQuotations(widget.enquiryId);
    context.read<FileProvider>().loadFiles(widget.enquiryId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<EnquiryProvider>(
          builder: (_, p, __) => Text(p.selectedEnquiry?.enquiryNumber ?? 'Enquiry Details'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Progress'),
            Tab(text: 'Measurements'),
            Tab(text: 'Quotations'),
            Tab(text: 'Files'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DetailsTab(enquiryId: widget.enquiryId),
          _ProgressTab(enquiryId: widget.enquiryId),
          _MeasurementsTab(enquiryId: widget.enquiryId),
          _QuotationsTab(enquiryId: widget.enquiryId),
          _FilesTab(enquiryId: widget.enquiryId),
        ],
      ),
    );
  }
}

// ========== DETAILS TAB ==========
class _DetailsTab extends StatelessWidget {
  final String enquiryId;
  const _DetailsTab({required this.enquiryId});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnquiryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        final e = provider.selectedEnquiry;
        if (e == null) return const Center(child: Text('Enquiry not found'));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoCard(title: 'Customer Info', children: [
                _InfoRow('Name', e.customerName),
                _InfoRow('Phone', e.customerPhone),
                if (e.customerEmail != null) _InfoRow('Email', e.customerEmail!),
                if (e.customerAddress != null) _InfoRow('Address', e.customerAddress!),
              ]),
              const SizedBox(height: 16),
              _InfoCard(title: 'Enquiry Info', children: [
                _InfoRow('Number', e.enquiryNumber),
                _InfoRow('Status', e.status),
                if (e.assignedStaff != null) _InfoRow('Assigned Staff', e.assignedStaff!),
                _InfoRow('Measurements', e.measurementsCount.toString()),
                _InfoRow('Quotations', e.quotationsCount.toString()),
                if (e.notes != null) _InfoRow('Notes', e.notes!),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context, e),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Enquiry'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Enquiry enquiry) {
    final nameCtrl = TextEditingController(text: enquiry.customerName);
    final phoneCtrl = TextEditingController(text: enquiry.customerPhone);
    final emailCtrl = TextEditingController(text: enquiry.customerEmail ?? '');
    final addressCtrl = TextEditingController(text: enquiry.customerAddress ?? '');
    final notesCtrl = TextEditingController(text: enquiry.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Enquiry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final data = <String, dynamic>{
                'customerName': nameCtrl.text.trim(),
                'customerPhone': phoneCtrl.text.trim(),
              };
              if (emailCtrl.text.isNotEmpty) data['customerEmail'] = emailCtrl.text.trim();
              if (addressCtrl.text.isNotEmpty) data['customerAddress'] = addressCtrl.text.trim();
              if (notesCtrl.text.isNotEmpty) data['notes'] = notesCtrl.text.trim();
              final success = await context.read<EnquiryProvider>().updateEnquiry(enquiryId, data);
              if (success) {
                context.read<EnquiryProvider>().loadEnquiryDetails(enquiryId);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry updated')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ========== PROGRESS TAB ==========
class _ProgressTab extends StatelessWidget {
  final String enquiryId;
  const _ProgressTab({required this.enquiryId});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnquiryProgressProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.progressList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddProgressDialog(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Update Status'),
                ),
              ),
            ),
            Expanded(
              child: provider.progressList.isEmpty
                  ? const Center(child: Text('No progress history'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.progressList.length,
                      itemBuilder: (context, index) {
                        final p = provider.progressList[index];
                        return _ProgressCard(progress: p);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showAddProgressDialog(BuildContext context, EnquiryProgressProvider provider) {
    String? selectedStatus;
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: provider.statusConfigs
                      .where((c) => c.isActive)
                      .map((c) => DropdownMenuItem(value: c.statusKey, child: Text(c.statusName)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v),
                ),
                const SizedBox(height: 8),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedStatus == null) return;
                Navigator.pop(ctx);
                final success = await provider.updateStatus(
                  enquiryId,
                  selectedStatus!,
                  notesCtrl.text.isNotEmpty ? notesCtrl.text.trim() : null,
                );
                if (success) {
                  context.read<EnquiryProvider>().loadEnquiryDetails(enquiryId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final EnquiryProgress progress;
  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(progress.status.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (progress.notes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(progress.notes!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${progress.createdAt.day}/${progress.createdAt.month}/${progress.createdAt.year} ${progress.createdAt.hour}:${progress.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== MEASUREMENTS TAB (Convert to Sq Ft / Cost view) ==========
class _MeasurementsTab extends StatefulWidget {
  final String enquiryId;
  const _MeasurementsTab({required this.enquiryId});

  @override
  State<_MeasurementsTab> createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends State<_MeasurementsTab> {
  bool _showCost = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<MeasurementProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.measurements.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Convert to Sq Ft / Cost toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Convert to Sq Ft', style: Theme.of(context).textTheme.titleLarge),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _showCost ? AppColors.primary : AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _showCost = !_showCost),
                      child: Text(
                        'Cost',
                        style: TextStyle(
                          color: _showCost ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Applied Rate section
              Text('Applied Rate', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Convert to Sq Ft', style: TextStyle(color: AppColors.textMuted)),
              ),
              const SizedBox(height: 16),

              // Appliance & Details table
              Text('Appliance', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 4),
              if (provider.measurements.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No measurements yet')))
              else ...[
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                      if (_showCost)
                        const Expanded(flex: 2, child: Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))
                      else
                        const Expanded(flex: 2, child: Text('Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                ...provider.measurements.map((m) => _MeasurementRow(
                  measurement: m,
                  showCost: _showCost,
                  enquiryId: widget.enquiryId,
                )),
              ],
              const SizedBox(height: 24),

              // Add Measurement button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMeasurementDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Measurement'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMeasurementDialog(BuildContext context) {
    String? selectedCategoryId;
    String? selectedCategoryKey;
    List<String> fields = [];
    final dataControllers = <String, TextEditingController>{};
    final notesCtrl = TextEditingController();

    final categories = [
      {'id': '', 'name': 'Area (L x W)', 'key': 'AREA', 'fields': ['length', 'width']},
      {'id': '', 'name': 'Length', 'key': 'LENGTH', 'fields': ['value']},
      {'id': '', 'name': 'Volume (L x W x H)', 'key': 'VOLUME', 'fields': ['length', 'width', 'height']},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Measurement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.asMap().entries.map((entry) =>
                    DropdownMenuItem(value: entry.key, child: Text(entry.value['name'] as String)),
                  ).toList(),
                  onChanged: (idx) {
                    setDialogState(() {
                      selectedCategoryKey = categories[idx!]['key'] as String;
                      fields = List<String>.from(categories[idx]['fields'] as List);
                      dataControllers.clear();
                      for (final f in fields) {
                        dataControllers[f] = TextEditingController();
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                ...fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: dataControllers[f],
                    decoration: InputDecoration(labelText: f.substring(0, 1).toUpperCase() + f.substring(1)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                )),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedCategoryKey == null) return;
                final measurementData = <String, dynamic>{};
                for (final entry in dataControllers.entries) {
                  final val = double.tryParse(entry.value.text);
                  if (val == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid value for ${entry.key}')));
                    return;
                  }
                  measurementData[entry.key] = val;
                }
                Navigator.pop(ctx);
                final data = <String, dynamic>{
                  'measurementData': measurementData,
                };
                if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
                  data['categoryId'] = selectedCategoryId;
                }
                if (notesCtrl.text.isNotEmpty) data['notes'] = notesCtrl.text.trim();

                final success = await context.read<MeasurementProvider>().createMeasurement(widget.enquiryId, data);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurement added')));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  final Measurement measurement;
  final bool showCost;
  final String enquiryId;
  const _MeasurementRow({required this.measurement, required this.showCost, required this.enquiryId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(measurement.category?.categoryName ?? 'Measurement', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                ...measurement.measurementData.entries.map(
                  (entry) => Text('${entry.key}: ${entry.value}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: showCost
                ? Text(
                    '\$${(measurement.calculatedValue ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  )
                : Text(
                    '${measurement.calculatedValue ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.danger, size: 18),
            onPressed: () async {
              final success = await context.read<MeasurementProvider>().deleteMeasurement(measurement.id, enquiryId);
              if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
            },
          ),
        ],
      ),
    );
  }
}

// ========== QUOTATIONS TAB (Dynamic Quotation Calculation) ==========
class _QuotationsTab extends StatelessWidget {
  final String enquiryId;
  const _QuotationsTab({required this.enquiryId});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuotationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.quotations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dynamic Quotation Calculation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              if (provider.quotations.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No quotations yet')))
              else
                ...provider.quotations.map((q) => _QuotationCard(quotation: q, enquiryId: enquiryId)),

              const SizedBox(height: 16),

              // Measurement categories summary
              Consumer<MeasurementProvider>(
                builder: (context, mp, _) {
                  if (mp.measurements.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      Text('Measurement Summary', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...mp.measurements.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(m.category?.categoryName ?? 'Category', style: const TextStyle(fontSize: 14)),
                            Text('${m.calculatedValue ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      )),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Generate PDF button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF...')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Generate PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),

              // Create Quotation button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Quotation'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final numberCtrl = TextEditingController(text: 'QT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final taxCtrl = TextEditingController(text: '18');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Quotation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Quotation Number')),
              const SizedBox(height: 8),
              TextField(controller: taxCtrl, decoration: const InputDecoration(labelText: 'Tax %'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final data = {
                'enquiryId': enquiryId,
                'quotationNumber': numberCtrl.text.trim(),
                'taxPercentage': double.tryParse(taxCtrl.text) ?? 18.0,
              };
              if (notesCtrl.text.isNotEmpty) data['notes'] = notesCtrl.text.trim();
              final success = await context.read<QuotationProvider>().createQuotation(data);
              if (success) {
                context.read<QuotationProvider>().loadQuotations(enquiryId);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation created')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _QuotationCard extends StatelessWidget {
  final Quotation quotation;
  final String enquiryId;
  const _QuotationCard({required this.quotation, required this.enquiryId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(quotation.quotationNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(quotation.status, style: const TextStyle(fontSize: 11, color: AppColors.warning)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount / Costs grid
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('\$${quotation.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Costs', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('\$${quotation.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),

            if (quotation.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              ...quotation.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.materialName ?? '', style: const TextStyle(fontSize: 13))),
                    Text('\$${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (quotation.sentAt == null)
                  TextButton.icon(
                    onPressed: () async {
                      final success = await context.read<QuotationProvider>().sendQuotation(quotation.id);
                      if (success) {
                        context.read<QuotationProvider>().loadQuotations(enquiryId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation sent')));
                      }
                    },
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Send'),
                  ),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading PDF...')));
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('PDF'),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.danger, size: 18),
                  onPressed: () async {
                    final success = await context.read<QuotationProvider>().deleteQuotation(quotation.id);
                    if (success) context.read<QuotationProvider>().loadQuotations(enquiryId);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========== FILES TAB (Image Attachments/Uploads) ==========
class _FilesTab extends StatelessWidget {
  final String enquiryId;
  const _FilesTab({required this.enquiryId});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.files.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dynamic Quotation Calculation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Upload Images section
              Text('Upload Images', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),

              // Upload buttons row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _pickAndUpload(context, ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Camera'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickAndUpload(context, ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Files grid with Amount/Costs columns
              if (provider.files.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Costs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                ...provider.files.map((f) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('\$${(f.fileSize ?? 0) > 0 ? ((f.fileSize ?? 0) / 100).toStringAsFixed(2) : '0.00'}'),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('\$${(f.fileSize ?? 0) > 0 ? ((f.fileSize ?? 0) / 80).toStringAsFixed(2) : '0.00'}'),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],

              // File list section
              Text('Files', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (provider.files.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.textLight),
                      const SizedBox(height: 8),
                      const Text('No files uploaded', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                )
              else
                ...provider.files.map((f) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(_getFileIcon(f.fileType), color: AppColors.primary),
                    title: Text(f.fileName, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${f.category ?? ''} • ${_formatSize(f.fileSize)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.danger, size: 18),
                      onPressed: () async {
                        final success = await context.read<FileProvider>().deleteFile(f.id, enquiryId);
                        if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted')));
                      },
                    ),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;
    final file = File(pickedFile.path);
    final success = await context.read<FileProvider>().uploadFile(enquiryId, file, category: 'SITE_PHOTO');
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded')));
    }
  }

  IconData _getFileIcon(String? type) {
    if (type == null) return Icons.insert_drive_file;
    if (type.contains('image')) return Icons.image;
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ========== SHARED HELPERS ==========
class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.textMuted))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
