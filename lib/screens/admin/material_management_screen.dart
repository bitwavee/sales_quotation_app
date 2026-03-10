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

class _MaterialManagementScreenState extends State<MaterialManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().loadMaterials();
    });
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
        title: const Text('Material Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Create'),
            Tab(text: 'CRUD'),
            Tab(text: 'Delete'),
            Tab(text: 'Price'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CreateMaterialTab(),
          _CrudMaterialTab(),
          _DeleteMaterialTab(),
          _PriceMaterialTab(),
        ],
      ),
    );
  }
}

// ========== CREATE TAB ==========
class _CreateMaterialTab extends StatefulWidget {
  @override
  State<_CreateMaterialTab> createState() => _CreateMaterialTabState();
}

class _CreateMaterialTabState extends State<_CreateMaterialTab> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  String _selectedUnit = 'sqft';
  final _units = ['sqft', 'meter', 'piece', 'kg'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Material Name *')),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedUnit,
            decoration: const InputDecoration(labelText: 'Unit *'),
            items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (v) => setState(() => _selectedUnit = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _costCtrl,
            decoration: const InputDecoration(labelText: 'Base Cost *', prefixText: '\$ '),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _create,
              child: const Text('Create Material'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    if (_nameCtrl.text.isEmpty || _costCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and cost are required')));
      return;
    }
    final cost = double.tryParse(_costCtrl.text);
    if (cost == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid cost')));
      return;
    }
    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'unit': _selectedUnit,
      'baseCost': cost,
    };
    if (_descCtrl.text.isNotEmpty) data['description'] = _descCtrl.text.trim();
    final success = await context.read<MaterialProvider>().createMaterial(data);
    if (success && mounted) {
      _nameCtrl.clear();
      _descCtrl.clear();
      _costCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material created')));
    }
  }
}

// ========== CRUD TAB ==========
class _CrudMaterialTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MaterialProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.materials.isEmpty) {
          return const Center(child: CircularProgressIndicator());
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
              return _MaterialEditCard(material: material);
            },
          ),
        );
      },
    );
  }
}

class _MaterialEditCard extends StatelessWidget {
  final MaterialItem material;
  const _MaterialEditCard({required this.material});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: material.isActive ? AppColors.primary : AppColors.textLight,
          child: const Icon(Icons.inventory_2, color: Colors.white, size: 18),
        ),
        title: Text(material.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${material.unit} | \$${material.baseCost.toStringAsFixed(2)}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.primary),
          onPressed: () => _showEditDialog(context),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
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
                TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Base Cost'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                SwitchListTile(title: const Text('Active'), value: isActive, onChanged: (v) => setDialogState(() => isActive = v)),
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
                if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material updated')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== DELETE TAB ==========
class _DeleteMaterialTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MaterialProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.materials.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.materials.isEmpty) {
          return const Center(child: Text('No materials found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.materials.length,
          itemBuilder: (context, index) {
            final material = provider.materials[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.inventory_2, color: AppColors.textMuted),
                title: Text(material.name),
                subtitle: Text('\$${material.baseCost.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.danger),
                  onPressed: () => _confirmDelete(context, material),
                ),
              ),
            );
          },
        );
      },
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
              if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ========== PRICE TAB ==========
class _PriceMaterialTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MaterialProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.materials.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.materials.isEmpty) {
          return const Center(child: Text('No materials found'));
        }
        return RefreshIndicator(
          onRefresh: () => provider.loadMaterials(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.materials.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final material = provider.materials[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(material.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    Text(
                      '\$ ${material.baseCost.toStringAsFixed(material.baseCost.truncateToDouble() == material.baseCost ? 0 : 2)}0',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
