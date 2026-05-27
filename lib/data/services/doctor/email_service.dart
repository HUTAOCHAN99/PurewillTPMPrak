// lib/data/services/email_service.dart
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmailService {
  
  // Untuk DEVELOPMENT: hanya print OTP ke console dan copy ke clipboard
  static Future<void> sendOTPDev({
    required String toEmail,
    required String otpCode,
    required String fullName,
    BuildContext? context,
  }) async {
    dev.log('╔════════════════════════════════════════════════════════════╗', name: 'DEV_EMAIL');
    dev.log('║                    DOCTOR ACTIVATION OTP                    ║', name: 'DEV_EMAIL');
    dev.log('╠════════════════════════════════════════════════════════════╣', name: 'DEV_EMAIL');
    dev.log('║ To Email: $toEmail', name: 'DEV_EMAIL');
    dev.log('║ User Name: $fullName', name: 'DEV_EMAIL');
    dev.log('║ OTP Code: $otpCode', name: 'DEV_EMAIL');
    dev.log('║                                                            ║', name: 'DEV_EMAIL');
    dev.log('║ Enter this OTP in the app to activate doctor account       ║', name: 'DEV_EMAIL');
    dev.log('╚════════════════════════════════════════════════════════════╝', name: 'DEV_EMAIL');
    
    // Copy OTP to clipboard for easy testing
    await Clipboard.setData(ClipboardData(text: otpCode));
    dev.log('📋 OTP copied to clipboard: $otpCode', name: 'DEV_EMAIL');
    
    // Show snackbar if context provided
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP: $otpCode (copied to clipboard)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  
  // Untuk PRODUCTION: Kirim email via SMTP Gmail
  static Future<bool> sendDoctorActivationOTP({
    required String toEmail,
    required String otpCode,
    required String fullName,
  }) async {
    try {
      // Untuk sementara, karena SMTP memerlukan konfigurasi,
      // kita gunakan mode development dulu
      dev.log('⚠️ SMTP not configured yet, using development mode', name: 'EMAIL_SERVICE');
      
      // Tampilkan OTP di console untuk production testing
      dev.log('========== PRODUCTION MODE (SMTP PENDING) ==========', name: 'EMAIL_SERVICE');
      dev.log('To: $toEmail', name: 'EMAIL_SERVICE');
      dev.log('OTP: $otpCode', name: 'EMAIL_SERVICE');
      dev.log('Template: Custom HTML with your design', name: 'EMAIL_SERVICE');
      dev.log('====================================================', name: 'EMAIL_SERVICE');
      
      return true;
      
    } catch (e) {
      dev.log('Error sending email: $e', name: 'EMAIL_SERVICE');
      return false;
    }
  }
  
  // Build HTML email template (matching your design)
  static String _buildEmailTemplate(String otpCode, String fullName) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Doctor Activation Code</title>
</head>
<body style="margin: 0; padding: 20px; font-family: Arial, sans-serif; background-color: #f5f5f5;">
  <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 12px; padding: 40px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
    <h2 style="color: #00BFA5; margin-bottom: 20px;">Welcome to PureWill!</h2>
    
    <p style="font-size: 16px; line-height: 1.5; color: #333;">Halo $fullName,</p>
    
    <p style="font-size: 16px; line-height: 1.5; color: #333;">Your Doctor activation code is:</p>
    
    <h1 style="font-size: 42px; letter-spacing: 8px; margin: 30px 0; text-align: center; color: #00BFA5; background-color: #f0f0f0; padding: 20px; border-radius: 8px; font-family: monospace;">
      $otpCode
    </h1>
    
    <p style="font-size: 16px; line-height: 1.5; color: #333;">Enter this code in the app to complete your doctor activation.</p>
    
    <p style="color: #666; font-size: 14px; margin-top: 20px;">
      This code will expire in <strong>24 hours</strong>.
    </p>
    
    <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
    
    <small style="color: #999; font-size: 12px;">
      PureWill - Your journey to self-control starts here<br>
      If you didn't request this, please ignore this email.
    </small>
  </div>
</body>
</html>
    ''';
  }
  
  // For production with SMTP (Gmail example)
  // Uncomment and configure when ready
  /*
  static Future<bool> sendEmailSMTP({
    required String toEmail,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final smtpServer = gmail('purewill.app@gmail.com', 'your_app_password');
      final message = Message()
        ..from = Address('purewill.app@gmail.com', 'PureWill')
        ..recipients.add(toEmail)
        ..subject = subject
        ..html = htmlContent;
      
      final sendReport = await send(message, smtpServer);
      dev.log('Email sent: ${sendReport.toString()}', name: 'EMAIL_SERVICE');
      return true;
    } catch (e) {
      dev.log('SMTP Error: $e', name: 'EMAIL_SERVICE');
      return false;
    }
  }
  */
}