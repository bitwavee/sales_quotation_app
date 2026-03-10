import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/staff_provider.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  String _selectedAction = 'create';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status section
            Text('Status', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            // Action Buttons
            _buildActionButton('Create', 'create'),
            const SizedBox(height: 8),
            _buildActionButton('Read', 'read'),
            const SizedBox(height: 8),
            _buildActionButton('Update', 'update'),
            const SizedBox(height: 8),
            _buildActionButton('Delete', 'delete'),
            const SizedBox(height: 24),

            // Content based on selected action
            Consumer<StaffProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.staffList.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null && provider.staffList.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Text(provider.error!, style: const TextStyle(color: AppColors.danger)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: () => provider.loadStaff(), child: const Text('Retry')),
                      ],
                    ),
                  );
                }

                if (_selectedAction == 'create') {
                  return _CreateStaffForm(onCreated: () => provider.loadStaff());
                }

                if (provider.staffList.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No staff members found')));
                }

                return Column(
                  children: provider.staffList.map((staff) {
                    return _StaffListItem(
                      staff: staff,
                      action: _selectedAction,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, String action) {
    final isSelected = _selectedAction == action;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedAction = action),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========== CREATE FORM ==========
class _CreateStaffForm extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateStaffForm({required this.onCreated});

  @override
  State<_CreateStaffForm> createState() => _CreateStaffFormState();
}

class _CreateStaffFormState extends State<_CreateStaffForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
        const SizedBox(height: 12),
        TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email *'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Password *'), obscureText: true),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _create,
            child: const Text('Create Staff'),
          ),
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, email and password are required')));
      return;
    }
    final data = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
    };
    if (_phoneCtrl.text.isNotEmpty) data['phone'] = _phoneCtrl.text.trim();
    final success = await context.read<StaffProvider>().createStaff(data);
    if (success && mounted) {
      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _passwordCtrl.clear();
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff created successfully')));
    }
  }
}

// ========== STAFF LIST ITEM ==========
class _StaffListItem extends StatelessWidget {
  final User staff;
  final String action;
  const _StaffListItem({required this.staff, required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: staff.isActive ? AppColors.primary : AppColors.textLight,
              radius: 20,
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(staff.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  if (staff.phone != null)
                    Text(staff.phone!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: staff.isActive ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          staff.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(fontSize: 11, color: staff.isActive ? AppColors.success : AppColors.danger),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(staff.role, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (action == 'update')
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () => _showEditDialog(context, staff),
              ),
            if (action == 'delete')
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.danger),
                onPressed: () => _confirmDelete(context, staff),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, User staff) {
    final nameCtrl = TextEditingController(text: staff.name);
    final phoneCtrl = TextEditingController(text: staff.phone ?? '');
    bool isActive = staff.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
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
                final data = <String, dynamic>{'name': nameCtrl.text.trim(), 'isActive': isActive};
                if (phoneCtrl.text.isNotEmpty) data['phone'] = phoneCtrl.text.trim();
                final success = await context.read<StaffProvider>().updateStaff(staff.id, data);
                if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff updated')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, User staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<StaffProvider>().deleteStaff(staff.id);
              if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
