import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String role = "user";
  bool loading = false;
  bool _adminExists = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final exists = await AuthService.checkAdminExists();
    if (mounted) {
      setState(() {
        _adminExists = exists;
        if (exists) {
          role = "user"; // Force to user if admin exists
        }
      });
    }
  }

  Future<void> signup() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields required")),
      );
      return;
    }

    if (role == "admin") {
      // Must be strictly alphanumeric, >=8 chars, >=1 uppercase, >=1 lowercase, >=1 digit
      final RegExp regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$');
      if (!regex.hasMatch(pass)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Admin password must be 8+ characters, with at least one uppercase letter, one lowercase letter, one number, and absolutely NO special characters.",
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
    }

    setState(() => loading = true);

    try {
      await AuthService.register(name, email, pass, role);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// TOP IMAGE
            Stack(
              children: [
                SizedBox(
                  height: Responsive.isMobile(context) ? 250 : 400,
                  width: double.infinity,
                  child: Image.network(
                    "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa",
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: Responsive.isMobile(context) ? 250 : 400,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0F172A).withOpacity(0.8),
                        const Color(0xFF0F172A),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 30,
                  left: 20,
                  child: Text(
                    "HostelHub",
                    style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),

            /// SIGNUP CARD
            Padding(
              padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_adminExists)
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(
                            labelText: "Account Type",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "user",
                              child: Text("User"),
                            ),
                            DropdownMenuItem(
                              value: "admin",
                              child: Text("Admin"),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              role = val!;
                            });
                          },
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "An Admin account already exists. You may only register as a User.",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF6366F1), // Indigo 500
                            foregroundColor: Colors.white,
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Create Account"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
