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
      appBar: AppBar(title: const Text('Enquiry Status Config')),
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
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => provider.loadConfigs(), child: const Text('Retry')),
                ],
              ),
            );
          }
          if (provider.configs.isEmpty) {
            return const Center(child: Text('No status configurations found'));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadConfigs(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.configs.length,
              itemBuilder: (context, index) {
                final config = provider.configs[index];
                return _ConfigCard(config: config);
              },
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

class _ConfigCard extends StatelessWidget {
  final EnquiryStatusConfig config;
  const _ConfigCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(config.color) ?? AppColors.primary,
          child: Text('${config.displayOrder}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(config.statusName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Key: ${config.statusKey}'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: config.isActive ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                config.isActive ? 'Active' : 'Inactive',
                style: TextStyle(fontSize: 12, color: config.isActive ? AppColors.success : AppColors.danger),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _showEditDialog(context, config);
            if (value == 'delete') _confirmDelete(context, config);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse('0x$hex') ?? 0xFF0099FF);
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
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config updated')));
                }
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
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config deleted')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
