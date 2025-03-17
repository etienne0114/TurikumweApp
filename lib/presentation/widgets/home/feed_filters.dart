// presentation/widgets/home/feed_filters.dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class FeedFilters extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;
  final String userDistrict;

  const FeedFilters({
    Key? key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.userDistrict,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip(
              context: context,
              label: 'All Posts',
              isSelected: currentFilter == 'all',
              onTap: () => onFilterChanged('all'),
            ),
            SizedBox(width: 12),
            _buildFilterChip(
              context: context,
              label: 'Following',
              isSelected: currentFilter == 'following',
              onTap: () => onFilterChanged('following'),
            ),
            SizedBox(width: 12),
            if (userDistrict.isNotEmpty) ...[
              _buildFilterChip(
                context: context,
                label: 'My District',
                isSelected: currentFilter == 'district',
                onTap: () => onFilterChanged('district'),
              ),
              SizedBox(width: 12),
            ],
            _buildFilterChip(
              context: context,
              label: 'Featured',
              isSelected: currentFilter == 'featured',
              onTap: () => onFilterChanged('featured'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}