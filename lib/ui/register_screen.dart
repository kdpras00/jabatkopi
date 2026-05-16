import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/network/api_client.dart';
import 'widgets/jk_glass_card.dart';
import 'widgets/jk_primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient().post('/auth/register', {
        'name': _nameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&w=800'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Ubah ke center untuk branding
            children: [
              const SizedBox(height: 60),
              const Text(
                'JABAT KOPI',
                style: TextStyle(
                  color: AppColors.caramelGold,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const Text(
                'PREMIUM COFFEE EXPERIENCE',
                style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 64),
              Form(
                key: _formKey,
                child: JkGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildTextField('Full Name', _nameController, icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField('Username', _usernameController, icon: Icons.alternate_email),
                      const SizedBox(height: 16),
                      _buildTextField('Email', _emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextField('Password', _passwordController, icon: Icons.lock_outline, obscureText: true),
                      const SizedBox(height: 32),
                      _isLoading 
                        ? const CircularProgressIndicator(color: AppColors.caramelGold)
                        : JkPrimaryButton(
                            label: 'CREATE ACCOUNT',
                            onPressed: _register,
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Login', style: TextStyle(color: AppColors.caramelGold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {required IconData icon, bool obscureText = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.caramelGold, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.caramelGold.withOpacity(0.5), size: 20),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
