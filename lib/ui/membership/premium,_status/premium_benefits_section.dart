import 'package:flutter/material.dart';

class PremiumBenefitsSection extends StatelessWidget {
  final List<String> benefits = const [
    "Unlimited meditation sessions",
    "Access to exclusive content",
    "Offline downloads available",
    "Ad-free experience",
    "Priority customer support",
  ];

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // ICON BOX
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Color(0xFFEDE3FF), // ungu pastel
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF8A4DFF), // deep purple icon
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // TEXT
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3C3C43),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white, // ← PUTIH SOLID
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE
          const Text(
            "Premium Benefits",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3C3C43),
            ),
          ),

          const SizedBox(height: 16),

          // BENEFIT LIST
          for (var item in benefits) _buildBenefitItem(item),
        ],
      ),
    );
  }
}
