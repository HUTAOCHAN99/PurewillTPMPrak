import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/ui/auth/auth_provider.dart';
import 'package:purewill/ui/auth/screen/login_screen.dart';
import 'package:purewill/ui/auth/screen/verif_screen.dart';
import 'package:purewill/ui/auth/view_model/auth_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool _obscurePassword = true;
  final TextEditingController _fullNameController = TextEditingController(text: 'example');
  final TextEditingController _emailController = TextEditingController(text: 'mountdev10@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: 'Rumah_12345');
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

// <<<<<<< HEAD
//   Future<void> _signUp() async {
//     try {
//           await ref
//               .read(
//                 authNotifierProvider.notifier,
//               )
//               .signup(
//                 _fullNameController.text.trim(),
//                 _emailController.text.trim(),
//                 _passwordController.text.trim(),
//               );
//           if (!mounted) return;

//           _showSnackBar("Registrasi Berhasil! Mengalihkan...");

//           await Future.delayed(const Duration(seconds: 1));

//           if (!mounted) return;

//           Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (context) => VerificationScreen(
//               email: _emailController.text.trim(),
//               type: VerificationType.registration,
//             ),
//           ),
//         );

//         } catch (e) {
//           if (mounted) {
//             _showSnackBar(
//                 "Login Gagal: ${e.toString().replaceFirst('Exception: ', '')}");
//           }
//         }
// =======
 Future<void> _signUp() async {
  if (!_formKey.currentState!.validate()) return;
  
  try {
    // Tampilkan loading
    setState(() {
    });
    
    // 1. Sign up user
    await ref.read(authNotifierProvider.notifier).signup(
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    
    if (!mounted) return;
    
    // 2. Tampilkan pesan sukses
    _showSnackBar("Registrasi Berhasil! Kode OTP telah dikirim ke email.");
    
    // 3. Check OTP status
    final currentUser = Supabase.instance.client.auth.currentUser;
    // print('User after signup: ${currentUser?.email}');
    // print('User confirmed: ${currentUser?.confirmedAt}');
    
    // 4. Navigasi ke verification screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VerificationScreen(
          email: _emailController.text.trim(),
          type: VerificationType.registration,
        ),
      ),
    );
    
  } on AuthException catch (e) {
    _showSnackBar("Registrasi Gagal: ${e.message}");
    
    // Log error detail
    // print('AuthException: ${e.message}');
    // print('Status: ${e.statusCode}');
    
  } catch (e) {
    _showSnackBar("Terjadi kesalahan: $e");
    // print('Error: $e');
  } finally {
    if (mounted) {
      setState(() {
      });
    }
// >>>>>>> f2d2932ae1d617906d117abaeeb90fd7045aea0c
  }
}

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                      child: Form(
                        key: _formKey,
                        child: Container(
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
                                      child: Image.asset(
                                        "assets/images/auth/sun_icon.png",
                                        width: screenWidth * 0.06,
                                        height: screenWidth * 0.06,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "New",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Journey",
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

                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 254, 254, 254),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      217,
                                      217,
                                      217,
                                      255,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _fullNameController,
                                        style: const TextStyle(fontSize: 16),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          hintText: "Enter full your name",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[500],
                                          ),
                                          errorStyle: const TextStyle(
                                            fontSize: 0,
                                            height: 0,
                                          ),
                                        ),
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
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        "assets/images/auth/persons.png",
                                        width: 24,
                                        height: 24,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16),

                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 254, 254, 254),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      217,
                                      217,
                                      217,
                                      255,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailController,
                                        style: const TextStyle(fontSize: 16),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          hintText: "Enter your email address",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[500],
                                          ),
                                          errorStyle: const TextStyle(
                                            fontSize: 0,
                                            height: 0,
                                          ),
                                        ),
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
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        "assets/images/auth/mail.png",
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16),

                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 254, 254, 254),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      217,
                                      217,
                                      217,
                                      255,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(fontSize: 16),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          hintText: "Create a Password",
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                          ),
                                          errorStyle: const TextStyle(
                                            fontSize: 0,
                                            height: 0,
                                          ),
                                        ),
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
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () =>
                                            _obscurePassword = !_obscurePassword,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : _signUp,
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
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "Register",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(),
                                      ),
                                    ),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Color.fromRGBO(82, 140, 207, 1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 16, bottom: 16),
                        child: Text(
                          "By registering, you agree to our Terms of Service and Privacy Policy",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.03,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Column(
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
                                color: Color.fromRGBO(82, 140, 207, 1),
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}