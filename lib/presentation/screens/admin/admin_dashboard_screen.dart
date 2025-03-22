// presentation/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/post_provider.dart';
import '../../../data/providers/group_provider.dart';
import '../../../data/providers/event_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/common/drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, int> _stats = {};
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, these would be fetched from Firebase
      // Here we're using placeholder data
      _stats = {
        'users': 1250,
        'posts': 4378,
        'groups': 86,
        'events': 124,
        'stories': 342,
        'reportedContent': 15,
        'activeUsers': 856,
      };
    } catch (e) {
      print('Error loading admin stats: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Admin Dashboard',
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    SizedBox(height: 24),
                    _buildStatsGrid(),
                    SizedBox(height: 24),
                    _buildSectionHeader('Quick Actions'),
                    SizedBox(height: 16),
                    _buildActionButtons(),
                    SizedBox(height: 24),
                    _buildSectionHeader('Recent Reports'),
                    SizedBox(height: 16),
                    _buildRecentReports(),
                    SizedBox(height: 24),
                    _buildSectionHeader('Platform Analytics'),
                    SizedBox(height: 16),
                    _buildAnalyticsChart(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Admin Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage community content, user accounts, and platform settings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Users', _stats['users'] ?? 0, Icons.people),
        _buildStatCard('Active Users', _stats['activeUsers'] ?? 0, Icons.person_outline),
        _buildStatCard('Posts', _stats['posts'] ?? 0, Icons.post_add),
        _buildStatCard('Groups', _stats['groups'] ?? 0, Icons.group_work),
        _buildStatCard('Events', _stats['events'] ?? 0, Icons.event),
        _buildStatCard('Stories', _stats['stories'] ?? 0, Icons.auto_stories),
        _buildStatCard('Reported Content', _stats['reportedContent'] ?? 0, Icons.report_problem, isAlert: true),
        _buildStatCard('Growth', 12, Icons.trending_up, isPercentage: true),
      ],
    );
  }
  
  Widget _buildStatCard(String title, int value, IconData icon, {bool isAlert = false, bool isPercentage = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isAlert && value > 0 ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon, 
                  color: isAlert && value > 0 ? Colors.red : AppTheme.primaryColor,
                ),
                Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: (isAlert && value > 0) 
                        ? Colors.red.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    isPercentage ? '↑ $value%' : value.toString(),
                    style: TextStyle(
                      color: isAlert && value > 0 ? Colors.red : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Total ${title.toLowerCase()}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacer(),
        TextButton(
          onPressed: () {
            // View all
          },
          child: Text('View All'),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton('Moderate Content', Icons.shield, () {
          Navigator.pushNamed(context, '/moderation');
        }),
        _buildActionButton('User Management', Icons.manage_accounts, () {
          // Navigate to user management
        }),
        _buildActionButton('Announcements', Icons.campaign, () {
          // Create announcement
        }),
      ],
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: MediaQuery.of(context).size.width / 3.5,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentReports() {
    // Sample reported content
    final reports = [
      {'type': 'Post', 'content': 'Inappropriate language in community post', 'time': '2h ago'},
      {'type': 'User', 'content': 'Profile with misleading information', 'time': '5h ago'},
      {'type': 'Comment', 'content': 'Harassment in event comment section', 'time': '1d ago'},
    ];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: reports.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final report = reports[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Icon(
                _getReportIcon(report['type']!),
                color: Colors.red,
                size: 20,
              ),
            ),
            title: Text(report['content']!),
            subtitle: Text('${report['type']} • ${report['time']}'),
            trailing: TextButton(
              onPressed: () {
                // Review report
              },
              child: Text('Review'),
            ),
          );
        },
      ),
    );
  }
  
  IconData _getReportIcon(String type) {
    switch (type) {
      case 'Post': return Icons.post_add;
      case 'User': return Icons.person;
      case 'Comment': return Icons.comment;
      case 'Group': return Icons.group;
      default: return Icons.report_problem;
    }
  }
  
  Widget _buildAnalyticsChart() {
    // In a real app, this would be a chart using a package like fl_chart or charts_flutter
    // For simplicity, we're just showing a placeholder
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        'User Growth Chart',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}