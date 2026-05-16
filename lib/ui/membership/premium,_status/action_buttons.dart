import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isPremiumUser;
  final VoidCallback onManageSubscription;
  final VoidCallback onCancelSubscription;

  const ActionButtons({
    super.key,
    required this.isPremiumUser,
    required this.onManageSubscription,
    required this.onCancelSubscription,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremiumUser) {
      return Column(
        children: [
          // ----------------------------------------------------------
          // MANAGE SUBSCRIPTION BUTTON (GRADIENT)
          // ----------------------------------------------------------
          GestureDetector(
            onTap: onManageSubscription,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4DB6FF), Color(0xFF004A91)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.tune, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Manage Subscription",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ----------------------------------------------------------
          // CANCEL SUBSCRIPTION BUTTON (OUTLINE)
          // ----------------------------------------------------------
          GestureDetector(
            onTap: onCancelSubscription,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.close, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    "Cancel Subscription",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // ----------------------------------------------------------
      // UPGRADE BUTTON (NON PREMIUM USER)
      // ----------------------------------------------------------
      return GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4DB6FF), Color(0xFF004A91)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Center(
            child: Text(
              "Upgrade to Premium",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }
  }
}
