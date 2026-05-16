// lib/ui/membership/widgets/payment_method_card.dart
import 'package:flutter/material.dart';
import 'package:purewill/ui/membership/payment_confirmation_screen.dart';

class PaymentMethodCard extends StatelessWidget {
  final List<PaymentMethod> paymentMethods;
  final String? selectedPaymentMethod;
  final Function(String) onPaymentMethodSelected;

  const PaymentMethodCard({
    super.key,
    required this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your preferred payment method',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // List Payment Methods
          Column(
            children: paymentMethods.map((method) => 
              GestureDetector(
                onTap: () => onPaymentMethodSelected(method.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedPaymentMethod == method.id
                        ? Colors.deepPurple[50]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedPaymentMethod == method.id
                          ? Colors.deepPurple
                          : Colors.grey[300]!,
                      width: selectedPaymentMethod == method.id ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: method.iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          method.icon,
                          color: method.iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: selectedPaymentMethod == method.id
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selectedPaymentMethod == method.id
                                    ? Colors.deepPurple
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              method.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selectedPaymentMethod == method.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selectedPaymentMethod == method.id
                            ? Colors.deepPurple
                            : Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              )
            ).toList(),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'You can choose and add some a little button to your system or address your system. It doesn\'t change.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}