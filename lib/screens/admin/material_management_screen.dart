import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/material_model.dart';
import '../../providers/material_provider.dart';

class MaterialManagementScreen extends StatefulWidget {
  const MaterialManagementScreen({Key? key}) : super(key: key);

  @override
  State<MaterialManagementScreen> createState() => _MaterialManagementScreenState();
}

class _MaterialManagementScreenState extends State<MaterialManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().loadMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Material Management')),
      body: Consumer<MaterialProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.materials.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.materials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => provider.loadMaterials(), child: const Text('Retry')),
                ],
              ),
            );
          }
          if (provider.materials.isEmpty) {
            return const Center(child: Text('No materials found'));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadMaterials(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.materials.length,
              itemBuilder: (context, index) {
                final material = provider.materials[index];
                return _MaterialCard(material: material);
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
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    String selectedUnit = 'sqft';
    final units = ['sqft', 'meter', 'piece', 'kg'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unit *'),
                  items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setDialogState(() => selectedUnit = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: costCtrl,
                  decoration: const InputDecoration(labelText: 'Base Cost *'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || costCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and cost are required')));
                  return;
                }
                final cost = double.tryParse(costCtrl.text);
                if (cost == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid cost')));
                  return;
                }
                Navigator.pop(ctx);
                final data = {
                  'name': nameCtrl.text.trim(),
                  'unit': selectedUnit,
                  'baseCost': cost,
                };
                if (descCtrl.text.isNotEmpty) data['description'] = descCtrl.text.trim();
                final success = await context.read<MaterialProvider>().createMaterial(data);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material created')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialItem material;
  const _MaterialCard({required this.material});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: material.isActive ? AppColors.primary : AppColors.textLight,
          child: const Icon(Icons.inventory_2, color: Colors.white),
        ),
        title: Text(material.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (material.description != null) Text(material.description!),
            Text('Unit: ${material.unit} | Cost: ₹${material.baseCost.toStringAsFixed(2)}'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: material.isActive ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                material.isActive ? 'Active' : 'Inactive',
                style: TextStyle(fontSize: 12, color: material.isActive ? AppColors.success : AppColors.danger),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _showEditDialog(context, material);
            if (value == 'delete') _confirmDelete(context, material);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, MaterialItem material) {
    final nameCtrl = TextEditingController(text: material.name);
    final descCtrl = TextEditingController(text: material.description ?? '');
    final costCtrl = TextEditingController(text: material.baseCost.toString());
    String selectedUnit = material.unit;
    bool isActive = material.isActive;
    final units = ['sqft', 'meter', 'piece', 'kg'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: units.contains(selectedUnit) ? selectedUnit : units.first,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setDialogState(() => selectedUnit = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: costCtrl,
                  decoration: const InputDecoration(labelText: 'Base Cost'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final cost = double.tryParse(costCtrl.text);
                if (cost == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid cost')));
                  return;
                }
                Navigator.pop(ctx);
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'unit': selectedUnit,
                  'baseCost': cost,
                  'isActive': isActive,
                };
                if (descCtrl.text.isNotEmpty) data['description'] = descCtrl.text.trim();
                final success = await context.read<MaterialProvider>().updateMaterial(material.id, data);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material updated')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MaterialItem material) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete ${material.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<MaterialProvider>().deleteMaterial(material.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material deleted')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
