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
      appBar: AppBar(title: const Text('Staff Management')),
      body: Consumer<StaffProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.staffList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.staffList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => provider.loadStaff(), child: const Text('Retry')),
                ],
              ),
            );
          }
          if (provider.staffList.isEmpty) {
            return const Center(child: Text('No staff members found'));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadStaff(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.staffList.length,
              itemBuilder: (context, index) {
                final staff = provider.staffList[index];
                return _StaffCard(staff: staff);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateStaffDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateStaffDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password *'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, email and password are required')));
                return;
              }
              final data = {
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'password': passwordCtrl.text,
              };
              if (phoneCtrl.text.isNotEmpty) data['phone'] = phoneCtrl.text.trim();
              Navigator.pop(ctx);
              final success = await context.read<StaffProvider>().createStaff(data);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff created successfully')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final User staff;
  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: staff.isActive ? AppColors.primary : AppColors.textLight,
          child: Text(staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(staff.email),
            if (staff.phone != null) Text(staff.phone!),
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
                    style: TextStyle(fontSize: 12, color: staff.isActive ? AppColors.success : AppColors.danger),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(staff.role, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _showEditDialog(context, staff);
            if (value == 'delete') _confirmDelete(context, staff);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
                Navigator.pop(ctx);
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'isActive': isActive,
                };
                if (phoneCtrl.text.isNotEmpty) data['phone'] = phoneCtrl.text.trim();
                final success = await context.read<StaffProvider>().updateStaff(staff.id, data);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff updated')));
                }
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
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff deleted')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
