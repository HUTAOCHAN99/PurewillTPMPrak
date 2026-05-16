// lib\ui\habit-tracker\widget\premium_card_button.dart - VERSI SIMPLE
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:purewill/domain/model/plan_model.dart';

class PremiumCardButton extends StatelessWidget {
  final bool isPremiumUser;
  final PlanModel? currentPlan;
  final VoidCallback onTap;

  const PremiumCardButton({
    super.key,
    required this.isPremiumUser,
    this.currentPlan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isPremiumUser
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3A2DA5),
                    Color(0xFF0C5FA8),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade200,
                  ],
                ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isPremiumUser ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // --- DECORATIVE CIRCLES (only for premium) ---
            if (isPremiumUser) ...[
              // Top Right Circle
              Align(
                alignment: Alignment.topRight,
                child: Transform.translate(
                  offset: const Offset(40, -40),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
              ),

              // Center Right Circle
              Align(
                alignment: Alignment.centerRight,
                child: Transform.translate(
                  offset: const Offset(50, 0),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                ),
              ),

              // Bottom Left Circle
              Align(
                alignment: Alignment.bottomLeft,
                child: Transform.translate(
                  offset: const Offset(-40, 40),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
              ),
            ],

            // --- MAIN CONTENT ---
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ICON
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPremiumUser
                            ? Colors.white.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.1),
                        border: Border.all(
                          color: isPremiumUser
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: isPremiumUser
                          ? const Icon(
                              FontAwesomeIcons.crown,
                              color: Color(0xFFFFEB3B),
                              size: 35,
                            )
                          : const Icon(
                              Icons.star_border,
                              color: Colors.grey,
                              size: 35,
                            ),
                    ),
                    const SizedBox(height: 12),

                    // TITLE - Template tetap
                    const Text(
                      "JOIN MEMBER NOW!!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 6),

                    // SUBTITLE - Template tetap
                    const Text(
                      "Active Subscription",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),

                    // ACTION BUTTON (for free users)
                    if (!isPremiumUser) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Upgrade Now",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3A2DA5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF3A2DA5),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // CURRENT PLAN INFO (for premium users)
                    if (isPremiumUser && currentPlan != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              currentPlan!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentPlan!.formattedPrice,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}