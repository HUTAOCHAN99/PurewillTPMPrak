import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:purewill/domain/model/plan_model.dart';

class PremiumStatusCard extends StatelessWidget {
  final bool isPremiumUser;
  final PlanModel? currentPlan;

  const PremiumStatusCard({
    super.key,
    required this.isPremiumUser,
    this.currentPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (isPremiumUser) ...[
            // --- SOFT CIRCLE TOP RIGHT menggunakan Alignment ---
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

            // --- SOFT CIRCLE CENTER menggunakan Alignment ---
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

            // --- SOFT CIRCLE BOTTOM LEFT menggunakan Alignment ---
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

          // --- CONTENT ---
          Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ICON dengan FontAwesome crown untuk premium
                  isPremiumUser
                      ? Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            FontAwesomeIcons.crown,
                            color: Color(0xFFFFEB3B),
                            size: 35,
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                  const SizedBox(height: 12),

                  // TITLE
                  Text(
                    isPremiumUser ? "PREMIUM MEMBER" : "FREE MEMBER",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isPremiumUser ? Colors.white : Colors.grey.shade800,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),

                  const SizedBox(height: 6),

                  // SUBTITLE
                  Text(
                    isPremiumUser ? "Active Subscription" : "Free Plan",
                    style: TextStyle(
                      fontSize: 14,
                      color: isPremiumUser
                          ? Colors.white.withOpacity(0.85)
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}