// lib/ui/membership/premium_status/dialogs/cancel_subscription_dialog.dart
import 'package:flutter/material.dart';

Future<void> showCancelSubscriptionDialog({
  required BuildContext context,
  required Future<void> Function() onCancel,
}) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel Subscription'),
      content: const Text(
        'Are you sure you want to cancel your subscription? '
        'You will lose access to premium features at the end of your billing period.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('No, Keep It'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              await onCancel();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subscription cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Yes, Cancel'),
        ),
      ],
    ),
  );
}