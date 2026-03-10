import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/enquiry_status_config_model.dart';
import '../../providers/enquiry_status_config_provider.dart';

class EnquiryStatusConfigScreen extends StatefulWidget {
  const EnquiryStatusConfigScreen({Key? key}) : super(key: key);

  @override
  State<EnquiryStatusConfigScreen> createState() => _EnquiryStatusConfigScreenState();
}

class _EnquiryStatusConfigScreenState extends State<EnquiryStatusConfigScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnquiryStatusConfigProvider>().loadConfigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Status Configuration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<EnquiryStatusConfigProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.configs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.configs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => provider.loadConfigs(), child: const Text('Retry')),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statuses Section
                Text('Statuses', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Status', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 12),

                // Status Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.configs.map((config) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: config.isActive ? AppColors.primary : AppColors.chipBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: config.isActive ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        config.statusName,
                        style: TextStyle(
                          color: config.isActive ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Configurable fields section
                Text('Configurable', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),

                // Per-status requirement config
                ...provider.configs.map((config) => _StatusConfigCard(config: config)),
                const SizedBox(height: 16),

                // Required fields section header
                Text('Per enquiry requirements', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),

                // Field requirement toggles
                _FieldRequirement(label: 'Contact', icon: Icons.lock_outline),
                const SizedBox(height: 8),
                _FieldRequirement(label: 'Description', icon: Icons.lock_outline),
                const SizedBox(height: 8),
                _FieldRequirement(label: 'Budget', icon: null, isDropdown: true),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    final orderCtrl = TextEditingController();
    final colorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Status Config'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Status Name *')),
              const SizedBox(height: 8),
              TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'Status Key *')),
              const SizedBox(height: 8),
              TextField(controller: orderCtrl, decoration: const InputDecoration(labelText: 'Display Order *'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: 'Color (hex)', hintText: '#FF5722')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || keyCtrl.text.isEmpty || orderCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, key and order are required')));
                return;
              }
              Navigator.pop(ctx);
              final data = <String, dynamic>{
                'statusName': nameCtrl.text.trim(),
                'statusKey': keyCtrl.text.trim(),
                'displayOrder': int.tryParse(orderCtrl.text) ?? 0,
              };
              if (colorCtrl.text.isNotEmpty) data['color'] = colorCtrl.text.trim();
              final success = await context.read<EnquiryStatusConfigProvider>().createConfig(data);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config created')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _StatusConfigCard extends StatelessWidget {
  final EnquiryStatusConfig config;
  const _StatusConfigCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(config.color) ?? AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.statusName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('Key: ${config.statusKey} | Order: ${config.displayOrder}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: config.isActive ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                config.isActive ? 'Active' : 'Inactive',
                style: TextStyle(fontSize: 11, color: config.isActive ? AppColors.success : AppColors.danger),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showEditDialog(context, config);
                if (value == 'delete') _confirmDelete(context, config);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse('0x$hex') ?? 0xFF1B1F3B);
  }

  void _showEditDialog(BuildContext context, EnquiryStatusConfig config) {
    final nameCtrl = TextEditingController(text: config.statusName);
    final keyCtrl = TextEditingController(text: config.statusKey);
    final orderCtrl = TextEditingController(text: config.displayOrder.toString());
    final colorCtrl = TextEditingController(text: config.color ?? '');
    bool isActive = config.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Status Config'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Status Name')),
                const SizedBox(height: 8),
                TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'Status Key')),
                const SizedBox(height: 8),
                TextField(controller: orderCtrl, decoration: const InputDecoration(labelText: 'Display Order'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: 'Color (hex)')),
                const SizedBox(height: 8),
                SwitchListTile(title: const Text('Active'), value: isActive, onChanged: (v) => setDialogState(() => isActive = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final data = <String, dynamic>{
                  'statusName': nameCtrl.text.trim(),
                  'statusKey': keyCtrl.text.trim(),
                  'displayOrder': int.tryParse(orderCtrl.text) ?? 0,
                  'isActive': isActive,
                };
                if (colorCtrl.text.isNotEmpty) data['color'] = colorCtrl.text.trim();
                final success = await context.read<EnquiryStatusConfigProvider>().updateConfig(config.id, data);
                if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config updated')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, EnquiryStatusConfig config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Config'),
        content: Text('Delete "${config.statusName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<EnquiryStatusConfigProvider>().deleteConfig(config.id);
              if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FieldRequirement extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isDropdown;
  const _FieldRequirement({required this.label, this.icon, this.isDropdown = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(icon, size: 18, color: AppColors.textMuted),
            ),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          if (isDropdown)
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted)
          else
            const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
