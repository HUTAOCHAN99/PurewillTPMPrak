import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/auth/auth_provider.dart';
import 'package:purewill/ui/auth/screen/newpassword_screen.dart';
import 'package:purewill/ui/auth/view_model/auth_view_model.dart';

enum VerificationType { registration, resetPassword }

class VerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final VerificationType type;

  const VerificationScreen({
    super.key,
    required this.email,
    this.type = VerificationType.registration,
  });

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final ScrollController _scrollController = ScrollController();

  int _countdown = 30;
  bool _isCountdownActive = true;
  bool _isVerifying = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _controllers[i].text.isEmpty) {
          _controllers[i].selection = TextSelection.collapsed(offset: 0);
        }
      });
    }
  }

  void _startCountdown() {
    _countdown = 30;
    _isCountdownActive = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _isCountdownActive = false;
          timer.cancel();
        }
      });
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  String? getCode() {
    final code = _controllers.map((controller) => controller.text).join();
    if (code.length != 6) {
      _showSnackBar("Please enter the complete 6-digit code");
      return null;
    }
    return code;
  }

  void _resendCode() async {
    if (!_isCountdownActive) {
      _startCountdown();
      try {
        if (widget.type == VerificationType.registration) {
          await ref.read(authNotifierProvider.notifier).resendSignupOTP(widget.email);
        } else {
          await ref
              .read(authNotifierProvider.notifier)
              .resendPasswordResetOtp(widget.email);
        }
      } catch (e) {
        _showSnackBar("Failed to resend code: $e");
      }
    }
  }

  Future<void> verifCode() async {
    final otp = getCode();
    if (otp != null) {
      if (widget.type == VerificationType.registration) {
        await ref
            .read(authNotifierProvider.notifier)
            .verifySignupOtp(widget.email, otp);
      } else {
        ref
            .read(authNotifierProvider.notifier)
            .verifyPasswordResetOtp(widget.email, otp);
      }

      if (!mounted) return;
      _showSnackBar("Verification Code Correct! ");

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      if (widget.type == VerificationType.registration) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false,); 
      } else {
        Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  NewPasswordScreen(key: widget.key, email: widget.email),
            ),
          );
      }



    }
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _controllers) controller.dispose();
    for (var focusNode in _focusNodes) focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
          
          
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/auth/bg2.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                children: [
                  Container(
                    height: screenHeight * 0.25,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: screenWidth * 0.25,
                          height: screenWidth * 0.25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: const Color.fromRGBO(102, 121, 163, 1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                "assets/images/auth/icon.png",
                                width: screenWidth * 0.24,
                                height: screenWidth * 0.24,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          "Your journey to self-control starts here",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: screenWidth * 0.15,
                                      height: screenWidth * 0.12,
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                          82,
                                          140,
                                          207,
                                          1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.lock,
                                          color: Colors.white,
                                          size: screenWidth * 0.08,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Enter",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.038,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Verification",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.038,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Code",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.038,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: screenHeight * 0.02),

                                Center(
                                  child: Text(
                                    "Enter the 6-digit code sent to your email",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Center(
                                  child: Text(
                                    widget.email,
                                    style: TextStyle(
                                      color: Color.fromRGBO(82, 140, 207, 1),
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Verification Code",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(6, (index) {
                                        return SizedBox(
                                          width: screenWidth * 0.12,
                                          child: TextField(
                                            controller: _controllers[index],
                                            focusNode: _focusNodes[index],
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            maxLength: 1,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: InputDecoration(
                                              counterText: "",
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color.fromARGB(
                                                    217,
                                                    217,
                                                    217,
                                                    255,
                                                  ),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              if (value.length == 1 &&
                                                  index < 5) {
                                                _focusNodes[index + 1]
                                                    .requestFocus();
                                              }
                                              if (value.isEmpty && index > 0) {
                                                _focusNodes[index - 1]
                                                    .requestFocus();
                                              }

                                              if (_isAllFieldsFilled()) {
                                                verifCode();
                                              }
                                            },
                                            onTap: () {
                                              Future.delayed(
                                                const Duration(milliseconds: 300),
                                                () {
                                                  _scrollController.animateTo(
                                                    _scrollController.position.maxScrollExtent,
                                                    duration: const Duration(milliseconds: 300),
                                                    curve: Curves.easeOut,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),

                                SizedBox(height: screenHeight * 0.02),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                          try {
                                            await verifCode();
                                          } catch (e) {
                                            _showSnackBar("verifikasi Gagal: $e");
                                          }

                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isVerifying
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            "Verify Code",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),

                                SizedBox(height: screenHeight * 0.02),

                                Column(
                                  children: [
                                    Center(
                                      child: Text(
                                        "Didn't receive code?",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Center(
                                      child: _isCountdownActive
                                          ? Text(
                                              "Resend code in $_countdown seconds",
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: screenWidth * 0.035,
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: _resendCode,
                                              child: Text(
                                                "Resend Code",
                                                style: TextStyle(
                                                  color: Color.fromRGBO(
                                                    82,
                                                    140,
                                                    207,
                                                    1,
                                                  ),
                                                  fontSize: screenWidth * 0.038,
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    child: Column(
                      children: [
                        Text(
                          "Need help?",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            "Contact support",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isAllFieldsFilled() =>
      _controllers.every((controller) => controller.text.isNotEmpty);
}