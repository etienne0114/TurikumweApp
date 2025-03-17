// presentation/widgets/common/drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = userProvider.currentUser;
    final isAdmin = user?.role == AppConstants.adminRole;
    final isModerator = user?.role == AppConstants.moderatorRole || isAdmin;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header with user info
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.displayName ?? 'User',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: user?.photoUrl == null
                  ? Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey.shade600,
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
          ),
          
          // Profile
          ListTile(
            leading: Icon(Icons.person),
            title: Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
          
          // Notifications
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.notifications);
            },
          ),
          
          // Saved Posts (not implemented in this version)
          ListTile(
            leading: Icon(Icons.bookmark),
            title: Text('Saved Posts'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to saved posts
            },
          ),
          
          // My Events
          ListTile(
            leading: Icon(Icons.event),
            title: Text('My Events'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to my events
            },
          ),
          
          // My Groups
          ListTile(
            leading: Icon(Icons.group),
            title: Text('My Groups'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to my groups
            },
          ),
          
          Divider(),
          
          // Admin section
          if (isAdmin || isModerator) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Text(
                'Admin',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Admin Dashboard
            if (isAdmin)
              ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
                },
              ),
            
            // Moderation
            ListTile(
              leading: Icon(Icons.shield),
              title: Text('Moderation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.moderation);
              },
            ),
            
            Divider(),
          ],
          
          // Settings
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
          ),
          
          // Help & Support
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help & support
            },
          ),
          
          // About
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About Turikumwe'),
            onTap: () {
              Navigator.pop(context);
              // Show about dialog
            },
          ),
          
          Divider(),
          
          // Logout
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                await authProvider.signOut();
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
          ),
          
          // App version
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version ${AppConstants.appVersion}',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}