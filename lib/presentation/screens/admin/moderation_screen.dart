// presentation/screens/admin/moderation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../data/providers/post_provider.dart';
import '../../../data/models/post.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/home/post_card.dart';

class ModerationScreen extends StatefulWidget {
  @override
  _ModerationScreenState createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _reportedContent = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportedContent();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadReportedContent() async {
    setState(() {
      _isLoading = true;
    });
    
    // This would fetch actual reported content in a real app
    // Using mock data for demonstration
    await Future.delayed(Duration(seconds: 1));
    
    setState(() {
      _reportedContent = [
        {
          'id': '1',
          'type': 'post',
          'content': 'This post contains inappropriate language that violates community guidelines.',
          'reporter': 'John Doe',
          'reportedUser': 'Mark Smith',
          'reason': 'Inappropriate Content',
          'date': DateTime.now().subtract(Duration(hours: 2)),
        },
        {
          'id': '2',
          'type': 'comment',
          'content': 'This comment contains hateful speech and should be removed.',
          'reporter': 'Alice Johnson',
          'reportedUser': 'Bob Williams',
          'reason': 'Hate Speech',
          'date': DateTime.now().subtract(Duration(hours: 5)),
        },
        {
          'id': '3',
          'type': 'user',
          'content': 'This user is impersonating a government official.',
          'reporter': 'James Brown',
          'reportedUser': 'Fake Official',
          'reason': 'Impersonation',
          'date': DateTime.now().subtract(Duration(days: 1)),
        },
        {
          'id': '4',
          'type': 'post',
          'content': 'This post contains misinformation about public health.',
          'reporter': 'Emma Wilson',
          'reportedUser': 'Health Skeptic',
          'reason': 'Misinformation',
          'date': DateTime.now().subtract(Duration(days: 2)),
        },
      ];
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Content Moderation'),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllReportsTab(),
                      _buildPostsTab(),
                      _buildCommentsTab(),
                      _buildUsersTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
        tabs: [
          Tab(text: 'All'),
          Tab(text: 'Posts'),
          Tab(text: 'Comments'),
          Tab(text: 'Users'),
        ],
      ),
    );
  }
  
  Widget _buildAllReportsTab() {
    if (_reportedContent.isEmpty) {
      return _buildEmptyState('No reported content to review');
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _reportedContent.length,
      itemBuilder: (context, index) {
        final report = _reportedContent[index];
        return _buildReportCard(report);
      },
    );
  }
  
  Widget _buildPostsTab() {
    final posts = _reportedContent.where((report) => report['type'] == 'post').toList();
    
    if (posts.isEmpty) {
      return _buildEmptyState('No reported posts to review');
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final report = posts[index];
        return _buildReportCard(report);
      },
    );
  }
  
  Widget _buildCommentsTab() {
    final comments = _reportedContent.where((report) => report['type'] == 'comment').toList();
    
    if (comments.isEmpty) {
      return _buildEmptyState('No reported comments to review');
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final report = comments[index];
        return _buildReportCard(report);
      },
    );
  }
  
  Widget _buildUsersTab() {
    final users = _reportedContent.where((report) => report['type'] == 'user').toList();
    
    if (users.isEmpty) {
      return _buildEmptyState('No reported users to review');
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final report = users[index];
        return _buildReportCard(report);
      },
    );
  }
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildReportTypeChip(report['type']),
                SizedBox(width: 8),
                Text(
                  report['reason'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  _getTimeAgo(report['date']),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              report['content'],
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 4),
                Text(
                  'Reported: ${report['reportedUser']}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(width: 16),
                Icon(
                  Icons.flag,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 4),
                Text(
                  'By: ${report['reporter']}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Dismiss report
                    _dismissReport(report['id']);
                  },
                  child: Text('Dismiss'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Take action based on report type
                    _takeAction(report);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text('Take Action'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReportTypeChip(String type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'post':
        icon = Icons.post_add;
        color = Colors.orange;
        break;
      case 'comment':
        icon = Icons.comment;
        color = Colors.purple;
        break;
      case 'user':
        icon = Icons.person;
        color = Colors.blue;
        break;
      default:
        icon = Icons.report_problem;
        color = Colors.red;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  void _dismissReport(String reportId) {
    setState(() {
      _reportedContent.removeWhere((report) => report['id'] == reportId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report dismissed')),
    );
  }
  
  void _takeAction(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Take Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select action for this ${report['type']}:'),
            SizedBox(height: 16),
            _buildActionOption(
              icon: Icons.delete,
              label: 'Remove Content',
              onTap: () {
                Navigator.pop(context);
                _removeContent(report);
              },
            ),
            _buildActionOption(
              icon: Icons.warning,
              label: 'Send Warning',
              onTap: () {
                Navigator.pop(context);
                _sendWarning(report);
              },
            ),
            if (report['type'] == 'user')
              _buildActionOption(
                icon: Icons.block,
                label: 'Suspend User',
                onTap: () {
                  Navigator.pop(context);
                  _suspendUser(report);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _removeContent(Map<String, dynamic> report) {
    setState(() {
      _reportedContent.removeWhere((r) => r['id'] == report['id']);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Content removed successfully')),
    );
  }
  
  void _sendWarning(Map<String, dynamic> report) {
    setState(() {
      _reportedContent.removeWhere((r) => r['id'] == report['id']);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Warning sent to ${report['reportedUser']}')),
    );
  }
  
  void _suspendUser(Map<String, dynamic> report) {
    setState(() {
      _reportedContent.removeWhere((r) => r['id'] == report['id']);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User ${report['reportedUser']} suspended')),
    );
  }
}