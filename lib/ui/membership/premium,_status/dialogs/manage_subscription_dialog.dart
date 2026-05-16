import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

Future<void> showManageSubscriptionDialog({
  required BuildContext context,
  required VoidCallback onNavigateToMembership,
  required VoidCallback onCancelSubscription,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                'Manage Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // ----------------------------------------------------------
              // MANAGE SUBSCRIPTION BUTTON (GRADIENT)
              // ----------------------------------------------------------
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onNavigateToMembership();
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.tune, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Manage Subscription",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------------
              // CANCEL SUBSCRIPTION BUTTON (OUTLINE)
              // ----------------------------------------------------------
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onCancelSubscription();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
