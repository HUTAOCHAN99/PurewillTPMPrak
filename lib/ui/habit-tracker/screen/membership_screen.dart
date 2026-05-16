import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/habit-tracker/widget/clean_bottom_navigation_bar.dart';
import 'package:purewill/ui/membership/plan_provider.dart';
import 'package:purewill/domain/model/plan_model.dart';
import 'package:purewill/ui/membership/payment_confirmation_screen.dart';
import 'package:purewill/ui/membership/premium_status_screen.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});
  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  int _selectedPlanIndex = 1; // Default ke monthly
  int _currentIndex = 0;
  String _planType = 'monthly'; // 'monthly' or 'yearly'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planProvider.notifier).loadPlans();
    });
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

  void _handlePlanTypeChange(String type) {
    setState(() {
      _planType = type;
      // Reset selection ke plan pertama dari tipe yang dipilih
      _selectedPlanIndex = 0;
    });
  }

  Future<void> _handleSubscribe(PlanModel plan) async {
    // Skip payment confirmation untuk plan free
    if (plan.type == 'free') {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        await ref.read(planProvider.notifier).subscribeToPlan(plan.id);

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully activated ${plan.name} plan!'),
              backgroundColor: Colors.green,
            ),
          );

          // Kembali ke home setelah beberapa detik
          await Future.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to activate plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Untuk plan premium, langsung navigate ke payment confirmation screen
    // User akan memilih payment method di sana
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(
              selectedPlan: plan,
              paymentMethod:
                  '', // Kosongkan dulu, user akan pilih di screen payment
            ),
          ),
        )
        .then((value) async {
          // Jika payment berhasil (value == true), proses subscription
          if (value == true && context.mounted) {
            // Tampilkan loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );

            try {
              await ref.read(planProvider.notifier).subscribeToPlan(plan.id);

              if (context.mounted) {
                Navigator.of(context).pop(); // Tutup loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully subscribed to ${plan.name}!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.of(context).pop(); // Tutup loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);
    final currentUserPlan = planState.currentPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PureWill',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
          child: planState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : planState.error != null
              ? Center(child: Text(planState.error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo dan Title
                      const SizedBox(height: 16),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose Your Plan',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Unlock your full potential with premium features',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black45),
                        ),
                      ),

                      // Tampilkan plan current user jika ada
                      if (currentUserPlan != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PremiumStatusScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current Plan: ${currentUserPlan.name}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Free Plan Card
                      if (planState.freePlan != null)
                        _buildPlanCard(
                          plan: planState.freePlan!,
                          isSelected:
                              _selectedPlanIndex == 0 &&
                              planState.freePlan!.type == 'free',
                          onTap: () => setState(() => _selectedPlanIndex = 0),
                          onSubscribe: _handleSubscribe,
                        ),

                      const SizedBox(height: 20),
                      const Divider(thickness: 2),
                      const SizedBox(height: 20),

                      // Toggle untuk monthly/yearly jika ada premium plans
                      if (planState.premiumPlans.isNotEmpty)
                        _buildPlanTypeToggle(
                          onChanged: _handlePlanTypeChange,
                          initialValue: _planType,
                        ),
                      if (planState.premiumPlans.isNotEmpty)
                        const SizedBox(height: 20),

                      // Premium Plan Cards berdasarkan tipe
                      ...planState.premiumPlans
                          .where((plan) => plan.type == _planType)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final plan = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(bottom: 20),
                              child: _buildPlanCard(
                                plan: plan,
                                isSelected: _selectedPlanIndex == index + 1,
                                onTap: () => setState(
                                  () => _selectedPlanIndex = index + 1,
                                ),
                                onSubscribe: _handleSubscribe,
                              ),
                            );
                          })
                          .toList(),

                      const SizedBox(height: 40),

                      // Why Choose Premium Section
                      _buildWhyChoosePremiumSection(),

                      const SizedBox(height: 40),

                      // Terms and Conditions
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Dengan memilih paket, Anda menyetujui Syarat & Ketentuan dan Kebijakan Privasi PureWill',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildPlanTypeToggle({
    required Function(String) onChanged,
    required String initialValue,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged('monthly'),
              child: Container(
                decoration: BoxDecoration(
                  color: initialValue == 'monthly'
                      ? Colors.deepPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    'Monthly',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: initialValue == 'monthly'
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged('yearly'),
              child: Container(
                decoration: BoxDecoration(
                  color: initialValue == 'yearly'
                      ? Colors.deepPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    'Yearly',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: initialValue == 'yearly'
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required PlanModel plan,
    required bool isSelected,
    required VoidCallback onTap,
    required Function(PlanModel) onSubscribe,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                        horizontal: 12,
                        vertical: 4,
                      ),
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
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                      style: const TextStyle(fontSize: 10, color: Colors.red),
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
                color: plan.type == 'free' ? Colors.blue : Colors.deepPurple,
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

            const SizedBox(height: 20),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onSubscribe(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.type == 'free'
                      ? Colors.blue
                      : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  plan.type == 'free' ? 'Gunakan Sekarang' : 'Pilih Paket Ini',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyChoosePremiumSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            'Why Choose Premium?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get access to exclusive features that enhance your experience',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 32),

          // Features Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildPremiumFeature(
                icon: Icons.analytics_outlined,
                title: 'Advanced Analytics',
              ),
              _buildPremiumFeature(
                icon: Icons.cloud_sync_outlined,
                title: 'Cloud Sync',
              ),
              _buildPremiumFeature(
                icon: Icons.notifications_active_outlined,
                title: 'Smart Reminders',
              ),
              _buildPremiumFeature(
                icon: Icons.workspace_premium_outlined,
                title: 'Exclusive Badges',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.deepPurple.shade100, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.deepPurple.shade400, Colors.blue.shade400],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade800,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
