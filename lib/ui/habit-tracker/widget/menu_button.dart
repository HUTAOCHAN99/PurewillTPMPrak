// lib/ui/habit-tracker/widget/menu_button.dart
import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle; 
  final int? badgeCount;
  final bool showSwitch;
  final bool? switchValue;
  final Function(bool)? onSwitchChanged;
  
  MenuButton({
    super.key,
    required this.icon, 
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badgeCount,
    this.showSwitch = false,
    this.switchValue,
    this.onSwitchChanged,
  }) : assert(
          !showSwitch || (switchValue != null && onSwitchChanged != null),
          'Jika showSwitch true, maka switchValue dan onSwitchChanged harus disediakan'
        );

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      trailing: _buildTrailing(),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }

  Widget _buildTrailing() {
    if (showSwitch && switchValue != null) {
      return Switch(
        value: switchValue!,
        onChanged: onSwitchChanged,
        activeColor: Colors.deepPurple,
      );
    }
    
    if (badgeCount != null && badgeCount! > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          badgeCount!.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey);
  }
}