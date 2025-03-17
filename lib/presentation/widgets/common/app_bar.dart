// presentation/widgets/common/app_bar.dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading;
  final double elevation;
  final Color? backgroundColor;
  final VoidCallback? onLeadingPressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.leading,
    this.elevation = 0,
    this.backgroundColor,
    this.onLeadingPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      elevation: elevation,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      leading: leading ?? 
        (showBackButton 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onLeadingPressed ?? () => Navigator.pop(context),
            )
          : null),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}