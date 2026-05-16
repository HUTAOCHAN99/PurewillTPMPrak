// lib/ui/membership/widgets/plan_summary_card.dart
import 'package:flutter/material.dart';
import 'package:purewill/domain/model/plan_model.dart';

class PlanSummaryCard extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;

  const PlanSummaryCard({
    super.key,
    required this.plan,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? plan.type == 'free'
                  ? Colors.blue
                  : Colors.deepPurple
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge jika ada
          if (plan.badgeText != null ||
              plan.isPromoActive ||
              plan.hasPromo) ...[
            Row(
              children: [
                if (plan.badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: plan.badgeText == 'POPULAR'
                          ? Colors.orange
                          : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plan.badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (plan.isPromoActive && plan.hasPromo) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${plan.discountPercentage.toStringAsFixed(0)}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (plan.isPromoActive) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Berlaku hingga ${plan.promoEndDate!.day}/${plan.promoEndDate!.month}/${plan.promoEndDate!.year}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Title
          Text(
            plan.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: plan.type == 'free'
                  ? Colors.blue
                  : Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.formattedPrice,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: plan.type == 'free'
                      ? Colors.green
                      : Colors.deepPurple,
                ),
              ),
              if (plan.type != 'free') const SizedBox(width: 4),
              if (plan.type != 'free')
                Text(
                  plan.type == 'yearly' ? '/tahun' : '/bulan',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),

          // Original Price jika ada diskon
          if (plan.hasPromo && plan.formattedOriginalPrice != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                plan.formattedOriginalPrice!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),

          const SizedBox(height: 16),
          const Divider(color: Colors.grey, height: 1),

          // Features
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: plan.features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: plan.type == 'free'
                              ? Colors.blue
                              : Colors.deepPurple,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}