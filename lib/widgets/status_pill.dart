import 'package:flutter/material.dart';

/// Small rounded status label — used for contact ack status
/// (Sent/Seen), permission grants, and message-channel tags.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11, color: foreground, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Shown for actions the app doesn't implement yet (kept minimal and
/// consistent instead of a bespoke widget per screen).
void showNotBuiltSnack(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Not built in this pass yet.')));
}
