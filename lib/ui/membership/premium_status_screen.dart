// lib/ui/membership/premium_status/premium_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/membership/plan_provider.dart';
import 'package:purewill/ui/habit-tracker/widget/clean_bottom_navigation_bar.dart';
import 'package:purewill/ui/membership/premium,_status/action_buttons.dart';
import 'package:purewill/ui/membership/premium,_status/current_plan_details.dart';
import 'package:purewill/ui/membership/premium,_status/dialogs/cancel_subscription_dialog.dart';
import 'package:purewill/ui/membership/premium,_status/dialogs/manage_subscription_dialog.dart';
import 'package:purewill/ui/membership/premium,_status/premium_benefits_section.dart';
import 'package:purewill/ui/membership/premium,_status/premium_status_card.dart';
import 'package:purewill/ui/membership/premium,_status/subscription_data.dart';
import 'package:purewill/ui/membership/premium,_status/team_support_section.dart';


class PremiumStatusScreen extends ConsumerStatefulWidget {
  const PremiumStatusScreen({super.key});
  
  @override
  ConsumerState<PremiumStatusScreen> createState() => _PremiumStatusScreenState();
}

class _PremiumStatusScreenState extends ConsumerState<PremiumStatusScreen> {
  int _currentIndex = 0;
  SubscriptionData _subscriptionData = SubscriptionData();
  bool _isLoadingSubscriptionDetails = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planProvider.notifier).refresh();
      _loadSubscriptionDetails();
    });
  }

  Future<void> _loadSubscriptionDetails() async {
    try {
      setState(() {
        _isLoadingSubscriptionDetails = true;
      });

      await _subscriptionData.loadSubscriptionData();
      
      setState(() {
        _isLoadingSubscriptionDetails = false;
      });
    } catch (e) {
      print('Error loading subscription details: $e');
      setState(() {
        _isLoadingSubscriptionDetails = false;
      });
    }
  }

  void _onNavBarTap(int index) {
    if (index == 2) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _currentIndex = index;
      });
      if (index == 0) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);
    final currentPlan = planState.currentPlan;
    final isPremiumUser = planState.isUserPremium ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Premium Status',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: planState.isLoading || _isLoadingSubscriptionDetails
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      PremiumStatusCard(
                        isPremiumUser: isPremiumUser,
                        currentPlan: currentPlan,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Current Plan Details Section
                      CurrentPlanDetails(
                        currentPlan: currentPlan,
                        isPremiumUser: isPremiumUser,
                        subscriptionData: _subscriptionData,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Premium Benefits Section
                      PremiumBenefitsSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Team Support Section
                      TeamSupportSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      ActionButtons(
                        isPremiumUser: isPremiumUser,
                        onManageSubscription: () {
                          showManageSubscriptionDialog(
                            context: context,
                            onNavigateToMembership: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                            onCancelSubscription: () {
                              Navigator.of(context).pop();
                              showCancelSubscriptionDialog(
                                context: context,
                                onCancel: () async {
                                  await ref.read(planProvider.notifier).cancelSubscription();
                                  await _loadSubscriptionDetails();
                                },
                              );
                            },
                          );
                        },
                        onCancelSubscription: () {
                          showCancelSubscriptionDialog(
                            context: context,
                            onCancel: () async {
                              await ref.read(planProvider.notifier).cancelSubscription();
                              await _loadSubscriptionDetails();
                            },
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
      bottomNavigationBar: CleanBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}