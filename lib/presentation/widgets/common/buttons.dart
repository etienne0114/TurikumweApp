// presentation/widgets/common/buttons.dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry padding;
  final Widget? icon;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonWidget = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: padding,
        backgroundColor: AppTheme.primaryColor,
        disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            )
          : icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon!,
                    SizedBox(width: 8),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
    );

    return isFullWidth
        ? buttonWidget
        : Align(
            alignment: Alignment.center,
            child: buttonWidget,
          );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry padding;
  final Widget? icon;

  const SecondaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonWidget = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: padding,
        side: BorderSide(color: AppTheme.primaryColor),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                strokeWidth: 2,
              ),
            )
          : icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon!,
                    SizedBox(width: 8),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
    );

    return isFullWidth
        ? buttonWidget
        : Align(
            alignment: Alignment.center,
            child: buttonWidget,
          );
  }
}