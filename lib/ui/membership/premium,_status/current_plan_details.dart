import 'package:flutter/material.dart';
import 'package:purewill/domain/model/plan_model.dart';
import 'package:purewill/ui/membership/premium,_status/subscription_data.dart';

class CurrentPlanDetails extends StatelessWidget {
  final PlanModel? currentPlan;
  final bool isPremiumUser;
  final SubscriptionData subscriptionData;

  const CurrentPlanDetails({
    super.key,
    required this.currentPlan,
    required this.isPremiumUser,
    required this.subscriptionData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Pastikan container mengambil lebar penuh
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicWidth( // Tambahkan IntrinsicWidth untuk memberikan constraint
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Gunakan MainAxisSize.min
          children: [
            // Title
            SizedBox(
              width: double.infinity,
              child: Text(
                'Current Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Row pertama: Plan Type + Harga di kanan
            Container(
              width: double.infinity, // Tambahkan container dengan width constraint
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bagian kiri: Icon + Plan Type
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.diamond,
                          size: 22,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      // Plan Type
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan Type',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentPlan?.name ?? 'Free',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isPremiumUser ? Colors.deepPurple : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Harga di kanan
                  Text(
                    currentPlan?.formattedPrice ?? 'Gratis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Start Date dengan icon calendar
            SizedBox(
              width: double.infinity,
              child: _buildDetailRow(
                icon: Icons.calendar_today,
                iconColor: Colors.blue,
                title: 'Start Date',
                value: subscriptionData.startDate != null
                  ? subscriptionData.formatDate(subscriptionData.startDate!)
                  : 'Not available',
              ),
            ),

            const SizedBox(height: 16),

            // Expiration Date dengan icon jam merah
            SizedBox(
              width: double.infinity,
              child: _buildDetailRow(
                icon: Icons.access_time,
                iconColor: Colors.red,
                title: 'Expiration Date',
                value: subscriptionData.endDate != null
                  ? subscriptionData.formatDate(subscriptionData.endDate!)
                  : 'Lifetime',
              ),
            ),

            const SizedBox(height: 16),

            // Auto-Renewal dengan icon recycle + Active di kanan
            Container(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bagian kiri: Icon + Text
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.autorenew,
                            size: 18,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 14),
                        
                        // Text Auto-Renewal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-Renewal',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPremiumUser && subscriptionData.endDate != null
                                  ? 'Next billing: ${_formatShortDate(subscriptionData.endDate!)}'
                                  : 'Not applicable',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Active di kanan
                  Padding(
                    padding: const EdgeInsets.only(top: 20), // Align dengan text value
                    child: Row(
                      children: [
                        Text(
                          subscriptionData.status == 'active' ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: subscriptionData.status == 'active'
                                ? Colors.green.shade700
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: subscriptionData.status == 'active'
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 14),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Short date formatting untuk Auto-Renewal
  String _formatShortDate(DateTime date) {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }
}