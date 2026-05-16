// lib/ui/membership/payment_confirmation_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/domain/model/plan_model.dart';
import 'package:purewill/ui/habit-tracker/widget/clean_bottom_navigation_bar.dart';

// Import widget yang sudah dipisah
import 'widgets/payment_method_card.dart';
import 'widgets/plan_summary_card.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/subscription_success_dialog.dart';
import 'widgets/payment_section_card.dart';

class PaymentConfirmationScreen extends ConsumerStatefulWidget {
  final PlanModel selectedPlan;
  final String paymentMethod;
  
  const PaymentConfirmationScreen({
    super.key,
    required this.selectedPlan,
    required this.paymentMethod,
  });

  @override
  ConsumerState<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends ConsumerState<PaymentConfirmationScreen> {
  int _currentIndex = 0;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _selectedPaymentMethod;
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: 'gopay',
      name: 'GoPay',
      description: '(e-wallet, [views])',
      icon: Icons.account_balance_wallet,
      iconColor: Colors.purple,
    ),
    PaymentMethod(
      id: 'dana',
      name: 'DANA',
      description: '(e-wallet, friendly...)',
      icon: Icons.account_balance,
      iconColor: Colors.blue,
    ),
    PaymentMethod(
      id: 'ovo',
      name: 'OVO',
      description: '(e.g., YouTube)',
      icon: Icons.payment,
      iconColor: Colors.purple,
    ),
    PaymentMethod(
      id: 'credit_card',
      name: 'Credit/Debit Card',
      description: '(Visa, MasterCard, JCB)',
      icon: Icons.credit_card,
      iconColor: Colors.indigo,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethod.isNotEmpty) {
      _selectedPaymentMethod = widget.paymentMethod;
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

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      final random = Random().nextDouble();
      if (random < 0.95) {
        setState(() {
          _isProcessing = false;
        });

        // Tampilkan dialog subscription success
        await _showSubscriptionSuccessDialog();
        
      } else {
        throw Exception('Payment failed. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showSubscriptionSuccessDialog() async {
    if (!mounted) return; // Tambahkan check mounted
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionSuccessDialog(
        onGoToDashboard: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(true); // Return to membership screen
        },
        onViewReceipt: () {
          // TODO: Implement view receipt functionality
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(true); // Return to membership screen
        },
      ),
    );
  }

  void _selectPaymentMethod(String methodId) {
    setState(() {
      _selectedPaymentMethod = methodId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Confirmation',
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFEEEEEE),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan gaya yang sama
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Complete Your Payment',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Select payment method and confirm your subscription',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Plan Summary Card
                PlanSummaryCard(
                  plan: widget.selectedPlan,
                  isSelected: true,
                ),
                const SizedBox(height: 16),

                // Order Summary
                OrderSummaryCard(selectedPlan: widget.selectedPlan),
                const SizedBox(height: 16),

                // What's Included Section
                _buildWhatsIncludedSection(),
                const SizedBox(height: 16),

                // Payment Method Selection
                PaymentMethodCard(
                  paymentMethods: _paymentMethods,
                  selectedPaymentMethod: _selectedPaymentMethod,
                  onPaymentMethodSelected: _selectPaymentMethod,
                ),

                const SizedBox(height: 20),

                // Error Message (jika ada)
                if (_errorMessage != null) _buildErrorMessage(),

                const SizedBox(height: 20),

                // Payment Button
                _buildPaymentButton(),

                const SizedBox(height: 20),

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

  Widget _buildWhatsIncludedSection() {
    return PaymentSectionCard(
      title: "What's Included:",
      icon: Icons.check_circle,
      iconColor: widget.selectedPlan.type == 'free' ? Colors.blue : Colors.deepPurple,
      children: widget.selectedPlan.features.map((feature) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                color: widget.selectedPlan.type == 'free' 
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
        )
      ).toList(),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Complete Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

// Model untuk payment method (tetap di file ini karena kecil)
class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}