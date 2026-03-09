import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${context.watch<AuthProvider>().user?.name}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            // Menu Items
            ListTile(
              leading: const Icon(Icons.people, color: AppColors.primary),
              title: const Text('Staff Management'),
              subtitle: const Text('Manage staff members'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showComingSoon(context, 'Staff Management'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: AppColors.primary),
              title: const Text('Material Management'),
              subtitle: const Text('Manage materials'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showComingSoon(context, 'Material Management'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: AppColors.primary),
              title: const Text('All Enquiries'),
              subtitle: const Text('View all enquiries'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _handleViewAllEnquiries(context),
            ),
            ListTile(
              leading: const Icon(Icons.assessment, color: AppColors.primary),
              title: const Text('Reports'),
              subtitle: const Text('View analytics'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showComingSoon(context, 'Reports'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _handleViewAllEnquiries(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading all enquiries...')),
    );
    // TODO: Implement navigation to enquiries list screen
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}